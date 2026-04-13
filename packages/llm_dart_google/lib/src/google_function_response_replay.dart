import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'google_provider_metadata_support.dart';
import 'google_shared.dart';

final class GoogleFunctionResponseReplay {
  static const kind = 'google.result.function_response';
  static const schema = 'google.function_response.v1';

  final String toolCallId;
  final String toolName;
  final Map<String, Object?> functionResponse;
  final List<GeneratedFile> files;
  final ProviderMetadata? providerMetadata;

  GoogleFunctionResponseReplay({
    required String toolCallId,
    required String toolName,
    Object? response,
    List<GeneratedFile> files = const [],
    String? functionCallId,
    Map<String, Object?> extraFunctionResponseFields = const {},
    ProviderMetadata? providerMetadata,
  }) : this._(
          toolCallId: _requireNonEmptyValue(toolCallId, name: 'toolCallId'),
          toolName: _requireNonEmptyValue(toolName, name: 'toolName'),
          functionResponse: _buildFunctionResponse(
            toolName: toolName,
            response: response,
            files: files,
            functionCallId: functionCallId,
            extraFunctionResponseFields: extraFunctionResponseFields,
          ),
          files: List<GeneratedFile>.unmodifiable(
            files.map(_normalizeFunctionResponseFile),
          ),
          providerMetadata: mergeProviderMetadata(
            providerMetadata,
            googleFunctionCallIdMetadata(functionCallId),
          ),
        );

  factory GoogleFunctionResponseReplay.fromJson(
    Map<String, Object?> json, {
    ProviderMetadata? providerMetadata,
  }) {
    final normalized = _normalizeJsonObject(
      json,
      path: 'replay',
    );
    final replayRole = _requiredNonEmptyString(
      normalized['replayRole'],
      path: 'replay.replayRole',
    );
    if (replayRole != 'tool') {
      throw FormatException(
        'Expected replay.replayRole to equal "tool", got $replayRole.',
      );
    }

    final schemaValue = _requiredNonEmptyString(
      normalized['schema'],
      path: 'replay.schema',
    );
    if (schemaValue != schema) {
      throw FormatException(
        'Expected replay.schema to equal $schema, got $schemaValue.',
      );
    }

    final toolCallId = _requiredNonEmptyString(
      normalized['toolCallId'],
      path: 'replay.toolCallId',
    );
    final toolName = _requiredNonEmptyString(
      normalized['toolName'],
      path: 'replay.toolName',
    );
    final topLevelFunctionCallId = _optionalNonEmptyString(
      normalized['functionCallId'],
      path: 'replay.functionCallId',
    );

    final functionResponse = _requiredObject(
      normalized['functionResponse'],
      path: 'replay.functionResponse',
    );
    final functionResponseName = _requiredNonEmptyString(
      functionResponse['name'],
      path: 'replay.functionResponse.name',
    );
    if (functionResponseName != toolName) {
      throw FormatException(
        'Expected replay.functionResponse.name to equal replay.toolName.',
      );
    }
    if (!functionResponse.containsKey('response')) {
      throw FormatException(
        'Expected replay.functionResponse.response to be present.',
      );
    }

    final nestedFunctionCallId = _optionalNonEmptyString(
      functionResponse['id'],
      path: 'replay.functionResponse.id',
    );
    if (topLevelFunctionCallId != null &&
        nestedFunctionCallId != null &&
        topLevelFunctionCallId != nestedFunctionCallId) {
      throw FormatException(
        'Expected replay.functionCallId to match replay.functionResponse.id.',
      );
    }

    final resolvedFunctionCallId =
        topLevelFunctionCallId ?? nestedFunctionCallId;
    final normalizedFunctionResponse = Map<String, Object?>.from(
      _normalizeJsonObject(
        functionResponse,
        path: 'replay.functionResponse',
      ),
    );
    normalizedFunctionResponse['response'] =
        normalizeJsonValue(normalizedFunctionResponse['response']);
    if (resolvedFunctionCallId != null &&
        !normalizedFunctionResponse.containsKey('id')) {
      normalizedFunctionResponse['id'] = resolvedFunctionCallId;
    }

    final files = _parseFunctionResponseFiles(
      normalizedFunctionResponse['parts'],
      path: 'replay.functionResponse.parts',
    );

    return GoogleFunctionResponseReplay._(
      toolCallId: toolCallId,
      toolName: toolName,
      functionResponse: normalizedFunctionResponse,
      files: files,
      providerMetadata: mergeProviderMetadata(
        providerMetadata,
        googleFunctionCallIdMetadata(resolvedFunctionCallId),
      ),
    );
  }

