# Breaking Decision And First Slices

Date: 2026-05-13

## Status

M1 direction is frozen.

This workstream will directly remove root-package legacy implementation
ownership. It will not create a separate compatibility package unless later
implementation evidence shows that a real external migration vehicle is
needed.

## Decision

The next breaking line is:

1. delete root legacy implementation ownership from `llm_dart`
2. keep root `llm_dart` as a modern facade and migration-documentation package
3. keep `llm_dart_ai` as the app-facing prompt and runtime layer
4. keep `llm_dart_provider` as the provider-facing specification layer
5. keep concrete providers in focused provider packages
6. move request customization to typed provider options and typed replay
   options, not output-side `ProviderMetadata`

## Why Direct Delete

The current source still contains enough root legacy code to act as a second
architecture:

- `lib/legacy.dart`
- `lib/builder`
- `lib/models`
- `lib/providers`
- `lib/src/compatibility`

Keeping this code in root makes the package graph harder to explain and keeps
old abstractions alive in tests, examples, smoke checks, and guards. Since this
is an intentional breaking window, freezing root legacy again would preserve
the problem instead of solving it.

A compatibility package is not the default choice because it would still need a
maintenance owner, test matrix, examples, version policy, and migration story.
That cost is only justified if users need a separate bridge after the modern
facade and migration recipes are in place.

## Vercel AI SDK Lessons To Keep

The useful lesson from `repo-ref/ai` is the ownership model, not TypeScript
package-count parity:

- AI functions own user-facing runtime ergonomics.
- Provider specifications define implementation contracts.
- Concrete providers adapt the provider specification to native APIs.
- Message layers stay distinct: UI messages, model/user messages,
  provider-contract messages, and provider-native wire messages.
- Provider-specific features remain provider-owned instead of being flattened
  into weak shared maps.

For Dart, this maps to:

- `llm_dart_ai` owns `ModelMessage`, prompt normalization, validation,
  generation helpers, tool-loop orchestration, structured results, and UI
  projection.
- `llm_dart_provider` owns `PromptMessage`, provider model contracts, common
  request/result structures, metadata, and provider option interfaces.
- provider packages own typed options, codecs, native helper clients, replay
  helpers, and capability profiles.
- root `llm_dart` owns import convenience and migration guidance only.

## What Must Not Be Lost

The refactor must preserve the project's Dart-first strengths:

- one clear app-facing way to call models
- typed provider options for discoverability
- provider-native features such as OpenAI responses, Anthropic cache control,
  Google thinking controls, xAI live search, and ElevenLabs audio options
- a raw escape hatch for fast provider feature adoption
- replay and provider metadata for observation, continuation, and diagnostics
- focused imports for users who only want one provider

## First Implementation Slices

### Slice 1 - Root Guard And Smoke Intent

Change intent first so future edits have an automated direction:

- update `tool/check_root_package_boundary_guards.dart` so root no longer
  treats `legacy.dart`, `builder`, `models`, `providers`, or compatibility
  internals as required stable ownership
- update `test/tool/check_root_package_boundary_guards_test.dart`
- remove `legacy.dart` usage from `tool/run_consumer_smoke.dart`
- make consumer smoke prove modern root/focused package imports only

Expected validation:

- `dart run tool/check_root_package_boundary_guards.dart`
- `dart test test/tool/check_root_package_boundary_guards_test.dart`
- targeted consumer-smoke tests if present

### Slice 2 - Legacy Import Guard Expansion

Stop new tests and examples from reintroducing root legacy imports:

- add a strict guard mode that recognizes root `builder`, `models`,
  `providers`, and legacy `core` subpath imports
- expand `tool/check_test_legacy_import_guards.dart` beyond
  `package:llm_dart/legacy.dart`
- reject root subpath imports for `builder`, `models`, `providers`, and legacy
  `core` compatibility APIs where modern packages exist
- shrink example guard allowlists instead of adding new exceptions

Expected validation:

- `dart run tool/check_test_legacy_import_guards.dart`
- `dart test test/tool/check_test_legacy_import_guards_test.dart`
- `dart run tool/check_example_api_guards.dart`
- `dart test test/tool/check_example_api_guards_test.dart`

Current state:

- strict mode is available through `--strict-root-legacy-subpaths`
- the latest strict inventory passes for guarded test scopes
- the previous inventory count of 81 root legacy subpath import violations has
  been burned down by deleting or migrating legacy tests
- switching strict mode to the default remains a hardening cleanup, not a
  blocker for root source deletion

### Slice 3 - Test And Example Migration

Delete or migrate legacy tests before deleting source directories:

- root legacy entrypoint tests become removal tests or are deleted
- provider behavior tests move to focused provider packages
- builder tests become migration-doc coverage or are removed
- examples use `llm_dart_ai` plus focused provider imports

Current state:

