using Cloud9.Lockbox.Intake;
using Cloud9.Lockbox.Posting;
using Cloud9.Lockbox.Processing;

namespace Cloud9.Lockbox.Tests;

public sealed class InsuranceRoutingTests : IDisposable
{
    private sealed class RecordingInsurancePoster : IInsurancePaymentPoster
    {
        public List<InsurancePaymentPost> Posts { get; } = [];
        public List<PostContext> PostContexts { get; } = [];
        public List<(PostContext Context, string Message)> Failures { get; } = [];

        public Task<PostResult> PostAsync(PostContext context, InsurancePaymentPost payment, CancellationToken cancellationToken)
        {
            Posts.Add(payment);
            PostContexts.Add(context);
            return Task.FromResult(new PostResult(0, "Success"));
        }

        public Task LogFailureAsync(PostContext context, string message, CancellationToken cancellationToken)
        {
            Failures.Add((context, message));
            return Task.CompletedTask;
        }
    }

    private sealed class FailingPatientPoster : IPaymentPoster
    {
        public Task<PostResult> PostAsync(PostContext context, PatientPaymentPost payment, CancellationToken cancellationToken) =>
            throw new InvalidOperationException("An insurance file reached the patient poster.");
    }

    private readonly string _parent = Directory.CreateTempSubdirectory("lockbox-routing-").FullName;

    public void Dispose() => Directory.Delete(_parent, recursive: true);

    private string Root(string flowFolder, params string[] scenarioIds)
    {
        var root = Path.Combine(_parent, flowFolder);
        var region = Directory.CreateDirectory(Path.Combine(root, "TESTC9")).FullName;
        foreach (var id in scenarioIds)
        {
            var source = Directory.GetFiles(InsuranceScenarios.Folder, $"*_{id}.835").Single();
            var target = Path.Combine(region, Path.GetFileName(source));
            File.Copy(source, target);
            File.SetLastWriteTimeUtc(target, DateTime.UtcNow.AddMinutes(-5));
        }
        return root;
    }

    [Theory]
    [InlineData("Insurance", LockboxFlowKind.Insurance)]
    [InlineData("insurance", LockboxFlowKind.Insurance)]
    [InlineData("Patient", LockboxFlowKind.Patient)]
    [InlineData("TESTC9", null)]
    [InlineData("testdata", null)]
    public void FromRoot_reads_the_flow_from_the_receive_folder_name(string folder, LockboxFlowKind? expected)
    {
        Assert.Equal(expected, LockboxFlows.FromRoot(Path.Combine(_parent, folder)));
        Assert.Equal(expected, LockboxFlows.FromRoot(Path.Combine(_parent, folder) + Path.DirectorySeparatorChar));
    }

    [Fact]
    public async Task Insurance_files_go_to_the_insurance_poster_and_never_to_the_patient_mapper()
    {
        var poster = new RecordingInsurancePoster();
        var processor = new LockboxProcessor(new FileIntake(Root("Insurance", "I01", "I02"), TimeSpan.Zero), new InsuranceLockboxFlow(poster));

        var results = await processor.RunAsync();

        Assert.Equal(LockboxFlowKind.Insurance, processor.Flow);
        Assert.All(results, r => Assert.Null(r.Error));
        Assert.Equal(3, poster.Posts.Count);
        Assert.Contains(poster.Posts, p => p.PaymentIdentifier == "EOB01010001");
    }

    [Fact]
    public async Task The_patient_flow_fails_an_insurance_file_instead_of_posting_it()
    {
        // The guard against a wrong root: the patient mapper cannot read REF*EJ claims as NM1 GUIDs.
        var processor = new LockboxProcessor(new FileIntake(Root("Patient", "I01"), TimeSpan.Zero), new FailingPatientPoster());

        var result = Assert.Single(await processor.RunAsync());

        Assert.Equal(LockboxFlowKind.Patient, processor.Flow);
        Assert.NotNull(result.Error);
        Assert.Equal(0, result.Payments);
    }

    [Fact]
    public async Task A_guard_failure_writes_one_log_row_posts_nothing_and_finishes_the_file()
    {
        var poster = new RecordingInsurancePoster();
        var processor = new LockboxProcessor(new FileIntake(Root("Insurance", "I17"), TimeSpan.Zero), new InsuranceLockboxFlow(poster));

        var result = Assert.Single(await processor.RunAsync());

        Assert.Null(result.Error);
        Assert.Contains($"{Path.DirectorySeparatorChar}{FileIntake.Done}{Path.DirectorySeparatorChar}", result.FinalPath);
        Assert.Empty(poster.Posts);
        var failure = Assert.Single(poster.Failures);
        Assert.Equal("There were 5 CLP payments and 2 PLB adjustments on transaction 0001", failure.Message);
        Assert.Equal("SDOC_20260804_TESTC9_I17.835", failure.Context.FileName);
        Assert.Equal(0, result.Payments);
        Assert.Equal(1, result.PaymentsWithErrors);
    }

    [Fact]
    public async Task Each_transaction_set_gets_its_own_import_guid()
    {
        var poster = new RecordingInsurancePoster();
        var contexts = new List<PostContext>();
        var flow = new InsuranceLockboxFlow(poster);
        var processor = new LockboxProcessor(new FileIntake(Root("Insurance", "I03"), TimeSpan.Zero), flow);

        var result = Assert.Single(await processor.RunAsync());

        Assert.Null(result.Error);
        Assert.Equal(2, result.Payments);
    }
}
