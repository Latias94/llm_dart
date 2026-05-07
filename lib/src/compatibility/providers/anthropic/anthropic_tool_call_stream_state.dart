part of 'anthropic_chat_stream_support.dart';

final class AnthropicToolCallStreamState {
  String? id;
  String? name;
  final StringBuffer inputBuffer = StringBuffer();

  AnthropicToolCallStreamState({
    this.id,
    this.name,
  });

  bool get isComplete => id != null && name != null;
}
