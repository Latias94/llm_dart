# Third-Party Notice (Test Fixtures)

This repository includes test fixtures copied/synced from the Vercel AI SDK
project.

- Upstream repository: `https://github.com/vercel/ai`
- Upstream license: Apache License 2.0 (see `repo-ref/ai/LICENSE`)
- Vendored snapshot commit (in this repo):
  - Run: `git -C repo-ref/ai rev-parse HEAD`
  - At time of writing: `c36a873ce00892a4c587c2e9492220b392aefd09`

These files are used for offline fixture replay and conformance testing. They
are not part of the `llm_dart` public API.
