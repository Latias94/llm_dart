import 'package:llm_dart_provider/llm_dart_provider.dart'
    show ModelError, ModelErrorKind;

/// Error thrown when a chat UI stream contains invalid or out-of-sequence
/// chunks.
final class ChatUiStreamError implements Exception {
  /// The chunk or event type that violated the UI stream state machine.
  final String chunkType;

  /// The part, tool call, or approval identifier associated with the error.
  final String chunkId;

  /// Human-readable diagnostic message.
  final String message;

  const ChatUiStreamError({
    required this.chunkType,
    required this.chunkId,
    required this.message,
  });

  ModelError toModelError() {
    return ModelError(
      kind: ModelErrorKind.stream,
      message: message,
      code: 'chat-ui-stream',
      details: {
        'chunkType': chunkType,
        'chunkId': chunkId,
      },
      originalType: runtimeType.toString(),
    );
  }

  @override
  String toString() {
    return 'ChatUiStreamError('
        'chunkType: $chunkType, '
        'chunkId: $chunkId, '
        'message: $message'
        ')';
  }
}
