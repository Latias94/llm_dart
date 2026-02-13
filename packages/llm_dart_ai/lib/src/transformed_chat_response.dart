import 'package:llm_dart_core/llm_dart_core.dart';

ChatResponse transformedChatResponse(
  ChatResponse inner, {
  String? text,
  String? thinking,
  ChatMessage? assistantMessage,
}) {
  final hasFinishReason = inner is ChatResponseWithFinishReason;
  final hasAssistantMessage = inner is ChatResponseWithAssistantMessage;
  final hasRequestMetadata = inner is ChatResponseWithRequestMetadata;
  final hasResponseMetadata = inner is ChatResponseWithResponseMetadata;

  var mask = 0;
  if (hasFinishReason) mask |= 1;
  if (hasAssistantMessage) mask |= 2;
  if (hasRequestMetadata) mask |= 4;
  if (hasResponseMetadata) mask |= 8;

  _TransformedChatResponseBase create(
    _TransformedChatResponseBase Function(
      ChatResponse inner, {
      String? text,
      String? thinking,
      ChatMessage? assistantMessage,
    }) ctor,
  ) =>
      ctor(
        inner,
        text: text,
        thinking: thinking,
        assistantMessage: assistantMessage,
      );

  return switch (mask) {
    0 => create(_T0.new),
    1 => create(_T1.new),
    2 => create(_T2.new),
    3 => create(_T3.new),
    4 => create(_T4.new),
    5 => create(_T5.new),
    6 => create(_T6.new),
    7 => create(_T7.new),
    8 => create(_T8.new),
    9 => create(_T9.new),
    10 => create(_T10.new),
    11 => create(_T11.new),
    12 => create(_T12.new),
    13 => create(_T13.new),
    14 => create(_T14.new),
    15 => create(_T15.new),
    _ => inner,
  };
}

abstract class _TransformedChatResponseBase extends ChatResponse {
  final ChatResponse inner;
  final String? _text;
  final String? _thinking;
  final ChatMessage? _assistantMessage;

  _TransformedChatResponseBase(
    this.inner, {
    String? text,
    String? thinking,
    ChatMessage? assistantMessage,
  })  : _text = text,
        _thinking = thinking,
        _assistantMessage = assistantMessage;

  @override
  String? get text => _text ?? inner.text;

  @override
  String? get thinking => _thinking ?? inner.thinking;

  @override
  List<ToolCall>? get toolCalls => inner.toolCalls;

  @override
  UsageInfo? get usage => inner.usage;

  @override
  Map<String, dynamic>? get providerMetadata => inner.providerMetadata;
}

mixin _WithFinishReason on _TransformedChatResponseBase
    implements ChatResponseWithFinishReason {
  @override
  LLMFinishReason? get finishReason =>
      (inner as ChatResponseWithFinishReason).finishReason;
}

mixin _WithAssistantMessage on _TransformedChatResponseBase
    implements ChatResponseWithAssistantMessage {
  @override
  ChatMessage get assistantMessage =>
      _assistantMessage ??
      (inner as ChatResponseWithAssistantMessage).assistantMessage;
}

mixin _WithRequestMetadata on _TransformedChatResponseBase
    implements ChatResponseWithRequestMetadata {
  @override
  LLMRequestMetadataPart? get requestMetadata =>
      (inner as ChatResponseWithRequestMetadata).requestMetadata;
}

mixin _WithResponseMetadata on _TransformedChatResponseBase
    implements ChatResponseWithResponseMetadata {
  @override
  LLMResponseMetadataPart? get responseMetadata =>
      (inner as ChatResponseWithResponseMetadata).responseMetadata;
}

class _T0 extends _TransformedChatResponseBase {
  _T0(super.inner, {super.text, super.thinking, super.assistantMessage});
}

class _T1 extends _TransformedChatResponseBase with _WithFinishReason {
  _T1(super.inner, {super.text, super.thinking, super.assistantMessage});
}

class _T2 extends _TransformedChatResponseBase with _WithAssistantMessage {
  _T2(super.inner, {super.text, super.thinking, super.assistantMessage});
}

class _T3 extends _TransformedChatResponseBase
    with _WithFinishReason, _WithAssistantMessage {
  _T3(super.inner, {super.text, super.thinking, super.assistantMessage});
}

class _T4 extends _TransformedChatResponseBase with _WithRequestMetadata {
  _T4(super.inner, {super.text, super.thinking, super.assistantMessage});
}

class _T5 extends _TransformedChatResponseBase
    with _WithFinishReason, _WithRequestMetadata {
  _T5(super.inner, {super.text, super.thinking, super.assistantMessage});
}

class _T6 extends _TransformedChatResponseBase
    with _WithAssistantMessage, _WithRequestMetadata {
  _T6(super.inner, {super.text, super.thinking, super.assistantMessage});
}

class _T7 extends _TransformedChatResponseBase
    with _WithFinishReason, _WithAssistantMessage, _WithRequestMetadata {
  _T7(super.inner, {super.text, super.thinking, super.assistantMessage});
}

class _T8 extends _TransformedChatResponseBase with _WithResponseMetadata {
  _T8(super.inner, {super.text, super.thinking, super.assistantMessage});
}

class _T9 extends _TransformedChatResponseBase
    with _WithFinishReason, _WithResponseMetadata {
  _T9(super.inner, {super.text, super.thinking, super.assistantMessage});
}

class _T10 extends _TransformedChatResponseBase
    with _WithAssistantMessage, _WithResponseMetadata {
  _T10(super.inner, {super.text, super.thinking, super.assistantMessage});
}

class _T11 extends _TransformedChatResponseBase
    with _WithFinishReason, _WithAssistantMessage, _WithResponseMetadata {
  _T11(super.inner, {super.text, super.thinking, super.assistantMessage});
}

class _T12 extends _TransformedChatResponseBase
    with _WithRequestMetadata, _WithResponseMetadata {
  _T12(super.inner, {super.text, super.thinking, super.assistantMessage});
}

class _T13 extends _TransformedChatResponseBase
    with _WithFinishReason, _WithRequestMetadata, _WithResponseMetadata {
  _T13(super.inner, {super.text, super.thinking, super.assistantMessage});
}

class _T14 extends _TransformedChatResponseBase
    with _WithAssistantMessage, _WithRequestMetadata, _WithResponseMetadata {
  _T14(super.inner, {super.text, super.thinking, super.assistantMessage});
}

class _T15 extends _TransformedChatResponseBase
    with
        _WithFinishReason,
        _WithAssistantMessage,
        _WithRequestMetadata,
        _WithResponseMetadata {
  _T15(super.inner, {super.text, super.thinking, super.assistantMessage});
}
