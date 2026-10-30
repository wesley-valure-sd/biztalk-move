using Cloud9.Lockbox.Mapping;
using Cloud9.Lockbox.Posting;
using Cloud9.Lockbox.X12;

namespace Cloud9.Lockbox.Processing;

/// <summary>The BizTalk flow of a receive folder. BizTalk picks it by the receive location (…\Patient\ or …\Insurance\).</summary>
public enum LockboxFlowKind
{
    Patient,
    Insurance,
}

/// <summary>The posts of one transaction set: how many posts ran, and how many ended with an error or a log-only failure.</summary>
public readonly record struct SetResult(int Payments, int WithErrors);

/// <summary>Maps and posts one transaction set for one BizTalk flow.</summary>
public interface ILockboxFlow
{
    LockboxFlowKind Kind { get; }

    Task<SetResult> PostSetAsync(X12TransactionSet set, PostContext context, DateTime processingTime, CancellationToken cancellationToken);
}

/// <summary>Flow A (Process_BBVA_835Patient).</summary>
public sealed class PatientLockboxFlow(IPaymentPoster poster) : ILockboxFlow
{
    public LockboxFlowKind Kind => LockboxFlowKind.Patient;

    public async Task<SetResult> PostSetAsync(X12TransactionSet set, PostContext context, DateTime processingTime, CancellationToken cancellationToken)
    {
        var payments = 0;
        var withErrors = 0;
        foreach (var post in PatientLockboxMapper.Map(set, processingTime))
        {
            // As in BizTalk, a payment with ErrorCount > 0 has a Failed ImportLog row and the set goes on.
            var result = await poster.PostAsync(context, post, cancellationToken);
            payments++;
            if (result.ErrorCount != 0) withErrors++;
        }
        return new SetResult(payments, withErrors);
    }
}

/// <summary>Flow C (Process_BBVA_835Insurance). A guard failure writes one Failed ImportLog row and posts nothing.</summary>
public sealed class InsuranceLockboxFlow(IInsurancePaymentPoster poster) : ILockboxFlow
{
    public LockboxFlowKind Kind => LockboxFlowKind.Insurance;

    public async Task<SetResult> PostSetAsync(X12TransactionSet set, PostContext context, DateTime processingTime, CancellationToken cancellationToken)
    {
        var mapped = InsuranceLockboxMapper.Map(set, processingTime);
        if (mapped.GuardFailure is not null)
        {
            await poster.LogFailureAsync(context, mapped.GuardFailure, cancellationToken);
            return new SetResult(0, 1);
        }

        var payments = 0;
        var withErrors = 0;
        foreach (var post in mapped.Posts)
        {
            var result = await poster.PostAsync(context, post, cancellationToken);
            payments++;
            if (result.ErrorCount != 0) withErrors++;
        }
        return new SetResult(payments, withErrors);
    }
}

public static class LockboxFlows
{
    /// <summary>
    /// The flow of an intake root from its folder name, as in the BizTalk receive folders (…\Patient\&lt;REGION&gt;\,
    /// …\Insurance\&lt;REGION&gt;\). Null if the name is neither.
    /// </summary>
    public static LockboxFlowKind? FromRoot(string root)
    {
        var name = Path.GetFileName(Path.TrimEndingDirectorySeparator(Path.GetFullPath(root)));
        return Enum.TryParse<LockboxFlowKind>(name, ignoreCase: true, out var kind) && Enum.IsDefined(kind) ? kind : null;
    }
}
