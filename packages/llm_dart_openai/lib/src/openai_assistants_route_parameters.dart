final class OpenAIAssistantsRouteParameters {
  const OpenAIAssistantsRouteParameters();

  String requireAssistantId(
    String value, {
    required String parameterName,
  }) {
    return requireId(
      value,
      parameterName: parameterName,
      label: 'assistant',
    );
  }

  String requireThreadId(
    String value, {
    required String parameterName,
  }) {
    return requireId(
      value,
      parameterName: parameterName,
      label: 'thread',
    );
  }

  String requireMessageId(
    String value, {
    required String parameterName,
  }) {
    return requireId(
      value,
      parameterName: parameterName,
      label: 'thread message',
    );
  }

  String requireRunId(
    String value, {
    required String parameterName,
  }) {
    return requireId(
      value,
      parameterName: parameterName,
      label: 'thread run',
    );
  }

  String requireStepId(
    String value, {
    required String parameterName,
  }) {
    return requireId(
      value,
      parameterName: parameterName,
      label: 'run step',
    );
  }

  String encodeAssistantId(String assistantId) {
    return Uri.encodeComponent(
      requireAssistantId(assistantId, parameterName: 'assistantId'),
    );
  }

  String encodeThreadId(String threadId) {
    return Uri.encodeComponent(
      requireThreadId(threadId, parameterName: 'threadId'),
    );
  }

  String encodeMessageId(String messageId) {
    return Uri.encodeComponent(
      requireMessageId(messageId, parameterName: 'messageId'),
    );
  }

  String encodeRunId(String runId) {
    return Uri.encodeComponent(
      requireRunId(runId, parameterName: 'runId'),
    );
  }

  String encodeStepId(String stepId) {
    return Uri.encodeComponent(
      requireStepId(stepId, parameterName: 'stepId'),
    );
  }

  String requireId(
    String value, {
    required String parameterName,
    required String label,
  }) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        parameterName,
        'Expected a non-empty OpenAI $label ID.',
      );
    }
    return normalized;
  }
}

Uri openAIAssistantsUriWithQuery(
  String uri,
  Map<String, String> queryParameters,
) {
  final parsed = Uri.parse(uri);
  if (queryParameters.isEmpty) {
    return parsed;
  }
  return parsed.replace(queryParameters: queryParameters);
}
