import 'openai_assistants_lifecycle_models.dart';
import 'openai_assistants_message_list_models.dart';
import 'openai_assistants_route_parameters.dart';
import 'openai_assistants_run_models.dart';
import 'openai_assistants_run_step_list_models.dart';

final class OpenAIAssistantsRouteSupport {
  final String baseUrl;
  final OpenAIAssistantsRouteParameters parameters;

  const OpenAIAssistantsRouteSupport({
    required this.baseUrl,
    this.parameters = const OpenAIAssistantsRouteParameters(),
  });

  Uri assistantsUri([OpenAIListAssistantsQuery? query]) {
    return openAIAssistantsUriWithQuery(
      '$baseUrl/assistants',
      query?.toQueryParameters() ?? const {},
    );
  }

  Uri assistantUri(String assistantId) {
    return Uri.parse(
      '$baseUrl/assistants/${parameters.encodeAssistantId(assistantId)}',
    );
  }

  Uri get threadsUri => Uri.parse('$baseUrl/threads');

  Uri threadUri(String threadId) {
    return Uri.parse(
      '$baseUrl/threads/${parameters.encodeThreadId(threadId)}',
    );
  }

  Uri threadMessagesUri(
    String threadId, [
    OpenAIListThreadMessagesQuery? query,
  ]) {
    return openAIAssistantsUriWithQuery(
      '$baseUrl/threads/${parameters.encodeThreadId(threadId)}/messages',
      query?.toQueryParameters() ?? const {},
    );
  }

  Uri threadMessageUri(String threadId, String messageId) {
    return Uri.parse(
      '$baseUrl/threads/${parameters.encodeThreadId(threadId)}/messages/${parameters.encodeMessageId(messageId)}',
    );
  }

  Uri threadRunsUri(String threadId, [OpenAIListRunsQuery? query]) {
    return openAIAssistantsUriWithQuery(
      '$baseUrl/threads/${parameters.encodeThreadId(threadId)}/runs',
      query?.toQueryParameters() ?? const {},
    );
  }

  Uri threadRunUri(String threadId, String runId) {
    return Uri.parse(
      '$baseUrl/threads/${parameters.encodeThreadId(threadId)}/runs/${parameters.encodeRunId(runId)}',
    );
  }

  Uri cancelThreadRunUri(String threadId, String runId) {
    return Uri.parse('${threadRunUri(threadId, runId)}/cancel');
  }

  Uri submitThreadRunToolOutputsUri(String threadId, String runId) {
    return Uri.parse('${threadRunUri(threadId, runId)}/submit_tool_outputs');
  }

  Uri createThreadAndRunUri() {
    return Uri.parse('$baseUrl/threads/runs');
  }

  Uri threadRunStepsUri(
    String threadId,
    String runId, [
    OpenAIListRunStepsQuery? query,
  ]) {
    return openAIAssistantsUriWithQuery(
      '$baseUrl/threads/${parameters.encodeThreadId(threadId)}/runs/${parameters.encodeRunId(runId)}/steps',
      query?.toQueryParameters() ?? const {},
    );
  }

  Uri threadRunStepUri(String threadId, String runId, String stepId) {
    return Uri.parse(
      '$baseUrl/threads/${parameters.encodeThreadId(threadId)}/runs/${parameters.encodeRunId(runId)}/steps/${parameters.encodeStepId(stepId)}',
    );
  }

  String requireAssistantId(
    String value, {
    required String parameterName,
  }) {
    return parameters.requireAssistantId(value, parameterName: parameterName);
  }

  String requireThreadId(
    String value, {
    required String parameterName,
  }) {
    return parameters.requireThreadId(value, parameterName: parameterName);
  }

  String requireMessageId(
    String value, {
    required String parameterName,
  }) {
    return parameters.requireMessageId(value, parameterName: parameterName);
  }

  String requireRunId(
    String value, {
    required String parameterName,
  }) {
    return parameters.requireRunId(value, parameterName: parameterName);
  }

  String requireStepId(
    String value, {
    required String parameterName,
  }) {
    return parameters.requireStepId(value, parameterName: parameterName);
  }
}
