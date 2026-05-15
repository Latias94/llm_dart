import 'dart:convert';

import '../common/json_codec_common.dart';
import '../content/file_data.dart';
import 'tool_output.dart';

/// Projects structured tool-output content into provider-neutral JSON values.
///
/// This is useful for provider protocols that can only replay tool results as
/// a string and need a stable JSON fallback for [ContentToolOutput].
List<Object?> projectToolOutputContentPartsToJson(
  List<ToolOutputContentPart> parts, {
  String path = r'$.toolOutput.parts',
}) {
  return [
    for (final entry in parts.asMap().entries)
      projectToolOutputContentPartToJson(
        entry.value,
        path: '$path[${entry.key}]',
      ),
  ];
}

/// Projects one structured tool-output content part into a JSON object.
JsonMap projectToolOutputContentPartToJson(
  ToolOutputContentPart part, {
  String path = r'$.toolOutput.parts[]',
}) {
  return switch (part) {
    TextToolOutputContentPart(:final text) => {
        'type': 'text',
        'text': text,
      },
    JsonToolOutputContentPart(:final value) => {
        'type': 'json',
        'value': normalizeJsonValue(value, path: '$path.value'),
      },
    FileToolOutputContentPart(
      :final mediaType,
      :final filename,
      :final data,
    ) =>
      {
        'type': 'file',
        'mediaType': mediaType,
        if (filename != null) 'filename': filename,
        'data': projectFileDataToJson(data),
      },
    CustomToolOutputContentPart(:final kind, :final data) => {
        'type': 'custom',
        'kind': kind,
        if (data != null) 'data': normalizeJsonValue(data, path: '$path.data'),
      },
  };
}

/// Projects shared [FileData] into a provider-neutral JSON object.
JsonMap projectFileDataToJson(FileData data) {
  return switch (data) {
    FileBytesData(:final bytes) => {
        'type': 'bytes',
        'bytes': {
          'encoding': 'base64',
          'data': base64Encode(bytes),
        },
      },
    FileUrlData(:final uri) => {
        'type': 'url',
        'uri': uri.toString(),
      },
    FileTextData(:final text) => {
        'type': 'text',
        'text': text,
      },
    FileProviderReferenceData(:final providerReference) => {
        'type': 'provider-reference',
        'providerReference': providerReference.toJsonMap(),
      },
  };
}
