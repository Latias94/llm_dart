# Scope And Gap Audit

Date: 2026-05-13

## Current Strengths

The repository is already structurally aligned with the durable parts of
`repo-ref/ai`:

- provider contracts are implementation-facing through `do*` methods
- `llm_dart_ai` owns user-facing runtime helpers and orchestration
- provider packages depend on provider contracts and transport, not root,
  runtime, chat, Flutter, or compatibility code
- typed provider options exist for provider-specific input behavior
- provider metadata is documented as output-side observation and replay data
- root and core compatibility surfaces are guarded
- transport owns HTTP, SSE, multipart, retry, diagnostics, and cancellation

## Gap 1 - Root Legacy Is Still Too Large

Current source still carries substantial root-package compatibility
implementation:

- `lib/legacy.dart`
- `lib/providers`
- `lib/models`
- `lib/builder`
- `lib/src/compatibility`

Risk:

- old abstractions continue to affect new architecture decisions
- root package remains hard to explain as a modern facade
- migration-era code keeps increasing test and maintenance cost

Recommendation:

- delete root legacy in the next intentional breaking line unless there is a
  concrete reason to move it to a separate compatibility package
- keep migration recipes and focused package replacements

## Gap 2 - App Prompt And Provider Prompt Are Still Both Runtime Inputs

Current runtime helpers accept both `messages:` user prompts and `prompt:`
provider-facing prompts.

Risk:

- common app code can keep constructing provider-facing prompt data
- provider contracts and runtime ergonomics remain harder to explain
- validation responsibility can drift back into provider codecs

Recommendation:

- make `ModelMessage` and shorthand prompts the documented default
- keep provider-facing `PromptMessage` inputs only as advanced/provider-contract
  escape hatches, or move them behind advanced helper names

## Gap 3 - Prompt Inputs Still Carry Metadata

The semantic direction is clear: `ProviderMetadata` is output-side data.
However, some prompt and tool output input shapes still expose metadata fields.

Risk:

- request customization can keep using output-shaped metadata
- provider codecs can regress into metadata-driven request behavior
- replay data and user-authored request options remain visually similar

Recommendation:

- remove ordinary request-side `ProviderMetadata` from prompt and tool-output
  input parts
- keep metadata on outputs and stream events
- use explicit replay prompt options for continuation

## Gap 4 - Provider Options Need A Future Composition Story

`CallOptions.providerOptions` currently carries one typed
`ProviderInvocationOptions` object.

Risk:

- provider-family options, gateway options, and provider-native options may
  compete for one slot
- users may fall back to ad hoc raw maps if typed composition is not available

Recommendation:

- evaluate a typed provider options bag or equivalent composition model
- preserve typed option classes as the primary Dart-first experience
- document a namespaced raw escape hatch for fast provider feature adoption

## Gap 5 - Structured Result Surface Needs A Final Direction

The repository now has structured output helpers, object helpers, and text-call
facades.

Risk:

- users see multiple equivalent-looking structured-generation paths
- future docs and examples may teach different surfaces
- stable API pressure can freeze accidental naming before the result layer is
  settled

Recommendation:

- choose one primary long-term structured-output path
- keep compatibility aliases only when they simplify migration
- preserve streaming partial-output and element-stream behavior

## Initial Recommendation

The next work should not reopen the package split. It should execute a focused
breaking line:

1. remove or relocate root legacy implementation ownership
2. converge app-facing prompts on `ModelMessage`
3. remove ordinary request-side metadata inputs
4. make replay explicit through typed options
5. freeze provider options composition and structured-output result direction

## M1 Decision Update

The root legacy exit strategy is now frozen as direct deletion by default.

The workstream will not create a compatibility package during the first pass.
That package would become another implementation owner and would preserve the
same maintenance pressure under a different name. It should be reconsidered
only if migration recipes and focused provider packages still leave a concrete
external workflow uncovered.

See [02-breaking-decision-and-first-slices.md](02-breaking-decision-and-first-slices.md)
for the decision record and first implementation slices.