  GoogleFunctionResponseReplay._({
    required this.toolCallId,
    required this.toolName,
    required Map<String, Object?> functionResponse,
    required List<GeneratedFile> files,
    required this.providerMetadata,
  })  : functionResponse = Map.unmodifiable(functionResponse),
        files = List<GeneratedFile>.unmodifiable(files);

  String? get functionCallId {
    return _optionalNonEmptyString(
      functionResponse['id'],
      path: 'functionResponse.id',
    );
  }

  Object? get response => functionResponse['response'];

  bool get hasFiles => files.isNotEmpty;

  Map<String, Object?> toJson() {
    return {
      'schema': schema,
      'replayRole': 'tool',
      'toolCallId': toolCallId,
      'toolName': toolName,
      if (functionCallId != null) 'functionCallId': functionCallId,
      'functionResponse': toFunctionResponseJson(),
    };
  }

  Map<String, Object?> toFunctionResponseJson() {
    return Map<String, Object?>.from(functionResponse);
  }

  CustomContentPart toCustomContentPart({
    ProviderMetadata? providerMetadata,
  }) {
    return CustomContentPart(
      kind: kind,
      data: toJson(),
      providerMetadata: _resolvedProviderMetadata(providerMetadata),
    );
  }

  CustomUiPart toCustomUiPart({
    ProviderMetadata? providerMetadata,
  }) {
    return CustomUiPart(
      kind: kind,
      data: toJson(),
      providerMetadata: _resolvedProviderMetadata(providerMetadata),
    );
  }

  CustomPromptPart toCustomPromptPart({
    ProviderMetadata? providerMetadata,
  }) {
    return CustomPromptPart(
      kind: kind,
      data: toJson(),
      providerMetadata: _resolvedProviderMetadata(providerMetadata),
    );
  }

  CustomEvent toCustomEvent({
    ProviderMetadata? providerMetadata,
  }) {
    return CustomEvent(
      kind: kind,
      data: toJson(),
      providerMetadata: _resolvedProviderMetadata(providerMetadata),
    );
  }

  static GoogleFunctionResponseReplay? tryParseData(
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
    } on ArgumentError {
      return null;
    }
  }

  static GoogleFunctionResponseReplay parseData(
    Object? data, {
    ProviderMetadata? providerMetadata,
  }) {
    return GoogleFunctionResponseReplay.fromJson(
      _requiredObject(
        data,
        path: 'replay',
      ),
      providerMetadata: providerMetadata,
    );
  }

  static GoogleFunctionResponseReplay? tryParseContentPart(ContentPart part) {
    if (part is! CustomContentPart || part.kind != kind) {
      return null;
    }

    return tryParseData(
      part.data,
      providerMetadata: part.providerMetadata,
    );
  }

  static GoogleFunctionResponseReplay? tryParseUiPart(ChatUiPart part) {
    if (part is! CustomUiPart || part.kind != kind) {
      return null;
    }

    return tryParseData(
      part.data,
      providerMetadata: part.providerMetadata,
    );
  }

  static GoogleFunctionResponseReplay? tryParsePromptPart(PromptPart part) {
    if (part is! CustomPromptPart || part.kind != kind) {
      return null;
    }

    return tryParseData(
      part.data,
      providerMetadata: part.providerMetadata,
    );
  }

  static GoogleFunctionResponseReplay? tryParseEvent(TextStreamEvent event) {
    if (event is! CustomEvent || event.kind != kind) {
      return null;
    }

    return tryParseData(
      event.data,
      providerMetadata: event.providerMetadata,
    );
  }

  ProviderMetadata? _resolvedProviderMetadata(
    ProviderMetadata? providerMetadata,
  ) {
    return mergeProviderMetadata(this.providerMetadata, providerMetadata);
  }
}

Map<String, Object?> _buildFunctionResponse({
  required String toolName,
  required Object? response,
  required List<GeneratedFile> files,
  required String? functionCallId,
  required Map<String, Object?> extraFunctionResponseFields,
}) {
  final normalizedExtraFields = _normalizeJsonObject(
    extraFunctionResponseFields,
    path: 'extraFunctionResponseFields',
  );
  for (final reservedKey in const {'id', 'name', 'response', 'parts'}) {
    if (normalizedExtraFields.containsKey(reservedKey)) {
      throw ArgumentError.value(
        extraFunctionResponseFields,
        'extraFunctionResponseFields',
        'extraFunctionResponseFields must not contain "$reservedKey".',
      );
    }
  }

  return {
    ...normalizedExtraFields,
    if (functionCallId != null && functionCallId.isNotEmpty)
      'id': functionCallId,
    'name': toolName,
    'response': normalizeJsonValue(response),
    if (files.isNotEmpty)
      'parts': [
        for (final file in files)
          _encodeFunctionResponseFile(
            _normalizeFunctionResponseFile(file),
          ),
      ],
  };
}

