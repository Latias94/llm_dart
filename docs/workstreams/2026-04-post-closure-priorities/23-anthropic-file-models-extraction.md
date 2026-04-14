# Anthropic File Models Extraction

## Why This Cut Was Worth Doing

`lib/src/compatibility/providers/anthropic/files.dart` mixed two responsibility
groups:

- Anthropic Files API data models
- Files API capability orchestration

The file data models are stable wire-format helpers, while `AnthropicFiles`
owns endpoint calls, form upload construction, deletion behavior, and local
convenience helpers.

The better ownership boundary is:

- `anthropic_file_models.dart` owns Anthropic-specific file data models
- `files.dart` owns `AnthropicFiles` API orchestration and re-exports the data
  models to preserve the legacy public import path

## What Changed

Added:

- `lib/src/compatibility/providers/anthropic/anthropic_file_models.dart`

Kept as the public compatibility Files API module:

- `lib/src/compatibility/providers/anthropic/files.dart`

The file-models file now owns:

- `AnthropicFile`
- `AnthropicFileListResponse`
- `AnthropicFileUploadRequest`
- `AnthropicFileListQuery`

The Files API module now stays focused on:

- upload form construction
- list/retrieve/download/delete endpoint calls
- file existence checks
- content-as-string helper
- total storage helper
- batch deletion helper
- preserving `package:llm_dart/providers/anthropic/files.dart` as the
  compatibility export path for file models

## Why This Boundary Is Better

This keeps the provider-specific file models close to Anthropic while reducing
the size and conceptual load of the Files API capability module.

It also keeps the same refactor pattern as the prompt-cache split:

- provider data models stay provider-local
- capability modules own endpoint orchestration
- legacy import paths remain stable during the larger architecture cleanup

## Validation

The refactor was validated with targeted checks:

- `dart analyze lib/src/compatibility/providers/anthropic/files.dart lib/src/compatibility/providers/anthropic/anthropic_file_models.dart test/providers/anthropic/anthropic_file_models_test.dart`
- `dart test test/providers/anthropic/anthropic_file_models_test.dart`
- `dart test test/providers/anthropic`
- `dart run tool/check_workspace_dependency_guards.dart`
- `dart run tool/check_root_package_boundary_guards.dart`
