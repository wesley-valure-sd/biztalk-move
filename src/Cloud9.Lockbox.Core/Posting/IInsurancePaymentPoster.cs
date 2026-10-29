namespace Cloud9.Lockbox.Posting;

/// <summary>Posts one insurance payment or adjustment and writes its ImportLog row, as BizTalk flow C does.</summary>
public interface IInsurancePaymentPoster
{
    Task<PostResult> PostAsync(PostContext context, InsurancePaymentPost payment, CancellationToken cancellationToken);

    /// <summary>Writes one Failed ImportLog row for a transaction set that BizTalk does not post (the CLP/PLB guard).</summary>
    Task LogFailureAsync(PostContext context, string message, CancellationToken cancellationToken);
}

/// <summary>Posts nothing. Used when no SQL connection is set.</summary>
public sealed class DryRunInsurancePoster : IInsurancePaymentPoster
{
    public Task<PostResult> PostAsync(PostContext context, InsurancePaymentPost payment, CancellationToken cancellationToken) =>
        Task.FromResult(new PostResult(0, "DRY RUN"));

    public Task LogFailureAsync(PostContext context, string message, CancellationToken cancellationToken) => Task.CompletedTask;
}
