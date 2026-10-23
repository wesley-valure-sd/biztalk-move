namespace Cloud9.Lockbox.Posting;

/// <summary>Context of one post. <see cref="FileName"/> becomes ilFileName, <see cref="ImportGuid"/> becomes ilImportGUID.</summary>
public sealed record PostContext(string PracticeName, string FileName, Guid ImportGuid);

/// <summary>The first result set of Post835PatientTransaction.</summary>
public sealed record PostResult(int ErrorCount, string ResponseMessage);

/// <summary>Posts one payment and writes its ImportLog row, as BizTalk flow A does.</summary>
public interface IPaymentPoster
{
    Task<PostResult> PostAsync(PostContext context, PatientPaymentPost payment, CancellationToken cancellationToken);
}

/// <summary>Posts nothing. Used when no SQL connection is set.</summary>
public sealed class DryRunPoster : IPaymentPoster
{
    public Task<PostResult> PostAsync(PostContext context, PatientPaymentPost payment, CancellationToken cancellationToken) =>
        Task.FromResult(new PostResult(0, "DRY RUN"));
}
