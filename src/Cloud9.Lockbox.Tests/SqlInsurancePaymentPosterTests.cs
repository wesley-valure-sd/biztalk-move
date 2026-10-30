using System.Data;
using Cloud9.Lockbox.Posting;
using Microsoft.Data.SqlClient;

namespace Cloud9.Lockbox.Tests;

public sealed class SqlInsurancePaymentPosterTests
{
    private static readonly DateTime Processed = new(2026, 10, 30, 9, 30, 15);
    private static readonly PostContext Context = new("TESTC9", @"C:\in\TESTC9\Processing\SDOC_20260929_TESTC9_I01.835", Guid.Parse("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"));

    private static InsurancePaymentPost Claim(string? f8 = "EOB01010001", string? adjustmentType = null) => new()
    {
        TransGuid = Guid.Parse("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"),
        TransDateTime = Processed,
        TransDateTimePosted = Processed,
        PatGuid = Guid.Parse("97E4A8E5-CFF0-41A9-A955-580219C0A4F5"),
        PipGuid = Guid.Parse("82FAF6B6-D4C3-0DFE-EDBA-D4FC67D6A321"),
        TransAmount = -54.5m,
        TransDueNowAmount = -54.5m,
        TransTotalDueAmount = -54.5m,
        TransNote = "Deposit Date: 20260929, Check Date: 20260923, Claim Number: 13874, Lockbox: X",
        TransReceiptNote = "Deposit Date: 20260929, Check Date: 20260923, Claim Number: 13874, Lockbox: X",
        TransReference = "1959226824",
        TransCheckNumber = "1959226824",
        TransRouting = "111000025",
        AdaClaimNumber = "13874",
        PipPolicyNumber = "123-45-69999",
        PtPaymentTypeCode = "CHK",
        PaymentIdentifier = f8,
        AdjustmentType = adjustmentType,
        SourceControlNumber = "0001",
    };

    private static object? Value(SqlCommand command, string name) => command.Parameters[name].Value;

    [Fact]
    public void Post_calls_the_schema_procedure_with_every_BizTalk_parameter()
    {
        using var command = SqlInsurancePaymentPoster.BuildPostCommand("TestC9", Context, Claim(), Processed);

        Assert.Equal("[TestC9].[usp_bts_Post835InsuranceTransaction]", command.CommandText);
        Assert.Equal(CommandType.StoredProcedure, command.CommandType);
        Assert.Equal(-54.5m, Value(command, "@transAmount"));
        Assert.Equal(-54.5m, Value(command, "@transDueNowAmount"));
        Assert.Equal(-54.5m, Value(command, "@transTotalDueAmount"));
        Assert.Equal(0m, Value(command, "@transProductionAmount"));
        Assert.Equal("0", Value(command, "@transIsGroup"));
        Assert.Equal("0", Value(command, "@transClaimAmount"));
        Assert.Equal("N", Value(command, "@transStatus"));
        Assert.Equal("13874", Value(command, "@adaClaimNumber"));
        Assert.Equal("123-45-69999", Value(command, "@pipPolicyNumber"));
        Assert.Equal("CHK", Value(command, "@ptPaymentTypeCode"));
        Assert.Equal("1959226824", Value(command, "@transCheckNumber"));
        Assert.Equal("1959226824", Value(command, "@transReference"));
        Assert.Equal("111000025", Value(command, "@transRouting"));
        Assert.Equal("EOB01010001", Value(command, "@PaymentIdentifier"));
        Assert.Equal(DBNull.Value, Value(command, "@ClaimIdentifier"));
        Assert.Equal(DBNull.Value, Value(command, "@AdjustmentType"));
        Assert.Equal(Value(command, "@transNote"), Value(command, "@transReceiptNote"));
        Assert.Equal(500, command.Parameters["@transNote"].Size);
        Assert.Equal(250, command.Parameters["@transReceiptNote"].Size);
    }

    [Fact]
    public void Post_sends_the_processing_time_the_file_name_only_and_the_insurance_process()
    {
        using var command = SqlInsurancePaymentPoster.BuildPostCommand("TestC9", Context, Claim(), Processed);

        Assert.Equal("SDOC_20260929_TESTC9_I01.835", Value(command, "@ilFileName"));
        Assert.Equal(Context.ImportGuid, Value(command, "@ilImportGUID"));
        Assert.Equal("Process_BBVA_835Insurance", Value(command, "@ilProcess"));
        Assert.Equal(Processed, Value(command, "@ilDateTime"));
    }

    [Fact]
    public void Post_sends_NULL_for_a_missing_REF_F8_and_missing_GUIDs()
    {
        var claim = Claim(f8: null) with { PatGuid = null, PipGuid = null, PipPolicyNumber = null };

        using var command = SqlInsurancePaymentPoster.BuildPostCommand("TestC9", Context, claim, Processed);

        Assert.Equal(DBNull.Value, Value(command, "@PaymentIdentifier"));
        Assert.Equal(DBNull.Value, Value(command, "@patGUID"));
        Assert.Equal(DBNull.Value, Value(command, "@pipGUID"));
        Assert.Equal(DBNull.Value, Value(command, "@pipPolicyNumber"));
    }

    [Fact]
    public void Post_sends_the_adjustment_type_of_a_PLB()
    {
        using var command = SqlInsurancePaymentPoster.BuildPostCommand("TestC9", Context, Claim(adjustmentType: "L6") with { TransReference = "ADJ1-1959226824" }, Processed);

        Assert.Equal("L6", Value(command, "@AdjustmentType"));
        Assert.Equal(SqlDbType.VarChar, command.Parameters["@AdjustmentType"].SqlDbType);
        Assert.Equal("ADJ1-1959226824", Value(command, "@transReference"));
    }

    [Fact]
    public void LogFailure_writes_one_Failed_level_0_row_with_no_external_reference()
    {
        using var command = SqlInsurancePaymentPoster.BuildLogFailureCommand("TestC9", Context, "There were 5 CLP payments and 2 PLB adjustments on transaction 0001", Processed);

        Assert.Equal("[TestC9].[usp_bts_AddImportLog]", command.CommandText);
        Assert.Equal("There were 5 CLP payments and 2 PLB adjustments on transaction 0001", Value(command, "@ilMessage"));
        Assert.Equal(0, Value(command, "@ilLogLevel"));
        Assert.Equal("Failed", Value(command, "@ilImportState"));
        Assert.Equal(DBNull.Value, Value(command, "@ilExternalReference"));
        Assert.Equal("Process_BBVA_835Insurance", Value(command, "@ilProcess"));
        Assert.Equal("SDOC_20260929_TESTC9_I01.835", Value(command, "@ilFileName"));
        Assert.Equal(Processed, Value(command, "@ilDateTime"));
    }

    [Theory]
    [InlineData("")]
    [InlineData("Test C9")]
    [InlineData("TestC9]; DROP TABLE x; --")]
    public void Rejects_a_schema_name_that_is_not_a_plain_name(string schema)
    {
        Assert.Throws<ArgumentException>(() => new SqlInsurancePaymentPoster("Server=x", schema));
        Assert.Throws<ArgumentException>(() => SqlInsurancePaymentPoster.BuildPostCommand(schema, Context, Claim(), Processed));
        Assert.Throws<ArgumentException>(() => SqlInsurancePaymentPoster.BuildLogFailureCommand(schema, Context, "x", Processed));
    }
}
