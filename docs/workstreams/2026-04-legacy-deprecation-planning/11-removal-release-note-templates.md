# Removal Release-Note Templates

## Goal

Provide reusable templates for the eventual breaking-window release notes and
migration notes.

The goal is not to write the final changelog text today.

The goal is to make sure every removal wave is announced with the same level of
clarity.

## General Release-Note Template

Use this template for a breaking-window release section.

```md
## Removed legacy compatibility leaves

This release removes a set of previously deprecated compatibility leaves.

Why:

- the stable replacement paths are now documented
- the removed APIs were leaf ergonomics, not core migration rails
- keeping them longer would extend avoidable API noise

Removed:

- <symbol or group 1>
- <symbol or group 2>
- <symbol or group 3>

Kept:

- <main compatibility trunk that still remains>
- <other explicitly retained migration rails>

Migration summary:

- replace <old symbol> with <new symbol>
- replace <old group> with <new documented direction>
- see <migration note link> for provider-family details
```

## Per-Symbol / Per-Group Migration Template

Use this template when a removal needs its own short migration note.

```md
### `<old symbol or group>`

Status:

- deprecated in <release or date>
- removed in <breaking release or planned window>

Why it was removed:

- <short reason 1>
- <short reason 2>

What to use instead:

- <replacement 1>
- <replacement 2>

Example before:

```dart
<old code>
```

Example after:

```dart
<new code>
```

Notes:

- <provider-owned boundary caveat>
- <partial equivalence caveat if needed>
```

## Template: Preset Helper Alias Removal

```md
### Removed deprecated preset helper aliases

This release removes the previously deprecated preset helper aliases such as
`createGoogleChatProvider(...)`, `createGroqFastProvider(...)`, and similar
family-specific preset constructors.

Use instead:

- `AI.<provider>(...).chatModel(...)` for stable app-facing code
- the non-deprecated root provider constructor when you still need the old
  root-package compatibility surface

Why:

- the preset helpers were thin model/default convenience leaves
- each provider family now has a documented migration note

See:

- `06-deprecated-preset-helper-aliases.md`
```

## Template: Builder Web-Search Helper Removal

```md
### Removed deprecated builder web-search helpers

This release removes the deprecated builder-era shared web-search helpers such
as `enableWebSearch()`, `webSearch(...)`, `newsSearch(...)`, and related
OpenRouter search ergonomics.

Use instead:

- provider-owned search APIs on `AI.<provider>(...).chatModel(...)`
- typed provider options/settings such as
  `OpenAIGenerateTextOptions(...)`,
  `AnthropicGenerateTextOptions(...)`,
  `XAIGenerateTextOptions(...)`, or
  `OpenRouterChatModelSettings(...)`

Why:

- search is provider-owned behavior, not one stable shared root abstraction

See:

- `07-builder-web-search-replacements.md`
```

## Template: `ai()` Deprecation Or Later Removal

```md
### `ai()` remains deprecated

`ai()` is a deprecated alias for the compatibility builder surface.

Use instead:

- `AI.<provider>(...)` for modern app-facing code
- `LLMBuilder()` when you still need the explicit compatibility builder trunk

Why:

- the alias no longer adds independent migration value
- keeping `AI` and `ai()` both prominent makes the public story less clear

See:

- `08-ai-helper-posture.md`
```

If a later release removes the alias entirely:

```md
### Removed deprecated `ai()` alias

This release removes the deprecated `ai()` helper.

Use instead:

- `LLMBuilder()` for compatibility builder flows
- `AI.<provider>(...)` for stable model-centric flows

Why:

- `ai()` was only a thin alias over `LLMBuilder()`
- the repository already migrated first-party code and docs away from it
```

## Template: `createProvider(..., extensions: ...)` Signature Change

```md
### Removed `extensions` from `createProvider(...)`

This release removes the deprecated `extensions` escape hatch from
`createProvider(...)`.

The `createProvider(...)` helper itself remains available for compatibility
code, but provider-specific behavior should no longer be passed through raw
string-key extensions.

Use instead:

- `LLMBuilder()` when you still need explicit compatibility builder flows
- provider-owned typed APIs and options when the provider is known

Why:

- the raw extension bag prolonged string-key coupling
- provider-specific semantics now have documented typed migration paths

See:

- `09-create-provider-posture.md`
```

## Template: Cancellation Alias Removal

```md
### Removed deprecated `CancelToken` alias

This release removes the deprecated `CancelToken` alias.

Use instead:

- `TransportCancellation`

Why:

- the replacement is direct and already documented
- keeping both names adds unnecessary compatibility noise
```

## Minimum Release-Note Quality Bar

Do not remove a public symbol group without release notes that:

- say exactly what was removed
- say exactly what stays
- point to a concrete replacement
- include at least one before/after snippet when the migration is not
  one-to-one
