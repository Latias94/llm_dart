# Root Legacy Classification

## Purpose

This note records the current root legacy decision set after the post-alpha
facade cleanup. It is the human-readable companion to
`tool/root_legacy_classification.dart` and the root boundary guard.

## Keep

| Surface | Decision | Note |
| --- | --- | --- |
| `package:llm_dart/llm_dart.dart` | keep | Default root facade that exports `ai.dart`. |
| `package:llm_dart/ai.dart` | keep | Provider-neutral modern aggregator facade. |
| `package:llm_dart/core.dart` | keep | Stable shared runtime facade over `llm_dart_ai`. |
| `package:llm_dart/transport.dart` | keep | Stable transport facade over `llm_dart_transport`. |
| `package:llm_dart/chat.dart` | keep | Stable chat facade over `llm_dart_chat`. |

## Remove

| Surface | Decision | Note |
| --- | --- | --- |
| `package:llm_dart/legacy.dart` | remove | No compatibility barrel remains in the active root package. |
| `package:llm_dart/builder/...` | remove | Builder-era root implementation ownership is gone. |
| `package:llm_dart/models/...` | remove | Model contracts now live in package-owned surfaces. |
| `package:llm_dart/providers/...` | remove | Direct provider packages own provider-native behavior. |
| Legacy `package:llm_dart/core/...` subpaths | remove | Use the modern `package:llm_dart/core.dart` facade instead. |
| `lib/src/bootstrap/` | remove | Root no longer owns bootstrap implementation internals. |
| `lib/src/compatibility/` | remove | Compatibility internals are no longer part of the root package. |
| `lib/src/config/` | remove | Configuration ownership belongs to the owning packages. |
| `lib/src/` root implementation ownership | remove | Root public files remain facades only. |

## Document

| Surface | Decision | Note |
| --- | --- | --- |
| Provider-facing `PromptMessage` input | document | Advanced/provider-contract prompt use only. |
| `generateObject(...)` / `streamObject(...)` | document | Thin wrappers or migration helpers around the text/result facades. |

## Notes

- This classification supersedes the older migration-era "keep/freeze"
  snapshot in the April legacy-deprecation planning workstream.
- The guard implementation reads the same decision table and derives its
  allowlists from the keep entries.
- The root README and example guards already reflect the keep/remove posture;
  this note is the current classification anchor for future maintenance.