- `test/core` root legacy tests have been removed where modern package
  coverage exists
- `test/models` root legacy tests have been removed; modern coverage now lives
  in `llm_dart_provider`, `llm_dart_ai`, `llm_dart_chat`, and focused provider
  packages
- `test/builder` root legacy tests have been removed; modern transport and
  typed provider option tests cover the retained behavior
- root legacy HTTP utility and HTTP integration tests have been removed;
  transport-owned tests cover the modern HTTP/Dio behavior
- root OpenAI-family compatibility provider tests for DeepSeek, Groq, Phind,
  xAI, and OpenRouter have been removed; `llm_dart_openai` owns those modern
  provider profiles and typed options
- root ElevenLabs provider tests have been removed; `llm_dart_elevenlabs` owns
  the modern entrypoint, capability profile, model describer, speech,
  transcription, and voice catalog coverage
- root Anthropic provider tests have been removed; `llm_dart_anthropic` owns
  the modern entrypoint, capability profile, model describer, language model,
  messages/stream/result codecs, files, MCP, and code-execution replay coverage
- root Google provider tests have been removed; `llm_dart_google` owns the
  modern entrypoint, capability profile, model describer, language model,
  generate-content/stream/result codecs, function response replay, server tool
  replay, image, speech, embedding, and custom part coverage
- root Ollama provider tests have been removed; `llm_dart_ollama` owns the
  modern entrypoint, capability profile, model describer, language model,
  embedding, and model catalog coverage
- compatibility tests, non-HTTP integration tests, and OpenAI root provider
  tests still import root legacy subpaths and remain in the strict migration
  inventory

Expected validation:

- affected package tests
- affected root tests
- `dart analyze` for touched packages

### Slice 4 - Source Removal

After guards and tests stop depending on legacy root ownership:

- delete `lib/legacy.dart`
- delete `lib/builder`
- delete `lib/models`
- delete `lib/providers`
- delete or empty root compatibility internals that no longer serve modern
  facade imports
- keep modern root entrypoints and focused provider barrels

Current status:

- complete for root source ownership as of 2026-05-13
- root `lib/` now contains only modern/focused facade entrypoints and
  `src/facade`
- `tool/check_root_package_boundary_guards.dart` rejects the deleted root
  directories and `legacy.dart` if they return

Expected validation:

- root package tests
- workspace package tests
- dependency guards
- consumer smoke
- publish dry-runs

### Slice 4a - OpenAI Residual Native APIs

OpenAI is the only remaining provider where root legacy tests still mix two
different concerns:

- provider-native lifecycle APIs that are still valuable outside the shared
  language-model call path
- old root builder, factory, config, and compatibility shells that should not
  survive the breaking line

Decision:

- move valuable OpenAI-native lifecycle APIs into `llm_dart_openai` if they
  are kept
- delete root-only builder/factory/config tests instead of preserving root
  ownership
- treat old root `CompletionCapability` as a compatibility-only facade; modern
  callers should use `openai(...).chatModel(...)` plus `llm_dart_ai`
  `generateTextCall(...)`
- replace README guidance that sends users back to root compatibility for
  Assistants or raw Responses lifecycle with focused-package APIs or explicit
  breaking-removal notes

Current classification:

- already modern in `llm_dart_openai`: chat completions, Responses generation
  codecs, Responses stream codecs, typed provider options, built-in tools,
  files, images, image editing, moderation, speech, transcription, embeddings,
  OpenRouter/DeepSeek/Groq/xAI/Phind profiles, capability descriptors, and
  custom OpenAI content/event helpers
- migrated: Assistants lifecycle helpers and raw Responses lifecycle helpers
  now live in `llm_dart_openai`
- deleted as legacy root surface: `LLMBuilder` OpenAI configuration tests,
  root `OpenAIProvider` bridge/factory/support tests, old message-conversion
  tests, and root completion helper tests

### Slice 5 - Prompt Metadata And Options Boundary

Once root no longer hides compatibility behavior:

- remove ordinary request-side `ProviderMetadata` from prompt and tool-output
  input constructors
- keep output metadata on results, events, UI projection, and replay
  observations
- carry replay through typed `ProviderReplayPromptPartOptions` or
  provider-owned typed helpers
- document and test the provider options composition model

Expected validation:

- provider replay metadata guard
- provider prompt normalization tests
- `llm_dart_ai` text/object generation tests
- focused provider codec tests

## Stop Conditions

Pause and re-evaluate only if one of these appears:

- a modern public API cannot express an important provider-native feature
- deleting root legacy would remove behavior with no focused-package
  replacement
- consumer smoke exposes an app-facing workflow that still requires root legacy
- publish dry-run proves a package export or dependency cycle that was not
  visible in targeted tests

Otherwise the default path is to keep deleting compatibility-era ownership and
move missing modern behavior into the correct focused package.
