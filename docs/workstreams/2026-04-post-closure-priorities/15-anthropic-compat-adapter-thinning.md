# Anthropic Compatibility Adapter Thinning

## Why This Cut Was Worth Doing

`lib/src/compatibility/providers/anthropic_compat_adapter.dart` had become a
real mixed host.

It was doing two separate jobs at once:

- adapter-level delegation into `LegacyChatCapabilityAdapter`
- Anthropic-specific request planning and role-aware prompt conversion

That second responsibility is not generic shared logic. It is still
provider-local compatibility behavior:

- promoting message-owned tools into bridged requests
- merging legacy cache policy into Anthropic provider options
- converting Anthropic-native content blocks into role-aware prompt messages
- replaying provider-native tool result blocks with stable tool names

This made the adapter larger than it needed to be. The cleaner boundary is:

- the adapter owns bridge delegation into the shared legacy adapter
- provider-local support owns Anthropic-specific planning and prompt shaping

## What Changed

Added:

- `lib/src/compatibility/providers/anthropic_compat_support.dart`

Kept as the adapter shell:

- `lib/src/compatibility/providers/anthropic_compat_adapter.dart`

The new support file now owns:

- request planning for message-owned tools
- Anthropic cache-policy merge rules
- provider-options validation
- role-aware prompt conversion for Anthropic content blocks
- tool replay naming and custom replay payload shaping

The adapter now stays focused on:

- composing the request plan with `LegacyChatCapabilityAdapter.buildRequest`
- delegating message conversion through the provider-local support

## Why This Boundary Is Better

This keeps `AnthropicLegacyChatCapabilityAdapter` small and honest.

It now reads like a bridge adapter instead of a combined adapter-plus-codec
module, while still keeping Anthropic-specific compatibility policy in one
provider-owned place.

This also keeps us aligned with the refactor rules for this phase:

- no new shared-core abstraction
- no symmetry-driven split of `anthropic/request_builder.dart`
- no public compatibility import change
- only a real ownership split around Anthropic-specific compatibility policy

## Validation

The refactor was validated with targeted checks:

- `dart analyze lib/src/compatibility/providers/anthropic_compat_adapter.dart lib/src/compatibility/providers/anthropic_compat_support.dart test/providers/anthropic/anthropic_compat_support_test.dart`
- `dart test test/providers/anthropic/anthropic_compat_support_test.dart`
- `dart test test/legacy_compatibility_test.dart`
- `dart run tool/check_workspace_dependency_guards.dart`
- `dart run tool/check_root_package_boundary_guards.dart`
