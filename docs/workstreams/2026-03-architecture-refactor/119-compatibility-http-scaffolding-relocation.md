# 119. Compatibility HTTP Scaffolding Relocation

## What Changed

The remaining root HTTP helper implementations that still exist mainly for the
legacy compatibility layer are now implemented under:

- `lib/src/compatibility/http/base_http_provider.dart`
- `lib/src/compatibility/http/dio_error_handler.dart`
- `lib/src/compatibility/http/http_config_utils.dart`
- `lib/src/compatibility/http/http_response_handler.dart`

The legacy HTTP config-shaping step has since been narrowed further into:

- `lib/src/config/legacy_http_client_config_adapter.dart`

The old paths remain as compatibility re-exports:

- `lib/src/base_http_provider.dart`
- `lib/src/dio_error_handler.dart`
- `lib/utils/http_config_utils.dart`
- `lib/utils/http_response_handler.dart`

## Why This Matters

The root package still directly depends on `dio` and `logging`, but after the
recent provider-shell relocation the remaining dependency pressure is more
honestly concentrated in a legacy HTTP scaffolding layer.

Before this relocation, those helpers still looked more general-purpose than
they really are:

- `BaseHttpProvider` still served legacy root provider implementations
- `DioErrorHandler` still mapped Dio failures into root `LLMError` types
- `HttpConfigUtils` still looked responsible for legacy `LLMConfig` HTTP
  extension shaping
- `HttpResponseHandler` still wrapped transport decoding with root error
  mapping

Placing them under `src/compatibility/http/` makes their role explicit.

## Architectural Effect

This step does not remove the root `dio` or `logging` dependencies yet.

Later follow-up slices also completed those direct dependency exits, but the
important architectural point of this note still stands: the remaining HTTP
scaffolding is compatibility-owned rather than long-term shared-center code.

It does narrow the ownership story:

- transport still owns reusable Dio setup primitives and request helpers
- provider packages still own modern request/response codecs
- root HTTP helpers are now visibly compatibility-owned instead of looking like
  neutral shared infrastructure

That mirrors the structural lesson we want from `repo-ref/ai`:

- keep compatibility scaffolding recognizable as scaffolding
- do not let migration-era plumbing keep masquerading as the long-term center
  of the architecture

## What This Does Not Claim

This relocation does not mean the root package is ready to drop `dio` and
`logging`.

Those runtime dependencies still remain because:

- legacy provider clients still live in the root package
- compatibility config extensions still expose Dio-oriented overrides
- root cancellation helpers still understand raw Dio cancellation exceptions
- several public compatibility tests still exercise the legacy HTTP wrappers

That follow-up narrowing now also includes:

- `LLMConfig -> DioHttpClientConfig` shaping living in the config layer instead
  of inside `HttpConfigUtils`
- compat transport creation no longer routing through
  `BaseHttpProvider.createConfiguredDio(...)`

## Next Honest Question

After this move, the next dependency-cleanup question is narrower:

- which remaining root provider clients should keep using compatibility HTTP
  scaffolding
- and which ones should instead shrink toward package-owned modern providers or
  thinner compatibility routes

That is a healthier next step than trying to remove root `dio` and `logging`
cosmetically before the remaining host role is actually gone.
