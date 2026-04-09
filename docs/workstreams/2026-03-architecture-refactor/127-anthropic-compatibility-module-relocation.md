# 127. Anthropic Compatibility Module Relocation

## What Changed

The remaining root-hosted Anthropic legacy implementation modules moved under
explicit compatibility ownership:

- `lib/src/compatibility/providers/anthropic/chat.dart`
- `lib/src/compatibility/providers/anthropic/client.dart`
- `lib/src/compatibility/providers/anthropic/dio_strategy.dart`
- `lib/src/compatibility/providers/anthropic/files.dart`
- `lib/src/compatibility/providers/anthropic/models.dart`
- `lib/src/compatibility/providers/anthropic/request_builder.dart`

The old public paths under `lib/providers/anthropic/` now act as compatibility
re-exports.

## Why This Matters

The Anthropic shell relocation made the root provider entrypoint
compatibility-owned, but the real implementation weight was still visibly
spread across the public provider directory.

That left the same mixed message Google had before its second thinning slice:

- the public provider shell looked compatibility-oriented
- but the legacy HTTP client, request builder, and capability modules still
  looked like first-class implementation homes

Moving those modules under `src/compatibility` makes the architecture more
honest:

- the root package is still a real Anthropic legacy host for now
- but that host role is explicitly a compatibility concern
- the package-owned modern mainline remains `llm_dart_anthropic`

## Boundary Effect

After this move:

- old imports continue to work through re-exports
- internal compatibility code can depend on compatibility-owned Anthropic
  modules directly
- the remaining root-hosted Anthropic surface is easier to inventory and
  classify into compatibility-only residual APIs versus real provider-owned
  modern gaps

## What This Move Does Not Solve

This relocation still does not:

- migrate model listing, token counting, or file-management convenience helpers
  into `llm_dart_anthropic`
- decide whether any of those helper APIs deserve provider-owned modern
  replacements
- move `config.dart` or `mcp_models.dart`, which still carry public
  compatibility-facing data-model responsibilities
- remove root `dio` or compatibility-era HTTP/error pressure entirely

Those remain separate follow-up decisions.

## Practical Result

Anthropic now matches the same structural direction already applied to Google
and the community-provider shells:

- public root paths stay stable as migration-era compatibility shells
- real legacy implementation ownership moves under `src/compatibility`
- deeper provider thinning can continue later without pretending the public
  provider directory is still the long-term implementation home
