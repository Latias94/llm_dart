import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

String encodeOpenAIToolOutputAsText(
  ToolOutput output, {
  String path = r'$.toolOutput',
}) {
  if (output is ExecutionDeniedToolOutput) {
    return output.reason ?? 'Tool execution denied';
  }

  if (output is ContentToolOutput) {
    return jsonEncode(
      projectToolOutputContentPartsToJson(
        output.parts,
        path: '$path.parts',
      ),
    );
  }

  final value = output.value;
  if (value == null) {
    return output.isError ? 'Tool execution failed' : 'null';
  }

  if (value is String) {
    return value;
  }

  return jsonEncode(
    normalizeJsonValue(value, path: '$path.value'),
  );
}
