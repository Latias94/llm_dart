import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'chat_transport.dart';

final class DirectChatTransport implements ChatTransport {
  final LanguageModel model;

  const DirectChatTransport({
    required this.model,
  });

  @override
  Stream<ChatUiStreamChunk> sendMessages(ChatTransportRequest request) {
    return projectTextStreamEventStream(
      streamText(
        model: model,
        prompt: request.prompt,
        tools: request.options.tools,
        toolChoice: request.options.toolChoice,
        options: request.options.generateOptions,
        callOptions: request.options.callOptions,
        functionToolExecutor: request.options.functionToolExecutor,
        maxSteps: request.options.maxSteps,
        stopWhen: request.options.stopWhen,
        onStepStart: request.options.onStepStart,
        onStepFinish: request.options.onStepFinish,
        onToolStart: request.options.onToolStart,
        onToolFinish: request.options.onToolFinish,
        onFinish: request.options.onFinish,
        onChunk: request.options.onChunk,
        onError: request.options.onError,
      ),
      messageMetadata: request.options.metadata,
    );
  }

  @override
  Stream<ChatUiStreamChunk>? reconnect(String chatId) => null;
}
