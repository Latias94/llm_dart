# OpenAI Family Policy Hub Split - Evidence And Gates

Status: Closed
Last updated: 2026-05-23

## Initial Gates

Before claiming the first slice complete:

```powershell
dart --suppress-analytics test packages/llm_dart_openai/test/openai_family_option_resolver_test.dart
dart --suppress-analytics test packages/llm_dart_openai/test/openai_language_model_test.dart packages/llm_dart_openai/test/openai_image_model_test.dart packages/llm_dart_openai/test/openai_speech_model_test.dart packages/llm_dart_openai/test/openai_transcription_model_test.dart
dart --suppress-analytics analyze packages/llm_dart_openai
git diff --check
```

Status: the generate-text and non-text helper split slices have been validated
with focused OpenAI tests, package analysis, workspace/root guards, and diff
hygiene checks.

## Package Gates

After the split grows beyond the first slice:

```powershell
dart --suppress-analytics test packages/llm_dart_openai/test
dart --suppress-analytics analyze packages/llm_dart_openai
dart --suppress-analytics run tool/check_workspace_dependency_guards.dart
dart --suppress-analytics run tool/check_root_package_boundary_guards.dart
git diff --check
```

## Evidence Anchors

- `packages/llm_dart_openai/lib/src/provider/openai_provider_options_bag.dart`
- `packages/llm_dart_openai/lib/src/provider/openai_provider_options_bag_generate_text.dart`
- `packages/llm_dart_openai/lib/src/provider/openai_provider_options_bag_non_text.dart`
- `packages/llm_dart_openai/lib/src/provider/openai_family_invocation_options.dart`
- `packages/llm_dart_openai/lib/src/provider/openai_family_common_option_resolver.dart`
- `packages/llm_dart_openai/lib/llm_dart_openai.dart`
- `packages/llm_dart_openai/test/openai_family_option_resolver_test.dart`

## Evidence Log

### 2026-05-23 - OPH-110 Generate-text compatibility seam split

Command:

```powershell
dart --suppress-analytics test packages/llm_dart_openai/test/openai_family_option_resolver_test.dart packages/llm_dart_openai/test/openai_language_model_test.dart packages/llm_dart_openai/test/openai_image_model_test.dart packages/llm_dart_openai/test/openai_speech_model_test.dart packages/llm_dart_openai/test/openai_transcription_model_test.dart
dart --suppress-analytics analyze packages/llm_dart_openai
git diff --check
```

Result: passed.

Notes:

- The OpenAI family option resolver still passes typed override, profile
  rejection, and provider bag compatibility tests.
- `llm_dart_openai` package analysis remains clean after the `part` split.
- `git diff --check` only reported the expected LF/CRLF warning on the
  updated workstream index.

### 2026-05-23 - OPH-210..OPH-250 Non-text option helper split

Command:

```powershell
dart --suppress-analytics test packages/llm_dart_openai/test/openai_family_option_resolver_test.dart packages/llm_dart_openai/test/openai_language_model_test.dart packages/llm_dart_openai/test/openai_embedding_model_test.dart packages/llm_dart_openai/test/openai_image_model_test.dart packages/llm_dart_openai/test/openai_speech_model_test.dart packages/llm_dart_openai/test/openai_transcription_model_test.dart
dart --suppress-analytics analyze packages/llm_dart_openai
dart --suppress-analytics run tool/check_workspace_dependency_guards.dart
dart --suppress-analytics run tool/check_root_package_boundary_guards.dart
git diff --check
```

Result: passed.

Notes:

- Embedding, image, speech, and transcription provider option compatibility
  helpers now live in
  `packages/llm_dart_openai/lib/src/provider/openai_provider_options_bag_non_text.dart`.
- `packages/llm_dart_openai/lib/src/provider/openai_provider_options_bag.dart`
  is now a small library facade plus shared JSON parsing helpers.
- Workspace dependency and root boundary guards stayed green, so the split did
  not widen package ownership.

### 2026-05-23 - OPH-310..OPH-330 Resolver seam and compatibility posture

Command:

```powershell
dart --suppress-analytics test packages/llm_dart_openai/test/openai_family_option_resolver_test.dart packages/llm_dart_openai/test/openai_language_model_test.dart packages/llm_dart_openai/test/openai_embedding_model_test.dart packages/llm_dart_openai/test/openai_image_model_test.dart packages/llm_dart_openai/test/openai_speech_model_test.dart packages/llm_dart_openai/test/openai_transcription_model_test.dart
dart --suppress-analytics analyze packages/llm_dart_openai
dart --suppress-analytics run tool/check_workspace_dependency_guards.dart
dart --suppress-analytics run tool/check_root_package_boundary_guards.dart
git diff --check
```

Result: passed.

Notes:

- `OpenAIFamilyProfile` resolvers now use
  `packages/llm_dart_openai/lib/src/provider/openai_family_invocation_options.dart`
  as the resolver-facing seam instead of importing the compatibility bag
  facade directly.
- `packages/llm_dart_openai/lib/src/provider/openai_provider_options_bag.dart`
  now documents its public posture as a `ProviderOptionsBag` compatibility
  bridge; typed option classes remain the preferred path for new provider and
  runtime code.
- The public `llm_dart_openai` facade remains stable while the internal
  ownership boundary is stricter.

## Closeout

Status: closed on 2026-05-23 after OPH-010 through OPH-450 were completed and
validated. Remaining long-term deprecation posture for public
`ProviderOptionsBag` helper functions is a follow-on decision, not a blocker
for this policy-hub split.
