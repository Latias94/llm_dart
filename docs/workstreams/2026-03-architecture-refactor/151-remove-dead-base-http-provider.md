# 151 Remove Dead BaseHttpProvider

## Why

`BaseHttpProvider` originally existed as a shared root-class for legacy HTTP
providers, but the earlier compatibility refactors changed that reality:

- provider clients now own their request/response behavior directly,
- compatibility HTTP helpers already cover the reusable pieces that still
  matter,
- no in-repo provider implementation still extends `BaseHttpProvider`.

That meant the class had become a dead compatibility shell that still widened
the root legacy surface for no architectural benefit.

## Decision

Remove `BaseHttpProvider` from the root legacy API instead of continuing to
maintain it as a nominal abstraction.

The replacement direction is explicit:

- shared low-level HTTP mechanics belong in `llm_dart_transport`,
- root compatibility-only request/error helpers stay as focused utilities,
- provider clients own provider semantics directly,
- modern package-owned model APIs should not inherit from a root HTTP base
  class.

## What Changed

- Removed the compatibility implementation file
  `lib/src/compatibility/http/base_http_provider.dart`.
- Removed the transitional export chain
  `lib/src/base_http_provider.dart` -> `lib/core/base_http_provider.dart`.
- Removed `core/base_http_provider.dart` from `package:llm_dart/legacy.dart`.

## Architectural Effect

This aligns the repository more closely with the intended post-compatibility
shape:

- no root HTTP inheritance base class,
- reuse through small helpers instead of a monolithic superclass,
- fewer legacy entrypoints that imply a still-supported extension pattern.

For migration, consumers that previously relied on `BaseHttpProvider` should
either:

- compose around provider clients and focused helpers, or
- move onto the modern package-owned model APIs where inheritance from root
  compatibility classes is not part of the design.
