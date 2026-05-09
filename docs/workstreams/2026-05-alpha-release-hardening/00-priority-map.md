# Priority Map

## Priority 0 - Freeze The Release Gate

The first hardening task is to make release validation repeatable.

The release gate should cover:

- workspace dependency guards
- root boundary guards
- core compatibility shell guard
- transport boundary guard
- test legacy-import guard
- package analysis
- package tests
- workspace publish dry-run
- clean Dart consumer smoke validation
- clean Flutter consumer smoke validation

The command should fail fast on validation errors and print enough context to
make the next action clear.

## Priority 1 - Audit Package Metadata

Before publishing, verify that package metadata matches the implemented
architecture:

- package descriptions describe current ownership, not historical ownership
- README files point new users to modern focused entrypoints
- compatibility packages and barrels are described as compatibility surfaces
- changelogs name breaking paths and replacements
- dependency constraints match the publish order
- `publish_to: none` remains limited to non-publishable helper packages

Metadata drift is a release blocker because it shapes how external users choose
entrypoints.

## Priority 2 - Validate Clean Consumers

Repository tests are necessary but not sufficient.

Clean consumers should verify:

- `package:llm_dart/llm_dart.dart`
- focused provider package imports
- `llm_dart_provider`, `llm_dart_ai`, `llm_dart_transport`, and
  `llm_dart_chat`
- `package:llm_dart/legacy.dart`
- `llm_dart_flutter` with a provider package

The smoke tests should avoid network calls. They should construct models,
typed options, shared contracts, chat/controller adapters, and legacy builder
chains.

## Priority 3 - Freeze Publish Order

Publishing should follow dependency direction:

1. `llm_dart_provider`
2. `llm_dart_ai`
3. `llm_dart_core`
4. `llm_dart_transport`
5. `llm_dart_chat`
6. `llm_dart_openai`
7. `llm_dart_google`
8. `llm_dart_anthropic`
9. `llm_dart_ollama`
10. `llm_dart_elevenlabs`
11. `llm_dart_flutter`
12. `llm_dart`

The order can change only if the package graph changes and the release gate
documents the new reason.

## Priority 4 - Record Post-Publish Verification

After publishing, repeat clean consumer smoke validation against pub.dev
versions rather than local path overrides.

The release should not be considered complete until:

- pub.dev package pages render expected metadata
- dependency resolution works without local overrides
- modern root, focused packages, Flutter, and legacy compatibility imports
  compile in clean consumers
- release notes point users to the migration matrix

## Stop Conditions

Stop hardening and fix the branch when:

- any guard fails
- analysis or tests fail
- publish dry-run reports a warning
- a clean consumer cannot resolve or compile
- package metadata contradicts implemented package ownership
- a release fix requires more than packaging, docs, exports, or narrowly scoped
  compatibility repairs

If the fix becomes architectural again, open a separate targeted workstream
instead of hiding it inside release hardening.
