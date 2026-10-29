using System.Data;
using System.Text.RegularExpressions;
using Microsoft.Data.SqlClient;

namespace Cloud9.Lockbox.Posting;

/// <summary>
/// Posts one insurance payment through [schema].usp_bts_Post835InsuranceTransaction in the Utility database, and writes
/// guard failures through [schema].usp_bts_AddImportLog. The posting procedure posts and writes the ImportLog row in one
/// transaction.
/// </summary>
public sealed partial class SqlInsurancePaymentPoster : IInsurancePaymentPoster
{
    public const string ProcessName = "Process_BBVA_835Insurance";
    private const string PostProcedure = "usp_bts_Post835InsuranceTransaction";
    private const string LogProcedure = "usp_bts_AddImportLog";

    private readonly string _connectionString;
    private readonly string _schema;
    private readonly TimeProvider _time;

    /// <param name="connectionString">A connection to the Utility database.</param>
    /// <param name="schema">The practice schema in Utility. This sprint uses only TestC9.</param>
    public SqlInsurancePaymentPoster(string connectionString, string schema = "TestC9", TimeProvider? time = null)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(connectionString);
        CheckSchema(schema);
        _connectionString = connectionString;
        _schema = schema;
        _time = time ?? TimeProvider.System;
    }

    public async Task<PostResult> PostAsync(PostContext context, InsurancePaymentPost payment, CancellationToken cancellationToken)
    {
        await using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync(cancellationToken);
        await using var command = BuildPostCommand(_schema, context, payment, _time.GetLocalNow().DateTime);
        command.Connection = connection;

        // A plain reader. INSERT ... EXEC fails when the procedure rolls back inside it.
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
            throw new InvalidOperationException($"[{_schema}].{PostProcedure} returned no result row.");
        return new PostResult(reader.GetInt32(0), reader.IsDBNull(1) ? "" : reader.GetString(1));
    }

    public async Task LogFailureAsync(PostContext context, string message, CancellationToken cancellationToken)
    {
        await using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync(cancellationToken);
        await using var command = BuildLogFailureCommand(_schema, context, message, _time.GetLocalNow().DateTime);
        command.Connection = connection;
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    /// <summary>Builds the post call. ilDateTime is the processing time, like the BizTalk server time.</summary>
    public static SqlCommand BuildPostCommand(string schema, PostContext context, InsurancePaymentPost payment, DateTime ilDateTime)
    {
        CheckSchema(schema);
        var command = new SqlCommand($"[{schema}].[{PostProcedure}]") { CommandType = CommandType.StoredProcedure };
        var p = command.Parameters;
        p.Add("@transGUID", SqlDbType.UniqueIdentifier).Value = payment.TransGuid;
        p.Add("@transDateTime", SqlDbType.DateTime).Value = payment.TransDateTime;
        p.Add("@transDateTimePosted", SqlDbType.DateTime).Value = payment.TransDateTimePosted;
        p.Add("@transStatus", SqlDbType.NVarChar, 2).Value = payment.TransStatus;
        p.Add("@patGUID", SqlDbType.UniqueIdentifier).Value = Db(payment.PatGuid);
        p.Add("@pipGUID", SqlDbType.UniqueIdentifier).Value = Db(payment.PipGuid);
        p.Add("@transAmount", SqlDbType.Money).Value = payment.TransAmount;
        p.Add("@transNote", SqlDbType.NVarChar, 500).Value = payment.TransNote;
        p.Add("@transReceiptNote", SqlDbType.NVarChar, 250).Value = payment.TransReceiptNote;
        p.Add("@transReference", SqlDbType.NVarChar, 100).Value = Db(payment.TransReference);
        p.Add("@transDueNowAmount", SqlDbType.Money).Value = payment.TransDueNowAmount;
        p.Add("@transTotalDueAmount", SqlDbType.Money).Value = payment.TransTotalDueAmount;
        p.Add("@transProductionAmount", SqlDbType.Money).Value = payment.TransProductionAmount;
        p.Add("@transIsGroup", SqlDbType.NVarChar, 100).Value = payment.TransIsGroup;
        p.Add("@transClaimAmount", SqlDbType.NVarChar, 100).Value = payment.TransClaimAmount;
        p.Add("@transCheckNumber", SqlDbType.NVarChar, 100).Value = Db(payment.TransCheckNumber);
        p.Add("@transRouting", SqlDbType.NVarChar, 100).Value = Db(payment.TransRouting);
        p.Add("@adaClaimNumber", SqlDbType.NVarChar, 100).Value = Db(payment.AdaClaimNumber);
        p.Add("@pipPolicyNumber", SqlDbType.NVarChar, 100).Value = Db(payment.PipPolicyNumber);
        p.Add("@ptPaymentTypeCode", SqlDbType.NVarChar, 3).Value = Db(payment.PtPaymentTypeCode);
        p.Add("@ClaimIdentifier", SqlDbType.NVarChar, 100).Value = Db(payment.ClaimIdentifier);
        // NULL when the claim has no REF*F8, as BizTalk sends it. The procedure stores '' in ImportLog, as production does.
        p.Add("@PaymentIdentifier", SqlDbType.NVarChar, 100).Value = Db(payment.PaymentIdentifier);
        p.Add("@AdjustmentType", SqlDbType.VarChar, 2).Value = Db(payment.AdjustmentType);
        p.Add("@ilFileName", SqlDbType.NVarChar, 250).Value = Path.GetFileName(context.FileName);
        p.Add("@ilImportGUID", SqlDbType.UniqueIdentifier).Value = context.ImportGuid;
        p.Add("@ilProcess", SqlDbType.NVarChar, 50).Value = ProcessName;
        p.Add("@ilDateTime", SqlDbType.DateTime).Value = ilDateTime;
        return command;
    }

    /// <summary>Builds the log-only call: one Failed row, level 0, no ilExternalReference, as the BizTalk guard writes it.</summary>
    public static SqlCommand BuildLogFailureCommand(string schema, PostContext context, string message, DateTime ilDateTime)
    {
        CheckSchema(schema);
        ArgumentException.ThrowIfNullOrWhiteSpace(message);
        var command = new SqlCommand($"[{schema}].[{LogProcedure}]") { CommandType = CommandType.StoredProcedure };
        var p = command.Parameters;
        p.Add("@ilFileName", SqlDbType.NVarChar, 250).Value = Path.GetFileName(context.FileName);
        p.Add("@ilProcess", SqlDbType.NVarChar, 50).Value = ProcessName;
        p.Add("@ilLogLevel", SqlDbType.Int).Value = 0;
        p.Add("@ilMessage", SqlDbType.NVarChar, -1).Value = message;
        p.Add("@ilImportGUID", SqlDbType.UniqueIdentifier).Value = context.ImportGuid;
        p.Add("@ilImportState", SqlDbType.NVarChar, 50).Value = "Failed";
        p.Add("@ilExternalReference", SqlDbType.VarChar, 100).Value = DBNull.Value;
        p.Add("@ilDateTime", SqlDbType.DateTime).Value = ilDateTime;
        return command;
    }

    private static object Db(object? value) => value ?? DBNull.Value;

    private static void CheckSchema(string schema)
    {
        ArgumentNullException.ThrowIfNull(schema);
        if (!SchemaName().IsMatch(schema))
            throw new ArgumentException("The schema name can contain only letters, digits, '_' and '-'.", nameof(schema));
    }

    [GeneratedRegex(@"^[A-Za-z0-9_-]+\z")]
    private static partial Regex SchemaName();
}
