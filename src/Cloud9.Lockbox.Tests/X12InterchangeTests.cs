using Cloud9.Lockbox.X12;

namespace Cloud9.Lockbox.Tests;

public class X12InterchangeTests
{
    [Fact]
    public void Reads_separators_from_the_ISA_and_splits_by_ST()
    {
        var x = X12Interchange.Parse(Sample835.Build());

        Assert.Equal('*', x.ElementSeparator);
        Assert.Equal(':', x.ComponentSeparator);
        Assert.Equal('~', x.SegmentTerminator);
        Assert.Equal("^", x.Isa[11]);
        var set = Assert.Single(x.TransactionSets);
        Assert.Equal("0001", set.ControlNumber);
        Assert.Equal("ST", set.Segments[0].Id);
        Assert.Equal("SE", set.Segments[^1].Id);
    }

    [Fact]
    public void Accepts_other_separators()
    {
        var text = Sample835.Build().Replace("~\r\n", "\n").Replace('*', '|');

        var x = X12Interchange.Parse(text);

        Assert.Equal('|', x.ElementSeparator);
        Assert.Equal('\n', x.SegmentTerminator);
        Assert.Single(x.TransactionSets);
    }

    [Fact]
    public void Rejects_a_wrong_SE01_segment_count()
    {
        var text = Sample835.Build().Replace("SE*", "SE*9");

        var ex = Assert.Throws<X12FormatException>(() => X12Interchange.Parse(text));
        Assert.Contains("SE01", ex.Message);
    }

    [Fact]
    public void Rejects_a_file_without_ISA()
    {
        Assert.Throws<X12FormatException>(() => X12Interchange.Parse("GS*HP*X~"));
    }
}
