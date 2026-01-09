library;

import 'dart:convert';
import 'dart:io';

typedef JsonMap = Map<String, dynamic>;

List<String> readFixtureLines(String path) => File(path)
    .readAsLinesSync()
    .map((l) => l.trim())
    .where((l) => l.isNotEmpty)
    .toList(growable: false);

String stripSseDataPrefix(String line) {
  var trimmed = line.trim();
  if (!trimmed.startsWith('data:')) return trimmed;
  trimmed = trimmed.substring('data:'.length);
  if (trimmed.startsWith(' ')) trimmed = trimmed.substring(1);
  return trimmed;
}

Stream<String> sseStreamFromJsonLines(Iterable<String> lines) async* {
  for (final raw in lines) {
    final line = raw.trim();
    if (line.isEmpty) continue;

    if (line.startsWith('data:')) {
      yield '$line\n\n';
      continue;
    }
    yield 'data: $line\n\n';
  }
}

Stream<String> sseStreamFromChunkFile(String path) =>
    sseStreamFromJsonLines(readFixtureLines(path));

List<List<String>> splitJsonLinesIntoSessions(
  Iterable<String> lines, {
  required bool Function(JsonMap json) isTerminalEvent,
}) {
  final sessions = <List<String>>[];
  var current = <String>[];

  for (final raw in lines) {
    final line = raw.trim();
    if (line.isEmpty) continue;

    current.add(stripSseDataPrefix(line));

    final decoded = jsonDecode(stripSseDataPrefix(line));
    if (decoded is JsonMap && isTerminalEvent(decoded)) {
      sessions.add(current);
      current = <String>[];
    }
  }

  if (current.isNotEmpty) sessions.add(current);
  return sessions;
}

List<Stream<String>> sseStreamsFromChunkFileSplitByTerminalEvent(
  String path, {
  required bool Function(JsonMap json) isTerminalEvent,
}) {
  final lines = readFixtureLines(path);
  final sessions =
      splitJsonLinesIntoSessions(lines, isTerminalEvent: isTerminalEvent);
  return sessions.map(sseStreamFromJsonLines).toList(growable: false);
}

bool isOpenAIResponsesTerminalEvent(JsonMap json) {
  final type = json['type'];
  return type == 'response.completed' ||
      type == 'response.failed' ||
      type == 'response.cancelled' ||
      type == 'response.incomplete';
}

bool isAnthropicMessagesTerminalEvent(JsonMap json) =>
    json['type'] == 'message_stop';

({String text, String thinking})
    expectedOpenAIResponsesTextThinkingFromChunkFile(
  String path,
) {
  final text = StringBuffer();
  final thinking = StringBuffer();

  for (final line in readFixtureLines(path)) {
    final json = jsonDecode(stripSseDataPrefix(line));
    if (json is! JsonMap) continue;

    final type = json['type'];
    if (type == 'response.output_text.delta') {
      final delta = json['delta'];
      if (delta is String && delta.isNotEmpty) text.write(delta);
    }
    if (type == 'response.reasoning_summary_text.delta') {
      final delta = json['delta'];
      if (delta is String && delta.isNotEmpty) thinking.write(delta);
    }
  }

  return (text: text.toString(), thinking: thinking.toString());
}

String expectedOpenAIChatCompletionsTextFromChunkFile(String path) {
  final buf = StringBuffer();

  for (final line in readFixtureLines(path)) {
    final json = jsonDecode(stripSseDataPrefix(line));
    if (json is! JsonMap) continue;

    final choices = json['choices'];
    if (choices is! List || choices.isEmpty) continue;

    final choice = choices.first;
    if (choice is! JsonMap) continue;

    final delta = choice['delta'];
    if (delta is! JsonMap) continue;

    final content = delta['content'];
    if (content is String && content.isNotEmpty) buf.write(content);
  }

  return buf.toString();
}

({String text, String thinking}) expectedAnthropicTextThinkingFromChunkFile(
  String path,
) {
  final textBlocks = <String>[];
  final thinkingBlocks = <String>[];

  final blockTypes = <int, String>{};
  final textBuffers = <int, StringBuffer>{};
  final thinkingBuffers = <int, StringBuffer>{};

  for (final line in readFixtureLines(path)) {
    final json = jsonDecode(stripSseDataPrefix(line));
    if (json is! JsonMap) continue;

    final type = json['type'];

    if (type == 'content_block_start') {
      final index = json['index'];
      final block = json['content_block'];
      if (index is! int || block is! JsonMap) continue;

      final blockType = block['type'];
      if (blockType is! String) continue;
      blockTypes[index] = blockType;

      if (blockType == 'text') {
        textBuffers[index] = StringBuffer();
      } else if (blockType == 'thinking') {
        thinkingBuffers[index] = StringBuffer();
      } else if (blockType == 'redacted_thinking') {
        thinkingBlocks
            .add('[Redacted thinking content - encrypted for safety]');
      }

      continue;
    }

    if (type == 'content_block_delta') {
      final index = json['index'];
      final delta = json['delta'];
      if (index is! int || delta is! JsonMap) continue;

      final deltaType = delta['type'];
      if (deltaType == 'text_delta') {
        final t = delta['text'];
        if (t is String) (textBuffers[index] ??= StringBuffer()).write(t);
      }
      if (deltaType == 'thinking_delta') {
        final t = delta['thinking'];
        if (t is String) (thinkingBuffers[index] ??= StringBuffer()).write(t);
      }
      continue;
    }

    if (type == 'content_block_stop') {
      final index = json['index'];
      if (index is! int) continue;

      final blockType = blockTypes[index];
      if (blockType == 'text') {
        final text = textBuffers[index]?.toString() ?? '';
        if (text.isNotEmpty) textBlocks.add(text);
      } else if (blockType == 'thinking') {
        final thinking = thinkingBuffers[index]?.toString() ?? '';
        if (thinking.isNotEmpty) thinkingBlocks.add(thinking);
      }

      blockTypes.remove(index);
      textBuffers.remove(index);
      thinkingBuffers.remove(index);
    }
  }

  return (text: textBlocks.join('\n'), thinking: thinkingBlocks.join('\n\n'));
}
