using System.Data;
using Cloud9.Lockbox.Posting;
using Microsoft.Data.SqlClient;

namespace Cloud9.Lockbox.Tests;

public sealed class SqlPaymentPosterTests
{
    private static readonly Guid PatGuid = Guid.Parse("11111111-2222-3333-4444-555555555555");
    private static readonly Guid PpGuid = Guid.Parse("66666666-7777-8888-9999-000000000000");
    private static readonly DateTime Processed = new(2026, 10, 21, 9, 30, 15);

    private static PatientPaymentPost Payment(Guid? pat = null, Guid? pp = null) => new()
    {
        TransGuid = Guid.Parse("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"),
        TransDateTime = Processed,
        TransDateTimePosted = Processed,
        PatGuid = pat,
        PpGuid = pp,
        TransAmount = -169.00m,
        TransDueNowAmount = 0m,
        TransTotalDueAmount = 0m,
        TransNote = "Check No: 2247",
        TransReference = "REF1",
        TransCheckNumber = "2247",
        TransRouting = "111000025",
        LbcLockboxCode = "CHK",
        PaymentIdentifier = "EOB12345678",
        SourceControlNumber = "0001",
    };

    private static object? Value(SqlCommand command, string name) => command.Parameters[name].Value;

    [Fact]
    public void Calls_the_schema_procedure_with_the_processing_time_and_the_file_name_only()
    {
        var importGuid = Guid.NewGuid();
        var context = new PostContext("GULFCOAST", @"C:\in\GULFCOAST\Processing\a.835", importGuid);

        using var command = SqlPaymentPoster.BuildCommand("TestC9", context, Payment(PatGuid, PpGuid), Processed);

        Assert.Equal("[TestC9].[usp_bts_Post835PatientTransaction]", command.CommandText);
        Assert.Equal(CommandType.StoredProcedure, command.CommandType);
        Assert.Equal("a.835", Value(command, "@ilFileName"));
        Assert.Equal(importGuid, Value(command, "@ilImportGUID"));
        Assert.Equal("Process_BBVA_835Patient", Value(command, "@ilProcess"));
        Assert.Equal(Processed, Value(command, "@ilDateTime"));
        Assert.Equal(-169.00m, Value(command, "@transAmount"));
        Assert.Equal("EOB12345678", Value(command, "@PaymentIdentifier"));
        Assert.Equal(SqlDbType.VarChar, command.Parameters["@PaymentIdentifier"].SqlDbType);
        Assert.Equal(PatGuid, Value(command, "@patGUID"));
        Assert.Equal(PpGuid, Value(command, "@ppGUID"));
    }

    [Fact]
    public void Sends_NULL_for_a_missing_patient_or_person_guid()
    {
        using var command = SqlPaymentPoster.BuildCommand("TestC9", new PostContext("GULFCOAST", "a.835", Guid.NewGuid()), Payment(), Processed);

        Assert.Equal(DBNull.Value, Value(command, "@patGUID"));
        Assert.Equal(DBNull.Value, Value(command, "@ppGUID"));
    }

    [Theory]
    [InlineData("")]
    [InlineData("Test C9")]
    [InlineData("TestC9]; DROP TABLE x; --")]
    [InlineData("TestC9\n")]
    public void Rejects_a_schema_name_that_is_not_a_plain_name(string schema)
    {
        Assert.Throws<ArgumentException>(() => new SqlPaymentPoster("Server=x", schema));
        Assert.Throws<ArgumentException>(() => SqlPaymentPoster.BuildCommand(schema, new PostContext("R", "a.835", Guid.NewGuid()), Payment(), Processed));
    }

    [Fact]
    public void Accepts_a_practice_schema_with_a_dash()
    {
        using var command = SqlPaymentPoster.BuildCommand("C9-MidWest", new PostContext("R", "a.835", Guid.NewGuid()), Payment(), Processed);

        Assert.Equal("[C9-MidWest].[usp_bts_Post835PatientTransaction]", command.CommandText);
    }
}
