part of 'openai_completion_support.dart';

final class _OpenAICompletionResponseSupport {
  const _OpenAICompletionResponseSupport();

  CompletionResponse parseResponse(Map<String, dynamic> responseData) {
    final choices = responseData['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      return const CompletionResponse(text: '');
    }

    final message = choices.first['message'] as Map<String, dynamic>?;
    final text = message?['content'] as String? ?? '';

    UsageInfo? usage;
    final usageData = responseData['usage'] as Map<String, dynamic>?;
    if (usageData != null) {
      usage = UsageInfo.fromJson(usageData);
    }

    return CompletionResponse(text: text, usage: usage);
  }

  List<String> parseStreamDeltas(
    OpenAIClient client,
    String chunk,
  ) {
    final deltas = <String>[];
    final jsonList = client.parseSSEChunk(chunk);
    if (jsonList.isEmpty) {
      return deltas;
    }

    for (final json in jsonList) {
      final choices = json['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        continue;
      }

      final choice = choices.first as Map<String, dynamic>;
      final delta = choice['delta'] as Map<String, dynamic>?;
      if (delta == null) {
        continue;
      }

      final content = delta['content'] as String?;
      if (content != null && content.isNotEmpty) {
        deltas.add(content);
      }
    }

    return deltas;
  }
}
