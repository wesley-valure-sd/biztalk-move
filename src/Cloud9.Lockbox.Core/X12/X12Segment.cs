namespace Cloud9.Lockbox.X12;

/// <summary>One X12 segment. <see cref="Elements"/>[0] is the segment id.</summary>
public sealed record X12Segment(IReadOnlyList<string> Elements)
{
    public string Id => Elements[0];

    /// <summary>Returns element <paramref name="position"/> (1-based, as in "CLP04"), or "" if absent.</summary>
    public string this[int position] => position < Elements.Count ? Elements[position] : string.Empty;

    public override string ToString() => string.Join('*', Elements);
}
