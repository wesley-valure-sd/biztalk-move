<#
.SYNOPSIS
  Write UTF-8 copies of the BizTalk source files to a scratch folder.
.DESCRIPTION
  Many BizTalk artifacts (.btm, .btp, some .xsd) are saved as UTF-16.
  Text tools and AI agents cannot read UTF-16 files well. This script
  writes a UTF-8 copy of each source file to the output folder. The
  folder structure stays the same. The script does not change a source file.
#>
param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path,
    [string]$OutDir = (Join-Path $env:TEMP 'c9decoded')
)

$ErrorActionPreference = 'Stop'
$extensions = '.btm', '.btp', '.odx', '.xsd', '.xml', '.sql', '.cs', '.config', '.xsl', '.xslt', '.btproj', '.csproj', '.ps1', '.btdfproj', '.sqlproj'

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$rootFull = (Resolve-Path $Root).Path.TrimEnd('\') + '\'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$count = 0

Get-ChildItem -Path $rootFull -Recurse -File |
Where-Object { $extensions -contains $_.Extension.ToLowerInvariant() -and $_.FullName -notlike '*\KnowledgeBase\*' } |
ForEach-Object {
    $rel = $_.FullName.Substring($rootFull.Length)
    $dest = Join-Path $OutDir $rel
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null
    $text = [System.IO.File]::ReadAllText($_.FullName)
    [System.IO.File]::WriteAllText($dest, $text, $utf8)
    $count++
}

"Wrote $count files to $OutDir" | Tee-Object -FilePath (Join-Path $OutDir '_done.txt')
