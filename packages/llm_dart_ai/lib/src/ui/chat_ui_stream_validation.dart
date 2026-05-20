import 'chat_ui_message.dart';

enum ChatUiMessageMetadataValidationPhase {
  start,
  patch,
  finish,
}

final class ChatUiMessageMetadataValidationContext {
  final ChatUiMessageMetadataValidationPhase phase;
  final String messageId;
  final Map<String, Object?> currentMetadata;
  final Map<String, Object?> patch;
  final Map<String, Object?> nextMetadata;

  ChatUiMessageMetadataValidationContext({
    required this.phase,
    required this.messageId,
    required Map<String, Object?> currentMetadata,
    required Map<String, Object?> patch,
    required Map<String, Object?> nextMetadata,
  })  : currentMetadata = Map.unmodifiable(currentMetadata),
        patch = Map.unmodifiable(patch),
        nextMetadata = Map.unmodifiable(nextMetadata);
}

typedef ChatUiMessageMetadataValidator = void Function(
  ChatUiMessageMetadataValidationContext context,
);

final class ChatUiDataPartValidationContext {
  final ChatUiMessage message;
  final DataUiPart<Object?> part;
  final bool isTransient;

  const ChatUiDataPartValidationContext({
    required this.message,
    required this.part,
    required this.isTransient,
  });
}

typedef ChatUiDataPartValidator = void Function(
  ChatUiDataPartValidationContext context,
);

final class ChatUiStreamValidator {
  final ChatUiMessageMetadataValidator? messageMetadataValidator;
  final ChatUiDataPartValidator? dataPartValidator;

  const ChatUiStreamValidator({
    this.messageMetadataValidator,
    this.dataPartValidator,
  });

  void validateMessageMetadataPatch({
    required ChatUiMessageMetadataValidationPhase phase,
    required ChatUiMessage message,
    required String messageId,
    required Map<String, Object?> patch,
  }) {
    final validator = messageMetadataValidator;
    if (validator == null || patch.isEmpty) {
      return;
    }

    final currentMetadata = message.metadata;
    final nextMetadata = <String, Object?>{
      ...currentMetadata,
      ...patch,
    };

    validator(
      ChatUiMessageMetadataValidationContext(
        phase: phase,
        messageId: messageId,
        currentMetadata: currentMetadata,
        patch: patch,
        nextMetadata: nextMetadata,
      ),
    );
  }

  void validateDataPart(
    DataUiPart<Object?> part, {
    required ChatUiMessage message,
    required bool isTransient,
  }) {
    final validator = dataPartValidator;
    if (validator == null) {
      return;
    }

    validator(
      ChatUiDataPartValidationContext(
        message: message,
        part: part,
        isTransient: isTransient,
      ),
    );
  }
}
