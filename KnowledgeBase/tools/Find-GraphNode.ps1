<#
.SYNOPSIS
  Find nodes in the code graph and show their neighbors.
.EXAMPLE
  ./Find-GraphNode.ps1 -Name '*BBVA_835Patient*'
.EXAMPLE
  ./Find-GraphNode.ps1 -Type sqlproc -Name '*Post835*' -Depth 2
.EXAMPLE
  ./Find-GraphNode.ps1 -Id 'flow:CHC-835-Insurance-ERA' -Depth 2 -EdgeType hasStep,implementedBy
.DESCRIPTION
  -Name and -Id accept wildcards. -Depth follows edges in both directions.
  -EdgeType limits the edges that the walk follows.
#>
param(
    [string]$Name = '*',
    [string]$Id,
    [string]$Type,
    [int]$Depth = 1,
    [string[]]$EdgeType,
    [string]$GraphDir = (Join-Path $PSScriptRoot '..\graph')
)

$nodes = @{}
foreach ($n in (Get-Content (Join-Path $GraphDir 'nodes.json') -Raw | ConvertFrom-Json)) { $nodes[$n.id] = $n }
$edges = Get-Content (Join-Path $GraphDir 'edges.json') -Raw | ConvertFrom-Json
if ($EdgeType) { $edges = $edges | Where-Object { $EdgeType -contains $_.type } }

$out = @{}; $in = @{}
foreach ($e in $edges) {
    if (-not $out.ContainsKey($e.from)) { $out[$e.from] = @() }
    if (-not $in.ContainsKey($e.to)) { $in[$e.to] = @() }
    $out[$e.from] += $e; $in[$e.to] += $e
}

$start = $nodes.Values | Where-Object {
    ($(if ($Id) { $_.id -like $Id } else { $_.name -like $Name -or $_.id -like "*:$Name" })) -and
    (-not $Type -or $_.type -eq $Type)
}
if (-not $start) { Write-Host 'No node matches.'; return }

foreach ($s in $start) {
    Write-Host ''
    Write-Host "== $($s.id)" -ForegroundColor Cyan
    $s.PSObject.Properties | Where-Object { $_.Name -notin 'id' } | ForEach-Object {
        $v = if ($_.Value -is [array]) { ($_.Value -join '; ') } else { $_.Value }
        Write-Host ("   {0}: {1}" -f $_.Name, $v)
    }
    $seen = @{ $s.id = $true }
    $frontier = @($s.id)
    for ($d = 1; $d -le $Depth; $d++) {
        $next = @()
        foreach ($fid in $frontier) {
            foreach ($e in @($out[$fid])) {
                if (-not $e) { continue }
                Write-Host ("   {0}-> [{1}] {2}" -f ('  ' * ($d - 1)), $e.type, $e.to)
                if (-not $seen.ContainsKey($e.to)) { $seen[$e.to] = $true; $next += $e.to }
            }
            foreach ($e in @($in[$fid])) {
                if (-not $e) { continue }
                Write-Host ("   {0}<- [{1}] {2}" -f ('  ' * ($d - 1)), $e.type, $e.from)
                if (-not $seen.ContainsKey($e.from)) { $seen[$e.from] = $true; $next += $e.from }
            }
        }
        $frontier = $next
    }
}
