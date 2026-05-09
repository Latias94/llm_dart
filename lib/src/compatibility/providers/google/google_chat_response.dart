import 'dart:convert';

import '../../../../core/capability.dart';
import '../../../../models/chat_models.dart';

/// Google chat response implementation.
final class GoogleChatResponse implements ChatResponse {
  final Map<String, dynamic> _rawResponse;

  GoogleChatResponse(this._rawResponse);

  @override
  String? get text {
    final parts = _extractParts(_rawResponse);
    if (parts == null) return null;

    final textParts = <String>[];
    for (final part in parts) {
      if (_isThought(part)) {
        continue;
      }

      final text = _extractText(part);
      if (text != null && text.isNotEmpty) {
        textParts.add(text);
      }
    }

    return textParts.isEmpty ? null : textParts.join('\n');
  }

  @override
  String? get thinking {
    final parts = _extractParts(_rawResponse);
    if (parts == null) return null;

    final thinkingParts = <String>[];
    for (final part in parts) {
      if (!_isThought(part)) {
        continue;
      }

      final text = _extractText(part);
      if (text != null && text.isNotEmpty) {
        thinkingParts.add(text);
      }
    }

    return thinkingParts.isEmpty ? null : thinkingParts.join('\n');
  }

  @override
  List<ToolCall>? get toolCalls => _extractToolCalls(_rawResponse);

  @override
  UsageInfo? get usage {
    final usageMetadata = _asMap(_rawResponse['usageMetadata']);
    if (usageMetadata == null) return null;

    return UsageInfo(
      promptTokens: _asInt(usageMetadata['promptTokenCount']),
      completionTokens: _asInt(usageMetadata['candidatesTokenCount']),
      totalTokens: _asInt(usageMetadata['totalTokenCount']),
      reasoningTokens: _asInt(usageMetadata['thoughtsTokenCount']),
    );
  }

  @override
  String toString() {
    final parts = <String>[];

    final thinkingContent = thinking;
    if (thinkingContent != null) {
      parts.add('Thinking: $thinkingContent');
    }

    final calls = toolCalls;
    if (calls != null) {
      parts.add(calls.map((call) => call.toString()).join('\n'));
    }

    final textContent = text;
    if (textContent != null) {
      parts.add(textContent);
    }

    return parts.join('\n');
  }
}

List<Map<String, dynamic>>? _extractParts(Map<String, dynamic> rawResponse) {
  final candidate = _firstCandidate(rawResponse);
  if (candidate == null) return null;

  final content = _asMap(candidate['content']);
  if (content == null) return null;

  final parts = content['parts'];
  if (parts is! List || parts.isEmpty) return null;

  final normalizedParts = <Map<String, dynamic>>[];
  for (final part in parts) {
    final partMap = _asMap(part);
    if (partMap != null) {
      normalizedParts.add(partMap);
    }
  }

  return normalizedParts.isEmpty ? null : normalizedParts;
}

Map<String, dynamic>? _firstCandidate(Map<String, dynamic> rawResponse) {
  final candidates = rawResponse['candidates'];
  if (candidates is! List || candidates.isEmpty) return null;

  return _asMap(candidates.first);
}

bool _isThought(Map<String, dynamic> part) {
  return part['thought'] as bool? ?? false;
}

String? _extractText(Map<String, dynamic> part) {
  final text = part['text'];
  if (text is String && text.isNotEmpty) {
    return text;
  }
  return null;
}

Map<String, dynamic>? _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

List<ToolCall>? _extractToolCalls(Map<String, dynamic> rawResponse) {
  final parts = _extractParts(rawResponse);
  if (parts == null) return null;

  final toolCalls = <ToolCall>[];
  for (final part in parts) {
    final functionCall = _asMap(part['functionCall']);
    if (functionCall == null) {
      continue;
    }

    final name = functionCall['name'] as String?;
    if (name == null || name.isEmpty) {
      continue;
    }

    final args = functionCall['args'];
    final arguments =
        args is Map ? jsonEncode(args) : jsonEncode(<String, dynamic>{});

    toolCalls.add(
      ToolCall(
        id: 'call_$name',
        callType: 'function',
        function: FunctionCall(name: name, arguments: arguments),
      ),
    );
  }

  return toolCalls.isEmpty ? null : toolCalls;
}

int? _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}
