using Cloud9.Lockbox.X12;

namespace Cloud9.Lockbox.Tests;

/// <summary>Reads the committed insurance scenario files in src\testdata\Insurance\TESTC9 (TestC9 identities, no PHI).</summary>
internal static class InsuranceScenarios
{
    public static string Folder { get; } = FindFolder();

    /// <summary>The text of scenario <paramref name="id"/>, for example "I01".</summary>
    public static string Text(string id)
    {
        var files = Directory.GetFiles(Folder, $"*_{id}.835");
        return File.ReadAllText(Assert.Single(files));
    }

    public static IReadOnlyList<X12TransactionSet> Sets(string id) => X12Interchange.Parse(Text(id)).TransactionSets;

    public static IEnumerable<string> Ids() =>
        Directory.GetFiles(Folder, "*.835").Select(f => Path.GetFileNameWithoutExtension(f).Split('_')[^1]).Order();

    private static string FindFolder()
    {
        for (var dir = new DirectoryInfo(AppContext.BaseDirectory); dir is not null; dir = dir.Parent)
        {
            var candidate = Path.Combine(dir.FullName, "testdata", "Insurance", "TESTC9");
            if (Directory.Exists(candidate)) return candidate;
        }
        throw new DirectoryNotFoundException("src\\testdata\\Insurance\\TESTC9 was not found above the test output folder.");
    }
}
