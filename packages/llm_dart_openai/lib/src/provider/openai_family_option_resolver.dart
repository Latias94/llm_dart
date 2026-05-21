import 'openai_family_option_resolver_base.dart';
import 'openai_family_profile.dart';

export 'openai_family_option_resolver_base.dart'
    show OpenAIFamilyOptionResolver;
export '../language/openai_family_shared_response_format.dart'
    show resolveOpenAIFamilySharedResponseFormat;
export 'openrouter_model_id_policy.dart' show resolveOpenRouterOnlineModelId;

OpenAIFamilyOptionResolver openAIFamilyOptionResolverFor(
  OpenAIFamilyProfile profile,
) {
  return profile.optionResolver;
}
