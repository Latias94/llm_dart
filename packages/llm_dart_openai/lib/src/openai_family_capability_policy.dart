import 'deepseek_capability_policy.dart';
import 'openai_family_capability_core.dart';
import 'openai_family_profile.dart';
import 'openrouter_capability_policy.dart';
import 'xai_capability_policy.dart';

export 'openai_family_capability_core.dart'
    show OpenAIFamilyCapabilityInput, OpenAIFamilyCapabilityPolicy;

OpenAIFamilyCapabilityPolicy openAIFamilyCapabilityPolicyFor(
  OpenAIFamilyProfile profile,
) {
  return switch (profile) {
    OpenAIProfile() => const OpenAICapabilityPolicy(),
    DeepSeekProfile() => const DeepSeekCapabilityPolicy(),
    OpenRouterProfile() => const OpenRouterCapabilityPolicy(),
    XAIProfile() => const XAICapabilityPolicy(),
    _ => const CompatibleOpenAICapabilityPolicy(),
  };
}
