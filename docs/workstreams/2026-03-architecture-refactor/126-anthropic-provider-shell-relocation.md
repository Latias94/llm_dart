# 126. Anthropic Provider Shell Relocation

## What Changed

The root Anthropic provider implementation moved under explicit compatibility
ownership:

- new implementation home:
  `lib/src/compatibility/providers/anthropic/provider_compat.dart`
- public entrypoint reduced to a compatibility re-export:
  `lib/providers/anthropic/provider.dart`

The internal Anthropic compatibility builder was also updated to depend on the
new compatibility-owned implementation path directly instead of importing the
public provider entrypoint.

## Why This Matters

The previous structure still made the root Anthropic provider entrypoint look
like the main implementation home for Anthropic.

That was now misleading because:

- `llm_dart_anthropic` already owns the modern shared-capability chat mainline
  plus provider-owned native-tool and execution-result helpers
- the root Anthropic provider is now better understood as a migration-era shell
  that still hosts residual legacy capabilities such as file management, model
  listing, token counting, and compatibility-facing convenience helpers
- the root package should keep shrinking toward an explicit compatibility host
  instead of continuing to look like the long-term Anthropic implementation
  center

This move does not finish the Anthropic migration. It makes the remaining work
more honest by putting the current root shell under the layer that actually
owns it.

## Boundary Effect

After this move:

- callers can still import `package:llm_dart/providers/anthropic/provider.dart`
  without source breakage
- the real implementation ownership is visibly under `src/compatibility`
- internal compatibility code no longer depends on the public provider path for
  the base Anthropic shell class

## What Did Not Change

This step intentionally does not:

- move `client.dart`, `chat.dart`, `files.dart`, `models.dart`, or
  `dio_strategy.dart` yet
- migrate root-hosted residual Anthropic APIs into `llm_dart_anthropic`
- change compatibility routing or bridge gating behavior
- widen the shared capability, event, or result model

Those remain later slices.

## Why Anthropic Was The Right Next Target

Compared with the remaining root-hosted provider families:

- Anthropic already has a meaningful package-owned modern home
- the remaining root-hosted shell is still easy to identify as transitional
- shell relocation is a low-risk first cut that clarifies ownership before any
  deeper module migration or residual-API classification work

That makes Anthropic the cleanest next thinning target after the Google slice.
