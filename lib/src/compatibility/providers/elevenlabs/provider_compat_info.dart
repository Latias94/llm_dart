part of 'provider_compat.dart';

mixin _ElevenLabsProviderInfo {
  _ElevenLabsProviderInfoSupport get _providerInfo;

  String get providerName => _providerInfo.providerName;

  ElevenLabsProvider copyWith({
    String? apiKey,
    String? baseUrl,
    String? voiceId,
    String? model,
    Duration? timeout,
    double? stability,
    double? similarityBoost,
    double? style,
    bool? useSpeakerBoost,
  }) {
    return _providerInfo.copyWith(
      apiKey: apiKey,
      baseUrl: baseUrl,
      voiceId: voiceId,
      model: model,
      timeout: timeout,
      stability: stability,
      similarityBoost: similarityBoost,
      style: style,
      useSpeakerBoost: useSpeakerBoost,
    );
  }

  bool supportsCapability(Type capability) {
    return _providerInfo.supportsCapability(capability);
  }

  Map<String, dynamic> get info => _providerInfo.info;

  @override
  String toString() => _providerInfo.describeProvider();
}
