import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_replay_json.dart';
import 'google_shared.dart';

Map<String, Object?> buildGoogleFunctionResponse({
  required String toolName,
  required Object? response,
  required List<GeneratedFile> files,
  required String? functionCallId,
  required Map<String, Object?> extraFunctionResponseFields,
}) {
  final normalizedExtraFields = normalizeGoogleReplayJsonObject(
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
          encodeGoogleFunctionResponseFile(
            normalizeGoogleFunctionResponseFile(file),
          ),
      ],
  };
}

GeneratedFile normalizeGoogleFunctionResponseFile(GeneratedFile file) {
  final hasBytes = file.bytes != null;
  final hasUri = file.uri != null;
  final hasProviderReference = file.providerReference != null;
  final hasText = file.text != null;
  if ([hasBytes, hasUri, hasProviderReference, hasText]
          .where((value) => value)
          .length !=
      1) {
    throw ArgumentError.value(
      file,
      'files',
      'Google function response files require exactly one of bytes, text, uri, or providerReference.',
    );
  }

  return GeneratedFile(
    mediaType: requireGoogleReplayNonEmptyValue(
      file.mediaType,
      name: 'files.mediaType',
    ),
    filename: normalizeGoogleOptionalDisplayName(file.filename),
    data: file.bytes == null
        ? file.text == null
            ? file.data
            : FileBytesData(
                utf8.encode(file.text!),
              )
        : FileBytesData(List<int>.unmodifiable(file.bytes!)),
  );
}

Map<String, Object?> encodeGoogleFunctionResponseFile(GeneratedFile file) {
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

  if (_googleFunctionResponseFileUri(file.providerReference)
      case final fileUri?) {
    return {
      'fileData': {
        'mimeType': file.mediaType,
        'fileUri': fileUri,
        if (file.filename != null) 'displayName': file.filename,
      },
    };
  }

  throw ArgumentError.value(
    file,
    'file',
    'Google function response files require bytes, uri, or providerReference.',
  );
}

List<GeneratedFile> parseGoogleFunctionResponseFiles(
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
      _parseGoogleFunctionResponseFile(
        list[index],
        path: '$path[$index]',
      ),
  ]);
}

GoogleFunctionResponseEncoding encodeGoogleToolOutputForFunctionResponse({
  required String toolName,
  required ToolOutput toolOutput,
}) {
  return switch (toolOutput) {
    ContentToolOutput(:final parts) => _encodeContentToolOutput(
        toolName: toolName,
        parts: parts,
      ),
    ExecutionDeniedToolOutput(:final reason) => GoogleFunctionResponseEncoding(
        response: {
          'name': toolName,
          'content': reason ?? 'Tool execution denied',
        },
      ),
    _ => GoogleFunctionResponseEncoding(
        response: {
          'name': toolName,
          'content': normalizeJsonValue(toolOutput.value) ?? 'null',
        },
      ),
  };
}

GeneratedFile _parseGoogleFunctionResponseFile(
  Object? value, {
  required String path,
}) {
  final map = requireGoogleReplayObject(value, path: path);
  final inlineData = asMap(map['inlineData']);
  final fileData = asMap(map['fileData']);

  if (inlineData != null && fileData != null) {
    throw FormatException(
      'Expected $path to contain either inlineData or fileData, not both.',
    );
  }

  if (inlineData != null) {
    final displayName = optionalGoogleReplayNonEmptyString(
      inlineData['displayName'],
      path: '$path.inlineData.displayName',
    );
    return GeneratedFile(
      mediaType: requireGoogleReplayNonEmptyString(
        inlineData['mimeType'],
        path: '$path.inlineData.mimeType',
      ),
      filename: displayName,
      data: FileBytesData(
        decodeBase64(
              requireGoogleReplayNonEmptyString(
                inlineData['data'],
                path: '$path.inlineData.data',
              ),
            ) ??
            (throw FormatException(
              'Expected $path.inlineData.data to be base64.',
            )),
      ),
    );
  }

  if (fileData != null) {
    final displayName = optionalGoogleReplayNonEmptyString(
      fileData['displayName'],
      path: '$path.fileData.displayName',
    );
    final uriString = requireGoogleReplayNonEmptyString(
      fileData['fileUri'],
      path: '$path.fileData.fileUri',
    );
    final uri = Uri.tryParse(uriString);
    if (uri == null) {
      throw FormatException('Expected $path.fileData.fileUri to be a URI.');
    }

    return GeneratedFile(
      mediaType: requireGoogleReplayNonEmptyString(
        fileData['mimeType'],
        path: '$path.fileData.mimeType',
      ),
      filename: displayName,
      data: FileUrlData(uri),
    );
  }

  throw FormatException(
    'Expected $path to contain inlineData or fileData.',
  );
}

String? _googleFunctionResponseFileUri(ProviderReference? reference) {
  if (reference == null) {
    return null;
  }

  return reference['google'] ??
      reference['vertex'] ??
      reference.requireProvider(
        'google',
        context: 'Google function response file',
      );
}

GoogleFunctionResponseEncoding _encodeContentToolOutput({
  required String toolName,
  required List<ToolOutputContentPart> parts,
}) {
  final responseTextParts = <String>[];
  final files = <GeneratedFile>[];

  for (final part in parts) {
    switch (part) {
      case TextToolOutputContentPart(:final text):
        responseTextParts.add(text);
      case JsonToolOutputContentPart(:final value):
        responseTextParts.add(
          jsonEncode({
            'type': 'json',
            'value': normalizeJsonValue(value),
          }),
        );
      case FileToolOutputContentPart(
          :final mediaType,
          :final filename,
          :final data,
        ):
        files.add(
          normalizeGoogleFunctionResponseFile(
            GeneratedFile(
              mediaType: mediaType,
              filename: filename,
              data: data,
            ),
          ),
        );
      case CustomToolOutputContentPart(
          :final kind,
          :final data,
        ):
        responseTextParts.add(
          jsonEncode({
            'type': 'custom',
            'kind': kind,
            if (data != null) 'data': normalizeJsonValue(data),
          }),
        );
    }
  }

  return GoogleFunctionResponseEncoding(
    response: {
      'name': toolName,
      'content': responseTextParts.isEmpty
          ? 'Tool executed successfully.'
          : responseTextParts.join('\n'),
    },
    files: List<GeneratedFile>.unmodifiable(files),
  );
}

final class GoogleFunctionResponseEncoding {
  final Object? response;
  final List<GeneratedFile> files;

  const GoogleFunctionResponseEncoding({
    required this.response,
    this.files = const [],
  });
}
