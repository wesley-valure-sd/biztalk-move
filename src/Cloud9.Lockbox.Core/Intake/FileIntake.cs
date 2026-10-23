namespace Cloud9.Lockbox.Intake;

public sealed record ClaimedFile(string Region, string FileName, string ProcessingPath);

/// <summary>
/// Folder intake that processes each file once and can reset it. Layout: <c>&lt;root&gt;\&lt;REGION&gt;\&lt;file&gt;</c>.
/// The region folder name is the practice name (pcName), as in the BizTalk receive locations.
/// A claim moves the file to <c>&lt;REGION&gt;\Processing</c>. Then it moves to <c>Done</c> or <c>Failed</c>.
/// Reset moves files from one of those folders back to <c>&lt;REGION&gt;</c>.
/// </summary>
public sealed class FileIntake
{
    public const string Processing = "Processing";
    public const string Done = "Done";
    public const string Failed = "Failed";

    private readonly string _root;
    private readonly TimeSpan _minFileAge;
    private readonly TimeProvider _time;

    public FileIntake(string root, TimeSpan minFileAge, TimeProvider? time = null)
    {
        if (!Directory.Exists(root)) throw new DirectoryNotFoundException($"The intake root '{root}' does not exist.");
        _root = Path.GetFullPath(root);
        _minFileAge = minFileAge;
        _time = time ?? TimeProvider.System;
    }

    public string Root => _root;

    /// <summary>Claims each stable file that sits directly in a region folder. Subfolders are not read.</summary>
    public IReadOnlyList<ClaimedFile> ClaimAll()
    {
        var claimed = new List<ClaimedFile>();
        var cutoff = _time.GetUtcNow().UtcDateTime - _minFileAge;
        foreach (var regionDir in Directory.EnumerateDirectories(_root).Order(StringComparer.OrdinalIgnoreCase))
        {
            var region = Path.GetFileName(regionDir);
            foreach (var file in Directory.EnumerateFiles(regionDir).Order(StringComparer.OrdinalIgnoreCase))
            {
                // A file that changed recently can still be in upload.
                if (File.GetLastWriteTimeUtc(file) > cutoff) continue;
                var target = UniquePath(Path.Combine(regionDir, Processing), Path.GetFileName(file));
                try
                {
                    File.Move(file, target);
                }
                catch (IOException)
                {
                    continue; // Locked or claimed by another run.
                }
                claimed.Add(new ClaimedFile(region, Path.GetFileName(file), target));
            }
        }
        return claimed;
    }

    public string Complete(ClaimedFile file) => MoveFromProcessing(file, Done);

    public string Fail(ClaimedFile file) => MoveFromProcessing(file, Failed);

    /// <summary>Moves files from <paramref name="state"/> back to their region folder. Returns the new paths.</summary>
    public IReadOnlyList<string> Reset(string state = Failed, string? region = null, string? fileName = null)
    {
        if (state is not (Processing or Done or Failed)) throw new ArgumentException($"State must be {Processing}, {Done}, or {Failed}.", nameof(state));
        var moved = new List<string>();
        foreach (var regionDir in Directory.EnumerateDirectories(_root))
        {
            if (region is not null && !string.Equals(Path.GetFileName(regionDir), region, StringComparison.OrdinalIgnoreCase)) continue;
            var from = Path.Combine(regionDir, state);
            if (!Directory.Exists(from)) continue;
            foreach (var file in Directory.EnumerateFiles(from))
            {
                if (fileName is not null && !string.Equals(Path.GetFileName(file), fileName, StringComparison.OrdinalIgnoreCase)) continue;
                var target = UniquePath(regionDir, Path.GetFileName(file));
                File.Move(file, target);
                moved.Add(target);
            }
        }
        return moved;
    }

    private string MoveFromProcessing(ClaimedFile file, string state)
    {
        var target = UniquePath(Path.Combine(_root, file.Region, state), Path.GetFileName(file.ProcessingPath));
        File.Move(file.ProcessingPath, target);
        return target;
    }

    private string UniquePath(string dir, string fileName)
    {
        Directory.CreateDirectory(dir);
        var path = Path.Combine(dir, fileName);
        if (!File.Exists(path)) return path;
        var stamp = _time.GetUtcNow().UtcDateTime.ToString("yyyyMMddHHmmssfff");
        return Path.Combine(dir, $"{Path.GetFileNameWithoutExtension(fileName)}_{stamp}{Path.GetExtension(fileName)}");
    }
}
