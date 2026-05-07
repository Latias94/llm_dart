part of 'responses_request_builder.dart';

final class _OpenAIResponsesToolSupport {
  const _OpenAIResponsesToolSupport();

  Map<String, dynamic> convertToolToResponsesFormat(Tool tool) {
    return {
      'type': 'function',
      'name': tool.function.name,
      'description': tool.function.description,
      'parameters': tool.function.parameters.toJson(),
    };
  }
}
