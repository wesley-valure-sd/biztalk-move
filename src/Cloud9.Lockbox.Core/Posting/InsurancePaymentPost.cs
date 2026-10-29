namespace Cloud9.Lockbox.Posting;

/// <summary>
/// The parameters that BizTalk flow C (Process_BBVA_835Insurance) sends to the practice procedure
/// BTS.Post835InsuranceTransaction for one CLP or one PLB adjustment. A null value means that BizTalk does not send it.
/// </summary>
public sealed record InsurancePaymentPost
{
    public required Guid TransGuid { get; init; }
    public required DateTime TransDateTime { get; init; }
    public required DateTime TransDateTimePosted { get; init; }
    public string TransStatus { get; init; } = "N";
    public Guid? PatGuid { get; init; }
    public Guid? PipGuid { get; init; }
    public required decimal TransAmount { get; init; }
    public required decimal TransDueNowAmount { get; init; }
    public required decimal TransTotalDueAmount { get; init; }
    public decimal TransProductionAmount { get; init; }
    public string TransClaimAmount { get; init; } = "0";
    public string TransIsGroup { get; init; } = "0";
    public required string TransNote { get; init; }
    public required string TransReceiptNote { get; init; }
    public string? TransReference { get; init; }
    public string? TransCheckNumber { get; init; }
    public string? TransRouting { get; init; }
    public string? AdaClaimNumber { get; init; }
    public string? PipPolicyNumber { get; init; }
    public string? PtPaymentTypeCode { get; init; }
    public string? ClaimIdentifier { get; init; }
    public string? PaymentIdentifier { get; init; }
    public string? AdjustmentType { get; init; }

    /// <summary>ST02 of the source transaction set. Not a procedure parameter.</summary>
    public required string SourceControlNumber { get; init; }

    /// <summary>A PLB adjustment. Its ImportLog message gets the prefix "ADJ - ".</summary>
    public bool IsAdjustment => AdjustmentType is not null;
}
