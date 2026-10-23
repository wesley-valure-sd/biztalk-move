namespace Cloud9.Lockbox.Posting;

/// <summary>
/// The parameters that BizTalk flow A (Process_BBVA_835Patient) sends to the practice procedure
/// BTS.Post835PatientTransaction for one CLP. A null value means that BizTalk does not send it.
/// </summary>
public sealed record PatientPaymentPost
{
    public required Guid TransGuid { get; init; }
    public required DateTime TransDateTime { get; init; }
    public required DateTime TransDateTimePosted { get; init; }
    public string TransStatus { get; init; } = "N";
    public Guid? PatGuid { get; init; }
    public Guid? PpGuid { get; init; }
    public required decimal TransAmount { get; init; }
    public required decimal TransDueNowAmount { get; init; }
    public required decimal TransTotalDueAmount { get; init; }
    public decimal TransProductionAmount { get; init; }
    public string TransClaimAmount { get; init; } = "0";
    public string TransIsGroup { get; init; } = "0";
    public string? TransNote { get; init; }
    public string? TransReference { get; init; }
    public string? TransCheckNumber { get; init; }
    public string? TransRouting { get; init; }
    public string? LbcLockboxCode { get; init; }
    public string LbcLockboxCodeType { get; init; } = "PATIENT";
    public string? PaymentIdentifier { get; init; }

    /// <summary>ST02 of the source transaction set. Not a procedure parameter.</summary>
    public required string SourceControlNumber { get; init; }
}
