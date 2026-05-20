import 'deepseek_option_resolver.dart';
import 'openai_family_common_option_resolver.dart';
import 'openai_family_option_resolver_base.dart';
import 'openai_family_profile.dart';
import 'openrouter_option_resolver.dart';
import 'xai_option_resolver.dart';

export 'openai_family_option_resolver_base.dart'
    show OpenAIFamilyOptionResolver;
export '../language/openai_family_shared_response_format.dart'
    show resolveOpenAIFamilySharedResponseFormat;
export 'openrouter_model_id_policy.dart' show resolveOpenRouterOnlineModelId;

OpenAIFamilyOptionResolver openAIFamilyOptionResolverFor(
  OpenAIFamilyProfile profile,
) {
  return switch (profile) {
    DeepSeekProfile() => const DeepSeekOptionResolver(),
    OpenRouterProfile() => const OpenRouterOptionResolver(),
    XAIProfile() => const XAIOptionResolver(),
    _ => const CommonOpenAIOptionResolver(),
  };
}
