import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'middleware.dart';
import 'transformed_chat_response.dart';

typedef TextTransform = String Function(String text);

String _defaultJsonTransform(String text) {
  var out = text;
  out = out.replaceFirst(RegExp(r'^```(?:json)?\s*\n?'), '');
  out = out.replaceFirst(RegExp(r'\n?```\s*$'), '');
  return out.trim();
}

/// Extracts JSON from text by stripping markdown fences.
///
/// This aligns with Vercel AI SDK's `extractJsonMiddleware`.
class ExtractJsonMiddleware extends LanguageModelMiddleware {
  final TextTransform transform;
  final bool _hasCustomTransform;

  ExtractJsonMiddleware({TextTransform? transform})
      : transform = transform ?? _defaultJsonTransform,
        _hasCustomTransform = transform != null;

  @override
  Future<ChatResponse> chat(
    ChatMiddlewareContext context,
    ChatMiddlewareNext next,
  ) async {
    final response = await next(context);
    final raw = response.text;
    if (raw == null || raw.isEmpty) return response;

    final transformed = transform(raw);
    if (transformed == raw) return response;

    ChatMessage? assistant;
    if (response is ChatResponseWithAssistantMessage) {
      final m = response.assistantMessage;
      assistant = ChatMessage(
        role: m.role,
        messageType: m.messageType,
        content: transform(m.content),
        name: m.name,
        protocolPayloads: m.protocolPayloads,
        providerOptions: m.providerOptions,
      );
    }

    return transformedChatResponse(
      response,
      text: transformed,
      assistantMessage: assistant,
    );
  }

  @override
  Stream<LLMStreamPart> stream(
    ChatStreamMiddlewareContext context,
    ChatStreamMiddlewareNext next,
  ) async* {
    const suffixBufferSize = 12;

    final textBlockStates = <String, _JsonTextBlockState>{};
    final textBlockOrder = <String>[];

    _JsonTextBlockState stateForId(String id) {
      return textBlockStates.putIfAbsent(
        id,
        () {
          textBlockOrder.add(id);
          return _JsonTextBlockState(
            startEvent: LLMTextStartPart(blockId: id),
            phase:
                _hasCustomTransform ? _JsonPhase.buffering : _JsonPhase.prefix,
          );
        },
      );
    }

    void emitStartIfNeeded(
        _JsonTextBlockState state, StreamController<LLMStreamPart> c) {
      if (state.startEmitted) return;
      state.startEmitted = true;
      c.add(state.startEvent);
    }

    Future<void> flushBlock(
      String id,
      StreamController<LLMStreamPart> controller, {
      Map<String, dynamic>? providerMetadata,
      bool emitEnd = false,
    }) async {
      final state = textBlockStates.remove(id);
      if (state == null) return;

      emitStartIfNeeded(state, controller);

      var remaining = state.buffer;
      if (state.phase == _JsonPhase.buffering) {
        remaining = transform(remaining);
      } else if (state.prefixStripped) {
        remaining =
            remaining.replaceFirst(RegExp(r'\n?```\s*$'), '').trimRight();
      } else {
        remaining = transform(remaining);
      }

      if (remaining.isNotEmpty) {
        controller.add(
          LLMTextDeltaPart(
            remaining,
            blockId: id,
          ),
        );
        state.emitted.write(remaining);
      }

      if (emitEnd) {
        controller.add(
          LLMTextEndPart(
            state.emitted.toString(),
            blockId: id,
            providerMetadata: providerMetadata,
          ),
        );
      }
    }

    final controller = StreamController<LLMStreamPart>(sync: true);
    Future<void> pump() async {
      try {
        await for (final part in next(context)) {
          switch (part) {
            case LLMTextStartPart(blockId: final blockId):
              final id = (blockId == null || blockId.isEmpty) ? '1' : blockId;
              final state = textBlockStates[id];
              if (state == null) {
                textBlockStates[id] = _JsonTextBlockState(
                  startEvent: LLMTextStartPart(
                    blockId: id,
                    providerMetadata: part.providerMetadata,
                  ),
                  phase: _hasCustomTransform
                      ? _JsonPhase.buffering
                      : _JsonPhase.prefix,
                );
                textBlockOrder.add(id);
              } else {
                state.startEvent = LLMTextStartPart(
                  blockId: id,
                  providerMetadata: part.providerMetadata,
                );
              }

            case LLMTextDeltaPart(:final delta, blockId: final blockId):
              final id = (blockId == null || blockId.isEmpty) ? '1' : blockId;
              final state = stateForId(id);
              state.buffer += delta;

              if (state.phase == _JsonPhase.buffering) {
                continue;
              }

              if (state.phase == _JsonPhase.prefix) {
                final buf = state.buffer;

                if (buf.isNotEmpty && !buf.startsWith('`')) {
                  state.phase = _JsonPhase.streaming;
                  emitStartIfNeeded(state, controller);
                } else if (buf.startsWith('```')) {
                  if (buf.contains('\n')) {
                    final match = RegExp(r'^```(?:json)?\s*\n').firstMatch(buf);
                    if (match != null) {
                      final stripped = buf.substring(match.group(0)!.length);
                      state.buffer = stripped;
                      state.prefixStripped = true;
                      state.phase = _JsonPhase.streaming;
                      emitStartIfNeeded(state, controller);
                    } else {
                      state.phase = _JsonPhase.streaming;
                      emitStartIfNeeded(state, controller);
                    }
                  } else {
                    continue;
                  }
                } else if (buf.length >= 3 && !buf.startsWith('```')) {
                  state.phase = _JsonPhase.streaming;
                  emitStartIfNeeded(state, controller);
                }
              }

              if (state.phase == _JsonPhase.streaming) {
                final buf = state.buffer;
                if (buf.length > suffixBufferSize) {
                  final toStream =
                      buf.substring(0, buf.length - suffixBufferSize);
                  final kept = buf.substring(buf.length - suffixBufferSize);
                  state.buffer = kept;

                  emitStartIfNeeded(state, controller);
                  controller.add(LLMTextDeltaPart(toStream, blockId: id));
                  state.emitted.write(toStream);
                }
              }

            case LLMTextEndPart(blockId: final blockId):
              final id = (blockId == null || blockId.isEmpty) ? '1' : blockId;
              await flushBlock(
                id,
                controller,
                providerMetadata: part.providerMetadata,
                emitEnd: true,
              );

            case LLMFinishPart():
              for (final id in List<String>.from(textBlockOrder)) {
                if (!textBlockStates.containsKey(id)) continue;
                await flushBlock(id, controller, emitEnd: true);
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

enum _JsonPhase { prefix, streaming, buffering }

class _JsonTextBlockState {
  LLMTextStartPart startEvent;
  _JsonPhase phase;
  String buffer = '';
  bool prefixStripped = false;
  bool startEmitted = false;
  final StringBuffer emitted = StringBuffer();

  _JsonTextBlockState({
    required this.startEvent,
    required this.phase,
  });
}
