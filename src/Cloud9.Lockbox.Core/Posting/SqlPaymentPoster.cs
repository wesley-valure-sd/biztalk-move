using System.Data;
using System.Text.RegularExpressions;
using Microsoft.Data.SqlClient;

namespace Cloud9.Lockbox.Posting;

/// <summary>
/// Posts one payment through [schema].usp_bts_Post835PatientTransaction in the Utility database.
/// The procedure posts the payment and writes the ImportLog row in one transaction.
/// </summary>
public sealed partial class SqlPaymentPoster : IPaymentPoster
{
    public const string ProcessName = "Process_BBVA_835Patient";
    private const string ProcedureName = "usp_bts_Post835PatientTransaction";

    private readonly string _connectionString;
    private readonly string _schema;
    private readonly TimeProvider _time;

    /// <param name="connectionString">A connection to the Utility database.</param>
    /// <param name="schema">The practice schema in Utility. This sprint uses only TestC9.</param>
    public SqlPaymentPoster(string connectionString, string schema = "TestC9", TimeProvider? time = null)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(connectionString);
        ArgumentNullException.ThrowIfNull(schema);
        if (!SchemaName().IsMatch(schema))
            throw new ArgumentException("The schema name can contain only letters, digits, '_' and '-'.", nameof(schema));
        _connectionString = connectionString;
        _schema = schema;
        _time = time ?? TimeProvider.System;
    }

    public async Task<PostResult> PostAsync(PostContext context, PatientPaymentPost payment, CancellationToken cancellationToken)
    {
        await using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync(cancellationToken);
        await using var command = BuildCommand(_schema, context, payment, _time.GetLocalNow().DateTime);
        command.Connection = connection;

        // A plain reader. INSERT ... EXEC fails when the procedure rolls back inside it.
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
            throw new InvalidOperationException($"[{_schema}].{ProcedureName} returned no result row.");
        return new PostResult(reader.GetInt32(0), reader.IsDBNull(1) ? "" : reader.GetString(1));
    }

    /// <summary>Builds the call. ilDateTime is the processing time, like the BizTalk server time.</summary>
    public static SqlCommand BuildCommand(string schema, PostContext context, PatientPaymentPost payment, DateTime ilDateTime)
    {
        if (!SchemaName().IsMatch(schema))
            throw new ArgumentException("The schema name can contain only letters, digits, '_' and '-'.", nameof(schema));
        var command = new SqlCommand($"[{schema}].[{ProcedureName}]") { CommandType = CommandType.StoredProcedure };
        var p = command.Parameters;
        p.Add("@transGUID", SqlDbType.UniqueIdentifier).Value = payment.TransGuid;
        p.Add("@transDateTime", SqlDbType.DateTime).Value = payment.TransDateTime;
        p.Add("@transDateTimePosted", SqlDbType.DateTime).Value = payment.TransDateTimePosted;
        p.Add("@transAmount", SqlDbType.Money).Value = payment.TransAmount;
        p.Add("@transNote", SqlDbType.NVarChar, 500).Value = Db(payment.TransNote);
        p.Add("@transReference", SqlDbType.NVarChar, 100).Value = Db(payment.TransReference);
        p.Add("@ilFileName", SqlDbType.NVarChar, 250).Value = Path.GetFileName(context.FileName);
        p.Add("@ilImportGUID", SqlDbType.UniqueIdentifier).Value = context.ImportGuid;
        p.Add("@transStatus", SqlDbType.NVarChar, 2).Value = payment.TransStatus;
        p.Add("@patGUID", SqlDbType.UniqueIdentifier).Value = Db(payment.PatGuid);
        p.Add("@ppGUID", SqlDbType.UniqueIdentifier).Value = Db(payment.PpGuid);
        p.Add("@transDueNowAmount", SqlDbType.Money).Value = payment.TransDueNowAmount;
        p.Add("@transTotalDueAmount", SqlDbType.Money).Value = payment.TransTotalDueAmount;
        p.Add("@transProductionAmount", SqlDbType.Money).Value = payment.TransProductionAmount;
        p.Add("@transIsGroup", SqlDbType.NVarChar, 100).Value = payment.TransIsGroup;
        p.Add("@transCheckNumber", SqlDbType.NVarChar, 100).Value = Db(payment.TransCheckNumber);
        p.Add("@transRouting", SqlDbType.NVarChar, 100).Value = Db(payment.TransRouting);
        p.Add("@lbcLockboxCode", SqlDbType.NVarChar, 100).Value = Db(payment.LbcLockboxCode);
        p.Add("@lbcLockboxCodeType", SqlDbType.NVarChar, 25).Value = payment.LbcLockboxCodeType;
        p.Add("@PaymentIdentifier", SqlDbType.VarChar, 100).Value = Db(payment.PaymentIdentifier);
        p.Add("@ilProcess", SqlDbType.NVarChar, 50).Value = ProcessName;
        p.Add("@ilDateTime", SqlDbType.DateTime).Value = ilDateTime;
        return command;
    }

    private static object Db(object? value) => value ?? DBNull.Value;

    [GeneratedRegex(@"^[A-Za-z0-9_-]+\z")]
    private static partial Regex SchemaName();
}
