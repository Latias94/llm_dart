import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

sealed class OpenAICustomPart {
  const OpenAICustomPart();

  String get kind;
  Map<String, Object?> get payload;
  ProviderMetadata? get providerMetadata;

  static OpenAICustomPart? tryParsePromptPart(PromptPart part) {
    return switch (part) {
      CustomPromptPart(:final kind, :final data, :final providerOptions) =>
        _parseCustomPayload(
          kind: kind,
          data: data,
          providerMetadata: providerReplayMetadataFromOptions(providerOptions),
        ),
      _ => null,
    };
  }

  static OpenAICustomPart? tryParseContentPart(ContentPart part) {
    return switch (part) {
      CustomContentPart(:final kind, :final data, :final providerMetadata) =>
        _parseCustomPayload(
          kind: kind,
          data: data,
          providerMetadata: providerMetadata,
        ),
      _ => null,
    };
  }

  static OpenAICustomPart? tryParseEvent(LanguageModelStreamEvent event) {
    return switch (event) {
      CustomEvent(:final kind, :final data, :final providerMetadata) =>
        _parseCustomPayload(
          kind: kind,
          data: data,
          providerMetadata: providerMetadata,
        ),
      _ => null,
    };
  }

  static List<OpenAICustomPart> parsePromptParts(Iterable<PromptPart> parts) {
    return parseTypedParts(parts, tryParsePromptPart);
  }

  static List<OpenAICustomPart> parseContentParts(Iterable<ContentPart> parts) {
    return parseTypedParts(parts, tryParseContentPart);
  }

  static List<OpenAICustomPart> parseEvents(
      Iterable<LanguageModelStreamEvent> events) {
    return parseTypedParts(events, tryParseEvent);
  }
}

final class OpenAIImageGenerationCallCustomPart extends OpenAICustomPart {
  static const customKind = 'openai.image_generation_call';

  @override
  final Map<String, Object?> payload;

  @override
  final ProviderMetadata? providerMetadata;

  const OpenAIImageGenerationCallCustomPart({
    required this.payload,
    this.providerMetadata,
  });

  @override
  String get kind => customKind;

  String? get itemId =>
      openaiMetadataString(providerMetadata, 'itemId') ??
      asString(payload['id']);

  String? get imageBase64 => asString(payload['result']);

  bool get hasImage => imageBase64 != null && imageBase64!.isNotEmpty;

  List<int>? decodeImageBytes() => decodeBase64(imageBase64);

  GeneratedFile? toGeneratedFile({
    String mediaType = 'image/png',
    String? filename,
  }) {
    final bytes = decodeImageBytes();
    if (bytes == null) {
      return null;
    }

    return GeneratedFile(
      mediaType: mediaType,
      filename: filename,
      data: FileBytesData(bytes),
    );
  }
}

final class OpenAIImageGenerationPartialCustomPart extends OpenAICustomPart {
  static const customKind = 'openai.image_generation_call.partial_image';

  @override
  final Map<String, Object?> payload;

  @override
  final ProviderMetadata? providerMetadata;

  const OpenAIImageGenerationPartialCustomPart({
    required this.payload,
    this.providerMetadata,
  });

  @override
  String get kind => customKind;

  String? get itemId =>
      asString(payload['item_id']) ??
      openaiMetadataString(providerMetadata, 'itemId');

  int? get outputIndex =>
      asInt(payload['output_index']) ??
      openaiMetadataInt(providerMetadata, 'outputIndex');

  String? get partialImageBase64 => asString(payload['partial_image_b64']);

  bool get hasImage =>
      partialImageBase64 != null && partialImageBase64!.isNotEmpty;

  List<int>? decodeImageBytes() => decodeBase64(partialImageBase64);

  GeneratedFile? toGeneratedFile({
    String mediaType = 'image/png',
    String? filename,
  }) {
    final bytes = decodeImageBytes();
    if (bytes == null) {
      return null;
    }

    return GeneratedFile(
      mediaType: mediaType,
      filename: filename,
      data: FileBytesData(bytes),
    );
  }
}

final class OpenAIMcpListToolsCustomPart extends OpenAICustomPart {
  static const customKind = 'openai.mcp_list_tools';

  @override
  final Map<String, Object?> payload;

  @override
  final ProviderMetadata? providerMetadata;

  const OpenAIMcpListToolsCustomPart({
    required this.payload,
    this.providerMetadata,
  });

  @override
  String get kind => customKind;

  String? get itemId =>
      openaiMetadataString(providerMetadata, 'itemId') ??
      asString(payload['id']);

  String? get serverLabel =>
      asString(payload['server_label']) ??
      openaiMetadataString(providerMetadata, 'serverLabel');

  List<Map<String, Object?>> get tools =>
      List<Map<String, Object?>>.unmodifiable([
        for (final item in asList(payload['tools']))
          if (asMap(item) case final tool?) tool,
      ]);

  int get toolCount => tools.length;

  List<String> get toolNames => List<String>.unmodifiable([
        for (final tool in tools)
          if (asString(tool['name']) case final name?) name,
      ]);

  Object? get error => payload['error'];

  bool get hasError => error != null;
}

final class OpenAICodeInterpreterCallCustomPart extends OpenAICustomPart {
  static const customKind = 'openai.code_interpreter_call';

  @override
  final Map<String, Object?> payload;

