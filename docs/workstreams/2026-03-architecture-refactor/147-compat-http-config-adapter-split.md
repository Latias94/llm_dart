# 147. Compat HTTP Config Adapter Split

## Goal

Reduce the remaining coupling inside the root compatibility HTTP layer by
separating legacy config shaping from HTTP helper wrappers.

## Problem

Before this slice:

- `HttpConfigUtils` both wrapped transport-owned Dio factory calls and shaped
  legacy `LLMConfig` HTTP extensions into `DioHttpClientConfig`
- `createCompatTransport(...)` still routed default Dio creation through
  `BaseHttpProvider.createConfiguredDio(...)`
- `BaseHttpProvider` therefore still looked like a central HTTP utility even
  though it no longer had any internal subclasses

That made the compatibility HTTP layer look more cohesive than it really was.

In practice there were two separate concerns:

1. legacy config adaptation
2. compatibility HTTP helper wrappers

## Decision

Split legacy HTTP config shaping into the config layer and make compat
transport creation depend on `HttpConfigUtils` directly instead of routing
through `BaseHttpProvider`.

## What Changed

### New config-layer adapter

- added `lib/src/config/legacy_http_client_config_adapter.dart`

This file now owns the mapping from:

- legacy `LLMConfig` + legacy extension accessors

to:

- transport-owned `DioHttpClientConfig`

### `HttpConfigUtils`

`lib/src/compatibility/http/http_config_utils.dart` now:

- delegates shaping to `createLegacyHttpClientConfig(...)`
- stays focused on compatibility wrapper behavior around
  `DioHttpClientFactory`
- no longer owns the legacy extension-to-transport config mapping itself

### `compat_transport`

`lib/src/compatibility/compat_transport.dart` now:

- creates the fallback Dio-backed transport through `HttpConfigUtils`
- no longer imports `BaseHttpProvider`
- no longer treats the base provider abstraction as a generic transport helper

### `BaseHttpProvider`

`lib/src/compatibility/http/base_http_provider.dart` now:

- keeps only the compatibility request/stream helper behavior
- no longer owns a static configured-Dio helper
- no longer depends on root config-shaping concerns

## Why This Boundary Is Better

This split makes the compatibility architecture more honest:

- config shaping lives in the config layer
- transport factory wrapping lives in the compatibility HTTP helper layer
- transport creation no longer depends on an abstract provider base class

That is closer to the structure we want from the long-term architecture:

- lower-level config translation is not hidden inside an unrelated helper
- abstract provider bases do not become accidental service locators
- migration-era scaffolding is easier to shrink one piece at a time

## What This Does Not Claim

This does not mean the whole compatibility HTTP layer is ready to disappear.

`HttpResponseHandler`, `DioErrorHandler`, and the remaining compatibility
clients still exist because the root package still hosts compatibility behavior
and root-owned `LLMError` mapping.

This slice only narrows one coupling seam inside that remaining layer.

## Validation

Validated with:

- `dart analyze`
- `dart analyze packages/llm_dart_transport`
- `dart test test/compat_transport_test.dart test/utils/http_config_utils_test.dart test/utils/dio/dio_advanced_features_test.dart test/utils/dio/dio_logging_test.dart test/utils/timeout_priority_test.dart`
