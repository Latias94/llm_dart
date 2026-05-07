part of 'google_chat_request_builder.dart';

final class _GoogleChatRequestBodyToolSupport {
  final GoogleConfig config;
  final GoogleChatMessageCodec messageCodec;

  const _GoogleChatRequestBodyToolSupport({
    required this.config,
    required this.messageCodec,
  });

  void applyTools(
    Map<String, dynamic> body,
    List<Tool>? tools,
  ) {
    final effectiveTools = tools ?? config.tools;
    if (effectiveTools != null && effectiveTools.isNotEmpty) {
      body['tools'] = <Map<String, dynamic>>[
        <String, dynamic>{
          'functionDeclarations': effectiveTools
              .map((tool) => messageCodec.convertTool(tool))
              .toList(),
        },
      ];

      final effectiveToolChoice = config.toolChoice;
      if (effectiveToolChoice != null) {
        body['tool_config'] = messageCodec.convertToolChoice(
          effectiveToolChoice,
          effectiveTools,
        );
      }
    }
  }
}
