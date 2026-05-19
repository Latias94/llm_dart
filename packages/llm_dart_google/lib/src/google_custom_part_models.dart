part of 'google_custom_part.dart';

final class GoogleToolCallCustomPart extends GoogleCustomPart {
  final GoogleToolCallReplay replay;

  const GoogleToolCallCustomPart(this.replay);

  @override
  String get kind => GoogleToolCallReplay.kind;

  @override
  String get toolCallId => replay.toolCallId;

  @override
  String get toolName => replay.toolName;

  @override
  String get replayRole => 'assistant';

  @override
  ProviderMetadata? get providerMetadata => replay.providerMetadata;

  Map<String, Object?> get toolCall => replay.toolCall;

  @override
  Map<String, Object?> toJson() => replay.toJson();

  CustomContentPart toCustomContentPart({
    ProviderMetadata? providerMetadata,
  }) {
    return replay.toCustomContentPart(providerMetadata: providerMetadata);
  }

  CustomPromptPart toCustomPromptPart({
    ProviderMetadata? providerMetadata,
  }) {
    return replay.toCustomPromptPart(providerMetadata: providerMetadata);
  }

  CustomEvent toCustomEvent({
    ProviderMetadata? providerMetadata,
  }) {
    return replay.toCustomEvent(providerMetadata: providerMetadata);
  }
}

final class GoogleToolResponseCustomPart extends GoogleCustomPart {
  final GoogleToolResponseReplay replay;

  const GoogleToolResponseCustomPart(this.replay);

  @override
  String get kind => GoogleToolResponseReplay.kind;

  @override
  String get toolCallId => replay.toolCallId;

  @override
  String get toolName => replay.toolName;

  @override
  String get replayRole => 'assistant';

  @override
  ProviderMetadata? get providerMetadata => replay.providerMetadata;

  Map<String, Object?> get toolResponse => replay.toolResponse;

  @override
  Map<String, Object?> toJson() => replay.toJson();

  CustomContentPart toCustomContentPart({
    ProviderMetadata? providerMetadata,
  }) {
    return replay.toCustomContentPart(providerMetadata: providerMetadata);
  }

  CustomPromptPart toCustomPromptPart({
    ProviderMetadata? providerMetadata,
  }) {
    return replay.toCustomPromptPart(providerMetadata: providerMetadata);
  }

  CustomEvent toCustomEvent({
    ProviderMetadata? providerMetadata,
  }) {
    return replay.toCustomEvent(providerMetadata: providerMetadata);
  }
}

final class GoogleFunctionResponseCustomPart extends GoogleCustomPart {
  final GoogleFunctionResponseReplay replay;

  const GoogleFunctionResponseCustomPart(this.replay);

  @override
  String get kind => GoogleFunctionResponseReplay.kind;

  @override
  String get toolCallId => replay.toolCallId;

  @override
  String get toolName => replay.toolName;

  @override
  String get replayRole => 'tool';

  @override
  ProviderMetadata? get providerMetadata => replay.providerMetadata;

  String? get functionCallId => replay.functionCallId;

  Object? get response => replay.response;

  List<GeneratedFile> get files => replay.files;

  @override
  Map<String, Object?> toJson() => replay.toJson();

  CustomContentPart toCustomContentPart({
    ProviderMetadata? providerMetadata,
  }) {
    return replay.toCustomContentPart(providerMetadata: providerMetadata);
  }

  CustomPromptPart toCustomPromptPart({
    ProviderMetadata? providerMetadata,
  }) {
    return replay.toCustomPromptPart(providerMetadata: providerMetadata);
  }

  CustomEvent toCustomEvent({
    ProviderMetadata? providerMetadata,
  }) {
    return replay.toCustomEvent(providerMetadata: providerMetadata);
  }
}
