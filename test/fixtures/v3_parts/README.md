# Canonical v3 Parts Goldens (`.jsonl`)

This directory stores **golden fixtures** for our canonical, AI SDK v3-aligned
stream part representation.

Goal:

- Compare **post-parse canonical parts** (not raw SSE/HTTP chunks).
- Keep tests stable across refactors by asserting on a small, deterministic JSON
  shape per part.

Related docs:

- `docs/ai_sdk_v3_refactor_purpose.md` (Appendix B: Fixture Alignment Contract)
- `docs/ai_sdk_v3_refactor_todo.md` (Golden fixtures conventions)

Upstream reference:

- Vercel AI SDK repository: `https://github.com/vercel/ai` (Apache-2.0)

---

## Layout

Recommended layout:

- `test/fixtures/v3_parts/<provider>/<scenario>.jsonl`
- `test/fixtures/v3_parts/<provider>/<scenario>.meta.json` (optional)

Where:

- `<provider>` matches the provider family or protocol reuse layer, e.g.:
  - `openai`
  - `anthropic`
  - `openai_compatible`
  - `azure`
  - `xai`
- `<scenario>` is a short, stable name that describes the fixture behavior:
  - `tool-input-split-boundaries`
  - `usage-late-after-finish-reason`
  - `sources-and-citations`

---

## Format

### `.jsonl`

One JSON object per line:

- each line is a single canonical stream part
- keys should be stable (omit null/empty fields)
- timestamps should be omitted unless explicitly asserted by the scenario
- very large base64-like blobs are redacted (stored as `{"$redacted":"base64","len":...,"hash":"fnv1a64:..."}`) to keep repo size manageable

### `.meta.json` (optional)

Use `../_template.meta.json` as a starting point.
