# Code graph

This folder holds a node/edge graph of the repository. Use it to move from one artifact to the next without a text search: flow → step → orchestration → map → schema → stored procedure → table, or receive port → orchestration → send port → setting.

`KnowledgeBase/tools/Build-CodeGraph.ps1` generates every file here except [curated](curated). Run the script again after a source change:

```powershell
pwsh -File KnowledgeBase/tools/Build-CodeGraph.ps1
```

## Files

| File                                                     | Contents                                                                                                                              |
| -------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| [index.md](index.md)                                     | Node counts and links to the important nodes                                                                                          |
| `nodes.json`                                             | Array of all nodes. One JSON object on each line                                                                                      |
| `edges.json`                                             | Array of all edges. One JSON object on each line                                                                                      |
| `adjacency/<type>/<name>.json`                           | One file for each node: the node, its outgoing edges, and its incoming edges. Each edge has the name, type and file of the other node |
| [curated/payment-flows.json](curated/payment-flows.json) | Hand-written flows, steps, business rules, and external systems for the 835 payment flows. The build merges this file                 |
| `build-summary.txt`, `build-warnings.txt`                | Result of the last build. A warning lists a reference that the build cannot resolve                                                   |

## How to traverse

1. Start at [index.md](index.md). Open a `flow:*` node for the payment flows, or an `orchestration:*` node for any integration.
2. Each adjacency file lists `outgoing` and `incoming` edges. Follow `toFile` or `fromFile` to the next node. The paths are relative to this folder.
3. For a terminal query, use the helper:

```powershell
# One node and its direct neighbors
pwsh -File KnowledgeBase/tools/Find-GraphNode.ps1 -Name 'Process_BBVA_835Insurance'

# All nodes of a type that match a pattern
pwsh -File KnowledgeBase/tools/Find-GraphNode.ps1 -Type sqlproc -Name '*Post835*'

# Walk a flow through its steps to the implementation (two levels)
pwsh -File KnowledgeBase/tools/Find-GraphNode.ps1 -Id 'flow:BBVA-835-Patient-Lockbox' -Depth 2 -EdgeType hasStep,implementedBy
```

## Node types

| Type                                                 | Id pattern                                                         | Source                                                             | Important fields                                                                                                                    |
| ---------------------------------------------------- | ------------------------------------------------------------------ | ------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------- |
| `solution`                                           | `solution:<name>`                                                  | `*.sln`                                                            | `path`                                                                                                                              |
| `project`                                            | `project:<file base name>`                                         | `*.btproj`, `*.csproj`, `*.sqlproj`                                | `kind`, `assemblyName`, `rootNamespace`, `framework`                                                                                |
| `file`                                               | `file:<relative path>`                                             | Every parsed file                                                  | `path`, `kind`                                                                                                                      |
| `orchestration`                                      | `orchestration:<module>.<service>`                                 | `*.odx` code section                                               | `line`, `activation`, `activationFilter`, `parameters`, `ports`, `messages`, `contextProperties`, `transaction`, `bindingStates`    |
| `messagetype`                                        | `messagetype:<module>.<name>`                                      | `messagetype` declarations in `*.odx`                              | `bodyType`                                                                                                                          |
| `porttype`                                           | `porttype:<module>.<name>`                                         | `porttype` declarations in `*.odx`                                 | `operations`                                                                                                                        |
| `map`                                                | `map:<namespace>.<type name>`                                      | `*.btm` and project item metadata                                  | `sourceSchema`, `targetSchema`, `linkCount`, `functoidCount`, `inlineScripts`, `readableSummary`                                    |
| `schema`                                             | `schema:<namespace>.<type name>`                                   | `*.xsd`                                                            | `kind`, `targetNamespace`, `rootElements`, `sqlActions`                                                                             |
| `pipeline`                                           | `pipeline:<namespace>.<type name>`                                 | `*.btp`                                                            | `direction`, `components`                                                                                                           |
| `class`, `method`                                    | `class:<namespace>.<class>`, `method:<namespace>.<class>.<method>` | `*.cs` (regex parse)                                               | `path`, `line`, `signatures`                                                                                                        |
| `external-component`                                 | `class:<full name>`                                                | Pipeline components that are not in this repository                |                                                                                                                                     |
| `sqlproc`                                            | `sqlproc:<database>.<schema>.<name>`                               | Central SQL project, WCF-SQL actions in schemas and orchestrations | `parameters`, `database`, `definedInRepo`                                                                                           |
| `sqltable`                                           | `sqltable:<database>.<schema>.<name>`                              | Central SQL project, test scripts                                  | `columns`, `database`, `definedInRepo`                                                                                              |
| `sqlscript`                                          | `sqlscript:<relative path>`                                        | `Cloud9.BizTalk.Scripts/**/*.sql`                                  | `database`, `purpose`, `folder`                                                                                                     |
| `receiveport`, `receivelocation`, `sendport`         | `<type>:<binding set>/<name>`                                      | `*/PortBindingsMaster.xml`                                         | `address`, `transport`, `receivePipeline`, `sendPipeline`, `filter`, `enabled`, `archiveFolder`, `pollingInterval`, `serviceWindow` |
| `setting`                                            | `setting:<binding set>/<NAME>`                                     | `*/SettingsFileGenerator.xml`                                      | `valuesByEnvironment` (secrets are `[REDACTED]`)                                                                                    |
| `flow`, `flowstep`, `businessrule`, `externalsystem` | `<type>:<name>`                                                    | [curated/payment-flows.json](curated/payment-flows.json)           | `logic`, `detail`, `doc`, `order`                                                                                                   |

