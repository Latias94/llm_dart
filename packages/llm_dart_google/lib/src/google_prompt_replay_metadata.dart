import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_language_model_policy.dart';
import 'google_shared.dart';

final class GooglePromptPartMetadata {
  final bool thought;
  final String? thoughtSignature;
  final String? functionCallId;

  const GooglePromptPartMetadata({
    this.thought = false,
    this.thoughtSignature,
    this.functionCallId,
  });

  Map<String, Object?> encodeThoughtFields({
    bool forceThought = false,
  }) {
    return {
      if (forceThought || thought) 'thought': true,
      if (thoughtSignature != null) 'thoughtSignature': thoughtSignature,
    };
  }
}

ProviderMetadata? googlePromptPartProviderMetadata(PromptPart part) {
  return providerReplayMetadataFromOptions(part.providerOptions);
}

GooglePromptPartMetadata resolveGooglePromptPartMetadata(
  ProviderMetadata? metadata,
) {
  final primary = metadata?.namespace('google');
  final fallback = metadata?.namespace('vertex');
  final resolved = primary ?? fallback;

  return GooglePromptPartMetadata(
    thought: resolved?['thought'] == true,
    thoughtSignature: asString(resolved?['thoughtSignature']),
    functionCallId: asString(resolved?['functionCallId']),
  );
}

String? googleFunctionCallId(
  ProviderMetadata? primaryMetadata, [
  ProviderMetadata? fallbackMetadata,
]) {
  final primary = primaryMetadata?.namespace('google') ??
      primaryMetadata?.namespace('vertex');
  final fallback = fallbackMetadata?.namespace('google') ??
      fallbackMetadata?.namespace('vertex');
  return asString(primary?['functionCallId']) ??
      asString(fallback?['functionCallId']);
}

bool shouldReplayGoogleFunctionCallId(
  GoogleLanguageModelPolicy policy,
  String? functionCallId,
) {
  return policy.supportsFunctionCallIdReplay &&
      functionCallId != null &&
      functionCallId.isNotEmpty;
}
