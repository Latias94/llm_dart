# Boundaries And Migration Guide

## Frozen Decisions

### Provider Method Names

`LanguageModel` is now an implementation-facing provider contract:

- `doGenerate(GenerateTextRequest request)` performs one provider generation
  call.
- `doStream(GenerateTextRequest request)` performs one provider stream call.
- User-facing helpers such as `generateText`, `streamText`, `streamTextRun`,
  object generation, tool loops, stop policy, result facades, and UI projection
  stay in `llm_dart_ai`.

The `do*` prefix is intentional. It makes a direct provider call read like an
implementation hook, not like the public orchestration API.

### Provider Options

Input-side provider customization belongs in typed provider options:

- model construction settings implement `ProviderModelOptions`
- per-invocation settings implement `ProviderInvocationOptions`
- `CallOptions.providerOptions` carries provider-native request options
- durable cross-provider knobs stay in `GenerateTextOptions`

Examples:

- OpenAI Responses `metadata`, `previousResponseId`, `builtInTools`, and
  `promptCacheKey` belong in `OpenAIGenerateTextOptions`
- Anthropic `metadata`, `container`, MCP servers, and thinking details belong
  in `AnthropicGenerateTextOptions`
- Google safety settings, response modalities, thinking settings, and native
  tools belong in `GoogleGenerateTextOptions`
- Ollama `raw`, `keepAlive`, `numCtx`, and provider binary resolution belong in
  `OllamaGenerateTextOptions`

Raw escape hatches are allowed only inside provider-owned typed option classes,
where the provider namespace and wire contract are clear.

### Provider Metadata

`ProviderMetadata` is output-side by default:

- provider raw response details
- response observations that are not shared fields
- stream metadata patches
- replay hints such as provider-generated tool call IDs or thought signatures
- provider continuation data that came from a previous model response

It must not be used as a request configuration bag. If a value changes what the
provider should send, sample, store, cache, search, think, or execute, it
belongs in `GenerateTextOptions`, `CallOptions`, or typed provider options.

Replay is the deliberate exception: prompt/content/tool parts may carry
provider metadata when that metadata was produced by an earlier provider result
and is required to faithfully continue a conversation.

### Shared Ownership

- `CallOptions.headers`, `timeout`, `maxRetries`, and `cancellation` are
  transport/invocation controls, not provider metadata.
- `GenerateTextOptions.responseFormat` owns shared structured-output intent.
  Provider-specific response-format extensions stay in typed provider options.
- Provider result fields such as `responseId`, `responseTimestamp`,
  `responseModelId`, `finishReason`, usage, and warnings stay as shared result
  fields when they are durable across providers.

## Direct Provider Call Migration

Old direct provider call:

```dart
final request = GenerateTextRequest(
  prompt: [
    UserPromptMessage.text('Write a haiku.'),
  ],
);

final result = await model.generate(request);
```

Preferred app-level migration:

```dart
final result = await generateText(
  model: model,
  prompt: [
    UserPromptMessage.text('Write a haiku.'),
  ],
);
```

Provider-implementation or adapter-level migration:

```dart
final request = GenerateTextRequest(
  prompt: [
    UserPromptMessage.text('Write a haiku.'),
  ],
);

final result = await model.doGenerate(request);
```

Old direct stream call:

```dart
final events = model.stream(request);
```

Provider-implementation or adapter-level migration:

```dart
final events = model.doStream(request);
```

Runtime-owned streaming migration:

```dart
final events = streamText(
  model: model,
  prompt: [
    UserPromptMessage.text('Write a haiku.'),
  ],
);
```

Runtime-owned multi-step streaming migration:

```dart
final run = streamTextRun(
  model: model,
  prompt: [
    UserPromptMessage.text('Call tools if needed.'),
  ],
  tools: tools,
  functionToolExecutor: executor,
);

final events = run.eventStream;
```

## Metadata-Driven Request Migration

### Provider File Identity

Old input-side metadata hint:

```dart
FilePromptPart(
  mediaType: 'application/pdf',
  data: FileUrlData(Uri.parse('https://example.test/doc.pdf')),
  providerMetadata: ProviderMetadata.forNamespace('openai', {
    'fileId': 'file_123',
  }),
);
```

New request identity:

```dart
const FilePromptPart(
  mediaType: 'application/pdf',
  data: FileProviderReferenceData(
    ProviderReference({
      'openai': 'file_123',
    }),
  ),
);
```

### Provider Wire Metadata Fields

Some provider APIs have an input field literally named `metadata`. That is
still request configuration and must use typed provider options, not
`ProviderMetadata`.

OpenAI Responses:

```dart
final result = await generateText(
  model: model,
  prompt: [
    UserPromptMessage.text('Summarize the ticket.'),
  ],
  callOptions: const CallOptions(
    providerOptions: OpenAIGenerateTextOptions(
      metadata: {
        'ticket_id': 'T-123',
      },
    ),
  ),
);
```

Anthropic Messages:

```dart
final result = await generateText(
  model: model,
  prompt: [
    UserPromptMessage.text('Summarize the ticket.'),
  ],
  callOptions: const CallOptions(
    providerOptions: AnthropicGenerateTextOptions(
      metadata: {
        'ticket_id': 'T-123',
      },
    ),
  ),
);
```

### Provider-Specific Request Features

Old metadata-shaped request feature:

```dart
final request = GenerateTextRequest(
  prompt: prompt,
  // Do not model request features as provider metadata.
);
```

New typed provider options:

```dart
final result = await generateText(
  model: model,
  prompt: prompt,
  callOptions: const CallOptions(
    providerOptions: GoogleGenerateTextOptions(
      includeThoughts: true,
      thinkingBudgetTokens: 1024,
    ),
  ),
);
```

## Compatibility Builder Policy

The root compatibility builder may still store older fluent builder settings in
the transitional `providerOptions` extension bag. That bag is a legacy bridge,
not a modern metadata contract.

New code should prefer:

- focused provider package imports
- `generateText`, `streamText`, or `streamTextRun` from `llm_dart_ai`
- typed provider options through `CallOptions.providerOptions`
- `ProviderMetadata` only for output observation and replay

The deprecated `ai()` builder alias has been removed in this breaking line.
Compatibility builder code should import `package:llm_dart/legacy.dart` and
construct `LLMBuilder()` explicitly.

## Provider Dependency Audit

The audited provider packages keep production dependencies on
`llm_dart_provider` and `llm_dart_transport` only:

- `llm_dart_openai`
- `llm_dart_anthropic`
- `llm_dart_google`
- `llm_dart_ollama`
- `llm_dart_elevenlabs`

They may keep `llm_dart_ai` in `dev_dependencies` for examples or tests, but
not in production `dependencies`.
