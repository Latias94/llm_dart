import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'middleware.dart';
import 'transformed_chat_response.dart';

/// Extracts XML-tagged reasoning from text and exposes it as `thinking`.
///
/// This aligns with Vercel AI SDK's `extractReasoningMiddleware`.
class ExtractReasoningMiddleware extends LanguageModelMiddleware {
  final String tagName;
  final String separator;
  final bool startWithReasoning;

  const ExtractReasoningMiddleware({
    required this.tagName,
    this.separator = '\n',
    this.startWithReasoning = false,
  });

  @override
  Future<ChatResponse> chat(
    ChatMiddlewareContext context,
    ChatMiddlewareNext next,
  ) async {
    final response = await next(context);
    final raw = response.text;
    if (raw == null || raw.isEmpty) return response;

    final extraction = _extractReasoningFromText(
      raw,
      tagName: tagName,
      separator: separator,
      startWithReasoning: startWithReasoning,
    );

    if (!extraction.matched) return response;

    final existingThinking = response.thinking;
    final combinedThinking = _joinNonEmpty(
      existingThinking,
      extraction.reasoning,
      separator,
    );

    ChatMessage? assistant;
    if (response is ChatResponseWithAssistantMessage) {
      final m = response.assistantMessage;
      assistant = ChatMessage(
        role: m.role,
        messageType: m.messageType,
        content: extraction.text,
        name: m.name,
        protocolPayloads: m.protocolPayloads,
        providerOptions: m.providerOptions,
      );
    }

    return transformedChatResponse(
      response,
      text: extraction.text,
      thinking: combinedThinking,
      assistantMessage: assistant,
    );
  }

  @override
  Stream<LLMStreamPart> stream(
    ChatStreamMiddlewareContext context,
    ChatStreamMiddlewareNext next,
  ) async* {
    final openingTag = '<$tagName>';
    final closingTag = '</$tagName>';

    final states = <String, _ReasoningState>{};
    final order = <String>[];
    var nextReasoningIndex = 0;

    _ReasoningState stateForId(String id) {
      return states.putIfAbsent(id, () {
        order.add(id);
        return _ReasoningState(
          textId: id,
          isReasoning: startWithReasoning,
          reasoningIndex: startWithReasoning ? nextReasoningIndex++ : null,
        );
      });
    }

    String ensureReasoningId(_ReasoningState s) {
      if (s.reasoningIndex != null) return 'reasoning-${s.reasoningIndex}';
      s.reasoningIndex = nextReasoningIndex++;
      return 'reasoning-${s.reasoningIndex}';
    }

    void closeReasoningIfOpen(
      _ReasoningState s,
      StreamController<LLMStreamPart> controller,
    ) {
      if (s.reasoningIndex == null) return;
      final id = 'reasoning-${s.reasoningIndex}';
      controller.add(
        LLMReasoningEndPart(
          s.reasoningEmitted.toString(),
          blockId: id,
        ),
      );
      s.reasoningIndex = null;
      s.reasoningEmitted.clear();
    }

    void emitTextStartIfNeeded(
      _ReasoningState s,
      StreamController<LLMStreamPart> controller,
    ) {
      if (s.textStartEmitted) return;
      s.textStartEmitted = true;
      controller.add(
        s.delayedTextStart ??
            LLMTextStartPart(
              blockId: s.textId,
            ),
      );
      s.delayedTextStart = null;
    }

    void publish(
      _ReasoningState s,
      StreamController<LLMStreamPart> controller,
      String text,
    ) {
      if (text.isEmpty) return;

      final prefix = s.afterSwitch &&
              (s.isReasoning ? !s.isFirstReasoning : !s.isFirstText)
          ? separator
          : '';

      if (s.isReasoning) {
        final reasoningId = ensureReasoningId(s);
        if (s.afterSwitch || s.isFirstReasoning) {
          controller.add(LLMReasoningStartPart(blockId: reasoningId));
        }
        controller.add(
          LLMReasoningDeltaPart(
            '$prefix$text',
            blockId: reasoningId,
          ),
        );
        s.reasoningEmitted.write('$prefix$text');
        s.isFirstReasoning = false;
      } else {
        emitTextStartIfNeeded(s, controller);
        controller.add(
          LLMTextDeltaPart(
            '$prefix$text',
            blockId: s.textId,
          ),
        );
        s.textEmitted.write('$prefix$text');
        s.isFirstText = false;
      }

      s.afterSwitch = false;
    }

    void processBuffer(
      _ReasoningState s,
      StreamController<LLMStreamPart> controller,
    ) {
      while (true) {
        final nextTag = s.isReasoning ? closingTag : openingTag;
        final startIndex =
            _getPotentialStartIndex(s.buffer.toString(), nextTag);
        if (startIndex == null) {
          publish(s, controller, s.buffer.toString());
          s.buffer.clear();
          return;
        }

        final buf = s.buffer.toString();
        publish(s, controller, buf.substring(0, startIndex));

        final hasFullMatch = startIndex + nextTag.length <= buf.length;
        if (!hasFullMatch) {
          final kept = buf.substring(startIndex);
          s.buffer
            ..clear()
            ..write(kept);
          return;
        }

        final after = buf.substring(startIndex + nextTag.length);
        s.buffer
          ..clear()
          ..write(after);

        if (s.isReasoning) {
          final reasoningId = ensureReasoningId(s);
          if (s.isFirstReasoning) {
            controller.add(LLMReasoningStartPart(blockId: reasoningId));
          }
          closeReasoningIfOpen(s, controller);
        } else {
          // switching from text -> reasoning
          ensureReasoningId(s);
        }

        s.isReasoning = !s.isReasoning;
        s.afterSwitch = true;
      }
    }

    Future<void> flushTextBlock(
      String id,
      StreamController<LLMStreamPart> controller, {
      Map<String, dynamic>? providerMetadata,
      bool emitEnd = false,
    }) async {
      final s = states[id];
      if (s == null) return;

      processBuffer(s, controller);

      if (s.isReasoning) {
        // Best-effort: close reasoning at end of text block.
        closeReasoningIfOpen(s, controller);
        s.isReasoning = false;
      }

      if (!s.textStartEmitted) {
        emitTextStartIfNeeded(s, controller);
      }

      if (emitEnd) {
        controller.add(
          LLMTextEndPart(
            s.textEmitted.toString(),
            blockId: id,
            providerMetadata: providerMetadata,
          ),
        );
        states.remove(id);
      }
    }

    final controller = StreamController<LLMStreamPart>(sync: true);
    Future<void> pump() async {
      try {
        await for (final part in next(context)) {
          switch (part) {
            case LLMTextStartPart(blockId: final blockId):
              final id = (blockId == null || blockId.isEmpty) ? '1' : blockId;
              final s = stateForId(id);
              s.delayedTextStart = LLMTextStartPart(
                blockId: id,
                providerMetadata: part.providerMetadata,
              );

            case LLMTextDeltaPart(:final delta, blockId: final blockId):
              final id = (blockId == null || blockId.isEmpty) ? '1' : blockId;
              final s = stateForId(id);
              s.buffer.write(delta);
              processBuffer(s, controller);

            case LLMTextEndPart(blockId: final blockId):
              final id = (blockId == null || blockId.isEmpty) ? '1' : blockId;
              await flushTextBlock(
                id,
                controller,
                providerMetadata: part.providerMetadata,
                emitEnd: true,
              );

            case LLMFinishPart():
              for (final id in List<String>.from(order)) {
                if (!states.containsKey(id)) continue;
                await flushTextBlock(id, controller, emitEnd: true);
              }
              controller.add(part);

            default:
              controller.add(part);
          }
        }
      } catch (e, st) {
        controller.addError(e, st);
      } finally {
        await controller.close();
      }
    }

    unawaited(pump());
    yield* controller.stream;
  }
}

