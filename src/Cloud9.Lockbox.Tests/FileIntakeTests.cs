using Cloud9.Lockbox.Intake;
using Cloud9.Lockbox.Posting;
using Cloud9.Lockbox.Processing;

namespace Cloud9.Lockbox.Tests;

public sealed class FileIntakeTests : IDisposable
{
    private sealed class FixedTime(DateTimeOffset now) : TimeProvider
    {
        public override DateTimeOffset GetUtcNow() => now;
        public override TimeZoneInfo LocalTimeZone => TimeZoneInfo.Utc;
    }

    private sealed class RecordingPoster(int errorCount = 0) : IPaymentPoster
    {
        public List<(PostContext Context, PatientPaymentPost Payment)> Calls { get; } = [];

        public Task<PostResult> PostAsync(PostContext context, PatientPaymentPost payment, CancellationToken cancellationToken)
        {
            Calls.Add((context, payment));
            return Task.FromResult(new PostResult(errorCount, errorCount == 0 ? "Success" : "Patient record not found"));
        }
    }

    private sealed class ThrowingPoster(string failOn) : IPaymentPoster
    {
        public List<string?> Attempts { get; } = [];

        public Task<PostResult> PostAsync(PostContext context, PatientPaymentPost payment, CancellationToken cancellationToken)
        {
            Attempts.Add(payment.PaymentIdentifier);
            if (payment.PaymentIdentifier == failOn) throw new InvalidOperationException("The connection was lost.");
            return Task.FromResult(new PostResult(0, "Success"));
        }
    }

    private static readonly DateTimeOffset Now = new(2026, 10, 20, 12, 0, 0, TimeSpan.Zero);
    private readonly string _root = Directory.CreateTempSubdirectory("lockbox-tests-").FullName;
    private readonly FixedTime _time = new(Now);

    public void Dispose() => Directory.Delete(_root, recursive: true);

    private string Drop(string region, string name, string content, TimeSpan? age = null)
    {
        var dir = Directory.CreateDirectory(Path.Combine(_root, region)).FullName;
        var path = Path.Combine(dir, name);
        File.WriteAllText(path, content);
        File.SetLastWriteTimeUtc(path, (Now - (age ?? TimeSpan.FromMinutes(5))).UtcDateTime);
        return path;
    }

    private FileIntake Intake(TimeSpan? minAge = null) => new(_root, minAge ?? TimeSpan.FromSeconds(30), _time);

    [Fact]
    public void Claims_a_file_once_and_keeps_the_region_as_practice_name()
    {
        Drop("GULFCOAST", "a.835", "x");
        var intake = Intake();

        var claimed = Assert.Single(intake.ClaimAll());

        Assert.Equal("GULFCOAST", claimed.Region);
        Assert.Equal(Path.Combine(_root, "GULFCOAST", "Processing", "a.835"), claimed.ProcessingPath);
        Assert.True(File.Exists(claimed.ProcessingPath));
        Assert.Empty(intake.ClaimAll());
    }

    [Fact]
    public void Skips_a_file_that_changed_within_the_minimum_age()
    {
        Drop("GULFCOAST", "new.835", "x", age: TimeSpan.FromSeconds(5));

        Assert.Empty(Intake().ClaimAll());
    }

    [Fact]
    public void Reset_moves_failed_files_back_and_the_next_claim_takes_them()
    {
        Drop("GULFCOAST", "a.835", "x");
        var intake = Intake();
        var failed = intake.Fail(intake.ClaimAll()[0]);
        Assert.Equal(Path.Combine(_root, "GULFCOAST", "Failed", "a.835"), failed);

        var moved = Assert.Single(intake.Reset(FileIntake.Failed, region: "GULFCOAST", fileName: "a.835"));

        Assert.Equal(Path.Combine(_root, "GULFCOAST", "a.835"), moved);
        File.SetLastWriteTimeUtc(moved, (Now - TimeSpan.FromMinutes(5)).UtcDateTime);
        Assert.Single(intake.ClaimAll());
    }

