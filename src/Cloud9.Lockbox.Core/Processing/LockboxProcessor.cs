using Cloud9.Lockbox.Intake;
using Cloud9.Lockbox.Posting;
using Cloud9.Lockbox.X12;

namespace Cloud9.Lockbox.Processing;

public sealed record FileResult(string Region, string FileName, string FinalPath, int Payments, int PaymentsWithErrors, string? Error);

/// <summary>Claims the waiting files, maps and posts each transaction set, and moves the file to Done or Failed.</summary>
public sealed class LockboxProcessor
{
    private readonly FileIntake _intake;
    private readonly ILockboxFlow _flow;
    private readonly TimeProvider _time;

    public LockboxProcessor(FileIntake intake, ILockboxFlow flow, TimeProvider? time = null)
    {
        _intake = intake;
        _flow = flow;
        _time = time ?? TimeProvider.System;
    }

    /// <summary>Flow A (patient lockbox).</summary>
    public LockboxProcessor(FileIntake intake, IPaymentPoster poster, TimeProvider? time = null)
        : this(intake, new PatientLockboxFlow(poster), time)
    {
    }

    public LockboxFlowKind Flow => _flow.Kind;

    public async Task<IReadOnlyList<FileResult>> RunAsync(CancellationToken cancellationToken = default)
    {
        var results = new List<FileResult>();
        foreach (var file in _intake.ClaimAll())
        {
            var payments = 0;
            var withErrors = 0;
            var errors = new List<string>();
            try
            {
                var interchange = X12Interchange.Parse(await File.ReadAllTextAsync(file.ProcessingPath, cancellationToken));
                var now = _time.GetLocalNow().DateTime;
                foreach (var set in interchange.TransactionSets)
                {
                    // BizTalk handles one transaction set as one message. A failure stops that set only.
                    try
                    {
                        var context = new PostContext(file.Region, file.FileName, Guid.NewGuid());
                        var result = await _flow.PostSetAsync(set, context, now, cancellationToken);
                        payments += result.Payments;
                        withErrors += result.WithErrors;
                    }
                    catch (Exception ex) when (ex is not OperationCanceledException)
                    {
                        // Payments of this set that were posted stay posted (KB D3). No ImportLog row, like BizTalk.
                        errors.Add($"ST {set.ControlNumber}: {ex.Message}");
                    }
                }
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                errors.Add(ex.Message);
            }
            var error = errors.Count == 0 ? null : string.Join("; ", errors);
            var finalPath = error is null ? _intake.Complete(file) : _intake.Fail(file);
            results.Add(new FileResult(file.Region, file.FileName, finalPath, payments, withErrors, error));
        }
        return results;
    }
}
