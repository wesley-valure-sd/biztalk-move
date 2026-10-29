using System.Globalization;
using System.Text;
using Cloud9.Lockbox.Posting;
using Cloud9.Lockbox.X12;

namespace Cloud9.Lockbox.Mapping;

/// <summary>The posts of one insurance transaction set, or the guard message when BizTalk posts nothing.</summary>
public sealed record InsuranceMapResult(IReadOnlyList<InsurancePaymentPost> Posts, string? GuardFailure)
{
    public bool IsGuardFailure => GuardFailure is not null;
}

/// <summary>
/// Maps a BBVA insurance lockbox 835 transaction set to Post835InsuranceTransaction parameters.
/// Copies orchestration Process_BBVA_835Insurance and the maps BBVA_835Insurance_To_ClaimPaymentBatchCanonical and
/// ClaimPaymentCanonical_To_Post835InsuranceTransaction (KnowledgeBase doc 02, flow C).
/// </summary>
public static class InsuranceLockboxMapper
{
    public const int NoteMaxLength = 250;

    public static InsuranceMapResult Map(X12TransactionSet transactionSet, DateTime processingTime)
    {
        ArgumentNullException.ThrowIfNull(transactionSet);
        var segments = transactionSet.Segments;
        if (segments[0][1] != "835") throw new X12FormatException($"Transaction set {transactionSet.ControlNumber} is a {segments[0][1]}, not an 835.");

        // The orchestration counts TS835_2000_Loop (LX) and PLB_ProviderAdjustment in the transaction set.
        var lxCount = segments.Count(s => s.Id == "LX");
        var plbCount = segments.Count(s => s.Id == "PLB");
        if (!(lxCount == 1 || plbCount == 0))
            return new InsuranceMapResult([], $"There were {lxCount} CLP payments and {plbCount} PLB adjustments on transaction {transactionSet.ControlNumber}");

        var firstLx = IndexOf(segments, "LX", 0);
        var headerEnd = firstLx < 0 ? segments.Count : firstLx;
        var bpr = Find(segments, "BPR", 0, headerEnd);
        var trn = Find(segments, "TRN", 0, headerEnd);
        var depositDate = (Find(segments, "DTM", 0, headerEnd, s => s[1] == "405") ?? Find(segments, "DTM", 0, headerEnd))?[2] ?? string.Empty;
        var lockbox = PatientLockboxMapper.GetLockboxNumber(Find(segments, "REF", 0, headerEnd, s => s[1] == "LB")?[2] ?? string.Empty, depositDate);
        var paymentMethod = bpr?[4] ?? string.Empty;
        var checkDate = bpr?[16] ?? string.Empty;
        var traceNumber = NullIfEmpty(trn?[2]);
        // The cumulative concatenate functoids have no scope input, so they collect the CAS of every claim in the
        // transaction set. Each NON claim of the set gets the same lists (checked on C9-P notes, 2026-10-29).
        var (claimAdjustments, serviceAdjustments) = AdjustmentLists(segments, headerEnd);
        // BizTalk sends the current time through GetDateTime, which drops fractions of a second.
        var postTime = processingTime.AddTicks(-(processingTime.Ticks % TimeSpan.TicksPerSecond));

        var posts = new List<InsurancePaymentPost>();
        for (var i = headerEnd; i < segments.Count; i++)
        {
            if (segments[i].Id != "CLP") continue;
            var end = NextLoopStart(segments, i + 1);
            var firstService = IndexOf(segments, "SVC", i + 1, end);
            var claimEnd = firstService < 0 ? end : firstService;
            var clp = segments[i];
            var amount = ParseAmount(clp[4], transactionSet.ControlNumber);

            var baseNote = $"Deposit Date: {depositDate}, Check Date: {checkDate}, Claim Number: {clp[1]}, Lockbox: {lockbox}";
            var note = paymentMethod == "NON"
                ? Left($"{baseNote}, {claimAdjustments}, {serviceAdjustments}", NoteMaxLength)
                : baseNote;

            posts.Add(new InsurancePaymentPost
            {
                TransGuid = Guid.NewGuid(),
                TransDateTime = postTime,
                TransDateTimePosted = postTime,
                PatGuid = ParseGuid(Find(segments, "REF", i + 1, claimEnd, s => s[1] == "EJ")?[2], "REF*EJ", transactionSet.ControlNumber),
                PipGuid = ParseGuid(Find(segments, "REF", i + 1, claimEnd, s => s[1] == "69")?[2], "REF*69", transactionSet.ControlNumber),
                TransAmount = -amount,
                TransDueNowAmount = -amount,
                TransTotalDueAmount = -amount,
                TransNote = note,
                TransReceiptNote = note,
                TransReference = traceNumber,
                TransCheckNumber = traceNumber,
                TransRouting = NullIfEmpty(bpr?[7]),
                AdaClaimNumber = NullIfEmpty(clp[1]),
                PipPolicyNumber = NullIfEmpty(Find(segments, "NM1", i + 1, claimEnd, s => s[1] == "QC")?[9]),
                PtPaymentTypeCode = NullIfEmpty(paymentMethod),
                ClaimIdentifier = NullIfEmpty(trn?[4]),
                PaymentIdentifier = NullIfEmpty(Find(segments, "REF", i + 1, claimEnd, s => s[1] == "F8")?[2]),
                SourceControlNumber = transactionSet.ControlNumber,
            });
        }
        return new InsuranceMapResult(posts, null);
    }

