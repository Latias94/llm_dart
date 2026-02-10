# Test Fixtures

This directory contains offline fixtures used by `dart test`.

## Upstream sources

Some fixtures are synced from the Vercel AI SDK repository:

- Repo: `https://github.com/vercel/ai`
- License: Apache-2.0 (`repo-ref/ai/LICENSE`)

We vendor the upstream repo under `repo-ref/ai` and sync selected fixture files
into `test/fixtures` for offline replays and conformance tests.

See:

- `tool/sync_vercel_fixtures.dart` (sync tool)
- `melos run fixtures:check` (CI integrity check)

