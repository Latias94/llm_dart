// This middleware logs ChatMessage-based conversations flowing through the
// legacy ChatCapability surface. New code should prefer prompt-first helpers,
// but logging still works on the ChatMessage model for compatibility.
// ignore_for_file: deprecated_member_use

import 'package:logging/logging.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

/// Configuration options for the built-in logging middlewares.
class LoggingOptions {
  /// Whether to log basic request information (provider/model, message count).
  final bool logRequestInfo;

  /// Whether to log chat messages.
  final bool logMessages;

  /// Whether to log reasoning/thinking content when available.
  final bool logThinking;

  /// Whether to log tool calls.
  final bool logToolCalls;

  /// Whether to log token usage information.
  final bool logUsage;

  /// Whether to log provider-specific metadata.
  final bool logMetadata;

  /// Maximum number of characters to include when logging text fields.
  final int maxTextLength;

  /// Create default logging options.
  ///
  /// By default this logs provider/model, usage and warnings/metadata,
  /// but avoids logging full prompt/response text to reduce risk of
  /// leaking sensitive data.
  const LoggingOptions({
    this.logRequestInfo = true,
    this.logMessages = false,
    this.logThinking = false,
    this.logToolCalls = true,
    this.logUsage = true,
    this.logMetadata = true,
    this.maxTextLength = 200,
  });

  /// Create a copy with modified fields.
  LoggingOptions copyWith({
    bool? logRequestInfo,
    bool? logMessages,
    bool? logThinking,
    bool? logToolCalls,
    bool? logUsage,
    bool? logMetadata,
    int? maxTextLength,
  }) {
    return LoggingOptions(
      logRequestInfo: logRequestInfo ?? this.logRequestInfo,
      logMessages: logMessages ?? this.logMessages,
      logThinking: logThinking ?? this.logThinking,
      logToolCalls: logToolCalls ?? this.logToolCalls,
      logUsage: logUsage ?? this.logUsage,
      logMetadata: logMetadata ?? this.logMetadata,
      maxTextLength: maxTextLength ?? this.maxTextLength,
    );
  }
}

String _truncate(String value, int maxLength) {
  if (value.length <= maxLength) return value;
  return '${value.substring(0, maxLength)}...<${value.length - maxLength} more chars>';
}

String _safeMessagePreview(ChatMessage message, int maxLength) {
  final name = message.name != null ? ' (${message.name})' : '';
  final content = _truncate(message.content, maxLength);
  return '${message.role.name}$name: $content';
}

String _formatUsage(UsageInfo usage) {
  return usage.toString();
}

Map<String, dynamic>? _configMetadata(LLMConfig config) {
  // Surface optional caller-provided metadata if present.
  return config.getExtension<Map<String, dynamic>>(LLMConfigKeys.metadata);
}

