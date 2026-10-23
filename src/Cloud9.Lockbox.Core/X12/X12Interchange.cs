namespace Cloud9.Lockbox.X12;

/// <summary>The segments of one ST/SE transaction set, ST and SE included.</summary>
public sealed record X12TransactionSet(string ControlNumber, IReadOnlyList<X12Segment> Segments);

/// <summary>
/// Parses one X12 interchange. The separators come from the ISA segment, so files with
/// ISA11 '^' and any segment terminator parse. Checks the envelope like the BizTalk EDI
/// disassembler does at a basic level: ISA/IEA, GS/GE, and ST/SE pairs, control numbers,
/// and SE01 segment counts.
/// </summary>
public sealed class X12Interchange
{
    private X12Interchange(char elementSeparator, char componentSeparator, char segmentTerminator, IReadOnlyList<X12Segment> segments, IReadOnlyList<X12TransactionSet> transactionSets)
    {
        ElementSeparator = elementSeparator;
        ComponentSeparator = componentSeparator;
        SegmentTerminator = segmentTerminator;
        Segments = segments;
        TransactionSets = transactionSets;
    }

    public char ElementSeparator { get; }
    public char ComponentSeparator { get; }
    public char SegmentTerminator { get; }
    public IReadOnlyList<X12Segment> Segments { get; }
    public IReadOnlyList<X12TransactionSet> TransactionSets { get; }
    public X12Segment Isa => Segments[0];

    public static X12Interchange Parse(string text)
    {
        ArgumentNullException.ThrowIfNull(text);
        var data = text.TrimStart('\uFEFF', ' ', '\r', '\n', '\t');
        if (!data.StartsWith("ISA", StringComparison.Ordinal) || data.Length < 106)
            throw new X12FormatException("The file does not start with a complete ISA segment.");

        var elementSeparator = data[3];
        // ISA has 16 elements. ISA16 is one character, and the segment terminator follows it.
        var separatorCount = 0;
        var isa16 = -1;
        for (var i = 3; i < data.Length; i++)
        {
            if (data[i] != elementSeparator) continue;
            if (++separatorCount == 16) { isa16 = i + 1; break; }
        }
        if (isa16 < 0 || isa16 + 1 >= data.Length)
            throw new X12FormatException("The ISA segment does not have 16 elements.");
        var componentSeparator = data[isa16];
        var segmentTerminator = data[isa16 + 1];

        var segments = data.Split(segmentTerminator)
            .Select(s => s.Trim('\r', '\n'))
            .Where(s => s.Length > 0)
            .Select(s => new X12Segment(s.Split(elementSeparator)))
            .ToList();

        return new X12Interchange(elementSeparator, componentSeparator, segmentTerminator, segments, ReadTransactionSets(segments));
    }

    private static List<X12TransactionSet> ReadTransactionSets(List<X12Segment> segments)
    {
        if (segments[^1].Id != "IEA") throw new X12FormatException("The interchange has no IEA segment.");
        if (segments[^1][2] != segments[0][13]) throw new X12FormatException($"IEA02 '{segments[^1][2]}' does not match ISA13 '{segments[0][13]}'.");

        var sets = new List<X12TransactionSet>();
        var groups = 0;
        string? groupControl = null;
        var setsInGroup = 0;
        List<X12Segment>? current = null;

        foreach (var segment in segments.Skip(1).Take(segments.Count - 2))
        {
            switch (segment.Id)
            {
                case "GS":
                    if (groupControl is not null) throw new X12FormatException("A GS segment starts before the previous GE.");
                    groupControl = segment[6];
                    setsInGroup = 0;
                    groups++;
                    break;
                case "GE":
                    if (groupControl is null) throw new X12FormatException("A GE segment has no GS.");
                    if (segment[2] != groupControl) throw new X12FormatException($"GE02 '{segment[2]}' does not match GS06 '{groupControl}'.");
                    if (segment[1] != setsInGroup.ToString()) throw new X12FormatException($"GE01 is '{segment[1]}', but the group has {setsInGroup} transaction sets.");
                    groupControl = null;
                    break;
                case "ST":
                    if (groupControl is null) throw new X12FormatException("An ST segment is outside a GS/GE group.");
                    if (current is not null) throw new X12FormatException("An ST segment starts before the previous SE.");
                    current = [segment];
                    break;
                case "SE":
                    if (current is null) throw new X12FormatException("An SE segment has no ST.");
                    current.Add(segment);
                    var st = current[0];
                    if (segment[2] != st[2]) throw new X12FormatException($"SE02 '{segment[2]}' does not match ST02 '{st[2]}'.");
                    if (segment[1] != current.Count.ToString()) throw new X12FormatException($"SE01 is '{segment[1]}', but transaction set {st[2]} has {current.Count} segments.");
                    sets.Add(new X12TransactionSet(st[2], current));
                    setsInGroup++;
                    current = null;
                    break;
                default:
                    if (current is null) throw new X12FormatException($"Segment {segment.Id} is outside a transaction set.");
                    current.Add(segment);
                    break;
            }
        }

        if (current is not null) throw new X12FormatException("The last transaction set has no SE segment.");
        if (groupControl is not null) throw new X12FormatException("The last functional group has no GE segment.");
        if (segments[^1][1] != groups.ToString()) throw new X12FormatException($"IEA01 is '{segments[^1][1]}', but the interchange has {groups} groups.");
        return sets;
    }
}
