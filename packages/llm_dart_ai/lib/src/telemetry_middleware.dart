import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'middleware.dart';
import 'prompt_input.dart';

typedef LanguageModelTelemetrySink = void Function(
  LanguageModelTelemetryEvent event,
);

sealed class LanguageModelTelemetryEvent {
  final DateTime timestamp;
  const LanguageModelTelemetryEvent(this.timestamp);
}

class CallOptionsSummary {
  final List<String> headerNamesLower;
  final List<String> bodyKeys;

  const CallOptionsSummary({
    required this.headerNamesLower,
    required this.bodyKeys,
  });

  bool get isEmpty => headerNamesLower.isEmpty && bodyKeys.isEmpty;
}

class PromptInputSummary {
  final String type; // 'messages' | 'promptIr'
  final int messageCount;
  final bool hasFileReferences;

  const PromptInputSummary({
    required this.type,
    required this.messageCount,
    required this.hasFileReferences,
  });
}

PromptInputSummary summarizePromptInput(StandardizedPromptInput input) {
  switch (input) {
    case StandardizedChatMessages(:final messages):
      return PromptInputSummary(
        type: 'messages',
        messageCount: messages.length,
        hasFileReferences: false,
      );
    case StandardizedPromptIr(:final prompt):
      return PromptInputSummary(
        type: 'promptIr',
        messageCount: prompt.messages.length,
        hasFileReferences: promptHasFileReferenceParts(prompt),
      );
  }
}

CallOptionsSummary summarizeCallOptions(LLMCallOptions callOptions) {
  final headerNamesLower = <String>[];
  final headers = callOptions.headers;
  if (headers != null && headers.isNotEmpty) {
    for (final key in headers.keys) {
      final lower = key.trim().toLowerCase();
      if (lower.isEmpty) continue;
      headerNamesLower.add(lower);
    }
    headerNamesLower.sort();
  }

  final bodyKeys = <String>[];
  final body = callOptions.body;
  if (body != null && body.isNotEmpty) {
    for (final key in body.keys) {
      final k = key.trim();
      if (k.isEmpty) continue;
      bodyKeys.add(k);
    }
    bodyKeys.sort();
  }

  return CallOptionsSummary(
    headerNamesLower: List<String>.unmodifiable(headerNamesLower),
    bodyKeys: List<String>.unmodifiable(bodyKeys),
  );
}

class LanguageModelChatStartEvent extends LanguageModelTelemetryEvent {
  final PromptInputSummary input;
  final int? toolsCount;
  final CallOptionsSummary callOptions;

  LanguageModelChatStartEvent({
    required DateTime timestamp,
    required this.input,
    required this.toolsCount,
    required this.callOptions,
  }) : super(timestamp);
}

class LanguageModelChatFinishEvent extends LanguageModelTelemetryEvent {
  final Duration elapsed;
  final LLMFinishReason? finishReason;
  final UsageInfo? usage;

  LanguageModelChatFinishEvent({
    required DateTime timestamp,
    required this.elapsed,
    required this.finishReason,
    required this.usage,
  }) : super(timestamp);
}

class LanguageModelChatErrorEvent extends LanguageModelTelemetryEvent {
  final Duration elapsed;
  final Object error;
  final StackTrace? stackTrace;

  LanguageModelChatErrorEvent({
    required DateTime timestamp,
    required this.elapsed,
    required this.error,
    required this.stackTrace,
  }) : super(timestamp);
}

class LanguageModelStreamStartEvent extends LanguageModelTelemetryEvent {
  final PromptInputSummary input;
  final int? toolsCount;
  final CallOptionsSummary callOptions;

  LanguageModelStreamStartEvent({
    required DateTime timestamp,
    required this.input,
    required this.toolsCount,
    required this.callOptions,
  }) : super(timestamp);
}

class LanguageModelStreamPartEvent extends LanguageModelTelemetryEvent {
  final String partType;

