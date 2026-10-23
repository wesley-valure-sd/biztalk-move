#Requires -Version 7
# Combines KnowledgeBase/README.md and docs/*.md into one self-contained HTML file.
param(
    [string]$OutFile
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
if (-not $OutFile) { $OutFile = Join-Path $root 'export\Cloud9-BizTalk-KnowledgeBase.html' }
$outDir = Split-Path $OutFile -Parent
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

$files = @(Join-Path $root 'README.md') +
@(Get-ChildItem (Join-Path $root 'docs') -Filter *.md | Sort-Object Name | ForEach-Object FullName)

$docIds = @{}
foreach ($f in $files) {
    $docIds[[IO.Path]::GetFullPath($f).ToLowerInvariant()] = 'doc-' + ([IO.Path]::GetFileNameWithoutExtension($f).ToLowerInvariant())
}

$sections = [System.Text.StringBuilder]::new()
$toc = [System.Text.StringBuilder]::new()

foreach ($f in $files) {
    $id = $docIds[[IO.Path]::GetFullPath($f).ToLowerInvariant()]
    $srcDir = Split-Path $f -Parent
    $md = Get-Content -LiteralPath $f -Raw -Encoding utf8
    $title = ([regex]::Match($md, '(?m)^#\s+(.+)$')).Groups[1].Value
    if (-not $title) { $title = [IO.Path]::GetFileNameWithoutExtension($f) }
    $html = (ConvertFrom-Markdown -InputObject $md).Html

    # Links to other exported docs become in-page anchors; other relative links are re-based to the export folder.
    $html = [regex]::Replace($html, 'href="([^"#:]+)(#[^"]*)?"', {
            param($m)
            $target = [IO.Path]::GetFullPath((Join-Path $srcDir ([uri]::UnescapeDataString($m.Groups[1].Value))))
            $key = $target.ToLowerInvariant()
            if ($docIds.ContainsKey($key)) { return 'href="#' + $docIds[$key] + '"' }
            $rel = [IO.Path]::GetRelativePath($outDir, $target).Replace('\', '/')
            $encoded = ($rel -split '/' | ForEach-Object { [uri]::EscapeDataString($_) }) -join '/'
            return 'href="' + $encoded + $m.Groups[2].Value + '"'
        })

    [void]$toc.AppendLine("<li><a href=""#$id"">$([System.Net.WebUtility]::HtmlEncode($title))</a></li>")
    [void]$sections.AppendLine("<section id=""$id"">$html</section>")
}

$generated = Get-Date -Format 'yyyy-MM-dd HH:mm'
$page = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Cloud9 BizTalk Knowledge Base</title>
<style>
body { font-family: Segoe UI, Arial, sans-serif; max-width: 1100px; margin: 0 auto; padding: 24px; line-height: 1.5; color: #1f2328; }
h1 { border-bottom: 2px solid #d0d7de; padding-bottom: 6px; }
h2 { border-bottom: 1px solid #d0d7de; padding-bottom: 4px; margin-top: 32px; }
code { background: #f3f4f6; padding: 1px 4px; border-radius: 4px; font-size: 90%; }
pre { background: #f6f8fa; padding: 12px; overflow-x: auto; border-radius: 6px; }
pre code { background: none; padding: 0; }
table { border-collapse: collapse; margin: 12px 0; font-size: 92%; }
th, td { border: 1px solid #d0d7de; padding: 6px 10px; vertical-align: top; text-align: left; }
th { background: #f6f8fa; }
nav { background: #f6f8fa; border: 1px solid #d0d7de; border-radius: 6px; padding: 8px 24px; }
section { page-break-before: always; }
section:first-of-type { page-break-before: auto; }
.meta { color: #656d76; font-size: 90%; }
@media print { nav { display: none; } a { color: inherit; } }
</style>
</head>
<body>
<p class="meta">Generated $generated from KnowledgeBase/README.md and KnowledgeBase/docs/*.md.</p>
<nav><strong>Contents</strong><ol>
$toc</ol></nav>
$sections
<script type="module">
import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs';
document.querySelectorAll('code.language-mermaid').forEach(c => {
  const d = document.createElement('div');
  d.className = 'mermaid';
  d.textContent = c.textContent;
  c.parentElement.replaceWith(d);
});
mermaid.initialize({ startOnLoad: false });
await mermaid.run();
</script>
</body>
</html>
"@

Set-Content -LiteralPath $OutFile -Value $page -Encoding utf8
"Wrote $OutFile ($($files.Count) documents)"
