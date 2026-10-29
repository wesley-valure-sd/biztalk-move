using Cloud9.Lockbox.Mapping;
using Cloud9.Lockbox.Posting;
using Cloud9.Lockbox.X12;

namespace Cloud9.Lockbox.Tests;

public class InsuranceLockboxMapperTests
{
    private static readonly DateTime Now = new(2026, 10, 30, 9, 15, 42, 517);

    private static InsuranceMapResult MapSingleSet(string id) => InsuranceLockboxMapper.Map(Assert.Single(InsuranceScenarios.Sets(id)), Now);

    private static InsurancePaymentPost MapSinglePost(string id) => Assert.Single(MapSingleSet(id).Posts);

    public static TheoryData<string> AllScenarioIds() => new(InsuranceScenarios.Ids());

    [Theory]
    [MemberData(nameof(AllScenarioIds))]
    public void Every_scenario_file_maps_without_an_exception(string id)
    {
        foreach (var set in InsuranceScenarios.Sets(id))
            InsuranceLockboxMapper.Map(set, Now);
    }

    [Fact]
    public void I01_maps_one_CLP_like_BizTalk_flow_C()
    {
        var post = MapSinglePost("I01");

        Assert.Equal(Guid.Parse("97E4A8E5-CFF0-41A9-A955-580219C0A4F5"), post.PatGuid);
        Assert.Equal(Guid.Parse("82FAF6B6-D4C3-0DFE-EDBA-D4FC67D6A321"), post.PipGuid);
        Assert.Equal("123-45-69999", post.PipPolicyNumber);
        Assert.Equal("13874", post.AdaClaimNumber);
        Assert.Equal(-54.5m, post.TransAmount);
        Assert.Equal(-54.5m, post.TransDueNowAmount);
        Assert.Equal(-54.5m, post.TransTotalDueAmount);
        Assert.Equal(0m, post.TransProductionAmount);
        Assert.Equal("0", post.TransClaimAmount);
        Assert.Equal("0", post.TransIsGroup);
        Assert.Equal("N", post.TransStatus);
        Assert.Equal("1959226824", post.TransCheckNumber);
        Assert.Equal("1959226824", post.TransReference);
        Assert.Equal("111000025", post.TransRouting);
        Assert.Equal("CHK", post.PtPaymentTypeCode);
        Assert.Null(post.ClaimIdentifier);
        Assert.Equal("EOB01010001", post.PaymentIdentifier);
        Assert.Null(post.AdjustmentType);
        Assert.False(post.IsAdjustment);
        Assert.Equal("0001", post.SourceControlNumber);
        Assert.NotEqual(Guid.Empty, post.TransGuid);
    }

    [Fact]
    public void Uses_the_processing_time_without_fractions_for_both_dates()
    {
        var post = MapSinglePost("I01");

        var expected = new DateTime(2026, 10, 30, 9, 15, 42);
        Assert.Equal(expected, post.TransDateTime);
        Assert.Equal(expected, post.TransDateTimePosted);
    }

    [Fact]
    public void A_payment_that_is_not_NON_gets_the_base_note_only()
    {
        var post = MapSinglePost("I01");

        Assert.Equal("Deposit Date: 20260929, Check Date: 20260923, Claim Number: 13874, Lockbox: 5913241507_82.0__KHFOY_GSYVGE", post.TransNote);
        Assert.Equal(post.TransNote, post.TransReceiptNote);
    }

    [Fact]
    public void NON_adds_the_first_pair_of_each_service_CAS_and_an_empty_claim_list()
    {
        var post = MapSinglePost("I05");

        Assert.Equal(
            "Deposit Date: 20260819, Check Date: 20260819, Claim Number: 13868, Lockbox: 61475_JSH-097540, , 2: 71.19, 2: 71.19, 2: 71.19",
            post.TransNote);
        Assert.Equal("NON", post.PtPaymentTypeCode);
        Assert.Equal(0m, post.TransAmount);
    }

    [Fact]
    public void NON_lists_claim_CAS_before_service_CAS()
    {
        var text = InsuranceScenarios.Text("I05")
            .Replace("REF*69*", "CAS*CO*45*10.5*1*CO*253*1.2~\r\nREF*69*")
            .Replace("SE*36*0001", "SE*37*0001");

        var post = Assert.Single(InsuranceLockboxMapper.Map(Assert.Single(X12Interchange.Parse(text).TransactionSets), Now).Posts);

        Assert.EndsWith("Lockbox: 61475_JSH-097540, 45: 10.5, 2: 71.19, 2: 71.19, 2: 71.19", post.TransNote);
    }

    [Fact]
    public void NON_gives_each_claim_of_a_set_the_CAS_of_the_whole_set()
    {
        var secondClaim = "LX*2~\r\nCLP*13867*4*50*0*50*ZZ~\r\nNM1*QC*1*TEST*PATIENT****MI*54651058~\r\nREF*F8*EOB05990001~\r\nSVC*AD:D0120*50*0**1~\r\nCAS*CO*45*50~\r\n";
        var text = InsuranceScenarios.Text("I05").Replace("SE*36*0001", secondClaim + "SE*42*0001");

        var posts = InsuranceLockboxMapper.Map(Assert.Single(X12Interchange.Parse(text).TransactionSets), Now).Posts;

        Assert.Equal(2, posts.Count);
        Assert.All(posts, p => Assert.EndsWith(", , 2: 71.19, 2: 71.19, 2: 71.19, 45: 50", p.TransNote));
        Assert.Contains("Claim Number: 13867,", posts[1].TransNote);
    }