    /// <summary>
    /// The BizTalk cumulative concatenates of "CAS02: CAS03, " over the claim CAS (loop 2100) and the service CAS
    /// (loop 2110) of the whole transaction set, each minus the last two characters. Only the first reason and amount
    /// pair of each CAS segment is used. No CAS gives "".
    /// </summary>
    private static (string Claim, string Service) AdjustmentLists(IReadOnlyList<X12Segment> segments, int from)
    {
        var claim = new StringBuilder();
        var service = new StringBuilder();
        StringBuilder? current = null;
        for (var i = from; i < segments.Count; i++)
        {
            switch (segments[i].Id)
            {
                case "CLP": current = claim; break;
                case "SVC": current = service; break;
                case "LX" or "PLB" or "SE": current = null; break;
                case "CAS": current?.Append(segments[i][2]).Append(": ").Append(segments[i][3]).Append(", "); break;
            }
        }
        return (Left(claim.ToString(), claim.Length - 2), Left(service.ToString(), service.Length - 2));
    }

    /// <summary>The BizTalk String Left functoid: a count of 0 or less gives "".</summary>
    private static string Left(string value, int count) => count <= 0 ? string.Empty : count >= value.Length ? value : value[..count];

    private static string? NullIfEmpty(string? value) => string.IsNullOrEmpty(value) ? null : value;

    private static int NextLoopStart(IReadOnlyList<X12Segment> segments, int from)
    {
        for (var i = from; i < segments.Count; i++)
            if (segments[i].Id is "CLP" or "LX" or "PLB" or "SE") return i;
        return segments.Count;
    }

    private static decimal ParseAmount(string value, string controlNumber) =>
        decimal.TryParse(value, NumberStyles.Number, CultureInfo.InvariantCulture, out var amount)
            ? amount
            : throw new X12FormatException($"CLP04 '{value}' in transaction set {controlNumber} is not a number.");

    // An empty or missing value is not sent, so the procedure receives NULL. The value is not echoed (it can be PHI).
    private static Guid? ParseGuid(string? value, string source, string controlNumber)
    {
        if (string.IsNullOrWhiteSpace(value)) return null;
        return Guid.TryParse(value, out var guid)
            ? guid
            : throw new X12FormatException($"{source} in transaction set {controlNumber} is not a GUID.");
    }

    private static int IndexOf(IReadOnlyList<X12Segment> segments, string id, int from, int to = int.MaxValue)
    {
        for (var i = from; i < Math.Min(to, segments.Count); i++)
            if (segments[i].Id == id) return i;
        return -1;
    }

    private static X12Segment? Find(IReadOnlyList<X12Segment> segments, string id, int from, int to, Func<X12Segment, bool>? match = null)
    {
        for (var i = from; i < to; i++)
            if (segments[i].Id == id && (match is null || match(segments[i]))) return segments[i];
        return null;
    }
}
