import '../core/capability.dart';
import '../models/chat_models.dart';
import '../models/tool_models.dart';

/// Default chat settings applied via middleware.
///
/// This is conceptually similar to Vercel AI's `defaultSettingsMiddleware`,
/// but focused on prompt-level settings that can be safely applied at
/// call time without rebuilding providers.
class DefaultChatSettings {
  /// Default system prompt to prepend when no system message is present.
  final String? systemPrompt;

  /// Whether to only inject [systemPrompt] when there is no existing
  /// system message in the chat history.
  ///
  /// When false, the default system prompt will always be inserted as
  /// the first message, before any existing messages.
  final bool onlyWhenNoSystemMessage;

  /// Default tools to use when a call does not provide explicit tools.
  ///
  /// If the `ChatCallContext.tools` is null and this field is non-null,
  /// the middleware will supply these tools to the provider.
  final List<Tool>? defaultTools;

  const DefaultChatSettings({
    this.systemPrompt,
    this.onlyWhenNoSystemMessage = true,
    this.defaultTools,
  });

  DefaultChatSettings copyWith({
    String? systemPrompt,
    bool? onlyWhenNoSystemMessage,
    List<Tool>? defaultTools,
  }) {
    return DefaultChatSettings(
      systemPrompt: systemPrompt ?? this.systemPrompt,
      onlyWhenNoSystemMessage:
          onlyWhenNoSystemMessage ?? this.onlyWhenNoSystemMessage,
      defaultTools: defaultTools ?? this.defaultTools,
    );
  }
}

/// Create a chat middleware that applies default chat settings.
///
/// This middleware currently supports:
/// - Injecting a default system prompt when none is present.
/// - Supplying default tools when a call does not provide tools.
///
/// For provider-level numeric defaults (temperature, maxTokens, etc.),
/// prefer using `LLMBuilder` and `ProviderDefaults` so that providers
/// can configure HTTP parameters at construction time.
ChatMiddleware createDefaultChatSettingsMiddleware(
  DefaultChatSettings settings,
) {
  return ChatMiddleware(
    transform: (ctx) async {
      var messages = ctx.messages;

      // Inject default system prompt when configured.
      if (settings.systemPrompt != null) {
        final hasSystemMessage =
            messages.any((m) => m.role == ChatRole.system);

        if (!hasSystemMessage || !settings.onlyWhenNoSystemMessage) {
          messages = <ChatMessage>[
            ChatMessage.system(settings.systemPrompt!),
            ...messages,
          ];
        }
      }

      // Supply default tools when none are provided at call time.
      final tools = ctx.tools ?? settings.defaultTools;

      return ctx.copyWith(
        messages: messages,
        tools: tools,
      );
    },
  );
}

