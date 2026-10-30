#Requires -Version 7
# Combines KnowledgeBase/README.md and docs/*.md into one self-contained HTML file.
# With -Doc, exports only that document (a path, or a file name under docs/) as its own page.
# Example: pwsh KnowledgeBase\tools\Export-DocsHtml.ps1 -Doc 06-retirement-roadmap.md -OutFile KnowledgeBase\export\BizTalk-Retirement-Roadmap.html
param(
    [string]$OutFile,
    [string]$Doc
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$single = [bool]$Doc

if ($single) {
    $docPath = if (Test-Path -LiteralPath $Doc) { (Resolve-Path -LiteralPath $Doc).Path } else { Join-Path $root (Join-Path 'docs' $Doc) }
    if (-not (Test-Path -LiteralPath $docPath)) { throw "Document not found: $Doc" }
    $files = @($docPath)
    if (-not $OutFile) { $OutFile = Join-Path $root ('export\' + [IO.Path]::GetFileNameWithoutExtension($docPath) + '.html') }
}
else {
    $files = @(Join-Path $root 'README.md') +
    @(Get-ChildItem (Join-Path $root 'docs') -Filter *.md | Sort-Object Name | ForEach-Object FullName)
    if (-not $OutFile) { $OutFile = Join-Path $root 'export\Cloud9-BizTalk-KnowledgeBase.html' }
}

$outDir = Split-Path $OutFile -Parent
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

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

    # A standalone page has no other documents to link to, so keep only the link text.
    if ($single) { $html = [regex]::Replace($html, '<a href="[^"]*\.md[^"]*">(.*?)</a>', '$1') }

    [void]$toc.AppendLine("<li><a href=""#$id"">$([System.Net.WebUtility]::HtmlEncode($title))</a></li>")
    [void]$sections.AppendLine("<section id=""$id"">$html</section>")
}

$generated = Get-Date -Format 'yyyy-MM-dd HH:mm'
if ($single) {
    $pageTitle = [System.Net.WebUtility]::HtmlEncode($title)
    $sourceNote = [IO.Path]::GetFileName($files[0])
    $nav = ''
}
else {
    $pageTitle = 'Cloud9 BizTalk Knowledge Base'
    $sourceNote = 'KnowledgeBase/README.md and KnowledgeBase/docs/*.md'
    $nav = "<nav><strong>Contents</strong><ol>`n$toc</ol></nav>"
}

$page = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>$pageTitle</title>
<script>
(function () {
  var theme = 'light';
  try { theme = localStorage.getItem('theme') || (matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'); } catch (e) { }
  document.documentElement.dataset.theme = theme;
})();
</script>
<style>
:root { --bg: #ffffff; --fg: #1f2328; --muted: #656d76; --border: #d0d7de; --surface: #f6f8fa; --code: #f3f4f6; --link: #0969da; --callout-bg: #fff8c5; --callout-border: #bf8700; }
:root[data-theme="dark"] { --bg: #0d1117; --fg: #e6edf3; --muted: #8b949e; --border: #30363d; --surface: #161b22; --code: #21262d; --link: #58a6ff; --callout-bg: #3b2e00; --callout-border: #d29922; }
body { font-family: Segoe UI, Arial, sans-serif; max-width: 1100px; margin: 0 auto; padding: 24px; line-height: 1.5; background: var(--bg); color: var(--fg); }
a { color: var(--link); }
h1 { border-bottom: 2px solid var(--border); padding-bottom: 6px; }
h2 { border-bottom: 1px solid var(--border); padding-bottom: 4px; margin-top: 32px; }
code { background: var(--code); padding: 1px 4px; border-radius: 4px; font-size: 90%; }
pre { background: var(--surface); padding: 12px; overflow-x: auto; border-radius: 6px; }
pre code { background: none; padding: 0; }
table { border-collapse: collapse; margin: 12px 0; font-size: 92%; }
th, td { border: 1px solid var(--border); padding: 6px 10px; vertical-align: top; text-align: left; }
th { background: var(--surface); }
blockquote { margin: 16px 0; padding: 4px 16px; border-left: 5px solid var(--callout-border); background: var(--callout-bg); border-radius: 0 6px 6px 0; }
tr { page-break-inside: avoid; }
nav { background: var(--surface); border: 1px solid var(--border); border-radius: 6px; padding: 8px 24px; }
section { page-break-before: always; }
section:first-of-type { page-break-before: auto; }
.meta { color: var(--muted); font-size: 90%; }
#theme-toggle { position: fixed; top: 12px; right: 12px; padding: 4px 10px; border: 1px solid var(--border); border-radius: 6px; background: var(--surface); color: var(--fg); cursor: pointer; font: inherit; font-size: 85%; }
:root.diagrams-ready .diagram-dark { display: none; }
:root.diagrams-ready[data-theme="dark"] .diagram-light { display: none; }
:root.diagrams-ready[data-theme="dark"] .diagram-dark { display: block; }
@media print {
  :root, :root[data-theme="dark"] { --bg: #ffffff; --fg: #1f2328; --muted: #656d76; --border: #d0d7de; --surface: #f6f8fa; --code: #f3f4f6; --link: #1f2328; --callout-bg: #fff8c5; --callout-border: #bf8700; }
  nav, #theme-toggle { display: none; }
  .diagram-dark { display: none !important; }
  .diagram-light { display: block !important; }
}
</style>
</head>
<body>
<button id="theme-toggle" type="button" aria-label="Toggle dark mode"></button>
<p class="meta">Generated $generated from $sourceNote.</p>
$nav
$sections
<script>
(function () {
  var root = document.documentElement;
  var btn = document.getElementById('theme-toggle');
  function label() { btn.textContent = root.dataset.theme === 'dark' ? 'Light mode' : 'Dark mode'; }
  btn.addEventListener('click', function () {
    var next = root.dataset.theme === 'dark' ? 'light' : 'dark';
    root.dataset.theme = next;
    try { localStorage.setItem('theme', next); } catch (e) { }
    label();
  });
  label();
})();
</script>
<script type="module">
import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs';
// Render each diagram once per theme, then show the one that matches the page theme.
// ConvertFrom-Markdown emits pre.mermaid; other converters emit code.language-mermaid.
document.querySelectorAll('pre.mermaid, code.language-mermaid').forEach(c => {
  const block = c.tagName === 'CODE' ? c.parentElement : c;
  const wrap = document.createElement('div');
  wrap.className = 'diagram';
  for (const kind of ['light', 'dark']) {
    const d = document.createElement('div');
    d.className = 'mermaid diagram-' + kind;
    d.textContent = c.textContent;
    wrap.appendChild(d);
  }
  block.replaceWith(wrap);
});
for (const [theme, kind] of [['default', 'light'], ['dark', 'dark']]) {
  mermaid.initialize({ startOnLoad: false, theme: theme });
  await mermaid.run({ nodes: document.querySelectorAll('.diagram-' + kind) });
}
document.documentElement.classList.add('diagrams-ready');
</script>
</body>
</html>
"@

Set-Content -LiteralPath $OutFile -Value $page -Encoding utf8
"Wrote $OutFile ($($files.Count) documents)"