/// Create a chat logging middleware.
///
/// This middleware logs high-level information about chat calls
/// (provider/model, usage, warnings, metadata) and can optionally
/// include prompt/response/thinking content depending on [options].
ChatMiddleware createChatLoggingMiddleware({
  Logger? logger,
  LoggingOptions options = const LoggingOptions(),
}) {
  final log = logger ?? Logger('LLMChatLoggingMiddleware');

  return ChatMiddleware(
    wrapChat: (next, ctx) async {
      if (options.logRequestInfo) {
        log.info(
          'chat request provider=${ctx.providerId} model=${ctx.model} '
          'messages=${ctx.messages.length}',
        );
      }

      if (options.logMessages) {
        for (final message in ctx.messages) {
          log.fine(_safeMessagePreview(message, options.maxTextLength));
        }
      }

      final configMeta = _configMetadata(ctx.config);
      if (options.logMetadata && configMeta != null && configMeta.isNotEmpty) {
        log.finer('chat request metadata=$configMeta');
      }

      final start = DateTime.now();
      try {
        final response = await next(ctx);
        final elapsed =
            DateTime.now().difference(start).inMilliseconds.toString();

        if (options.logUsage && response.usage != null) {
          log.info(
            'chat response provider=${ctx.providerId} model=${ctx.model} '
            'elapsedMs=$elapsed usage=${_formatUsage(response.usage!)}',
          );
        } else {
          log.info(
            'chat response provider=${ctx.providerId} model=${ctx.model} '
            'elapsedMs=$elapsed',
          );
        }

        if (options.logThinking && response.thinking != null) {
          log.finer(
            'chat thinking=${_truncate(response.thinking!, options.maxTextLength)}',
          );
        }

        if (options.logToolCalls && response.toolCalls != null) {
          log.finer(
            'chat toolCalls=${response.toolCalls}'
            ' (count=${response.toolCalls!.length})',
          );
        }

        if (options.logMetadata && response.metadata != null) {
          log.finer('chat metadata=${response.metadata}');
        }

        if (response.warnings.isNotEmpty) {
          for (final warning in response.warnings) {
            log.warning(
              'chat warning code=${warning.code} message=${warning.message} '
              'details=${warning.details}',
            );
          }
        }

        return response;
      } catch (e, st) {
        log.severe(
          'chat error provider=${ctx.providerId} model=${ctx.model} error=$e',
          e,
          st,
        );
        rethrow;
      }
    },
    wrapStream: (next, ctx) async* {
      if (options.logRequestInfo) {
        log.info(
          'chatStream request provider=${ctx.providerId} model=${ctx.model} '
          'messages=${ctx.messages.length}',
        );
      }

      final configMeta = _configMetadata(ctx.config);
      if (options.logMetadata && configMeta != null && configMeta.isNotEmpty) {
        log.finer('chatStream request metadata=$configMeta');
      }

      final start = DateTime.now();
      var totalText = 0;
      var totalThinking = 0;

      try {
        final stream = next(ctx);

        await for (final event in stream) {
          if (options.logMessages || options.logThinking) {
            if (event is TextDeltaEvent) {
              totalText += event.delta.length;
            } else if (event is ThinkingDeltaEvent) {
              totalThinking += event.delta.length;
            }
          }

          if (options.logToolCalls && event is ToolCallDeltaEvent) {
            log.finer('chatStream toolCallDelta=${event.toolCall}');
          }

          yield event;
        }

        final elapsed =
            DateTime.now().difference(start).inMilliseconds.toString();

        log.info(
          'chatStream completed provider=${ctx.providerId} model=${ctx.model} '
          'elapsedMs=$elapsed textChars=$totalText thinkingChars=$totalThinking',
        );
      } catch (e, st) {
        log.severe(
          'chatStream error provider=${ctx.providerId} model=${ctx.model} error=$e',
          e,
          st,
        );
        rethrow;
      }
    },
  );
}

/// Create an embedding logging middleware.
///
/// This middleware logs high-level information about embedding calls
/// (provider/model, input size) and can optionally include partial
/// input text depending on [options].
EmbeddingMiddleware createEmbeddingLoggingMiddleware({
  Logger? logger,
  LoggingOptions options = const LoggingOptions(),
}) {
  final log = logger ?? Logger('LLMEmbeddingLoggingMiddleware');

  return EmbeddingMiddleware(
    wrapEmbed: (next, ctx) async {
      if (options.logRequestInfo) {
        log.info(
          'embed request provider=${ctx.providerId} model=${ctx.model} '
          'inputCount=${ctx.input.length}',
        );
      }

      if (options.logMessages) {
        final previews = ctx.input
            .map((s) => _truncate(s, options.maxTextLength))
            .toList(growable: false);
        log.fine('embed inputPreview=$previews');
      }

      final configMeta = _configMetadata(ctx.config);
      if (options.logMetadata && configMeta != null && configMeta.isNotEmpty) {
        log.finer('embed request metadata=$configMeta');
      }

      final start = DateTime.now();
      try {
        final result = await next(ctx);
        final elapsed =
            DateTime.now().difference(start).inMilliseconds.toString();

        final dims = result.isNotEmpty ? result.first.length : 0;

        log.info(
          'embed response provider=${ctx.providerId} model=${ctx.model} '
          'elapsedMs=$elapsed vectorCount=${result.length} dimensions=$dims',
        );

        return result;
      } catch (e, st) {
        log.severe(
          'embed error provider=${ctx.providerId} model=${ctx.model} error=$e',
          e,
          st,
        );
        rethrow;
      }
    },
  );
}
