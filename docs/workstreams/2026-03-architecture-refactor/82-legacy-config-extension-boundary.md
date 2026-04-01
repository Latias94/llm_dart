# Legacy Config Extension Boundary

## Goal

This note records a transitional cleanup of the root-package compatibility
configuration path around `LLMConfig.extensions`.

The goal was not to replace the legacy extension map yet. The goal was to:

- make the current compatibility-only extension keys explicit
- reduce string-key drift across builder, factory, transport, and compatibility
  layers
- document how this differs from the `providerOptions` / `providerMetadata`
  shape in `repo-ref/ai`
- prepare a safer path toward a future namespaced provider-options model

## 1. Current Problem

The root package still uses a flat `LLMConfig.extensions` map for multiple
unrelated concerns:

- provider-specific invocation options
- HTTP and transport runtime options
- compatibility-only migration helpers
- builder convenience flags

That means multiple layers must remember the same raw string keys:

- builder entrypoints
- provider config adapters
- provider factories
- compatibility bridge gating
- HTTP setup helpers

This is structurally weaker than `repo-ref/ai`, where provider-specific data is
carried in provider-scoped `providerOptions` and projected back through
provider-scoped metadata.

## 2. Reference Difference Versus `repo-ref/ai`

The important idea borrowed from the reference is not package count. It is the
boundary:

- shared call settings stay shared
- provider-specific options stay grouped under provider-owned namespaces
- provider metadata comes back through similarly scoped structures

In the current root compatibility API, we cannot switch all callers to that
shape immediately without a larger breaking migration. The legacy extension map
still exists for compatibility.

## 3. Landed Transitional Rule

This cleanup freezes a transitional rule for the compatibility layer:

- the flat extension map remains compatibility-only
- new code should not scatter fresh raw string literals for existing legacy keys
- builder, factory, transport, and compatibility helpers should read from one
  centralized key/accessor layer
- this is a migration aid, not the final stable long-term config design

## 4. Landed Changes

The root package now has an internal centralized legacy config key/accessor
layer:

- `lib/src/config/legacy_config_keys.dart`
- `lib/src/config/legacy_config_extensions.dart`

This layer is now used by high-value compatibility hotspots including:

- builder config entrypoints
- OpenAI and OpenAI-compatible factories
- Google, Anthropic, Ollama, and ElevenLabs config adapters
- HTTP and transport helper code
- compatibility web-search and HTTP-extension gating

It also fixes one concrete drift issue:

- `GoogleLLMBuilder.reasoningEffort(...)` now stores the same string value form
  as the generic builder path instead of storing the enum object directly

## 5. Why This Matters Architecturally

This is a small internal change, but it matters because it narrows one of the
root package's most persistent maintenance hazards:

- builder and reader logic are less likely to silently diverge
- compatibility gating can share the same vocabulary as request-shaping helpers
- HTTP runtime options are easier to recognize as infrastructure options rather
  than provider options
- the next migration step toward namespaced provider options becomes easier to
  plan and test

## 6. What This Does Not Solve Yet

This transitional layer does not yet solve the deeper design issue:

- `LLMConfig.extensions` is still flat
- provider options are still not grouped by provider namespace
- some compatibility-era overlap still exists between shared fields and
  extension keys

Examples that still show the legacy shape:

- Google still has compatibility-only extension-backed settings that would be
  cleaner as typed provider options
- HTTP runtime settings still live beside provider invocation flags in the same
  map
- some older builder helpers still reflect compatibility-era ergonomics instead
  of the narrower provider-owned APIs in the new packages

## 7. Recommended Next Step

After this transitional cleanup, the next higher-value step is not adding more
string helpers. It is deciding the migration boundary for:

- namespaced legacy provider options inside `LLMConfig.extensions`, or
- direct migration pressure toward package-owned typed settings without growing
  the root compatibility map further

That decision should be made provider-family by provider-family, starting with
the OpenAI-family compatibility surface because it currently has the highest
volume of flat extension usage.
