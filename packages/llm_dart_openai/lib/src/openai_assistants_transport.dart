import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_assistants_lifecycle_models.dart';
import 'openai_assistants_message_models.dart';
import 'openai_assistants_route_support.dart';
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
  final OpenAIAssistantsRouteSupport routes;

  OpenAIAssistantsTransportSupport({
    required this.apiKey,
    required this.baseUrl,
    required this.profile,
    required this.settings,
  }) : routes = OpenAIAssistantsRouteSupport(baseUrl: baseUrl);

  Uri assistantsUri([OpenAIListAssistantsQuery? query]) {
    return routes.assistantsUri(query);
  }

  Uri assistantUri(String assistantId) {
    return routes.assistantUri(assistantId);
  }

  Uri get threadsUri => routes.threadsUri;

  Uri threadUri(String threadId) {
    return routes.threadUri(threadId);
  }

  Uri threadMessagesUri(
    String threadId, [
    OpenAIListThreadMessagesQuery? query,
  ]) {
    return routes.threadMessagesUri(threadId, query);
  }

  Uri threadMessageUri(String threadId, String messageId) {
    return routes.threadMessageUri(threadId, messageId);
  }

  Uri threadRunsUri(String threadId, [OpenAIListRunsQuery? query]) {
    return routes.threadRunsUri(threadId, query);
  }

  Uri threadRunUri(String threadId, String runId) {
    return routes.threadRunUri(threadId, runId);
  }

  Uri cancelThreadRunUri(String threadId, String runId) {
    return routes.cancelThreadRunUri(threadId, runId);
  }

  Uri submitThreadRunToolOutputsUri(String threadId, String runId) {
    return routes.submitThreadRunToolOutputsUri(threadId, runId);
  }

  Uri createThreadAndRunUri() {
    return routes.createThreadAndRunUri();
  }

  Uri threadRunStepsUri(
    String threadId,
    String runId, [
    OpenAIListRunStepsQuery? query,
  ]) {
    return routes.threadRunStepsUri(threadId, runId, query);
  }

  Uri threadRunStepUri(String threadId, String runId, String stepId) {
    return routes.threadRunStepUri(threadId, runId, stepId);
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
    return routes.requireAssistantId(value, parameterName: parameterName);
  }

  String requireThreadId(
    String value, {
    required String parameterName,
  }) {
    return routes.requireThreadId(value, parameterName: parameterName);
  }

  String requireMessageId(
    String value, {
    required String parameterName,
  }) {
    return routes.requireMessageId(value, parameterName: parameterName);
  }

  String requireRunId(
    String value, {
    required String parameterName,
  }) {
    return routes.requireRunId(value, parameterName: parameterName);
  }

  String requireStepId(
    String value, {
    required String parameterName,
  }) {
    return routes.requireStepId(value, parameterName: parameterName);
  }
}