    [Fact]
    public void Keeps_both_files_when_a_name_is_already_in_Done()
    {
        var intake = Intake();
        Drop("GULFCOAST", "a.835", "first");
        intake.Complete(intake.ClaimAll()[0]);
        Drop("GULFCOAST", "a.835", "second");

        var second = intake.Complete(intake.ClaimAll()[0]);

        Assert.Equal(2, Directory.GetFiles(Path.Combine(_root, "GULFCOAST", "Done")).Length);
        Assert.NotEqual(Path.Combine(_root, "GULFCOAST", "Done", "a.835"), second);
    }

    [Fact]
    public async Task Processor_posts_each_payment_and_moves_the_file_to_Done()
    {
        Drop("GULFCOAST", "a.835", Sample835.Build(claims: [new Sample835.Claim(), new Sample835.Claim(Clp04: "10.00")]));
        var poster = new RecordingPoster();

        var result = Assert.Single(await new LockboxProcessor(Intake(), poster, _time).RunAsync());

        Assert.Null(result.Error);
        Assert.Equal(2, result.Payments);
        Assert.True(File.Exists(Path.Combine(_root, "GULFCOAST", "Done", "a.835")));
        Assert.All(poster.Calls, c => Assert.Equal(new PostContext("GULFCOAST", "a.835", poster.Calls[0].Context.ImportGuid), c.Context));
    }

    [Fact]
    public async Task Processor_counts_procedure_errors_but_still_finishes_the_file()
    {
        Drop("GULFCOAST", "a.835", Sample835.Build(claims: new Sample835.Claim(PatGuid: null, PpGuid: null)));

        var result = Assert.Single(await new LockboxProcessor(Intake(), new RecordingPoster(errorCount: 1), _time).RunAsync());

        Assert.Null(result.Error);
        Assert.Equal(1, result.PaymentsWithErrors);
        Assert.True(File.Exists(Path.Combine(_root, "GULFCOAST", "Done", "a.835")));
    }

    [Fact]
    public async Task Processor_goes_on_with_the_next_set_when_one_set_fails_to_map()
    {
        Drop("GULFCOAST", "a.835", Sample835.BuildSets(
            ("0001", "837", [new Sample835.Claim()]),
            ("0002", "835", [new Sample835.Claim(), new Sample835.Claim(F8: "EOB22222222")])));
        var poster = new RecordingPoster();

        var result = Assert.Single(await new LockboxProcessor(Intake(), poster, _time).RunAsync());

        Assert.NotNull(result.Error);
        Assert.Contains("ST 0001", result.Error);
        Assert.Equal(2, result.Payments);
        Assert.Equal(2, poster.Calls.Count);
        Assert.True(File.Exists(Path.Combine(_root, "GULFCOAST", "Failed", "a.835")));
    }

    [Fact]
    public async Task Processor_stops_one_set_when_the_poster_throws_and_posts_the_next_set()
    {
        Drop("GULFCOAST", "a.835", Sample835.BuildSets(
            ("0001", "835", [new Sample835.Claim(F8: "EOB11111111"), new Sample835.Claim(F8: "EOB11111112")]),
            ("0002", "835", [new Sample835.Claim(F8: "EOB22222222")])));
        var poster = new ThrowingPoster("EOB11111111");

        var result = Assert.Single(await new LockboxProcessor(Intake(), poster, _time).RunAsync());

        Assert.Contains("ST 0001", result.Error);
        Assert.Equal(["EOB11111111", "EOB22222222"], poster.Attempts);
        Assert.Equal(1, result.Payments);
        Assert.True(File.Exists(Path.Combine(_root, "GULFCOAST", "Failed", "a.835")));
    }

    [Fact]
    public async Task Processor_moves_an_invalid_file_to_Failed_and_posts_nothing()
    {
        Drop("GULFCOAST", "bad.835", Sample835.Build().Replace("SE*", "SE*9"));
        var poster = new RecordingPoster();

        var result = Assert.Single(await new LockboxProcessor(Intake(), poster, _time).RunAsync());

        Assert.NotNull(result.Error);
        Assert.Empty(poster.Calls);
        Assert.True(File.Exists(Path.Combine(_root, "GULFCOAST", "Failed", "bad.835")));
    }
}
