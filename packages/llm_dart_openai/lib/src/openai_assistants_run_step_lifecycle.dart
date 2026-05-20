import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_assistants_lifecycle_client_support.dart';
import 'openai_assistants_run_step_list_models.dart';
import 'openai_assistants_run_step_response_model.dart';
import 'openai_assistants_transport.dart';

final class OpenAIAssistantsRunStepLifecycle {
  final TransportClient transport;
  final OpenAIAssistantsTransportSupport requestSupport;

  const OpenAIAssistantsRunStepLifecycle({
    required this.transport,
    required this.requestSupport,
  });

  Future<OpenAIListRunStepsResponse> list(
    String threadId,
    String runId, {
    OpenAIListRunStepsQuery? query,
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) {
    return sendOpenAIAssistantsJsonModel(
      transport: transport,
      requestSupport: requestSupport,
      uri: requestSupport.threadRunStepsUri(threadId, runId, query),
      method: TransportMethod.get,
      responseName: 'thread run step list response',
      decode: (json) => OpenAIListRunStepsResponse.fromJson(json),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIRunStep> retrieve(
    String threadId,
    String runId,
    String stepId, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) {
    return sendOpenAIAssistantsJsonModel(
      transport: transport,
      requestSupport: requestSupport,
      uri: requestSupport.threadRunStepUri(threadId, runId, stepId),
      method: TransportMethod.get,
      responseName: 'thread run step retrieve response',
      decode: (json) => OpenAIRunStep.fromJson(json),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }
}