  @override
  final ProviderMetadata? providerMetadata;

  const OpenAICodeInterpreterCallCustomPart({
    required this.payload,
    this.providerMetadata,
  });

  @override
  String get kind => customKind;

  String? get itemId =>
      openaiMetadataString(providerMetadata, 'itemId') ??
      asString(payload['id']);

  String? get containerId =>
      asString(payload['container_id']) ??
      openaiMetadataString(providerMetadata, 'containerId');

  String get code => asString(payload['code']) ?? '';

  List<Map<String, Object?>> get outputs =>
      List<Map<String, Object?>>.unmodifiable([
        for (final item in asList(payload['outputs']))
          if (asMap(item) case final output?) output,
      ]);

  int get outputCount =>
      openaiMetadataInt(providerMetadata, 'outputCount') ?? outputs.length;

  List<String> get logs => List<String>.unmodifiable([
        for (final output in outputs)
          if (asString(output['logs']) case final logs?) logs,
      ]);
}

final class OpenAIToolSearchCallCustomPart extends OpenAICustomPart {
  static const customKind = 'openai.tool_search_call';

  @override
  final Map<String, Object?> payload;

  @override
  final ProviderMetadata? providerMetadata;

  const OpenAIToolSearchCallCustomPart({
    required this.payload,
    this.providerMetadata,
  });

  @override
  String get kind => customKind;

  String? get itemId =>
      openaiMetadataString(providerMetadata, 'itemId') ??
      asString(payload['id']);

  String? get callId =>
      asString(payload['call_id']) ??
      openaiMetadataString(providerMetadata, 'callId');

  String get execution =>
      asString(payload['execution']) ??
      openaiMetadataString(providerMetadata, 'execution') ??
      'server';

  Object? get arguments => payload['arguments'];

  bool get providerExecuted => execution == 'server';
}

final class OpenAIToolSearchOutputCustomPart extends OpenAICustomPart {
  static const customKind = 'openai.tool_search_output';

  @override
  final Map<String, Object?> payload;

  @override
  final ProviderMetadata? providerMetadata;

  const OpenAIToolSearchOutputCustomPart({
    required this.payload,
    this.providerMetadata,
  });

  @override
  String get kind => customKind;

  String? get itemId =>
      openaiMetadataString(providerMetadata, 'itemId') ??
      asString(payload['id']);

  String? get callId =>
      asString(payload['call_id']) ??
      openaiMetadataString(providerMetadata, 'callId');

  String get execution =>
      asString(payload['execution']) ??
      openaiMetadataString(providerMetadata, 'execution') ??
      'server';

  List<Map<String, Object?>> get tools =>
      List<Map<String, Object?>>.unmodifiable([
        for (final item in asList(payload['tools']))
          if (asMap(item) case final tool?) tool,
      ]);

  int get toolCount =>
      openaiMetadataInt(providerMetadata, 'toolCount') ?? tools.length;

  List<String> get toolNames => List<String>.unmodifiable([
        for (final tool in tools)
          if (asString(tool['name']) case final name?) name,
      ]);
}

OpenAICustomPart? _parseCustomPayload({
  required String kind,
  required Object? data,
  required ProviderMetadata? providerMetadata,
}) {
  final payload = asMap(data);
  if (payload == null) {
    return null;
  }

  return switch (kind) {
    OpenAIImageGenerationCallCustomPart.customKind =>
      OpenAIImageGenerationCallCustomPart(
        payload: payload,
        providerMetadata: providerMetadata,
      ),
    OpenAIImageGenerationPartialCustomPart.customKind =>
      OpenAIImageGenerationPartialCustomPart(
        payload: payload,
        providerMetadata: providerMetadata,
      ),
    OpenAIMcpListToolsCustomPart.customKind => OpenAIMcpListToolsCustomPart(
        payload: payload,
        providerMetadata: providerMetadata,
      ),
    OpenAICodeInterpreterCallCustomPart.customKind =>
      OpenAICodeInterpreterCallCustomPart(
        payload: payload,
        providerMetadata: providerMetadata,
      ),
    OpenAIToolSearchCallCustomPart.customKind => OpenAIToolSearchCallCustomPart(
        payload: payload,
        providerMetadata: providerMetadata,
      ),
    OpenAIToolSearchOutputCustomPart.customKind =>
      OpenAIToolSearchOutputCustomPart(
        payload: payload,
        providerMetadata: providerMetadata,
      ),
    _ => null,
  };
}

Map<String, Object?>? asMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }

  if (value is Map) {
    return Map<String, Object?>.from(value);
  }

  return null;
}

List<Object?> asList(Object? value) {
  if (value is List<Object?>) {
    return value;
  }

  if (value is List) {
    return List<Object?>.from(value);
  }

  return const [];
}

String? asString(Object? value) {
  return value is String ? value : null;
}

int? asInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return null;
}

List<int>? decodeBase64(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  return base64Decode(value);
}

String? openaiMetadataString(
  ProviderMetadata? providerMetadata,
  String key,
) {
  final openai = providerMetadata?.namespace('openai');
  return asString(openai?[key]);
}

int? openaiMetadataInt(
  ProviderMetadata? providerMetadata,
  String key,
) {
  final openai = providerMetadata?.namespace('openai');
  return asInt(openai?[key]);
}