  LanguageModelStreamPartEvent({
    required DateTime timestamp,
    required this.partType,
  }) : super(timestamp);
}

class LanguageModelStreamFinishEvent extends LanguageModelTelemetryEvent {
  final Duration elapsed;
  final LLMFinishReason? finishReason;
  final UsageInfo? usage;

  LanguageModelStreamFinishEvent({
    required DateTime timestamp,
    required this.elapsed,
    required this.finishReason,
    required this.usage,
  }) : super(timestamp);
}

class LanguageModelStreamErrorEvent extends LanguageModelTelemetryEvent {
  final Duration elapsed;
  final Object error;
  final StackTrace? stackTrace;

  LanguageModelStreamErrorEvent({
    required DateTime timestamp,
    required this.elapsed,
    required this.error,
    required this.stackTrace,
  }) : super(timestamp);
}

/// Emits best-effort telemetry events for chat and streaming calls.
///
/// Safety notes:
/// - This middleware does NOT include message contents or header values.
/// - It only reports message/tool counts + callOptions header names/body keys.
class TelemetryMiddleware extends LanguageModelMiddleware {
  final LanguageModelTelemetrySink onEvent;

  const TelemetryMiddleware({
    required this.onEvent,
  });

  @override
  Future<ChatResponse> chat(
    ChatMiddlewareContext context,
    ChatMiddlewareNext next,
  ) async {
    final sw = Stopwatch()..start();
    onEvent(
      LanguageModelChatStartEvent(
        timestamp: DateTime.now().toUtc(),
        input: summarizePromptInput(context.input),
        toolsCount: context.tools?.length,
        callOptions: summarizeCallOptions(context.callOptions),
      ),
    );

    try {
      final response = await next(context);
      final finishReason = response is ChatResponseWithFinishReason
          ? response.finishReason
          : null;
      onEvent(
        LanguageModelChatFinishEvent(
          timestamp: DateTime.now().toUtc(),
          elapsed: sw.elapsed,
          finishReason: finishReason,
          usage: response.usage,
        ),
      );
      return response;
    } catch (e, st) {
      onEvent(
        LanguageModelChatErrorEvent(
          timestamp: DateTime.now().toUtc(),
          elapsed: sw.elapsed,
          error: e,
          stackTrace: st,
        ),
      );
      rethrow;
    }
  }

  @override
  Stream<LLMStreamPart> stream(
    ChatStreamMiddlewareContext context,
    ChatStreamMiddlewareNext next,
  ) async* {
    final sw = Stopwatch()..start();
    onEvent(
      LanguageModelStreamStartEvent(
        timestamp: DateTime.now().toUtc(),
        input: summarizePromptInput(context.input),
        toolsCount: context.tools?.length,
        callOptions: summarizeCallOptions(context.callOptions),
      ),
    );

    LLMFinishReason? finishReason;
    UsageInfo? usage;

    try {
      await for (final part in next(context)) {
        onEvent(
          LanguageModelStreamPartEvent(
            timestamp: DateTime.now().toUtc(),
            partType: part.runtimeType.toString(),
          ),
        );

        if (part is LLMFinishPart) {
          finishReason = part.finishReason ??
              (part.response is ChatResponseWithFinishReason
                  ? (part.response as ChatResponseWithFinishReason).finishReason
                  : null);
          usage = part.usage ?? part.response.usage;
        }

        yield part;
      }

      onEvent(
        LanguageModelStreamFinishEvent(
          timestamp: DateTime.now().toUtc(),
          elapsed: sw.elapsed,
          finishReason: finishReason,
          usage: usage,
        ),
      );
    } catch (e, st) {
      onEvent(
        LanguageModelStreamErrorEvent(
          timestamp: DateTime.now().toUtc(),
          elapsed: sw.elapsed,
          error: e,
          stackTrace: st,
        ),
      );
      rethrow;
    }
  }
}
