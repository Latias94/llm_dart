# Data Structure Redesign

Status: structured file data and provider-reference input identity slice
complete.

This slice introduces the long-lived shared data vocabulary while keeping the
old constructor shapes source-compatible:

- `ProviderReference` is now a shared provider-native reference value.
- `FileData` is now a sealed data union with bytes, URL, text, and provider
  reference variants.
- `ToolOutput` is now an explicit common output union.
- `GeneratedFile`, `FilePromptPart`, `ImagePromptPart`,
  `ReasoningFilePromptPart`, `ToolResultContent`, and
  `ToolResultPromptPart` expose the new structured data while retaining legacy
  `uri`, `bytes`, `output`, and `isError` accessors for migration.
- OpenAI, Anthropic, and Google have first-round codec support for the new
  provider-reference file path where their APIs expose one.
- `ToolResultContent` and `ToolResultPromptPart` now store only `ToolOutput`;
  legacy `output` and `isError` inputs are constructor-time migration shims.
- OpenAI input-side file IDs now resolve only through
  `FileProviderReferenceData`; `providerMetadata.openai.fileId` is no longer
  accepted as an input file identity hint.

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

Implementation rule for the breaking line:

- input-side controls belong in typed provider options or structured prompt
  data
- provider-owned file identity belongs in `ProviderReference`
- output replay details and observed provider IDs may remain in
  `ProviderMetadata`
- provider metadata file-id hints are not an input compatibility path in the
  breaking API line

## File Data

The current `FilePromptPart` shape uses nullable `uri` and `bytes` fields and
often relies on provider metadata for hosted file identity.

Implemented shared shape:

```dart
sealed class FileData {
  const FileData();

  Uri? get uri => null;
  List<int>? get bytes => null;
  String? get text => null;
  ProviderReference? get providerReference => null;
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
  final ProviderReference providerReference;
}
```

Prompt file parts now hold:

- `mediaType`
- optional `filename`
- required `FileData data`
- optional provider metadata for output/replay compatibility

Provider codec support in the first slice:

- OpenAI Responses resolves `FileProviderReferenceData({'openai': ...})` to
  `input_image.file_id` or `input_file.file_id`
- OpenAI Chat Completions resolves OpenAI PDF provider references to
  `file.file_id`
- Anthropic resolves `FileProviderReferenceData({'anthropic': ...})` to
  `source: { type: "file", file_id: ... }` and enables the Files API beta
  header
- Google resolves `FileProviderReferenceData({'google': ...})` or
  `{'vertex': ...}` to `fileData.fileUri`
- core prompt JSON serialization preserves `FileData` while still decoding the
  legacy `uri` and `bytes` shape
- prompt and generated-file JSON encodes only the structured `data` shape while
  still reading legacy `uri` and `bytes` payloads

## Provider Reference

Implemented shared provider-reference value:

```dart
final class ProviderReference {
  final Map<String, String> values;

  String requireProvider(String providerId, {String? context});
}
```

Rules:

- keys are provider IDs such as `openai`, `anthropic`, or `google`
- values are provider-specific identifiers
- provider codecs resolve their own entry or throw a clear error
- provider references are input data, not output metadata
- provider IDs are validated as lowercase, provider-style keys when serialized

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

Compatibility rule:

- legacy `output` and `isError` are projected into `ToolOutput` at
  construction time
- provider codecs should consume `toolOutput`
- core prompt JSON serialization preserves `ToolOutput` while still decoding
  the legacy `output` and `isError` shape
- provider-native replay blocks remain `CustomPromptPart` / `CustomContentPart`
  owned by the provider package

Breaking note:

- `ToolResultContent` and `ToolResultPromptPart` are intentionally no longer
  `const` constructors, because they normalize legacy `output` / `isError`
  arguments into the explicit `ToolOutput` union.

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

## Migration Recipes

Old file prompts continue to compile:

```dart
FilePromptPart(
  mediaType: 'application/pdf',
  bytes: bytes,
);
```

New file prompts should prefer structured data:

```dart
FilePromptPart(
  mediaType: 'application/pdf',
  data: FileBytesData(bytes),
);

FilePromptPart(
  mediaType: 'application/pdf',
  data: FileProviderReferenceData(
    ProviderReference.forProvider('openai', 'file_123'),
  ),
);
```

Old tool results continue to compile:

```dart
ToolResultPromptPart(
  toolCallId: 'call_1',
  toolName: 'weather',
  output: {'temperature': 28},
);
```

New tool results should prefer explicit output variants:

```dart
ToolResultPromptPart(
  toolCallId: 'call_1',
  toolName: 'weather',
  toolOutput: JsonToolOutput({'temperature': 28}),
);

ToolResultPromptPart(
  toolCallId: 'call_2',
  toolName: 'weather',
  toolOutput: ErrorTextToolOutput('timeout'),
);
```

## Remaining Breaking Work

- expand provider-reference coverage beyond OpenAI, Anthropic, and Google
- decide whether `ContentToolOutput` needs provider-specific multimodal content
  adapters before the breaking release
