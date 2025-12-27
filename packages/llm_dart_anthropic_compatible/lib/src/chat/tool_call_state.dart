part of 'package:llm_dart_anthropic_compatible/chat.dart';

/// Helper class to track tool call state across multiple streaming events.
///
/// Anthropic's streaming API splits tool call data across events:
/// - content_block_start: provides id and name
/// - content_block_delta: provides partial_json chunks (multiple events)
/// - content_block_stop: signals completion (no data)
class _ToolCallState {
  String? id;
  String? name;
  final StringBuffer inputBuffer = StringBuffer();
  bool prefilledInput = false;
  bool emitted = false;

  bool get isComplete => id != null && name != null;
}
