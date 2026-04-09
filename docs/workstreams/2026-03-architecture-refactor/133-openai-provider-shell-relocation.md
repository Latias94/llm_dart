# 133. OpenAI Provider Shell Relocation

## What Changed

The root OpenAI provider implementation moved under explicit compatibility
ownership:

- new implementation home:
  `lib/src/compatibility/providers/openai/provider_compat.dart`
- public entrypoint reduced to a compatibility re-export:
  `lib/providers/openai/provider.dart`

The internal OpenAI-family compatibility builder was also updated to depend on
the new compatibility-owned implementation path directly instead of importing
the public provider entrypoint.

## Why This Matters

The previous structure still made `lib/providers/openai/provider.dart` look
like the real implementation home for OpenAI.

That was now misleading because:

- `llm_dart_openai` already owns the main modern OpenAI shared-capability
  surfaces for text generation, embeddings, images, speech, transcription, and
  typed provider-owned extras
- the remaining root OpenAI provider is better understood as a migration-era
  compatibility shell above residual legacy capability modules and helper APIs
- the residual OpenAI audit already showed that most of the remaining root
  surface is compatibility-only, not unfinished provider-package migration work

Moving the shell does not finish OpenAI thinning by itself, but it makes the
current ownership honest and easier to continue from.

## Boundary Effect

After this move:

- callers can still import `package:llm_dart/providers/openai/provider.dart`
  without source breakage
- the real implementation ownership is visibly under `src/compatibility`
- internal compatibility code no longer depends on the public provider path for
  the base OpenAI shell class

This matches the pattern already used for the Google and Anthropic root shells.

## What Did Not Change

This slice intentionally does not:

- move OpenAI legacy capability modules such as files, moderation, assistants,
  completions, or model listing into `llm_dart_openai`
- remove the root OpenAI client or legacy config types
- change OpenAI-family compatibility routing or bridge gating behavior
- widen the shared capability, event, or result model

Those remain separate follow-up slices.

## Why This Was The Right Next OpenAI Cut

After the provider-owned image edit helper landed, the next highest-leverage
OpenAI move was not another endpoint migration.

It was ownership cleanup:

- the modern package boundary is already mostly in place
- the residual root surface already has a classification
- shell relocation is low risk and makes later residual thinning less
  ambiguous

That makes shell relocation a better next step than continuing to add more
provider-owned helpers without first making the compatibility host explicit.
