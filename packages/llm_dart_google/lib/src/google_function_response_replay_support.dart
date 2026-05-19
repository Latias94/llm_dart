import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_function_response_file_codec.dart';
import 'google_replay_json.dart';

export 'google_function_response_file_codec.dart'
    show
        encodeGoogleFunctionResponseFile,
        normalizeGoogleFunctionResponseFile,
        parseGoogleFunctionResponseFiles;
export 'google_function_response_tool_output_encoder.dart'
    show
        GoogleFunctionResponseEncoding,
        encodeGoogleToolOutputForFunctionResponse;

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
