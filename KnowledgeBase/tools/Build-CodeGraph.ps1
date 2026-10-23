<#
.SYNOPSIS
  Build a node/edge graph of the BizTalk source tree.
.DESCRIPTION
  The script reads the source files and writes a graph to the output folder:
    nodes.json      All nodes (id, type, name, path, line, metadata).
    edges.json      All edges (from, to, type, metadata).
    adjacency\      One JSON file for each node with its incoming and outgoing edges.
    index.md        Node counts and a list of the important nodes.
  The script also merges the hand-written files in graph\curated\*.json.
  The script does not change a source file. Run it again after a source change.
#>
param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path,
    [string]$OutDir = (Join-Path $PSScriptRoot '..\graph')
)

$ErrorActionPreference = 'Stop'
$rootFull = (Resolve-Path $Root).Path.TrimEnd('\') + '\'
$nodes = [ordered]@{}
$edges = New-Object System.Collections.Generic.List[object]
$edgeKeys = New-Object 'System.Collections.Generic.HashSet[string]'
$warnings = New-Object System.Collections.Generic.List[string]
$secretPattern = 'PASSWORD|PWD|PPK|SECRET|TOKEN|PRIVATEKEY|APIKEY'

function Get-Rel([string]$path) { $path.Substring($rootFull.Length).Replace('\', '/') }

# XmlNode, Match, and other rich objects do not serialize well. Reduce every value to plain data.
function ConvertTo-Plain($v) {
    if ($null -eq $v) { return $null }
    if ($v -is [string] -or $v -is [int] -or $v -is [long] -or $v -is [bool] -or $v -is [double]) { return $v }
    if ($v -is [System.Xml.XmlNode]) { return $v.InnerText }
    if ($v -is [System.Collections.IDictionary]) {
        $o = [ordered]@{}
        foreach ($k in $v.Keys) { $o["$k"] = ConvertTo-Plain $v[$k] }
        return $o
    }
    if ($v -is [System.Collections.IEnumerable]) {
        $list = New-Object System.Collections.Generic.List[object]
        foreach ($x in $v) { $list.Add((ConvertTo-Plain $x)) }
        return , $list
    }
    return "$v"
}

function Add-Node([string]$id, [string]$type, [string]$name, [hashtable]$props) {
    if (-not $nodes.Contains($id)) { $nodes[$id] = [ordered]@{ id = $id; type = $type; name = $name } }
    $n = $nodes[$id]
    if ($props) {
        foreach ($k in $props.Keys) {
            $v = ConvertTo-Plain $props[$k]
            if ($null -eq $v) { continue }
            if ($v -is [string] -and $v -eq '') { continue }
            $n[$k] = $v
        }
    }
    return $n
}

function Add-Edge([string]$from, [string]$to, [string]$type, [hashtable]$props) {
    $key = "$from|$type|$to"
    if (-not $edgeKeys.Add($key)) { return }
    $e = [ordered]@{ from = $from; to = $to; type = $type }
    if ($props) { foreach ($k in $props.Keys) { $v = ConvertTo-Plain $props[$k]; if ($null -ne $v -and "$v" -ne '') { $e[$k] = $v } } }
    $edges.Add($e)
}

function New-LineIndex([string]$text) {
    $starts = New-Object System.Collections.Generic.List[int]
    $starts.Add(0)
    foreach ($m in [regex]::Matches($text, "`n")) { $starts.Add($m.Index + 1) }
    return , $starts
}

function Get-Line($starts, [int]$pos) {
    $i = $starts.BinarySearch($pos)
    if ($i -ge 0) { return $i + 1 }
    return (-bnot $i)
}

function Read-Text([string]$path) { [System.IO.File]::ReadAllText($path) }

function Get-SourceFiles([string[]]$extensions) {
    Get-ChildItem -Path $rootFull -Recurse -File |
    Where-Object {
        $extensions -contains $_.Extension.ToLowerInvariant() -and
        $_.FullName -notmatch '\\(bin|obj|packages|KnowledgeBase|\.vscode)\\'
    }
}

function Add-FileNode([string]$fullPath, [string]$kind) {
    $rel = Get-Rel $fullPath
    $id = "file:$rel"
    Add-Node $id 'file' ([System.IO.Path]::GetFileName($fullPath)) @{ path = $rel; kind = $kind } | Out-Null
    return $id
}

# ---------------------------------------------------------------- projects and solutions
$typeByFile = @{}      # rel path (lower) -> full .NET type name (schemas, maps, pipelines)
$projectByFile = @{}   # rel path (lower) -> list of project ids

foreach ($pf in Get-SourceFiles @('.btproj', '.csproj', '.sqlproj')) {
    $projId = "project:$($pf.BaseName)"
    $relDir = (Get-Rel $pf.DirectoryName)
    try { [xml]$px = Read-Text $pf.FullName } catch { $warnings.Add("Cannot parse $($pf.FullName)"); continue }
    $pgs = @($px.Project.PropertyGroup)
    $asm = ($pgs | ForEach-Object { $_.AssemblyName } | Where-Object { $_ } | Select-Object -First 1)
    $rns = ($pgs | ForEach-Object { $_.RootNamespace } | Where-Object { $_ } | Select-Object -First 1)
    $fw = ($pgs | ForEach-Object { $_.TargetFrameworkVersion } | Where-Object { $_ } | Select-Object -First 1)
    $kind = switch ($pf.Extension.ToLowerInvariant()) { '.btproj' { 'biztalk' } '.csproj' { 'csharp' } default { 'sql-database' } }
    Add-Node $projId 'project' $pf.BaseName @{ path = (Get-Rel $pf.FullName); kind = $kind; assemblyName = "$asm"; rootNamespace = "$rns"; framework = "$fw" } | Out-Null

    foreach ($ig in @($px.Project.ItemGroup)) {
        if (-not $ig) { continue }
        foreach ($item in @($ig.ChildNodes)) {
            if ($item.NodeType -ne 'Element') { continue }
            $inc = $item.GetAttribute('Include')
            if (-not $inc) { continue }
            switch ($item.LocalName) {
                'ProjectReference' {
                    $refName = [System.IO.Path]::GetFileNameWithoutExtension($inc)
                    Add-Edge $projId "project:$refName" 'references' $null
                }
                { $_ -in 'Schema', 'Map', 'Pipeline', 'XLang', 'Compile', 'Build', 'Content', 'None' } {
                    if ($inc -match '^\.\.' -or $inc -match '\*') { continue }
                    $relFile = ($relDir + '/' + $inc.Replace('\', '/')).TrimStart('/')
                    $key = $relFile.ToLowerInvariant()
                    if (-not $projectByFile.ContainsKey($key)) { $projectByFile[$key] = New-Object System.Collections.Generic.List[string] }
                    $projectByFile[$key].Add($projId)
                    $tn = $item.TypeName; $ns = $item.Namespace
                    if ($tn -and $ns -and $item.LocalName -in 'Schema', 'Map', 'Pipeline') { $typeByFile[$key] = "$ns.$tn" }
                }
            }
        }
    }
}

foreach ($sln in Get-SourceFiles @('.sln')) {
    $slnId = "solution:$($sln.BaseName)"
    Add-Node $slnId 'solution' $sln.BaseName @{ path = (Get-Rel $sln.FullName) } | Out-Null
    foreach ($m in [regex]::Matches((Read-Text $sln.FullName), 'Project\("[^"]+"\)\s*=\s*"([^"]+)",\s*"([^"]+)"')) {
        $p = $m.Groups[2].Value
        if ($p -match '\.(btproj|csproj|sqlproj)$') { Add-Edge $slnId ("project:" + [System.IO.Path]::GetFileNameWithoutExtension($p)) 'contains' $null }
    }
}

function Connect-FileToProjects([string]$fileId) {
    $key = $fileId.Substring(5).ToLowerInvariant()
    if ($projectByFile.ContainsKey($key)) { foreach ($p in $projectByFile[$key]) { Add-Edge $p $fileId 'contains' $null } }
}

# ---------------------------------------------------------------- SQL (central DB project and scripts)
$centralProcs = @{}
$centralTables = @{}
$sqlRefPattern = '(?i)\b(FROM|JOIN|INTO|UPDATE)\s+(?:\[?(\w+)\]?\.)?\[?(\w+)\]?'

foreach ($f in Get-SourceFiles @('.sql')) {
    $rel = Get-Rel $f.FullName
    $text = Read-Text $f.FullName
    $fileId = Add-FileNode $f.FullName 'sql'
    Connect-FileToProjects $fileId
    $isCentral = $rel -like 'Cloud9.BizTalk.Database/*'
    if ($isCentral) {
        foreach ($m in [regex]::Matches($text, '(?im)^\s*CREATE\s+(TABLE|PROCEDURE|PROC)\s+(?:\[?(\w+)\]?\.)?\[?(\w+)\]?')) {
            $schema = if ($m.Groups[2].Success) { $m.Groups[2].Value } else { 'dbo' }
            $name = $m.Groups[3].Value
            if ($m.Groups[1].Value -match '^TABLE$') {
                $cols = @([regex]::Matches($text, '(?m)^\s*\[(\w+)\]\s+\[?(\w+)\]?(\s*\([^)]*\))?') | ForEach-Object { "$($_.Groups[1].Value) $($_.Groups[2].Value)$($_.Groups[3].Value.Trim())" })
                $id = "sqltable:BizTalkCloud9Common.$schema.$name"
                Add-Node $id 'sqltable' "$schema.$name" @{ database = 'BizTalkCloud9Common'; path = $rel; columns = $cols } | Out-Null
                $centralTables[$name.ToLowerInvariant()] = $id
            }
            else {
                $params = @([regex]::Matches($text.Substring(0, [Math]::Max(0, ($text.IndexOf("`nAS", [StringComparison]::OrdinalIgnoreCase))) + 0), '@(\w+)\s+([\w]+(?:\s*\([^)]*\))?)') | ForEach-Object { "@$($_.Groups[1].Value) $($_.Groups[2].Value)" })
                $id = "sqlproc:BizTalkCloud9Common.$schema.$name"
                Add-Node $id 'sqlproc' "$schema.$name" @{ database = 'BizTalkCloud9Common'; path = $rel; parameters = $params; definedInRepo = $true } | Out-Null
                $centralProcs[$name.ToLowerInvariant()] = $id
            }
            Add-Edge $fileId $id 'defines' $null
        }
    }
}
# Second pass: proc -> table references and script -> table references.
foreach ($f in Get-SourceFiles @('.sql')) {
    $rel = Get-Rel $f.FullName
    $text = Read-Text $f.FullName
    $fileId = "file:$rel"
    $procMatch = [regex]::Match($text, '(?im)^\s*CREATE\s+(?:PROCEDURE|PROC)\s+(?:\[?(\w+)\]?\.)?\[?(\w+)\]?')
    if ($rel -like 'Cloud9.BizTalk.Database/*' -and $procMatch.Success) {
        $procId = $centralProcs[$procMatch.Groups[2].Value.ToLowerInvariant()]
        foreach ($m in [regex]::Matches($text, $sqlRefPattern)) {
            $t = $m.Groups[3].Value.ToLowerInvariant()
            if ($centralTables.ContainsKey($t)) {
                $verb = if ($m.Groups[1].Value -match '(?i)INTO|UPDATE') { 'writes' } else { 'reads' }
                Add-Edge $procId $centralTables[$t] $verb $null
            }
        }
    }
    elseif ($rel -like 'Cloud9.BizTalk.Scripts/*') {
        $db = ([regex]::Match($text, '(?i)USE\s+\[?([\w\-]+)\]?')).Groups[1].Value
        $scriptId = "sqlscript:$rel"
        $purpose = ([regex]::Match($text, '(?m)^--\s*(.+)$')).Groups[1].Value.Trim()
        Add-Node $scriptId 'sqlscript' $f.Name @{ path = $rel; database = $db; purpose = $purpose; folder = $f.Directory.Name } | Out-Null
        Add-Edge $scriptId $fileId 'definedIn' $null
        foreach ($m in [regex]::Matches($text, $sqlRefPattern)) {
            $schema = if ($m.Groups[2].Success) { $m.Groups[2].Value } else { 'dbo' }
            $t = $m.Groups[3].Value
            if ($t -match '^(?i)(select|where|set|values)$') { continue }
            if ($db -eq 'BizTalkCloud9Common' -and $centralTables.ContainsKey($t.ToLowerInvariant())) { $tid = $centralTables[$t.ToLowerInvariant()] }
            else {
                $tid = "sqltable:PracticeDB.$schema.$t"
                Add-Node $tid 'sqltable' "$schema.$t" @{ database = 'PracticeDB (one database per practice; not in this repo)'; definedInRepo = $false } | Out-Null
            }
            Add-Edge $scriptId $tid 'queries' $null
        }
    }
}

function Resolve-ProcId([string]$procName, [string]$schema = 'BTS') {
    $k = $procName.ToLowerInvariant()
    if ($centralProcs.ContainsKey($k)) { return $centralProcs[$k] }
    $id = "sqlproc:PracticeDB.$schema.$procName"
    Add-Node $id 'sqlproc' "$schema.$procName" @{ database = 'PracticeDB (one database per practice; resolved at run time from BTS.PracticeConfig.pcInstanceAddress)'; definedInRepo = $false } | Out-Null
    return $id
}

# ---------------------------------------------------------------- schemas
$schemaByType = @{}   # full type name (lower) -> node id
$schemaByFile = @{}   # rel path (lower) -> node id
foreach ($f in Get-SourceFiles @('.xsd')) {
    $rel = Get-Rel $f.FullName
    $fileId = Add-FileNode $f.FullName 'xsd'
    Connect-FileToProjects $fileId
    $text = Read-Text $f.FullName
    $typeName = $typeByFile[$rel.ToLowerInvariant()]
    $id = if ($typeName) { "schema:$typeName" } else { "schema:file:$rel" }
    $tns = ([regex]::Match($text, 'targetNamespace="([^"]+)"')).Groups[1].Value
    $roots = @()
    try { [xml]$sx = $text; $roots = @($sx.schema.element | Where-Object { $_ } | ForEach-Object { $_.name }) } catch { $warnings.Add("Cannot parse $rel") }
    $kind = 'canonical-or-other'
    if ($text -match 'schema_type="property"') { $kind = 'property-schema' }
    elseif ($tns -match '/TypedProcedures/') { $kind = 'wcf-sql-typed-procedure' }
    elseif ($tns -match '/ProceduresResultSets/') { $kind = 'wcf-sql-result-set' }
    elseif ($tns -match '/TypedPolling/') { $kind = 'wcf-sql-typed-polling' }
    elseif ($tns -match '/TableOp/|/Types/Tables?/|/TableType') { $kind = 'wcf-sql-table' }
    elseif ($tns -match '2003/10/Serialization') { $kind = 'wcf-serialization' }
    elseif ($tns -match 'EDI/X12') { $kind = 'x12-edi' }
    elseif ($tns -match 'HL7|hl7') { $kind = 'hl7' }
    $actions = @([regex]::Matches($text, '<doc:action[^>]*>([^<]+)</doc:action>') | ForEach-Object { $_.Groups[1].Value } | Where-Object { $_ -notmatch '/response$' })
    Add-Node $id 'schema' ($(if ($typeName) { $typeName } else { $f.BaseName })) @{ path = $rel; targetNamespace = $tns; rootElements = $roots; kind = $kind; sqlActions = $actions } | Out-Null
    Add-Edge $id $fileId 'definedIn' $null
    if ($typeName) { $schemaByType[$typeName.ToLowerInvariant()] = $id }
    $schemaByFile[$rel.ToLowerInvariant()] = $id
    foreach ($a in $actions) {
        $parts = $a.Split('/')
        if ($parts.Length -ge 3 -and $parts[0] -eq 'TypedProcedure') { Add-Edge $id (Resolve-ProcId $parts[2] $parts[1]) 'describesParametersOf' $null }
    }
}

function Resolve-SchemaId([string]$typeRef, [string]$moduleNs, [string]$relDir) {
    if (-not $typeRef) { return $null }
    if ($typeRef -match '\.xsd$' -and $relDir) {
        $full = [System.IO.Path]::GetFullPath((Join-Path (Join-Path $rootFull $relDir) $typeRef))
        $k = (Get-Rel $full).ToLowerInvariant()
        if ($schemaByFile.ContainsKey($k)) { return $schemaByFile[$k] }
    }
    $cands = @($typeRef)
    if ($moduleNs) { $cands += "$moduleNs.$typeRef" }
    foreach ($c in $cands) {
        $k = $c.ToLowerInvariant()
        if ($schemaByType.ContainsKey($k)) { return $schemaByType[$k] }
        $i = $c.LastIndexOf('.')
        if ($i -gt 0) { $k2 = $c.Substring(0, $i).ToLowerInvariant(); if ($schemaByType.ContainsKey($k2)) { return $schemaByType[$k2] } }
    }
    $last = $typeRef.Split('.')[-1].ToLowerInvariant()
    $hits = @($schemaByType.Keys | Where-Object { $_.EndsWith(".$last") })
    if ($hits.Count -eq 1) { return $schemaByType[$hits[0]] }
    return $null
}

# ---------------------------------------------------------------- C#
$methodIndex = @{}   # "Class.Method" (lower) -> method id
foreach ($f in Get-SourceFiles @('.cs')) {
    if ($f.Name -match '^(AssemblyInfo|GlobalSuppressions)\.cs$' -or $f.Name -match '\.designer\.cs$') { continue }
    $rel = Get-Rel $f.FullName
    $text = Read-Text $f.FullName
    $fileId = Add-FileNode $f.FullName 'csharp'
    Connect-FileToProjects $fileId
    $lines = New-LineIndex $text
    $ns = ([regex]::Match($text, 'namespace\s+([\w\.]+)')).Groups[1].Value
    $classes = @([regex]::Matches($text, '(?m)^[ \t]*(?:\[[^\]]*\]\s*)*(?:(public|internal|private|protected)\s+)?(?:(?:static|sealed|abstract|partial)\s+)*(class|interface|enum|struct)\s+(\w+)'))
    foreach ($c in $classes) {
        $cid = "class:$ns.$($c.Groups[3].Value)"
        Add-Node $cid 'class' "$ns.$($c.Groups[3].Value)" @{ path = $rel; line = (Get-Line $lines $c.Index); kind = $c.Groups[2].Value; visibility = $c.Groups[1].Value } | Out-Null
        Add-Edge $fileId $cid 'defines' $null
    }
    foreach ($m in [regex]::Matches($text, '(?m)^[ \t]*(public|internal|protected|private)((?:\s+(?:static|override|virtual|async|sealed|new|extern))*)\s+([\w<>\[\],\.\?]+)\s+(\w+)\s*\(([^)]*)\)')) {
        if ($m.Groups[3].Value -in 'class', 'interface', 'enum', 'struct', 'new', 'return') { continue }
        $owner = $classes | Where-Object { $_.Index -lt $m.Index } | Select-Object -Last 1
        if (-not $owner) { continue }
        $cls = "$ns.$($owner.Groups[3].Value)"
        $mid = "method:$cls.$($m.Groups[4].Value)"
        $sig = "$($m.Groups[1].Value)$($m.Groups[2].Value) $($m.Groups[3].Value) $($m.Groups[4].Value)($(($m.Groups[5].Value -replace '\s+', ' ').Trim()))"
        $n = Add-Node $mid 'method' "$($owner.Groups[3].Value).$($m.Groups[4].Value)" @{ path = $rel; line = (Get-Line $lines $m.Index); class = $cls }
        if (-not $n.Contains('signatures')) { $n['signatures'] = New-Object System.Collections.Generic.List[string] }
        if (-not $n['signatures'].Contains($sig)) { $n['signatures'].Add($sig) }
        Add-Edge "class:$cls" $mid 'hasMethod' $null
        $methodIndex["$($owner.Groups[3].Value).$($m.Groups[4].Value)".ToLowerInvariant()] = $mid
        $methodIndex["$cls.$($m.Groups[4].Value)".ToLowerInvariant()] = $mid
    }
}

function Resolve-MethodId([string]$cls, [string]$method) {
    foreach ($k in @("$cls.$method", "$($cls.Split('.')[-1]).$method")) { if ($methodIndex.ContainsKey($k.ToLowerInvariant())) { return $methodIndex[$k.ToLowerInvariant()] } }
    $id = "method:$cls.$method"
    Add-Node $id 'method' "$($cls.Split('.')[-1]).$method" @{ class = $cls; definedInRepo = $false } | Out-Null
    return $id
}

# ---------------------------------------------------------------- maps
$mapByType = @{}
foreach ($f in Get-SourceFiles @('.btm')) {
    $rel = Get-Rel $f.FullName
    $fileId = Add-FileNode $f.FullName 'btm'
    Connect-FileToProjects $fileId
    $typeName = $typeByFile[$rel.ToLowerInvariant()]
    $id = if ($typeName) { "map:$typeName" } else { "map:file:$rel" }
    try { [xml]$mx = Read-Text $f.FullName } catch { $warnings.Add("Cannot parse $rel"); continue }
    $ms = $mx.mapsource
    $src = $ms.SrcTree.Reference.Location; $trg = $ms.TrgTree.Reference.Location
    $links = @($ms.Pages.Page | ForEach-Object { $_.Links.Link } | Where-Object { $_ })
    $functoids = @($ms.Pages.Page | ForEach-Object { $_.Functoids.Functoid } | Where-Object { $_ })
    $inline = New-Object System.Collections.Generic.List[string]
    foreach ($fn in $functoids) {
        foreach ($s in @($fn.ScripterCode.Script | Where-Object { $_ })) {
            if ($s.Language -eq 'ExternalAssembly') {
                Add-Edge $id (Resolve-MethodId $s.Class $s.Function) 'callsMethod' @{ via = 'scripting functoid (ExternalAssembly)' }
            }
            else {
                $code = $s.InnerText
                foreach ($mm in [regex]::Matches($code, 'public\s+[\w\.]+\s+(\w+)\s*\(|xsl:template name="([^"]+)"')) {
                    $nm = if ($mm.Groups[1].Success) { $mm.Groups[1].Value } else { $mm.Groups[2].Value }
                    if (-not $inline.Contains("$($s.Language):$nm")) { $inline.Add("$($s.Language):$nm") }
                }
            }
        }
    }
    Add-Node $id 'map' ($(if ($typeName) { $typeName } else { $f.BaseName })) @{
        path = $rel; sourceSchema = $src; sourceRoot = $ms.SrcTree.RootNode_Name; targetSchema = $trg; targetRoot = $ms.TrgTree.RootNode_Name
        linkCount = $links.Count; functoidCount = $functoids.Count; inlineScripts = $inline
        readableSummary = "KnowledgeBase/map-summaries/$($f.BaseName).txt"
    } | Out-Null
    Add-Edge $id $fileId 'definedIn' $null
    $mapDir = Get-Rel $f.DirectoryName
    $sid = Resolve-SchemaId $src $null $mapDir; if ($sid) { Add-Edge $id $sid 'sourceSchema' @{ root = $ms.SrcTree.RootNode_Name } } elseif ($src) { $warnings.Add("Map $rel source schema not resolved: $src") }
    $tid = Resolve-SchemaId $trg $null $mapDir; if ($tid) { Add-Edge $id $tid 'targetSchema' @{ root = $ms.TrgTree.RootNode_Name } } elseif ($trg) { $warnings.Add("Map $rel target schema not resolved: $trg") }
    if ($typeName) { $mapByType[$typeName.ToLowerInvariant()] = $id }
}

function Resolve-MapId([string]$ref) {
    $k = $ref.ToLowerInvariant()
    if ($mapByType.ContainsKey($k)) { return $mapByType[$k] }
    $last = $ref.Split('.')[-1].ToLowerInvariant()
    $hits = @($mapByType.Keys | Where-Object { $_.EndsWith(".$last") })
    if ($hits.Count -ge 1) { return $mapByType[$hits[0]] }
    $id = "map:$ref"
    Add-Node $id 'map' $ref @{ definedInRepo = $false } | Out-Null
    return $id
}

# ---------------------------------------------------------------- pipelines
$pipelineByType = @{}
foreach ($f in Get-SourceFiles @('.btp')) {
    $rel = Get-Rel $f.FullName
    $fileId = Add-FileNode $f.FullName 'btp'
    Connect-FileToProjects $fileId
    $typeName = $typeByFile[$rel.ToLowerInvariant()]
    $id = if ($typeName) { "pipeline:$typeName" } else { "pipeline:file:$rel" }
    $text = Read-Text $f.FullName
    $comps = @([regex]::Matches($text, '<Name>([^<]+)</Name>') | ForEach-Object { $_.Groups[1].Value })
    $direction = if ($text -match 'BTSReceivePolicy') { 'receive' } else { 'send' }
    Add-Node $id 'pipeline' ($(if ($typeName) { $typeName } else { $f.BaseName })) @{ path = $rel; direction = $direction; components = $comps } | Out-Null
    Add-Edge $id $fileId 'definedIn' $null
    foreach ($c in $comps) {
        $cid = "class:$c"
        if (-not $nodes.Contains($cid)) { Add-Node $cid 'external-component' $c @{ definedInRepo = $false } | Out-Null }
        Add-Edge $id $cid 'usesComponent' $null
    }
    if ($typeName) { $pipelineByType[$typeName.ToLowerInvariant()] = $id }
}

# ---------------------------------------------------------------- orchestrations
$orchParsed = New-Object System.Collections.Generic.List[object]
$messageTypes = @{}   # "module.name" lower -> body type
foreach ($f in Get-SourceFiles @('.odx')) {
    $rel = Get-Rel $f.FullName
    $fileId = Add-FileNode $f.FullName 'odx'
    Connect-FileToProjects $fileId
    $text = Read-Text $f.FullName
    $lines = New-LineIndex $text
    $start = $text.IndexOf('#endif // __DESIGNER_DATA')
    if ($start -lt 0) { $warnings.Add("No XLANG code section in $rel"); continue }
    $module = ([regex]::Match($text.Substring($start), 'module\s+([\w\.]+)')).Groups[1].Value
    foreach ($m in [regex]::Matches($text.Substring($start), 'messagetype\s+(\w+)\s*\{\s*body\s+([\w\.]+)\s+\w+;')) {
        $mtId = "messagetype:$module.$($m.Groups[1].Value)"
        Add-Node $mtId 'messagetype' $m.Groups[1].Value @{ path = $rel; bodyType = $m.Groups[2].Value; module = $module } | Out-Null
        $messageTypes["$module.$($m.Groups[1].Value)".ToLowerInvariant()] = $mtId
        Add-Edge $fileId $mtId 'defines' $null
        $sid = Resolve-SchemaId $m.Groups[2].Value $module
        if ($sid) { Add-Edge $mtId $sid 'bodySchema' @{ bodyType = $m.Groups[2].Value } }
    }
    foreach ($m in [regex]::Matches($text.Substring($start), 'porttype\s+(\w+)\s*\{(.*?)\n\s{4}\};', 'Singleline')) {
        $ptId = "porttype:$module.$($m.Groups[1].Value)"
        $ops = @([regex]::Matches($m.Groups[2].Value, '(oneway|requestresponse|solicitresponse)\s+(\w+)\s*\{\s*([^}]*)\}') | ForEach-Object { "$($_.Groups[1].Value) $($_.Groups[2].Value)($((($_.Groups[3].Value) -replace '\s+', ' ').Trim()))" })
        Add-Node $ptId 'porttype' $m.Groups[1].Value @{ path = $rel; operations = $ops; module = $module } | Out-Null
        Add-Edge $fileId $ptId 'defines' $null
    }
    $svc = [regex]::Match($text.Substring($start), '(internal|public)\s+service\s+(longrunning\s+transaction\s+|atomic\s+transaction\s+)?(\w+)')
    if (-not $svc.Success) { continue }
    $orchId = "orchestration:$module.$($svc.Groups[3].Value)"
    $orchParsed.Add([pscustomobject]@{ Id = $orchId; Module = $module; Text = $text; Start = $start; Lines = $lines; Rel = $rel; FileId = $fileId; Svc = $svc })
}

foreach ($o in $orchParsed) {
    $code = $o.Text.Substring($o.Start)
    $off = $o.Start
    $ports = @([regex]::Matches($code, 'port\s+(implements|uses)\s+(dynamic\s+)?([\w\.]+)\s+(\w+);') | ForEach-Object { "$($_.Groups[4].Value) ($($_.Groups[1].Value)$(if ($_.Groups[2].Success) { ' dynamic' }) $($_.Groups[3].Value))" })
    $msgs = @([regex]::Matches($code, '(?m)^\s*message\s+([\w\.]+)\s+(\w+);') | ForEach-Object { [pscustomobject]@{ Type = $_.Groups[1].Value; Name = $_.Groups[2].Value } })
    $params = ([regex]::Match($code.Substring($o.Svc.Index), 'body\s*\(([^)]*)\)')).Groups[1].Value.Trim()
    $act = [regex]::Match($code, 'activate\s*(?:\((?<f>.*?)\))?\s*receive\s*\((?<p>\w+)\.(?<o>\w+),\s*(?<m>\w+)\)')
    $ctxProps = @([regex]::Matches($code, '\w+\(((?:BTS|FILE|EDI|WCF|SFTP|FTP|Microsoft\.XLANGs\.BaseTypes)\.\w+)\)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    $props = @{
        path = $o.Rel; line = (Get-Line $o.Lines ($off + $o.Svc.Index)); module = $o.Module
        transaction = $o.Svc.Groups[2].Value.Trim(); visibility = $o.Svc.Groups[1].Value
        ports = $ports; messages = @($msgs | ForEach-Object { "$($_.Name): $($_.Type)" }); contextProperties = $ctxProps
    }
    if ($params) { $props['parameters'] = $params; $props['invocation'] = 'called/started by another orchestration' }
    if ($act.Success) { $props['activation'] = "activate receive ($($act.Groups['p'].Value).$($act.Groups['o'].Value), $($act.Groups['m'].Value))"; if ($act.Groups['f'].Success) { $props['activationFilter'] = $act.Groups['f'].Value } }
    Add-Node $o.Id 'orchestration' $o.Svc.Groups[3].Value $props | Out-Null
    Add-Edge $o.Id $o.FileId 'definedIn' $null

    foreach ($msg in $msgs) {
        $k = "$($o.Module).$($msg.Type)".ToLowerInvariant()
        if ($messageTypes.ContainsKey($k)) { Add-Edge $o.Id $messageTypes[$k] 'usesMessageType' @{ message = $msg.Name } }
        else { $sid = Resolve-SchemaId $msg.Type $o.Module; if ($sid) { Add-Edge $o.Id $sid 'usesSchema' @{ message = $msg.Name } } }
    }
    foreach ($m in [regex]::Matches($code, 'transform\s*\((?<out>[^)]*)\)\s*=\s*(?<map>[\w\.]+)\s*\((?<in>[^)]*)\)')) {
        Add-Edge $o.Id (Resolve-MapId $m.Groups['map'].Value) 'usesMap' @{ line = (Get-Line $o.Lines ($off + $m.Index)); input = $m.Groups['in'].Value; output = $m.Groups['out'].Value }
    }
    foreach ($m in [regex]::Matches($code, '\b(?<k>call|exec)\s+(?<o>[\w\.]+)\s*\(')) {
        $target = $m.Groups['o'].Value
        $tid = "orchestration:$target"
        if (-not $nodes.Contains($tid)) {
            $hit = $orchParsed | Where-Object { $_.Id -like "*.$($target.Split('.')[-1])" } | Select-Object -First 1
            if ($hit) { $tid = $hit.Id }
        }
        Add-Edge $o.Id $tid ($(if ($m.Groups['k'].Value -eq 'call') { 'callsOrchestration' } else { 'startsOrchestration' })) @{ line = (Get-Line $o.Lines ($off + $m.Index)) }
    }
    foreach ($m in [regex]::Matches($code, '\(WCF\.Action\)\s*=\s*"(?<a>[^"]+)"')) {
        $parts = $m.Groups['a'].Value.Split('/')
        if ($parts.Length -ge 3) { Add-Edge $o.Id (Resolve-ProcId $parts[2] $parts[1]) 'invokesProc' @{ line = (Get-Line $o.Lines ($off + $m.Index)); via = 'dynamic WCF-SQL send port (WCF.Action set in code)' } }
    }
    foreach ($m in [regex]::Matches($code, '\bsend\s*\((?<p>\w+)\.(?<op>\w+),')) {
        $op = $m.Groups['op'].Value
        if ($centralProcs.ContainsKey($op.ToLowerInvariant())) { Add-Edge $o.Id $centralProcs[$op.ToLowerInvariant()] 'invokesProc' @{ line = (Get-Line $o.Lines ($off + $m.Index)); via = "static send port operation $op (BtsActionMapping)" } }
    }
    foreach ($m in [regex]::Matches($code, 'Cloud9\.BizTalk\.(?<ns>Helper|ReportGenerator|SignalR\.Helper)\.(?<c>\w+)\.(?<m>\w+)\s*\(')) {
        Add-Edge $o.Id (Resolve-MethodId "Cloud9.BizTalk.$($m.Groups['ns'].Value).$($m.Groups['c'].Value)" $m.Groups['m'].Value) 'callsMethod' @{ line = (Get-Line $o.Lines ($off + $m.Index)) }
    }
}

# ---------------------------------------------------------------- bindings and settings
foreach ($bf in Get-SourceFiles @('.xml') | Where-Object { $_.Name -eq 'PortBindingsMaster.xml' }) {
    $set = $bf.Directory.Name
    $rel = Get-Rel $bf.FullName
    $fileId = Add-FileNode $bf.FullName 'binding'
    $raw = Read-Text $bf.FullName
    try { [xml]$bx = $raw } catch { $warnings.Add("Cannot parse binding file $rel"); continue }
    $bi = $bx.BindingInfo

    foreach ($sp in @($bi.SendPortCollection.SendPort | Where-Object { $_ })) {
        $spId = "sendport:$set/$($sp.Name)"
        $filter = @(([regex]::Matches([string]$sp.Filter, 'Property="([^"]+)" Operator="(\d+)" Value="([^"]*)"')) | ForEach-Object { "$($_.Groups[1].Value) op$($_.Groups[2].Value) '$($_.Groups[3].Value)'" })
        $actions = @([regex]::Matches([string]$sp.PrimaryTransport.TransportTypeData, 'Operation Name=(?:&quot;|")(\w+)') | ForEach-Object { $_.Groups[1].Value })
        Add-Node $spId 'sendport' $sp.Name @{
            bindingSet = $set; path = $rel; isStatic = $sp.IsStatic; isTwoWay = $sp.IsTwoWay
            address = [string]$sp.PrimaryTransport.Address; transport = [string]$sp.PrimaryTransport.TransportType.Name
            sendPipeline = [string]$sp.TransmitPipeline.Name; filter = $filter; actionMappings = $actions
        } | Out-Null
        Add-Edge $spId $fileId 'definedIn' $null
        foreach ($v in [regex]::Matches([string]$sp.OuterXml, '\$\{(\w+)\}')) { Add-Edge $spId "setting:$set/$($v.Groups[1].Value)" 'usesSetting' $null }
        $pl = [string]$sp.TransmitPipeline.Name
        if ($pl -and $pipelineByType.ContainsKey($pl.ToLowerInvariant())) { Add-Edge $spId $pipelineByType[$pl.ToLowerInvariant()] 'usesPipeline' $null }
    }
    foreach ($rp in @($bi.ReceivePortCollection.ReceivePort | Where-Object { $_ })) {
        $rpId = "receiveport:$set/$($rp.Name)"
        Add-Node $rpId 'receiveport' $rp.Name @{ bindingSet = $set; path = $rel; isTwoWay = $rp.IsTwoWay; application = [string]$rp.ApplicationName } | Out-Null
        Add-Edge $rpId $fileId 'definedIn' $null
        foreach ($rl in @($rp.ReceiveLocations.ReceiveLocation | Where-Object { $_ })) {
            $rlId = "receivelocation:$set/$($rl.Name)"
            $pd = [string]$rl.ReceivePipelineData
            $archive = ([regex]::Match($pd, 'FilePath vt="8">([^<]+)<')).Groups[1].Value
            $td = [string]$rl.ReceiveLocationTransportTypeData
            $poll = ([regex]::Match($td, 'PollingInterval vt="\d+">(\d+)<')).Groups[1].Value
            $pollUnit = ([regex]::Match($td, 'PollingIntervalUnit vt="\d+">(\w+)<')).Groups[1].Value
            $plName = ([string]$rl.ReceivePipeline.Name)
            Add-Node $rlId 'receivelocation' $rl.Name @{
                bindingSet = $set; path = $rel; address = ([string]$rl.Address).Trim(); transport = [string]$rl.ReceiveLocationTransportType.Name
                receivePipeline = $plName; enabled = [string]$rl.Enable; archiveFolder = $archive
                pollingInterval = "$poll $pollUnit".Trim(); serviceWindow = "$([string]$rl.ReceiveLocationFromTime) to $([string]$rl.ReceiveLocationToTime) (enabled=$([string]$rl.ReceiveLocationServiceWindowEnabled))"
            } | Out-Null
            Add-Edge $rlId $rpId 'partOf' $null
            if ($plName -and $pipelineByType.ContainsKey($plName.ToLowerInvariant())) { Add-Edge $rlId $pipelineByType[$plName.ToLowerInvariant()] 'usesPipeline' $null }
            foreach ($v in [regex]::Matches([string]$rl.OuterXml, '\$\{(\w+)\}')) { if ($v.Groups[1].Value -notmatch '^(DO_NOT_START|DEV_ENV)') { Add-Edge $rlId "setting:$set/$($v.Groups[1].Value)" 'usesSetting' $null } }
        }
    }
    foreach ($mr in @($bi.ModuleRefCollection.ModuleRef | Where-Object { $_ })) {
        foreach ($svc in @($mr.Services.Service | Where-Object { $_ })) {
            $oid = "orchestration:$($svc.Name)"
            if (-not $nodes.Contains($oid)) { Add-Node $oid 'orchestration' $svc.Name.Split('.')[-1] @{ definedInRepo = $false } | Out-Null }
            $n = $nodes[$oid]
            if (-not $n.Contains('bindingStates')) { $n['bindingStates'] = [ordered]@{} }
            $n['bindingStates'][$set] = [string]$svc.State
            foreach ($p in @($svc.Ports.Port | Where-Object { $_ })) {
                $rpName = if ($p.ReceivePortRef) { $p.ReceivePortRef.GetAttribute('Name') } else { '' }
                $spName = if ($p.SendPortRef) { $p.SendPortRef.GetAttribute('Name') } else { '' }
                if ($rpName) {
                    $rid = "receiveport:$set/$rpName"
                    if (-not $nodes.Contains($rid)) { Add-Node $rid 'receiveport' $rpName @{ bindingSet = $set; note = 'Bound here but not defined in this binding file. The port is defined in another binding set or exists only on the server.' } | Out-Null }
                    Add-Edge $oid $rid 'boundToReceivePort' @{ logicalPort = $p.Name; bindingSet = $set }
                }
                if ($spName) {
                    $sid = "sendport:$set/$spName"
                    if (-not $nodes.Contains($sid)) {
                        if ($p.BindingOption -eq '4') { Add-Node $sid 'sendport' $spName @{ bindingSet = $set; isStatic = 'false'; note = 'Dynamic send port. BizTalk creates it at deploy time. The orchestration sets the address and transport at run time.' } | Out-Null }
                        else { Add-Node $sid 'sendport' $spName @{ bindingSet = $set; note = 'Bound here but not defined in this binding file.' } | Out-Null }
                    }
                    Add-Edge $oid $sid 'boundToSendPort' @{ logicalPort = $p.Name; bindingSet = $set; bindingOption = $p.BindingOption }
                }
            }
        }
    }
}

foreach ($sf in Get-SourceFiles @('.xml') | Where-Object { $_.Name -eq 'SettingsFileGenerator.xml' }) {
    $set = $sf.Directory.Name
    $rel = Get-Rel $sf.FullName
    try { [xml]$sx = Read-Text $sf.FullName } catch { $warnings.Add("Cannot parse $rel"); continue }
    $envNames = @(); $fileNames = @()
    foreach ($row in @($sx.Workbook.Worksheet | Where-Object { $_.Name -eq 'Settings' } | ForEach-Object { $_.Table.Row })) {
        $cells = @(); $col = 0
        foreach ($c in @($row.Cell)) {
            if (-not $c) { continue }
            $idx = $c.GetAttribute('Index', 'urn:schemas-microsoft-com:office:spreadsheet')
            if ($idx) { $col = [int]$idx - 1 }
            while ($cells.Count -lt $col) { $cells += '' }
            $cells += $c.InnerText.Trim(); $col++
        }
        if ($cells.Count -lt 2 -or -not $cells[0]) { continue }
        if ($cells[0] -like 'Settings File Name*') { $fileNames = $cells[1..($cells.Count - 1)] | ForEach-Object { $_ -replace '^Exported_|\.xml$', '' }; continue }
        if ($cells[0] -like 'Environment Name*') { $envNames = $cells[1..($cells.Count - 1)]; continue }
        if ($cells[0] -like 'Generate File*') { continue }
        if ($cells[0] -notmatch '^[A-Za-z][\w]+$') { continue }
        $vals = [ordered]@{}
        for ($i = 1; $i -lt $cells.Count; $i++) {
            $env = if ($i - 1 -lt $envNames.Count -and $envNames[$i - 1]) { $envNames[$i - 1] } else { "col$i" }
            if ($i - 1 -lt $fileNames.Count -and $fileNames[$i - 1]) { $env = "$env ($($fileNames[$i - 1]))" }
            if ($vals.Contains($env)) { $env = "$env #$i" }
            $vals[$env] = if ($cells[0] -match $secretPattern) { '[REDACTED]' } else { $cells[$i] }
        }
        Add-Node "setting:$set/$($cells[0])" 'setting' $cells[0] @{ bindingSet = $set; path = $rel; valuesByEnvironment = $vals } | Out-Null
    }
}

# ---------------------------------------------------------------- curated overlay
$curatedDir = Join-Path $OutDir 'curated'
if (Test-Path $curatedDir) {
    foreach ($cf in Get-ChildItem $curatedDir -Filter *.json) {
        $cj = Get-Content $cf.FullName -Raw | ConvertFrom-Json -AsHashtable
        foreach ($n in @($cj.nodes)) {
            $p = @{}; foreach ($k in $n.Keys) { if ($k -notin 'id', 'type', 'name') { $p[$k] = $n[$k] } }
            $p['curated'] = $true
            Add-Node $n.id $n.type $n.name $p | Out-Null
        }
        foreach ($e in @($cj.edges)) {
            $p = @{}; foreach ($k in $e.Keys) { if ($k -notin 'from', 'to', 'type') { $p[$k] = $e[$k] } }
            $p['curated'] = $true
            Add-Edge $e.from $e.to $e.type $p
        }
    }
}

# ---------------------------------------------------------------- validate and write
foreach ($e in $edges) {
    foreach ($end in $e.from, $e.to) {
        if (-not $nodes.Contains($end)) {
            $t = $end.Split(':')[0]
            Add-Node $end $t ($end.Substring($t.Length + 1)) @{ placeholder = $true; note = 'Referenced but not found in the source tree.' } | Out-Null
            $warnings.Add("Placeholder node created for $end")
        }
    }
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$adjDir = Join-Path $OutDir 'adjacency'
if (Test-Path $adjDir) { Remove-Item -Recurse -Force $adjDir }
New-Item -ItemType Directory -Force -Path $adjDir | Out-Null

$nodeList = @($nodes.Values)
function Write-JsonArray($items, [string]$path, [string]$label) {
    $parts = foreach ($it in $items) {
        try { $it | ConvertTo-Json -Depth 8 -Compress }
        catch { $warnings.Add("$label not serializable: $(($it | Out-String).Trim()) : $_") }
    }
    [System.IO.File]::WriteAllText($path, "[`n" + ($parts -join ",`n") + "`n]`n")
}
Write-JsonArray $nodeList (Join-Path $OutDir 'nodes.json') 'Node'
Write-JsonArray $edges (Join-Path $OutDir 'edges.json') 'Edge'

$out = @{}; $in = @{}
foreach ($e in $edges) {
    if (-not $out.ContainsKey($e.from)) { $out[$e.from] = New-Object System.Collections.Generic.List[object] }
    if (-not $in.ContainsKey($e.to)) { $in[$e.to] = New-Object System.Collections.Generic.List[object] }
    $out[$e.from].Add($e); $in[$e.to].Add($e)
}

function Get-SafeName([string]$id) { ($id.Substring($id.IndexOf(':') + 1) -replace '[<>:"/\\|?*\s]', '_') }

$adjPathById = @{}
foreach ($n in $nodeList) {
    $typeDir = Join-Path $adjDir $n.type
    if (-not (Test-Path $typeDir)) { New-Item -ItemType Directory -Path $typeDir | Out-Null }
    $adjPathById[$n.id] = "adjacency/$($n.type)/$(Get-SafeName $n.id).json"
}
foreach ($n in $nodeList) {
    $o = @(if ($out.ContainsKey($n.id)) { $out[$n.id] | ForEach-Object { $x = [ordered]@{ type = $_.type; to = $_.to; toName = $nodes[$_.to].name; toType = $nodes[$_.to].type; toFile = $adjPathById[$_.to] }; foreach ($k in $_.Keys) { if ($k -notin 'from', 'to', 'type') { $x[$k] = $_[$k] } }; $x } })
    $i = @(if ($in.ContainsKey($n.id)) { $in[$n.id] | ForEach-Object { $x = [ordered]@{ type = $_.type; from = $_.from; fromName = $nodes[$_.from].name; fromType = $nodes[$_.from].type; fromFile = $adjPathById[$_.from] }; foreach ($k in $_.Keys) { if ($k -notin 'from', 'to', 'type') { $x[$k] = $_[$k] } }; $x } })
    $doc = [ordered]@{ node = $n; outgoing = $o; incoming = $i }
    try { [System.IO.File]::WriteAllText((Join-Path $OutDir $adjPathById[$n.id]), ($doc | ConvertTo-Json -Depth 8)) }
    catch { $warnings.Add("Adjacency file not written for $($n.id): $_") }
}

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('# Code graph index')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('Generated by `KnowledgeBase/tools/Build-CodeGraph.ps1`. Do not edit by hand. Run the script again after a source change.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine("Nodes: $($nodeList.Count). Edges: $($edges.Count).")
[void]$sb.AppendLine('')
[void]$sb.AppendLine('| Node type | Count |')
[void]$sb.AppendLine('|---|---|')
foreach ($g in ($nodeList | Group-Object { $_['type'] } | Sort-Object Name)) { [void]$sb.AppendLine("| $($g.Name) | $($g.Count) |") }
[void]$sb.AppendLine('')
foreach ($t in 'flow', 'flowstep', 'businessrule', 'externalsystem', 'orchestration', 'map', 'pipeline', 'sqlproc', 'sqltable', 'receiveport', 'sendport', 'project', 'solution', 'class', 'sqlscript') {
    $items = @($nodeList | Where-Object { $_['type'] -eq $t } | Sort-Object { $_['id'] })
    if ($items.Count -eq 0) { continue }
    [void]$sb.AppendLine("## $t")
    [void]$sb.AppendLine('')
    foreach ($n in $items) { [void]$sb.AppendLine("- [$($n.id)]($($adjPathById[$n.id]))") }
    [void]$sb.AppendLine('')
}
[System.IO.File]::WriteAllText((Join-Path $OutDir 'index.md'), $sb.ToString())
$warnings | Sort-Object -Unique | Set-Content -Path (Join-Path $OutDir 'build-warnings.txt') -Encoding utf8

"Nodes: $($nodeList.Count); Edges: $($edges.Count); Warnings: $(@($warnings | Sort-Object -Unique).Count)" | Tee-Object -FilePath (Join-Path $OutDir 'build-summary.txt')
