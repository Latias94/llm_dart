# 144. Root Registry Logging Decoupling

## Question

Can the root provider-registry and root bootstrap path keep lightweight failure
diagnostics without depending directly on `package:logging`?

## What Was Reviewed

- `lib/core/registry.dart`
- `lib/src/bootstrap/root_registry_bootstrap.dart`
- `test/core/registry_test.dart`

## Change

Yes.

The root registry and bootstrap path now use Dart SDK `dart:developer` logging
for their lightweight diagnostic messages instead of `package:logging`.

This covers:

- lazy built-in provider registration failures in `LLMProviderRegistry`
- root bootstrap factory creation failures
- root bootstrap skip/registration status notes

## Why This Matters

This is another small but worthwhile root dependency-slimming slice:

- the registry/bootstrap path is root orchestration logic, not provider runtime
  transport logic
- it did not need the richer `package:logging` dependency surface
- SDK logging is enough for low-frequency diagnostic messages here

## Boundary

This does **not** remove the root package's direct `logging` runtime dependency
yet.

Many root-hosted compatibility/provider clients still import `package:logging`
directly.

This slice only removes that dependency from:

- `lib/core/registry.dart`
- `lib/src/bootstrap/root_registry_bootstrap.dart`

## Result

The root package now has two fewer direct `package:logging` imports, while
provider registration behavior stays unchanged:

- registration errors remain non-fatal
- bootstrap still attempts to register all built-in providers
- the registry still lazily initializes on first use
