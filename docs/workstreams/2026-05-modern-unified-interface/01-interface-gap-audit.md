# Interface Gap Audit

## Current Recommended Shape

The modern API is moving toward provider facades plus model contracts:

```dart
final provider = openai(apiKey: apiKey, transport: transport);
final model = provider.chatModel('gpt-4.1-mini');
final result = await generateText(model, prompt: 'Hello');
```

This is a better default than the legacy builder because construction,
transport, model settings, and generation runtime are not hidden inside one
large mutable object.

## Gap 1: Dynamic Model Selection

Apps that choose providers at runtime still need a small unified selection
primitive. Without it, they either create their own ad hoc map or fall back to
the legacy builder because it feels like the only dynamic entrypoint.

The desired primitive is provider-agnostic and model-kind aware:

```dart
final registry = ModelRegistry(
  languageModels: {
    'openai': openai(apiKey: openAiKey).chatModel,
    'anthropic': anthropic(apiKey: anthropicKey).chatModel,
  },
);

final model = registry.languageModel('openai:gpt-4.1-mini');
```

This keeps the dynamic behavior but does not own provider configuration.

## Gap 2: Structured Object Generation

The runtime already has structured-output support, but the recommended surface
is not as obvious as Vercel AI SDK's `generateObject` and `streamObject`
concepts. This should be audited from a user workflow perspective:

First implementation slice:

- `generateObject` and `streamObject` now wrap the existing `OutputSpec`
  structured-output runtime with object-first names.
- `StreamOutputResult` exposes final text, finish reason, response metadata,
  usage, provider metadata, and parsed output from the same result object.
- the lower-level `generateOutput`, `streamOutput`, and custom `OutputSpec`
  APIs remain available for arrays, choices, raw JSON, and custom parsing.

- generate JSON-like objects from a schema
- stream partial object deltas where a provider can support it
- preserve provider warnings and raw metadata
- avoid making schemas provider-specific unless the provider requires it

## Gap 3: Request Options And Transport Serialization

Modern model requests already carry `CallOptions` with timeout, headers,
cancellation, and typed provider invocation options. The follow-up gap is making
these concerns consistently available through higher-level transports,
especially HTTP chat transport protocols.

First implementation slice:

- `HttpChatTransportRequestPayload` and reconnect payloads now carry serialized
  call options.
- timeout, headers, and max retries are represented in the wire protocol.
- timeout, max retries, and cancellation also apply to the client-side HTTP
  stream request.
- typed provider options remain Dart objects and require an explicit HTTP
  provider-options encoder before they are serialized to JSON.

The target should align with the Vercel-style idea of request options and custom
fetch while preserving Dart ownership:

- `TransportClient` remains the common injectable transport abstraction
- Dio remains injectable through transport implementations
- per-call headers, timeout, and cancellation stay in `CallOptions`
- provider-specific options remain typed Dart objects
- debug and telemetry concerns should be implemented through transport
  diagnostics or middleware rather than provider-specific one-offs

## Gap 4: Stream Part Alignment

The current stream contracts represent text, reasoning, tool calls, tool
results, finish events, warnings, and errors. The next design pass should check
whether app-level stream consumers can handle:

- provider-native custom parts without losing structured data
- tool call lifecycle updates
- resumable or replayable UI streams
- JSON/object streaming without overloading text events

The goal is not to copy every reference SDK event. The goal is predictable app
behavior with provider-native escape hatches.

## Gap 5: Example And Documentation Positioning

Some examples still reference compatibility builders or legacy entrypoints
because they demonstrate migration-era behavior. That can remain, but the docs
should clearly separate:

- recommended modern usage
- dynamic model selection
- provider-specific advanced usage
- legacy migration compatibility

Users should not have to infer which API is the future direction.

First implementation slice:

- the root README now introduces `ModelRegistry` for runtime model selection
  and `generateObject` / `streamObject` for object-first structured output
- the examples index and getting-started docs now point runtime provider
  selection toward `ModelRegistry` instead of legacy builders
- the provider comparison example now demonstrates `ModelRegistry` for
  runtime selection alongside the existing multi-provider comparison output
- the structured-output example now uses `generateObject` and `streamObject`
  for object-shaped results while retaining lower-level `OutputSpec` examples
  for arrays and choices
- the updated examples have a no-key smoke path so they can be run safely
  without live provider credentials

## Gap 6: Legacy Compatibility Tail

`LLMBuilder` remains useful for migration, especially for users coming from
v0.10. It should not influence new model contracts or package ownership.

The desired position is:

- modern docs recommend provider facades and task functions
- legacy docs import `package:llm_dart/legacy.dart`
- compatibility code is tested but not extended with new features
- new provider-native capabilities are added to provider packages first
