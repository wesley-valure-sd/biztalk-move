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
                "map" when args.Length == 2 => Map(args[1]),
                "ping" when args.Length == 1 => Ping(),
                "run" when args.Length >= 2 => Run(args[1], Option(args, "--min-age-seconds") is { } s ? int.Parse(s) : 30, Option(args, "--schema") ?? "TestC9"),
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
    private static int Run(string root, int minAgeSeconds, string schema)
    {
        var connection = Environment.GetEnvironmentVariable(ConnectionVariable);
        IPaymentPoster poster = string.IsNullOrWhiteSpace(connection) ? new DryRunPoster() : new SqlPaymentPoster(connection, schema);
        Console.WriteLine(poster is DryRunPoster ? "Dry run. Set LOCKBOX_SQL_CONNECTION to post." : $"Posting to the {schema} schema in Utility.");
        var processor = new LockboxProcessor(new FileIntake(root, TimeSpan.FromSeconds(minAgeSeconds)), poster);
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

    // Prints the Post835PatientTransaction parameters for each CLP. The output can contain PHI.
    private static int Map(string path)
    {
        var interchange = X12Interchange.Parse(File.ReadAllText(path));
        var posts = interchange.TransactionSets.SelectMany(ts => PatientLockboxMapper.Map(ts, DateTime.Now)).ToList();
        Console.WriteLine(JsonSerializer.Serialize(posts, Json));
        return 0;
    }

    private static int Usage()
    {
        Console.Error.WriteLine("""
            Usage:
              lockbox map <file.835>    Print the Post835PatientTransaction parameters (can contain PHI).
              lockbox ping
                  Open the connection in LOCKBOX_SQL_CONNECTION and print the login. It changes nothing.
              lockbox run <root> [--min-age-seconds 30] [--schema TestC9]
                  Process <root>\<REGION>\*: claim to Processing, map, post, move to Done or Failed.
                  Posts through [schema].usp_bts_Post835PatientTransaction in Utility when the
                  LOCKBOX_SQL_CONNECTION environment variable holds a connection string. Otherwise it is a dry run.
              lockbox reset <root> [--state Failed|Done|Processing] [--region <REGION>] [--file <name>]
                  Move files back to <root>\<REGION> so that the next run processes them again.
            """);
        return 1;
    }
}