`PracticeDB` in an id means the per-practice Cloud9 database. Its procedures and tables are not in this repository (`definedInRepo: false`).

## Edge types

| Type                                                                        | From → to                                                           | Meaning                                                             |
| --------------------------------------------------------------------------- | ------------------------------------------------------------------- | ------------------------------------------------------------------- |
| `contains`                                                                  | solution → project, project → file                                  | Membership                                                          |
| `references`                                                                | project → project                                                   | Project reference                                                   |
| `defines`, `definedIn`                                                      | file ↔ class / schema / map / messagetype / porttype / proc / table | Location                                                            |
| `hasMethod`                                                                 | class → method                                                      |                                                                     |
| `usesMap`                                                                   | orchestration → map                                                 | `transform` shape. Fields `line`, `input`, `output`                 |
| `usesMessageType`, `usesSchema`                                             | orchestration → messagetype or schema                               | Message declarations                                                |
| `bodySchema`                                                                | messagetype → schema                                                | Message body type                                                   |
| `sourceSchema`, `targetSchema`                                              | map → schema                                                        | Map source and target                                               |
| `callsMethod`                                                               | orchestration or map → method                                       | Helper call or external-assembly functoid                           |
| `callsOrchestration`, `startsOrchestration`                                 | orchestration → orchestration                                       | `call` and `exec` shapes                                            |
| `invokesProc`                                                               | orchestration → sqlproc                                             | `WCF.Action` in code, or an operation on a static WCF-SQL send port |
| `describesParametersOf`                                                     | schema → sqlproc                                                    | WCF-SQL typed procedure schema                                      |
| `reads`, `writes`                                                           | sqlproc → sqltable                                                  | Table names in the procedure body (central database only)           |
| `queries`                                                                   | sqlscript → sqltable                                                | Table names in a test script                                        |
| `boundToReceivePort`, `boundToSendPort`                                     | orchestration → port                                                | Binding file. Fields `logicalPort`, `bindingSet`                    |
| `partOf`                                                                    | receivelocation → receiveport                                       |                                                                     |
| `usesPipeline`                                                              | port or location → pipeline                                         |                                                                     |
| `usesComponent`                                                             | pipeline → class                                                    | Pipeline component                                                  |
| `usesSetting`                                                               | port or location → setting                                          | `${NAME}` placeholder                                               |
| `hasStep`, `implementedBy`, `entryPoint`, `source`, `appliesTo`, `verifies` | curated nodes → any                                                 | Hand-written links (field `curated: true`)                          |

## Limits

1. The C# parse uses regular expressions. It finds classes and methods, not call graphs inside C#.
2. Map links to functoids are not graph edges. Read the map summary (`readableSummary` field) for field-level logic.
3. The build does not parse the party agreements in `Configuration/PartyCollection*.xml`. Document 02 summarizes them.
4. The graph shows the source. The deployed server can differ (see [05-known-issues-and-open-questions.md](../docs/05-known-issues-and-open-questions.md)).
