using System.Text.Json;
using Cloud9.Lockbox.Intake;
using Cloud9.Lockbox.Mapping;
using Cloud9.Lockbox.Posting;
using Cloud9.Lockbox.Processing;
using Cloud9.Lockbox.X12;

namespace Cloud9.Lockbox.Cli;

public static class Program
{
    private static readonly JsonSerializerOptions Json = new() { WriteIndented = true };
    private const string ConnectionVariable = "LOCKBOX_SQL_CONNECTION";

    public static int Main(string[] args)
    {
        try
        {
            return args.FirstOrDefault()?.ToLowerInvariant() switch
            {
                "map" when args.Length >= 2 => Map(args[1], FlowOption(args) ?? FlowFromPath(args[1])),
                "ping" when args.Length == 1 => Ping(),
                "run" when args.Length >= 2 => Run(args[1], FlowOption(args) ?? LockboxFlows.FromRoot(args[1]), Option(args, "--min-age-seconds") is { } s ? int.Parse(s) : 30, Option(args, "--schema") ?? "TestC9"),
                "reset" when args.Length >= 2 => Reset(args[1], Option(args, "--state") ?? FileIntake.Failed, Option(args, "--region"), Option(args, "--file")),
                _ => Usage(),
            };
        }
        catch (X12FormatException ex)
        {
            Console.Error.WriteLine($"Invalid 835: {ex.Message}");
            return 2;
        }
        catch (Exception ex) when (ex is DirectoryNotFoundException or ArgumentException or FormatException or Microsoft.Data.SqlClient.SqlException)
        {
            Console.Error.WriteLine(ex.Message);
            return 1;
        }
    }

    private static string? Option(string[] args, string name)
    {
        var i = Array.FindIndex(args, a => string.Equals(a, name, StringComparison.OrdinalIgnoreCase));
        return i >= 0 && i + 1 < args.Length ? args[i + 1] : null;
    }

    private static LockboxFlowKind? FlowOption(string[] args) => Option(args, "--flow") switch
    {
        null => null,
        var value when Enum.TryParse<LockboxFlowKind>(value, ignoreCase: true, out var kind) && Enum.IsDefined(kind) => kind,
        var value => throw new ArgumentException($"--flow must be patient or insurance, not '{value}'."),
    };

    // A file under ...\Patient\<REGION>\ or ...\Insurance\<REGION>\.
    private static LockboxFlowKind? FlowFromPath(string path) =>
        LockboxFlows.FromRoot(Path.GetDirectoryName(Path.GetDirectoryName(Path.GetFullPath(path))) ?? string.Empty);

    private static LockboxFlowKind RequireFlow(LockboxFlowKind? flow, string path) =>
        flow ?? throw new ArgumentException($"Cannot tell the flow of '{path}'. Use a folder named Patient or Insurance (as the BizTalk receive folders), or give --flow patient or --flow insurance.");

    // Opens the connection and prints the login, database, and server. It changes nothing.
    private static int Ping()
    {
        var connection = Environment.GetEnvironmentVariable(ConnectionVariable);
        if (string.IsNullOrWhiteSpace(connection))
            throw new ArgumentException($"Set {ConnectionVariable} to a connection string.");
        using var sql = new Microsoft.Data.SqlClient.SqlConnection(connection);
        sql.Open();
        using var command = sql.CreateCommand();
        command.CommandText = "SELECT SUSER_SNAME(), DB_NAME(), @@SERVERNAME";
        using var reader = command.ExecuteReader();
        reader.Read();
        Console.WriteLine($"Login: {reader.GetString(0)} | Database: {reader.GetString(1)} | Server: {reader.GetString(2)}");
        return 0;
    }

    // Without LOCKBOX_SQL_CONNECTION it is a dry run: files move, nothing posts.
    private static int Run(string root, LockboxFlowKind? flowKind, int minAgeSeconds, string schema)
    {
        var kind = RequireFlow(flowKind, root);
        var connection = Environment.GetEnvironmentVariable(ConnectionVariable);
        var dryRun = string.IsNullOrWhiteSpace(connection);
        ILockboxFlow flow = kind switch
        {
            LockboxFlowKind.Insurance => new InsuranceLockboxFlow(dryRun ? new DryRunInsurancePoster() : new SqlInsurancePaymentPoster(connection!, schema)),
            _ => new PatientLockboxFlow(dryRun ? new DryRunPoster() : new SqlPaymentPoster(connection!, schema)),
        };
        Console.WriteLine(dryRun ? $"{kind} flow. Dry run. Set LOCKBOX_SQL_CONNECTION to post." : $"{kind} flow. Posting to the {schema} schema in Utility.");
        var processor = new LockboxProcessor(new FileIntake(root, TimeSpan.FromSeconds(minAgeSeconds)), flow);
        var results = processor.RunAsync().GetAwaiter().GetResult();
        foreach (var r in results)
            Console.WriteLine($"{r.Region}\\{r.FileName}: {(r.Error is null ? "Done" : "Failed")}, {r.Payments} payments, {r.PaymentsWithErrors} with errors{(r.Error is null ? "" : $" ({r.Error})")}");
        Console.WriteLine($"{results.Count} files.");
        return results.Any(r => r.Error is not null) ? 3 : 0;
    }

    private static int Reset(string root, string state, string? region, string? file)
    {
        var moved = new FileIntake(root, TimeSpan.Zero).Reset(state, region, file);
        foreach (var path in moved) Console.WriteLine($"Reset: {path}");
        Console.WriteLine($"{moved.Count} files.");
        return 0;
    }

    // Prints the procedure parameters for each CLP (and each guard failure for insurance). The output can contain PHI.
    private static int Map(string path, LockboxFlowKind? flowKind)
    {
        var kind = RequireFlow(flowKind, path);
        var interchange = X12Interchange.Parse(File.ReadAllText(path));
        object output = kind == LockboxFlowKind.Insurance
            ? interchange.TransactionSets.Select(ts => InsuranceLockboxMapper.Map(ts, DateTime.Now)).ToList()
            : interchange.TransactionSets.SelectMany(ts => PatientLockboxMapper.Map(ts, DateTime.Now)).ToList();
        Console.WriteLine(JsonSerializer.Serialize(output, Json));
        return 0;
    }

    private static int Usage()
    {
        Console.Error.WriteLine("""
            Usage:
              lockbox map <file.835> [--flow patient|insurance]
                  Print the procedure parameters (can contain PHI). The flow comes from the folder two levels up
                  (...\Patient\<REGION>\file or ...\Insurance\<REGION>\file) unless --flow is given.
              lockbox ping
                  Open the connection in LOCKBOX_SQL_CONNECTION and print the login. It changes nothing.
              lockbox run <root> [--flow patient|insurance] [--min-age-seconds 30] [--schema TestC9]
                  Process <root>\<REGION>\*: claim to Processing, map, post, move to Done or Failed.
                  The flow comes from the root folder name (Patient or Insurance, as the BizTalk receive folders)
                  unless --flow is given. It does not guess: other root names need --flow.
                  Patient posts through [schema].usp_bts_Post835PatientTransaction, insurance through
                  [schema].usp_bts_Post835InsuranceTransaction (guard failures through [schema].usp_bts_AddImportLog),
                  in Utility when LOCKBOX_SQL_CONNECTION holds a connection string. Otherwise it is a dry run.
              lockbox reset <root> [--state Failed|Done|Processing] [--region <REGION>] [--file <name>]
                  Move files back to <root>\<REGION> so that the next run processes them again.
            """);
        return 1;
    }
}
