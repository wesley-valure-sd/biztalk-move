namespace Cloud9.Lockbox.Tests;

/// <summary>Builds synthetic BBVA patient 835 files with the shape of the 2026 production samples. No real data.</summary>
internal static class Sample835
{
    public const string PatGuid = "11111111-2222-3333-4444-555555555555";
    public const string PpGuid = "66666666-7777-8888-9999-000000000000";

    public sealed record Claim(string Clp04 = "169.00", string? PatGuid = Sample835.PatGuid, string? PpGuid = Sample835.PpGuid, string F8 = "EOB12345678");

    public static string Build(string bpr04 = "CHK", string bpr16 = "20260807", string dtm405 = "20260811", string lockbox = "1_GUL-123456_20260811", params Claim[] claims)
    {
        if (claims.Length == 0) claims = [new Claim()];
        return Envelope([Body("0001", "835", bpr04, bpr16, dtm405, lockbox, claims)]);
    }

    /// <summary>One file with more than one transaction set. A set with another transaction type fails in the mapper.</summary>
    public static string BuildSets(params (string ControlNumber, string TransactionType, Claim[] Claims)[] sets) =>
        Envelope(sets.Select(s => Body(s.ControlNumber, s.TransactionType, "CHK", "20260807", "20260811", "1_GUL-123456_20260811", s.Claims)).ToList());

    private static List<string> Body(string controlNumber, string transactionType, string bpr04, string bpr16, string dtm405, string lockbox, Claim[] claims)
    {
        var body = new List<string>
        {
            $"ST*{transactionType}*{controlNumber}",
            $"BPR*C*{claims.Sum(c => decimal.Parse(c.Clp04, System.Globalization.CultureInfo.InvariantCulture))}*C*{bpr04}*CTX*01*111000025*DA*000123*1999999999**01*222000025*DA*000456*{bpr16}",
            "TRN*1*2247*1999999999",
            "REF*2U*TEST",
            $"REF*LB*{lockbox}",
            "REF*TJ*000000000",
            $"DTM*405*{dtm405}",
            "N1*PR*TEST PAYER",
            "N3*NOT PROVIDED",
            "N4*DEFAULT CITY*XX*99999",
            "PER*BL*TEST CONTACT",
            "N1*PE*SMILE DOCTORS*XX*1234567890",
            "LX*1",
            "TS3*1234567890*11*20261231*1*169",
        };
        foreach (var c in claims)
        {
            body.Add($"CLP*ABC123456*1*{c.Clp04}*{c.Clp04}*0*ZZ");
            body.Add(c.PatGuid is null ? "NM1*QC*1*TEST*PATIENT" : $"NM1*QC*1*TEST*PATIENT****MI*{c.PatGuid}");
            if (c.PpGuid is not null) body.Add($"NM1*IL*1*TEST*PARENT****MI*{c.PpGuid}");
            body.Add("NM1*82*2*SMILE DOCTORS*****XX*1234567890");
            body.Add($"REF*F8*{c.F8}");
            body.Add("REF*G2*000000");
            body.Add("DTM*232*20260801");
            body.Add("DTM*233*20260801");
        }
        body.Add($"SE*{body.Count + 1}*{controlNumber}");
        return body;
    }

    private static string Envelope(List<List<string>> sets)
    {
        var isa = "ISA*00*          *00*          *ZZ*BBVANAV        *ZZ*SMILE DOCTORS  *260811*0600*^*00501*000000001*0*P*:";
        var segments = new List<string> { isa, "GS*HP*BBVANAV*SMILE DOCTORS*20260811*0600*1*X*005010X221A1" };
        foreach (var set in sets) segments.AddRange(set);
        segments.Add($"GE*{sets.Count}*1");
        segments.Add("IEA*1*000000001");
        return string.Join("~\r\n", segments) + "~\r\n";
    }
}