GeneratedFile _normalizeFunctionResponseFile(GeneratedFile file) {
  final hasBytes = file.bytes != null;
  final hasUri = file.uri != null;
  if (hasBytes == hasUri) {
    throw ArgumentError.value(
      file,
      'files',
      'Google function response files require exactly one of bytes or uri.',
    );
  }

  return GeneratedFile(
    mediaType: _requireNonEmptyValue(file.mediaType, name: 'files.mediaType'),
    filename: _normalizeOptionalDisplayName(file.filename),
    uri: file.uri,
    bytes: file.bytes == null ? null : List<int>.unmodifiable(file.bytes!),
  );
}

Map<String, Object?> _encodeFunctionResponseFile(GeneratedFile file) {
  if (file.bytes != null) {
    return {
      'inlineData': {
        'mimeType': file.mediaType,
        'data': base64Encode(file.bytes!),
        if (file.filename != null) 'displayName': file.filename,
      },
    };
  }

  if (file.uri != null) {
    return {
      'fileData': {
        'mimeType': file.mediaType,
        'fileUri': file.uri.toString(),
        if (file.filename != null) 'displayName': file.filename,
      },
    };
  }

  throw ArgumentError.value(
    file,
    'file',
    'Google function response files require bytes or uri.',
  );
}

List<GeneratedFile> _parseFunctionResponseFiles(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return const [];
  }

  final list = value is List ? value : null;
  if (list == null) {
    throw FormatException('Expected $path to be a list.');
  }

  return List<GeneratedFile>.unmodifiable([
    for (var index = 0; index < list.length; index++)
      _parseFunctionResponseFile(
        list[index],
        path: '$path[$index]',
      ),
  ]);
}

GeneratedFile _parseFunctionResponseFile(
  Object? value, {
  required String path,
}) {
  final map = _requiredObject(value, path: path);
  final inlineData = asMap(map['inlineData']);
  final fileData = asMap(map['fileData']);

  if (inlineData != null && fileData != null) {
    throw FormatException(
      'Expected $path to contain either inlineData or fileData, not both.',
    );
  }

  if (inlineData != null) {
    final displayName = _optionalNonEmptyString(
      inlineData['displayName'],
      path: '$path.inlineData.displayName',
    );
    return GeneratedFile(
      mediaType: _requiredNonEmptyString(
        inlineData['mimeType'],
        path: '$path.inlineData.mimeType',
      ),
      filename: displayName,
      bytes: decodeBase64(
        _requiredNonEmptyString(
          inlineData['data'],
          path: '$path.inlineData.data',
        ),
      ),
    );
  }

  if (fileData != null) {
    final displayName = _optionalNonEmptyString(
      fileData['displayName'],
      path: '$path.fileData.displayName',
    );
    final uriString = _requiredNonEmptyString(
      fileData['fileUri'],
      path: '$path.fileData.fileUri',
    );
    final uri = Uri.tryParse(uriString);
    if (uri == null) {
      throw FormatException('Expected $path.fileData.fileUri to be a URI.');
    }

    return GeneratedFile(
      mediaType: _requiredNonEmptyString(
        fileData['mimeType'],
        path: '$path.fileData.mimeType',
      ),
      filename: displayName,
      uri: uri,
    );
  }

  throw FormatException(
    'Expected $path to contain inlineData or fileData.',
  );
}

Map<String, Object?> _normalizeJsonObject(
  Map<String, Object?> json, {
  required String path,
}) {
  final normalized = normalizeJsonValue(json);
  if (normalized is Map<String, Object?>) {
    return normalized;
  }

  if (normalized is Map) {
    return Map<String, Object?>.from(normalized);
  }

  throw FormatException('Expected $path to be a JSON object.');
}

Map<String, Object?> _requiredObject(
  Object? value, {
  required String path,
}) {
  final object = asMap(value);
  if (object == null) {
    throw FormatException('Expected $path to be an object.');
  }

  return object;
}

String _requiredNonEmptyString(
  Object? value, {
  required String path,
}) {
  final stringValue = value is String ? value : null;
  if (stringValue == null || stringValue.isEmpty) {
    throw FormatException('Expected $path to be a non-empty string.');
  }

  return stringValue;
}

String? _optionalNonEmptyString(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }

  if (value is! String) {
    throw FormatException('Expected $path to be a string.');
  }

  return value.isEmpty ? null : value;
}

String _requireNonEmptyValue(String value, {required String name}) {
  if (value.isEmpty) {
    throw ArgumentError.value(value, name, '$name must not be empty.');
  }

  return value;
}

String? _normalizeOptionalDisplayName(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  return value;
}
