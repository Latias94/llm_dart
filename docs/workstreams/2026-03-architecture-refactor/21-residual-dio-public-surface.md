# Residual Dio Public Surface

## Goal

This document freezes the remaining public `dio` exposure after the transport-first cancellation cleanup.

The immediate question is no longer whether `CancelToken` should stay public. That part is already resolved.

The practical question now is:

> Which `dio`-typed APIs still remain in the root public surface, and how should they leave without breaking the transport boundary again?

## 1. Current State After The Cancellation Cleanup

The current breaking round already removed the largest public leak:

- public cancellation now uses `TransportCancellation`
- `core/cancellation.dart` no longer re-exports `dio.CancelToken`
- root/core error handling no longer depends on `dio` types as its public contract

This means the old `CancelToken` leak is no longer the main blocker.

## 2. The Former Remaining Explicit Public Leak

Before this cleanup slice, the main remaining root-level public `dio` surface was:

- `HttpConfig.dioClient(Dio dio)`

Why it still matters:

- it is part of the builder API
- it requires importing `package:dio/dio.dart`
- it keeps the stable facade aware of one transport implementation

This is different from provider implementation code that happens to use `FormData`, `MultipartFile`, or `ResponseBody` internally.

Those provider internals are implementation details.

`HttpConfig.dioClient(Dio dio)` was a user-facing API.

That builder shortcut has now been removed from the stable root API.

The transport-first replacement path is:

- `HttpConfig.transportClient(TransportClient client)`

## 3. Why This Should Not Survive The Stable API

Keeping a public root builder method that takes `Dio` conflicts with the dependency policy already frozen for this workstream:

- the stable facade should depend on transport abstractions, not transport implementations
- `llm_dart_core` and the root stable API should not force users onto `dio`
- future transport changes should not require redesigning the root builder surface

It also creates design confusion:

- the preferred path is now `transportClient(TransportClient)`
- but the old builder still advertises a transport-specific shortcut

That mixed message makes the migration less credible.

## 4. Recommended Boundary

The recommended stable boundary is:

- root builder accepts `TransportClient`
- transport implementation details stay in `llm_dart_transport`
- callers that want a `Dio`-backed transport can opt into it explicitly through `DioTransportClient`

That means the transport-specific knowledge belongs here:

- `dio`
- `DioTransportClient`

It should not be re-promoted into the root facade just for convenience.

## 5. Recommended Exit Path

### Stable Path

Keep and promote:

- `HttpConfig.transportClient(TransportClient client)`

Recommended user shape:

```dart
final dio = Dio();

final provider = await ai()
    .openai()
    .apiKey(apiKey)
    .model('gpt-4.1')
    .http(
      (http) => http.transportClient(
        DioTransportClient(dio: dio),
      ),
    )
    .build();
```

### Compatibility Path

The old raw-Dio builder shortcut should now be treated as removed from the stable API.

If a temporary compatibility shim is ever reintroduced, it should live behind a clearly compatibility-oriented surface rather than returning to the main builder contract.

## 6. What Should Not Be Done

Do not respond to this remaining leak by adding more root helpers such as:

- `multipartClient(...)`
- `customDioAdapter(...)`
- public root methods that expose `DioException`, `FormData`, or `MultipartFile`

That would only recreate the same layering problem under different names.

## 7. Delivery Order

Recommended order:

1. keep `transportClient(TransportClient)` as the only promoted path
2. stop using `dioClient(Dio)` in new docs and examples
3. keep any raw-Dio migration help outside the stable builder API
4. only then close the remaining `dio` public-surface cleanup item

## 8. Review Rule

When a new root or core API proposes to accept a transport-implementation type, ask:

> Is this required by the stable architecture, or is it only a convenience shortcut for one concrete transport implementation?

If it is only a convenience shortcut for one transport implementation, it should not enter the stable root API.
