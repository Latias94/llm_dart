import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_function_response_file_codec.dart';

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
