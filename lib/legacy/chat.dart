// Legacy ChatMessage-based chat model exports.
//
// New code should prefer ModelMessage + ChatContentPart from
// `package:llm_dart/llm_dart.dart`. This library is provided for
// backwards compatibility with existing ChatMessage-based code and
// may be removed in a future major release.
library;

export 'package:llm_dart_core/llm_dart_core.dart'
    show
        ChatMessage,
        MessageType,
        TextMessage,
        ImageMessage,
        FileMessage,
        ImageUrlMessage,
        ToolUseMessage,
        ToolResultMessage;
