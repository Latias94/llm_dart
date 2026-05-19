import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_assistants_lifecycle_models.dart';
import 'openai_assistants_message_models.dart';
import 'openai_assistants_run_models.dart';
import 'openai_assistants_run_step_models.dart';
import 'openai_family_profile.dart';
import 'openai_non_text_model_support.dart';

final class OpenAIAssistantsSettings {
  final String? organization;
  final String? project;
  final Map<String, String> headers;

  const OpenAIAssistantsSettings({
    this.organization,
    this.project,
    this.headers = const {},
  });
}

final class OpenAIAssistantsTransportSupport {
  final String apiKey;
  final String baseUrl;
  final OpenAIFamilyProfile profile;
  final OpenAIAssistantsSettings settings;

  const OpenAIAssistantsTransportSupport({
    required this.apiKey,
    required this.baseUrl,
    required this.profile,
    required this.settings,
  });

  Uri assistantsUri([OpenAIListAssistantsQuery? query]) {
    final uri = Uri.parse('$baseUrl/assistants');
    final queryParameters = query?.toQueryParameters() ?? const {};
    if (queryParameters.isEmpty) {
      return uri;
    }
    return uri.replace(queryParameters: queryParameters);
  }

  Uri assistantUri(String assistantId) {
    return Uri.parse(
      '$baseUrl/assistants/${Uri.encodeComponent(requireAssistantId(
        assistantId,
        parameterName: 'assistantId',
      ))}',
    );
  }

  Uri get threadsUri => Uri.parse('$baseUrl/threads');

  Uri threadUri(String threadId) {
    return Uri.parse(
      '$baseUrl/threads/${Uri.encodeComponent(requireThreadId(
        threadId,
        parameterName: 'threadId',
      ))}',
    );
  }

  Uri threadMessagesUri(
    String threadId, [
    OpenAIListThreadMessagesQuery? query,
  ]) {
    return _uriWithQuery(
      '$baseUrl/threads/${Uri.encodeComponent(requireThreadId(
        threadId,
        parameterName: 'threadId',
      ))}/messages',
      query?.toQueryParameters() ?? const {},
    );
  }

  Uri threadMessageUri(String threadId, String messageId) {
    return Uri.parse(
      '$baseUrl/threads/${Uri.encodeComponent(requireThreadId(
        threadId,
        parameterName: 'threadId',
      ))}/messages/${Uri.encodeComponent(requireMessageId(
        messageId,
        parameterName: 'messageId',
      ))}',
    );
  }

  Uri threadRunsUri(String threadId, [OpenAIListRunsQuery? query]) {
    return _uriWithQuery(
      '$baseUrl/threads/${Uri.encodeComponent(requireThreadId(
        threadId,
        parameterName: 'threadId',
      ))}/runs',
      query?.toQueryParameters() ?? const {},
    );
  }

  Uri threadRunUri(String threadId, String runId) {
    return Uri.parse(
      '$baseUrl/threads/${Uri.encodeComponent(requireThreadId(
        threadId,
        parameterName: 'threadId',
      ))}/runs/${Uri.encodeComponent(requireRunId(
        runId,
        parameterName: 'runId',
      ))}',
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
    return _uriWithQuery(
      '$baseUrl/threads/${Uri.encodeComponent(requireThreadId(
        threadId,
        parameterName: 'threadId',
      ))}/runs/${Uri.encodeComponent(requireRunId(
        runId,
        parameterName: 'runId',
      ))}/steps',
      query?.toQueryParameters() ?? const {},
    );
  }

  Uri threadRunStepUri(String threadId, String runId, String stepId) {
    return Uri.parse(
      '$baseUrl/threads/${Uri.encodeComponent(requireThreadId(
        threadId,
        parameterName: 'threadId',
      ))}/runs/${Uri.encodeComponent(requireRunId(
        runId,
        parameterName: 'runId',
      ))}/steps/${Uri.encodeComponent(requireStepId(
        stepId,
        parameterName: 'stepId',
      ))}',
    );
  }

  TransportRequest jsonRequest({
    required Uri uri,
    required TransportMethod method,
    Object? body,
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? extraHeaders,
    bool contentType = false,
  }) {
    return TransportRequest(
      uri: uri,
      method: method,
      headers: buildHeaders(
        extraHeaders: extraHeaders,
        contentType: contentType,
      ),
      body: body,
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      responseType: TransportResponseType.json,
    );
  }

  Map<String, String> buildHeaders({
    Map<String, String>? extraHeaders,
    bool contentType = false,
  }) {
    return buildOpenAIFamilyDefaultHeaders(
      profile: profile,
      apiKey: apiKey,
      organization: settings.organization,
      project: settings.project,
      headers: {
        ...settings.headers,
        'openai-beta': 'assistants=v2',
        if (contentType) 'content-type': 'application/json',
        'accept': 'application/json',
        if (extraHeaders != null) ...extraHeaders,
      },
    );
  }

  String requireAssistantId(
    String value, {
    required String parameterName,
  }) {
    return _requireNonEmptyId(
      value,
      parameterName: parameterName,
      label: 'assistant',
    );
  }

  String requireThreadId(
    String value, {
    required String parameterName,
  }) {
    return _requireNonEmptyId(
      value,
      parameterName: parameterName,
      label: 'thread',
    );
  }

  String requireMessageId(
    String value, {
    required String parameterName,
  }) {
    return _requireNonEmptyId(
      value,
      parameterName: parameterName,
      label: 'thread message',
    );
  }

  String requireRunId(
    String value, {
    required String parameterName,
  }) {
    return _requireNonEmptyId(
      value,
      parameterName: parameterName,
      label: 'thread run',
    );
  }

  String requireStepId(
    String value, {
    required String parameterName,
  }) {
    return _requireNonEmptyId(
      value,
      parameterName: parameterName,
      label: 'run step',
    );
  }

  String _requireNonEmptyId(
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

Uri _uriWithQuery(String uri, Map<String, String> queryParameters) {
  final parsed = Uri.parse(uri);
  if (queryParameters.isEmpty) {
    return parsed;
  }
  return parsed.replace(queryParameters: queryParameters);
}
