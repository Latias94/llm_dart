import 'dart:convert';

import '../../../../core/capability.dart';
import '../../../../models/chat_models.dart';

part 'google_chat_response_part_support.dart';
part 'google_chat_response_content_support.dart';
part 'google_chat_response_stringify_support.dart';
part 'google_chat_response_tool_support.dart';
part 'google_chat_response_usage_support.dart';

/// Google chat response implementation.
final class GoogleChatResponse implements ChatResponse {
  final Map<String, dynamic> _rawResponse;

  static const _contentSupport = _GoogleChatResponseContentSupport();
  static const _stringifySupport = _GoogleChatResponseStringifySupport();
  static const _toolSupport = _GoogleChatResponseToolSupport();
  static const _usageSupport = _GoogleChatResponseUsageSupport();

  GoogleChatResponse(this._rawResponse);

  @override
  String? get text => _contentSupport.extractText(_rawResponse);

  @override
  String? get thinking => _contentSupport.extractThinking(_rawResponse);

  @override
  List<ToolCall>? get toolCalls => _toolSupport.extractToolCalls(_rawResponse);

  @override
  UsageInfo? get usage => _usageSupport.extractUsage(_rawResponse);

  @override
  String toString() => _stringifySupport.stringify(_rawResponse);
}
