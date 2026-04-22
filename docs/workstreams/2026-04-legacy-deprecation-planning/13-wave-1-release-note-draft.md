# Wave-1 Release Note Draft

## Goal

Turn the already-landed wave-1 removal slice on
`refactor/architecture-foundation` into concrete release-note and changelog
text.

This document is no longer a template.

It is the source draft behind the actual `CHANGELOG.md`
`0.11.0-alpha.1` entry.

The main work left for later preview/stable follow-ups is no longer to invent
release text from scratch. It is only to adapt this text to the next explicit
alpha/beta/RC/stable heading when the release vehicle changes.

## Scope

This draft covers the branch-landed wave-1 leaf removals:

- deprecated preset helper aliases
- deprecated builder web-search helpers
- the `createProvider(..., extensions: ...)` signature removal
- the deprecated `CancelToken` alias removal

It also records what intentionally stays:

- `legacy.dart`
- `LLMBuilder()`
- `createProvider(...)`
- non-deprecated root provider constructors
- the already-soft-deprecated `ai()` alias

## Suggested Changelog Section

Use this as the starting point for the next deliberate breaking release.

```md
## [next-breaking-release] - TBD

### Removed

- Removed the previously deprecated preset helper aliases across the
  OpenAI-family, Google, Anthropic, Groq, DeepSeek, Ollama, xAI, Phind, and
  ElevenLabs compatibility families. Use `AI.<provider>(...).<model/api>(...)`
  for modern app-facing code, or the non-deprecated root provider constructor
  when you still need the compatibility root surface.
- Removed the deprecated builder web-search helpers and the deprecated
  OpenRouter builder search ergonomics. Use provider-owned search tools,
  typed provider options, and provider-owned model settings on
  `AI.<provider>(...).chatModel(...)` instead.
- Removed the deprecated `extensions` escape hatch from
  `createProvider(...)`. The `createProvider(...)` helper itself remains
  available for compatibility code, but provider-specific behavior should now
  move to typed provider APIs/options or explicit provider/builder surfaces.
- Removed the deprecated `CancelToken` alias. Use
  `TransportCancellation` instead.

### Deprecated

- `ai()` remains deprecated. Use `AI.<provider>(...)` for modern code or
  `LLMBuilder()` for explicit compatibility builder flows.

### Migration summary

- Replace preset helper aliases such as `createGoogleChatProvider(...)` with
  `AI.google(...).chatModel(...)` for modern code, or `createGoogleProvider(...)`
  when you still need the root compatibility provider surface.
- Replace shared builder web-search helpers with provider-owned search APIs,
  for example `OpenAIGenerateTextOptions(...)`,
  `AnthropicGenerateTextOptions(...)`,
  `XAIGenerateTextOptions(...)`, or
  `OpenRouterChatModelSettings(...)`.
- Replace `createProvider(..., extensions: ...)` by branching earlier into the
  known provider API, or by staying on `LLMBuilder()` / `createProvider(...)`
  without raw extension bags.
- Replace `CancelToken` with `TransportCancellation`.

### Kept

- `legacy.dart` remains the explicit compatibility import.
- `LLMBuilder()` remains the compatibility builder trunk.
- `createProvider(...)` remains the frozen generic compatibility helper.
- Non-deprecated root provider constructors such as `createOpenAIProvider(...)`
  and `createGoogleProvider(...)` remain available.
```

## Per-Group Migration Notes

These are the shorter migration notes that can be copied into release notes,
migration guides, or pull-request summaries.

### 1. Removed Deprecated Preset Helper Aliases

Status:

- deprecated before this breaking window
- removed in the wave-1 breaking slice now present on this branch

Why removed:

- they were leaf preset conveniences, not compatibility trunks
- each provider family already has a documented migration direction
- docs and examples no longer need them as the default copy-paste path

Use instead:

- `AI.<provider>(...).<model/api>(...)` for modern app-facing code
- the non-deprecated root provider constructor when you still need the old
  compatibility provider surface

Example before:

```dart
final provider = createGoogleChatProvider(
  apiKey: apiKey,
);
```

Example after:

```dart
final model = AI.google(apiKey: apiKey).chatModel('gemini-2.5-flash');
```

Compatibility fallback:

```dart
final provider = createGoogleProvider(
  apiKey: apiKey,
  model: 'gemini-2.5-flash',
);
```

See:

- `06-deprecated-preset-helper-aliases.md`

### 2. Removed Deprecated Builder Web-Search Helpers

Status:

- deprecated before this breaking window
- removed in the wave-1 breaking slice now present on this branch

Why removed:

- search semantics are provider-owned, not one stable shared builder toggle
- the old helper bag mixed incompatible concepts such as sources, time windows,
  location, and result limits
- the repository already has stable provider-owned replacements

Use instead:

- provider-native search tools or typed provider options on
  `AI.<provider>(...).chatModel(...)`

Example before:

```dart
final provider = await LLMBuilder()
    .openai((openai) => openai.webSearch())
    .apiKey(apiKey)
    .model('gpt-5-mini')
    .build();
```

Example after:

```dart
final model = AI.openai(apiKey: apiKey).chatModel('gpt-5-mini');

final result = await generateTextCall(
  model: model,
  prompt: [
    UserPromptMessage.text('Search for recent Dart SDK release notes.'),
  ],
  callOptions: const CallOptions(
    providerOptions: OpenAIGenerateTextOptions(
      builtInTools: [OpenAIWebSearchTool()],
    ),
  ),
);
```

Notes:

- OpenRouter keeps only the narrower compatibility `onlineSearch()` helper
  because it still maps cleanly to the retained online-intent bridge
- deprecated OpenRouter builder helpers such as `searchPrompt(...)`,
  `maxSearchResults(...)`, and `forNewsAndEvents()` should migrate to normal
  prompt shaping plus provider-owned stable settings

See:

- `07-builder-web-search-replacements.md`

### 3. Removed `extensions` From `createProvider(...)`

Status:

- the raw `extensions` bag was deprecated before this breaking window
- the parameter is now removed on this branch
- `createProvider(...)` itself remains available

Why removed:

- the raw extension bag preserved string-key provider coupling
- typed provider-owned APIs now exist for the main provider-specific behaviors
- the function itself still has compatibility value, but the raw escape hatch
  does not

Use instead:

- branch earlier into a known provider API when provider-specific behavior is
  needed
- keep using `createProvider(...)` only for generic compatibility creation
- keep using `LLMBuilder()` when you still need the explicit builder
  compatibility surface

Example before:

```dart
final provider = createProvider(
  providerId: 'openai',
  apiKey: apiKey,
  model: 'gpt-4.1-mini',
  extensions: {
    'parallelToolCalls': true,
  },
);
```

Example after:

```dart
final model = AI.openai(apiKey: apiKey).chatModel('gpt-4.1-mini');

final result = await generateTextCall(
  model: model,
  prompt: [
    UserPromptMessage.text('Summarize the latest tool results.'),
  ],
  callOptions: const CallOptions(
    providerOptions: OpenAIGenerateTextOptions(
      parallelToolCalls: true,
    ),
  ),
);
```

Compatibility-oriented fallback:

```dart
final provider = await LLMBuilder()
    .provider('openai')
    .apiKey(apiKey)
    .model('gpt-4.1-mini')
    .build();
```

Notes:

- do not replace one raw extension bag with another untyped map
- if the provider is runtime-selected but provider-specific extras still
  matter, branch into the provider-owned API earlier instead of trying to keep
  the generic helper fully dynamic

See:

- `09-create-provider-posture.md`

### 4. Removed Deprecated `CancelToken` Alias

Status:

- deprecated before this breaking window
- removed in the wave-1 breaking slice now present on this branch

Why removed:

- the transport-owned replacement is direct and already documented
- keeping both names adds low-value compatibility noise

Use instead:

- `TransportCancellation`

Example before:

```dart
final cancelToken = CancelToken();
```

Example after:

```dart
final cancelToken = TransportCancellation();
```

## Explicit Non-Removals For The Same Release

To keep the breaking window conservative, the release notes should also say
what did **not** get removed:

- `legacy.dart` still remains the explicit compatibility host
- `LLMBuilder()` still remains the real builder migration trunk
- `createProvider(...)` still remains available without `extensions`
- non-deprecated root provider constructors still remain
- `ai()` remains deprecated, but is not removed in wave 1

## Bottom Line

The wave-1 branch slice is now documented strongly enough to ship as a
deliberate breaking release without inventing changelog text at the last
minute.

The next decision is no longer "what should wave 1 say?"

The next decision is only:

- ship this already-prepared leaf-removal wave
- or deliberately defer it to a later breaking window
