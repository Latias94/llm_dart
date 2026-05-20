# Four-Seam Fearless Refactor

## Goal

Complete four AI SDK-inspired architecture refactors while preserving the Dart library's strengths:

1. Root package dependency topology: make the root package a runtime/convenience surface rather than the architectural owner of concrete providers.
2. Provider-utils / transport seam: move provider-aware helper behavior out of pure transport and into an explicit provider utility seam.
3. OpenAI provider organization: group OpenAI implementation by route/capability so Responses, Chat Completions, files, images, audio, assistants, and tools have local ownership.
4. Typed provider options + provider options bag: keep Dart typed options, but add a namespaced bag seam for cross-runtime/provider option transport and future JSON serialization.

## Principles

- Preserve provider-owned features; do not flatten native APIs into weak shared abstractions.
- Prefer deeper modules: small external interface, concentrated implementation locality.
- Keep provider packages independent of root, chat, Flutter, and runtime orchestration.
- Make every migration slice testable with focused guards/tests before broad workspace validation.

## Validation Gates

- `dart run tool/check_workspace_dependency_guards.dart`
- `dart run tool/check_root_package_boundary_guards.dart`
- focused package `dart analyze .` / `dart test` for touched packages
- `git diff --check`

## Status

Started 2026-05-21 (Asia/Shanghai). This workstream is intentionally breaking; compatibility is kept only when it does not obscure the new seam.