    [Fact]
    public void NON_cuts_the_note_to_250_characters()
    {
        var manyCas = string.Concat(Enumerable.Repeat("CAS*PR*2*71.19~\r\n", 30));
        var text = InsuranceScenarios.Text("I05")
            .Replace("CAS*PR*2*71.19**3*71.19~\r\nAMT*B6*142.38~\r\nSE*36*0001", manyCas + "AMT*B6*142.38~\r\nSE*65*0001");

        var post = Assert.Single(InsuranceLockboxMapper.Map(Assert.Single(X12Interchange.Parse(text).TransactionSets), Now).Posts);

        Assert.Equal(InsuranceLockboxMapper.NoteMaxLength, post.TransNote.Length);
    }

    [Fact]
    public void I02_maps_each_CLP_of_one_set_to_its_own_post()
    {
        var posts = MapSingleSet("I02").Posts;

        Assert.Equal(2, posts.Count);
        Assert.NotEqual(posts[0].PaymentIdentifier, posts[1].PaymentIdentifier);
        Assert.NotEqual(posts[0].TransGuid, posts[1].TransGuid);
    }

    [Fact]
    public void I03_maps_each_transaction_set_on_its_own()
    {
        var sets = InsuranceScenarios.Sets("I03");

        Assert.Equal(2, sets.Count);
        Assert.All(sets, s => Assert.Single(InsuranceLockboxMapper.Map(s, Now).Posts));
    }

    [Theory]
    [InlineData("I07", 0)]
    [InlineData("I08", 1)]
    public void Posts_a_zero_or_negative_CLP04(string id, int sign)
    {
        var post = MapSinglePost(id);

        Assert.Equal(sign, Math.Sign(post.TransAmount));
    }

    [Fact]
    public void I09_sends_null_GUIDs_and_policy_when_REF_EJ_REF_69_and_NM109_are_missing()
    {
        var post = MapSinglePost("I09");

        Assert.Null(post.PatGuid);
        Assert.Null(post.PipGuid);
        Assert.Null(post.PipPolicyNumber);
        Assert.Equal("904999388", post.AdaClaimNumber);
    }

    [Theory]
    [InlineData("I08")]
    [InlineData("I10")]
    [InlineData("I13")]
    public void Sends_null_PaymentIdentifier_when_REF_F8_is_missing(string id)
    {
        Assert.Null(MapSinglePost(id).PaymentIdentifier);
    }

    [Theory]
    [InlineData("I04", "000000000000000")]
    [InlineData("I22", "A000000000")]
    public void Sends_TRN02_as_text_whatever_its_shape(string id, string shape)
    {
        var post = MapSinglePost(id);

        Assert.Equal(shape, System.Text.RegularExpressions.Regex.Replace(System.Text.RegularExpressions.Regex.Replace(post.TransCheckNumber!, "[0-9]", "0"), "[A-Za-z]", "A"));
        Assert.Equal(post.TransCheckNumber, post.TransReference);
    }

    [Theory]
    [InlineData("I11", "00000000000000")]
    [InlineData("I12", "AAA000000")]
    public void Sends_CLP01_as_text_so_the_procedure_owns_the_int_conversion(string id, string shape)
    {
        var post = MapSinglePost(id);

        Assert.Equal(shape, System.Text.RegularExpressions.Regex.Replace(System.Text.RegularExpressions.Regex.Replace(post.AdaClaimNumber!, "[0-9]", "0"), "[A-Za-z]", "A"));
    }

    [Fact]
    public void I16_sends_null_pipPolicyNumber_when_NM1_QC_has_no_NM109()
    {
        var post = MapSinglePost("I16");

        Assert.Null(post.PipPolicyNumber);
        Assert.NotNull(post.PipGuid);
    }

    [Fact]
    public void I17_fails_the_guard_with_the_BizTalk_message_and_posts_nothing()
    {
        var result = MapSingleSet("I17");

        Assert.True(result.IsGuardFailure);
        Assert.Empty(result.Posts);
        Assert.Equal("There were 5 CLP payments and 2 PLB adjustments on transaction 0001", result.GuardFailure);
    }

    [Theory]
    [InlineData("I14")]
    [InlineData("I15")]
    public void One_CLP_with_PLB_passes_the_guard(string id)
    {
        var result = MapSingleSet(id);

        Assert.False(result.IsGuardFailure);
        Assert.Single(result.Posts, p => !p.IsAdjustment);
    }

    [Fact]
    public void I15_without_REF_LB_gets_an_empty_lockbox_in_the_note()
    {
        Assert.EndsWith(", Lockbox: ", MapSinglePost("I15").TransNote);
    }

    [Fact]
    public void Rejects_a_REF_69_that_is_not_a_GUID_without_echoing_the_value()
    {
        var text = InsuranceScenarios.Text("I01").Replace("REF*69*82FAF6B6-D4C3-0DFE-EDBA-D4FC67D6A321", "REF*69*GCE098806");

        var ex = Assert.Throws<X12FormatException>(() => InsuranceLockboxMapper.Map(Assert.Single(X12Interchange.Parse(text).TransactionSets), Now));

        Assert.Contains("REF*69", ex.Message);
        Assert.DoesNotContain("GCE098806", ex.Message);
    }
}
