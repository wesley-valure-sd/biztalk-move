using System.Globalization;
using Cloud9.Lockbox.Posting;
using Cloud9.Lockbox.X12;

namespace Cloud9.Lockbox.Mapping;

/// <summary>
/// Maps a BBVA patient lockbox 835 transaction set to Post835PatientTransaction parameters.
/// Copies BizTalk maps BBVA_835Patient_To_ClaimPaymentBatchCanonical and
/// ClaimPaymentCanonical_To_Post835PatientTransaction (KnowledgeBase doc 02, flow A).
/// </summary>
public static class PatientLockboxMapper
{
    public static IReadOnlyList<PatientPaymentPost> Map(X12TransactionSet transactionSet, DateTime processingTime)
    {
        ArgumentNullException.ThrowIfNull(transactionSet);
        var segments = transactionSet.Segments;
        if (segments[0][1] != "835") throw new X12FormatException($"Transaction set {transactionSet.ControlNumber} is a {segments[0][1]}, not an 835.");

        var firstLx = IndexOf(segments, "LX", 0);
        var headerEnd = firstLx < 0 ? segments.Count : firstLx;
        var bpr = Find(segments, "BPR", 0, headerEnd);
        var trn = Find(segments, "TRN", 0, headerEnd);
        // BizTalk reads the header DTM (production date, DTM*405). Claim DTM*232/233 are not used.
        var depositDtm = Find(segments, "DTM", 0, headerEnd, s => s[1] == "405") ?? Find(segments, "DTM", 0, headerEnd);
        var lockboxRef = Find(segments, "REF", 0, headerEnd, s => s[1] == "LB");

        var paymentMethod = bpr?[4];
        var routing = bpr?[7];
        var checkDate = bpr?[16] ?? string.Empty;
        var traceNumber = trn?[2];
        var depositDate = depositDtm?[2] ?? string.Empty;
        var note = $"Deposit Date: {depositDate}, Check Date: {checkDate}, Lockbox: {GetLockboxNumber(lockboxRef?[2] ?? string.Empty, depositDate)}";
        // BizTalk sends the current time through FormatDate, which drops fractions of a second.
        var postTime = processingTime.AddTicks(-(processingTime.Ticks % TimeSpan.TicksPerSecond));

        var posts = new List<PatientPaymentPost>();
        for (var i = headerEnd; i < segments.Count; i++)
        {
            if (segments[i].Id != "CLP") continue;
            var end = NextLoopStart(segments, i + 1);
            var clp = segments[i];
            var amount = ParseAmount(clp[4], transactionSet.ControlNumber);

            posts.Add(new PatientPaymentPost
            {
                TransGuid = Guid.NewGuid(),
                TransDateTime = postTime,
                TransDateTimePosted = postTime,
                PatGuid = ParseGuid(Find(segments, "NM1", i + 1, end, s => s[1] == "QC")?[9], "NM1*QC NM109", transactionSet.ControlNumber),
                PpGuid = ParseGuid(Find(segments, "NM1", i + 1, end, s => s[1] == "IL")?[9], "NM1*IL NM109", transactionSet.ControlNumber),
                TransAmount = -amount,
                TransDueNowAmount = -amount,
                TransTotalDueAmount = -amount,
                TransNote = note,
                TransReference = traceNumber,
                TransCheckNumber = traceNumber,
                TransRouting = routing,
                LbcLockboxCode = paymentMethod,
                PaymentIdentifier = Find(segments, "REF", i + 1, end, s => s[1] == "F8")?[2],
                SourceControlNumber = transactionSet.ControlNumber,
            });
        }
        return posts;
    }

    /// <summary>Same as the BizTalk inline script: removes the deposit date and one trailing '_'.</summary>
    public static string GetLockboxNumber(string lockboxCode, string checkDate)
    {
        if (checkDate.Length > 0 && lockboxCode.Contains(checkDate, StringComparison.Ordinal))
            lockboxCode = lockboxCode.Replace(checkDate, string.Empty, StringComparison.Ordinal);
        if (lockboxCode.EndsWith('_'))
            lockboxCode = lockboxCode[..^1];
        return lockboxCode;
    }

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

    // An empty or missing NM109 is not sent, so the procedure receives NULL.
    private static Guid? ParseGuid(string? value, string source, string controlNumber)
    {
        if (string.IsNullOrWhiteSpace(value)) return null;
        return Guid.TryParse(value, out var guid)
            ? guid
            : throw new X12FormatException($"{source} in transaction set {controlNumber} is not a GUID.");
    }

    private static int IndexOf(IReadOnlyList<X12Segment> segments, string id, int from)
    {
        for (var i = from; i < segments.Count; i++)
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