class _ReasoningState {
  final String textId;
  final StringBuffer buffer = StringBuffer();

  bool isReasoning;
  bool afterSwitch = false;
  bool isFirstReasoning = true;
  bool isFirstText = true;

  int? reasoningIndex;
  final StringBuffer reasoningEmitted = StringBuffer();
  final StringBuffer textEmitted = StringBuffer();

  LLMTextStartPart? delayedTextStart;
  bool textStartEmitted = false;

  _ReasoningState({
    required this.textId,
    required this.isReasoning,
    required this.reasoningIndex,
  });
}

int? _getPotentialStartIndex(String text, String searchedText) {
  if (searchedText.isEmpty) return null;

  final directIndex = text.indexOf(searchedText);
  if (directIndex != -1) return directIndex;

  for (var i = text.length - 1; i >= 0; i--) {
    final suffix = text.substring(i);
    if (searchedText.startsWith(suffix)) {
      return i;
    }
  }

  return null;
}

({bool matched, String reasoning, String text}) _extractReasoningFromText(
  String raw, {
  required String tagName,
  required String separator,
  required bool startWithReasoning,
}) {
  final openingTag = '<$tagName>';
  final closingTag = '</$tagName>';
  final text = startWithReasoning ? '$openingTag$raw' : raw;

  final regexp = RegExp(
    '${RegExp.escape(openingTag)}(.*?)${RegExp.escape(closingTag)}',
    dotAll: true,
  );
  final matches = regexp.allMatches(text).toList(growable: false);
  if (matches.isEmpty) return (matched: false, reasoning: '', text: raw);

  final reasoningText = matches.map((m) => m.group(1) ?? '').join(separator);

  var textWithoutReasoning = text;
  for (var i = matches.length - 1; i >= 0; i--) {
    final match = matches[i];
    final index = match.start;
    final full = match.group(0) ?? '';
    final before = textWithoutReasoning.substring(0, index);
    final after = textWithoutReasoning.substring(index + full.length);
    textWithoutReasoning = before +
        (before.isNotEmpty && after.isNotEmpty ? separator : '') +
        after;
  }

  if (startWithReasoning &&
      textWithoutReasoning.startsWith(openingTag) &&
      raw.isNotEmpty) {
    // Remove the synthetic opening tag if it survived (e.g., no closing tag).
    textWithoutReasoning = textWithoutReasoning.substring(openingTag.length);
  }

  return (
    matched: true,
    reasoning: reasoningText,
    text: textWithoutReasoning,
  );
}

String? _joinNonEmpty(String? a, String b, String separator) {
  final left = a?.trim();
  final right = b.trim();
  final hasLeft = left != null && left.isNotEmpty;
  final hasRight = right.isNotEmpty;
  if (!hasLeft && !hasRight) return null;
  if (!hasLeft) return right;
  if (!hasRight) return left;
  return '$left$separator$right';
}
