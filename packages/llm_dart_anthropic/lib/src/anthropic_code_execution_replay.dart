import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_code_execution_replay_codec.dart';
import 'anthropic_code_execution_replay_json.dart';
import 'anthropic_code_execution_replay_result.dart';

export 'anthropic_code_execution_replay_result.dart';

final class AnthropicCodeExecutionReplay {
  static const kind = anthropicCodeExecutionReplayKind;
  static const schema = anthropicCodeExecutionReplaySchema;
  static const canonicalToolName = anthropicCodeExecutionCanonicalToolName;

  final String toolCallId;
  final String toolName;
  final AnthropicCodeExecutionBlockType blockType;
  final Map<String, Object?> block;
  final AnthropicCodeExecutionResult result;
  final ProviderMetadata? providerMetadata;

  factory AnthropicCodeExecutionReplay({
    required String toolCallId,
    String toolName = canonicalToolName,
    required AnthropicCodeExecutionBlockType blockType,
    required Map<String, Object?> block,
    ProviderMetadata? providerMetadata,
  }) {
    return AnthropicCodeExecutionReplay._fromData(
      anthropicDecodeCodeExecutionReplayBlock(
        toolCallId: toolCallId,
        toolName: toolName,
        blockType: blockType,
        block: block,
      ),
      providerMetadata: providerMetadata,
    );
  }

  factory AnthropicCodeExecutionReplay.fromJson(
    Map<String, Object?> json, {
    ProviderMetadata? providerMetadata,
  }) {
    return AnthropicCodeExecutionReplay._fromData(
      anthropicDecodeCodeExecutionReplayJson(json),
      providerMetadata: providerMetadata,
    );
  }

  const AnthropicCodeExecutionReplay._({
    required this.toolCallId,
    required this.toolName,
    required this.blockType,
    required this.block,
    required this.result,
    required this.providerMetadata,
  });

  factory AnthropicCodeExecutionReplay._fromData(
    AnthropicCodeExecutionReplayData data, {
    ProviderMetadata? providerMetadata,
  }) {
    return AnthropicCodeExecutionReplay._(
      toolCallId: data.toolCallId,
      toolName: data.toolName,
      blockType: data.blockType,
      block: data.block,
      result: data.result,
      providerMetadata: providerMetadata,
    );
  }

  String get resultType => result.type;

  List<AnthropicExecutionFileHandle> get fileHandles => result.fileHandles;

  bool get hasFileHandles => fileHandles.isNotEmpty;

  Map<String, Object?> toJson() {
    return anthropicEncodeCodeExecutionReplayJson(
      AnthropicCodeExecutionReplayData(
        toolCallId: toolCallId,
        toolName: toolName,
        blockType: blockType,
        block: block,
        result: result,
      ),
    );
  }

  CustomContentPart toCustomContentPart({
    ProviderMetadata? providerMetadata,
  }) {
    return CustomContentPart(
      kind: kind,
      data: toJson(),
      providerMetadata: providerMetadata ?? this.providerMetadata,
    );
  }

  CustomPromptPart toCustomPromptPart({
    ProviderMetadata? providerMetadata,
  }) {
    final metadata = providerMetadata ?? this.providerMetadata;
    return CustomPromptPart(
      kind: kind,
      data: toJson(),
      providerOptions: ProviderReplayPromptPartOptions.fromMetadata(metadata),
    );
  }

  CustomEvent toCustomEvent({
    ProviderMetadata? providerMetadata,
  }) {
    return CustomEvent(
      kind: kind,
      data: toJson(),
      providerMetadata: providerMetadata ?? this.providerMetadata,
    );
  }

  static AnthropicCodeExecutionReplay? tryParseData(
    Object? data, {
    ProviderMetadata? providerMetadata,
  }) {
    try {
      return parseData(
        data,
        providerMetadata: providerMetadata,
      );
    } on FormatException {
      return null;
    } on UnsupportedError {
      return null;
    }
  }

  static AnthropicCodeExecutionReplay parseData(
    Object? data, {
    ProviderMetadata? providerMetadata,
  }) {
    return AnthropicCodeExecutionReplay.fromJson(
      anthropicReplayRequiredObject(
        data,
        path: 'replay',
      ),
      providerMetadata: providerMetadata,
    );
  }

  static AnthropicCodeExecutionReplay? tryParseContentPart(ContentPart part) {
    if (part is! CustomContentPart || part.kind != kind) {
      return null;
    }

    return tryParseData(
      part.data,
      providerMetadata: part.providerMetadata,
    );
  }

  static AnthropicCodeExecutionReplay? tryParsePromptPart(PromptPart part) {
    if (part is! CustomPromptPart || part.kind != kind) {
      return null;
    }

    return tryParseData(
      part.data,
      providerMetadata: providerReplayMetadataFromOptions(
        part.providerOptions,
      ),
    );
  }

  static AnthropicCodeExecutionReplay? tryParseEvent(
    LanguageModelStreamEvent event,
  ) {
    if (event is! CustomEvent || event.kind != kind) {
      return null;
    }

    return tryParseData(
      event.data,
      providerMetadata: event.providerMetadata,
    );
  }
}
