import 'openai_family_capability_core.dart';
import 'openai_family_profile.dart';

export 'openai_family_capability_core.dart'
    show OpenAIFamilyCapabilityInput, OpenAIFamilyCapabilityPolicy;

OpenAIFamilyCapabilityPolicy openAIFamilyCapabilityPolicyFor(
  OpenAIFamilyProfile profile,
) {
  return profile.capabilityPolicy;
}
