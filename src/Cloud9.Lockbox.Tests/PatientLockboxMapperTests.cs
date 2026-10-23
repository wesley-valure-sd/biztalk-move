using Cloud9.Lockbox.Mapping;
using Cloud9.Lockbox.X12;

namespace Cloud9.Lockbox.Tests;

public class PatientLockboxMapperTests
{
    private static readonly DateTime Now = new(2026, 8, 11, 14, 36, 3, 730);

    private static IReadOnlyList<Posting.PatientPaymentPost> MapSingleSet(string text) =>
        PatientLockboxMapper.Map(Assert.Single(X12Interchange.Parse(text).TransactionSets), Now);

    [Fact]
    public void Maps_one_CLP_like_BizTalk_flow_A()
    {
        var post = Assert.Single(MapSingleSet(Sample835.Build()));

        Assert.Equal(Guid.Parse(Sample835.PatGuid), post.PatGuid);
        Assert.Equal(Guid.Parse(Sample835.PpGuid), post.PpGuid);
        Assert.Equal(-169.00m, post.TransAmount);
        Assert.Equal(-169.00m, post.TransDueNowAmount);
        Assert.Equal(-169.00m, post.TransTotalDueAmount);
        Assert.Equal(0m, post.TransProductionAmount);
        Assert.Equal("0", post.TransClaimAmount);
        Assert.Equal("0", post.TransIsGroup);
        Assert.Equal("N", post.TransStatus);
        Assert.Equal("2247", post.TransReference);
        Assert.Equal("2247", post.TransCheckNumber);
        Assert.Equal("111000025", post.TransRouting);
        Assert.Equal("CHK", post.LbcLockboxCode);
        Assert.Equal("PATIENT", post.LbcLockboxCodeType);
        Assert.Equal("EOB12345678", post.PaymentIdentifier);
        Assert.Equal("0001", post.SourceControlNumber);
        Assert.NotEqual(Guid.Empty, post.TransGuid);
    }

    [Fact]
    public void Uses_the_processing_time_without_fractions_for_both_dates()
    {
        var post = Assert.Single(MapSingleSet(Sample835.Build()));

        var expected = new DateTime(2026, 8, 11, 14, 36, 3);
        Assert.Equal(expected, post.TransDateTime);
        Assert.Equal(expected, post.TransDateTimePosted);
    }

    [Fact]
    public void Builds_the_note_from_the_deposit_date_check_date_and_stripped_lockbox()
    {
        var post = Assert.Single(MapSingleSet(Sample835.Build(bpr16: "20260807", dtm405: "20260811", lockbox: "1_GUL-123456_20260811")));

        Assert.Equal("Deposit Date: 20260811, Check Date: 20260807, Lockbox: 1_GUL-123456", post.TransNote);
    }

    [Fact]
    public void Sends_null_GUIDs_when_NM109_is_empty_or_NM1_IL_is_missing()
    {
        var post = Assert.Single(MapSingleSet(Sample835.Build(bpr04: "PCC", claims: new Sample835.Claim(PatGuid: null, PpGuid: null))));

        Assert.Null(post.PatGuid);
        Assert.Null(post.PpGuid);
        Assert.Equal("PCC", post.LbcLockboxCode);
    }

    [Fact]
    public void Maps_each_CLP_to_its_own_post_with_its_own_IDs()
    {
        var second = new Sample835.Claim(Clp04: "74.53", PatGuid: "aaaaaaaa-0000-0000-0000-000000000001", PpGuid: "aaaaaaaa-0000-0000-0000-000000000002", F8: "EOB00000002");

        var posts = MapSingleSet(Sample835.Build(claims: [new Sample835.Claim(), second]));

        Assert.Equal(2, posts.Count);
        Assert.Equal(-74.53m, posts[1].TransAmount);
        Assert.Equal(Guid.Parse(second.PatGuid!), posts[1].PatGuid);
        Assert.Equal("EOB00000002", posts[1].PaymentIdentifier);
        Assert.Equal("EOB12345678", posts[0].PaymentIdentifier);
        Assert.NotEqual(posts[0].TransGuid, posts[1].TransGuid);
    }

    [Fact]
    public void Rejects_an_NM109_that_is_not_a_GUID_without_echoing_the_value()
    {
        var ex = Assert.Throws<X12FormatException>(() => MapSingleSet(Sample835.Build(claims: new Sample835.Claim(PatGuid: "GCE098806"))));

        Assert.Contains("NM1*QC NM109", ex.Message);
        Assert.DoesNotContain("GCE098806", ex.Message);
    }

    [Theory]
    [InlineData("1_GUL-123456_20260811", "20260811", "1_GUL-123456")]
    [InlineData("DAL-674462_3_20200205", "20200205", "DAL-674462_3")]
    [InlineData("1_GUL-123456", "20260811", "1_GUL-123456")]
    [InlineData("1_GUL-123456_", "", "1_GUL-123456")]
    public void GetLockboxNumber_matches_the_BizTalk_script(string code, string date, string expected)
    {
        Assert.Equal(expected, PatientLockboxMapper.GetLockboxNumber(code, date));
    }
}
