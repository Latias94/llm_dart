# Data Structure Redesign

## Provider Options And Provider Metadata

The shared vocabulary should distinguish input-side provider customization from
output-side provider detail.

Target distinction:

- provider options
  - input-side, request shaping, provider-owned
  - preferably typed in Dart
- provider metadata
  - output-side, observation, replay detail, provider-owned
  - JSON-safe and namespaced

Provider metadata must not be the primary way to pass input-side file IDs,
tool settings, search controls, or lifecycle instructions.

## File Data

The current `FilePromptPart` shape uses nullable `uri` and `bytes` fields and
often relies on provider metadata for hosted file identity.

Target shared shape:

```dart
sealed class FileData {
  const FileData();
}

final class FileBytesData extends FileData {
  final List<int> bytes;
}

final class FileUrlData extends FileData {
  final Uri uri;
}

final class FileTextData extends FileData {
  final String text;
}

final class FileProviderReferenceData extends FileData {
  final ProviderReference reference;
}
```

Prompt file parts should then hold:

- `mediaType`
- optional `filename`
- `FileData data`
- optional typed or namespaced provider options

## Provider Reference

Add a shared provider-reference value:

```dart
final class ProviderReference {
  final Map<String, String> values;
}
```

Rules:

- keys are provider IDs such as `openai`, `anthropic`, or `google`
- values are provider-specific identifiers
- provider codecs resolve their own entry or throw a clear error
- provider references are input data, not output metadata

Provider file clients may return both:

- provider-native file descriptors
- shared provider references for prompt reuse

## Tool Output

The current `ToolResultPromptPart.output` plus `isError` is too broad for the
next breaking line.

Target shared shape:

```dart
sealed class ToolOutput {
  const ToolOutput();
}

final class TextToolOutput extends ToolOutput {
  final String value;
}

final class JsonToolOutput extends ToolOutput {
  final Object? value;
}

final class ErrorTextToolOutput extends ToolOutput {
  final String value;
}

final class ErrorJsonToolOutput extends ToolOutput {
  final Object? value;
}

final class ExecutionDeniedToolOutput extends ToolOutput {
  final String? reason;
}

final class ContentToolOutput extends ToolOutput {
  final List<ToolOutputContentPart> parts;
}
```

This keeps common tool semantics explicit while leaving provider-native replay
details in provider-owned custom parts or options.

## Reasoning

Shared reasoning should remain common when it is model output semantics:

- reasoning text
- reasoning file
- reasoning stream lanes

Provider controls for reasoning effort, budgets, encrypted replay, or provider
specific summary handling should remain provider-owned unless a stable
cross-provider control proves useful.

## Capability Profiles

Capability profiles should stay as a Dart-specific strength.

The redesign should preserve:

- shared feature descriptors
- provider feature descriptors
- confidence levels
- optional model marker interfaces

The capability layer is descriptive and app-facing. Provider codecs still own
final validation and warnings.
