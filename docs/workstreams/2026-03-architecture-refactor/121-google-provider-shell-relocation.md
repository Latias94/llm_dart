# 121. Google Provider Shell Relocation

## What Changed

The root Google provider implementation moved under explicit compatibility
ownership:

- new implementation home:
  `lib/src/compatibility/providers/google/provider_compat.dart`
- public entrypoint reduced to a compatibility re-export:
  `lib/providers/google/provider.dart`

The internal Google compatibility builder was also updated to depend on the new
compatibility-owned implementation path directly instead of importing the public
provider entrypoint.

## Why This Matters

The previous structure still made the root public provider entrypoint look like
the primary implementation home for Google.

That was misleading because:

- `llm_dart_google` already owns the modern shared-capability mainlines for
  chat, embeddings, image generation, and speech
- the root Google provider is now better understood as a migration-era shell
  that still hosts residual legacy capability modules and fallback behavior
- the root package should keep shrinking toward an explicit compatibility host,
  not remain the visually dominant implementation home for duplicated provider
  capability families

This relocation does not solve the whole Google migration story by itself, but
it makes the remaining work more honest and easier to reason about.

## Boundary Effect

After this move:

- callers can still import `package:llm_dart/providers/google/provider.dart`
  without source breakage
- the real implementation ownership is visibly under `src/compatibility`
- internal compatibility code no longer depends on the public provider path for
  the base Google shell class

## What Did Not Change

This step intentionally does not:

- remove the root Google client
- remove root `dio` or `logging` pressure
- migrate the remaining residual Google capability modules into
  `llm_dart_google`
- widen the shared event or result model

Those are later slices.

## Why Google Was The Right Next Target

Compared with the other remaining root-hosted families:

- Google already has a strong package-owned modern home in `llm_dart_google`
- the duplicated capability families are easy to identify
- the public shell relocation is low risk and reinforces the target ownership
  model before deeper thinning

This makes Google a better next slice than a premature broad OpenAI relocation.
