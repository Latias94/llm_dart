import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_family_common_option_resolver.dart';
import 'openai_provider_options_bag.dart';
import 'resolved_openai_chat_settings.dart';
import 'resolved_openai_options.dart';

final class DeepSeekOptionResolver extends CommonOpenAIOptionResolver {
  const DeepSeekOptionResolver();

  @override
  ResolvedOpenAIGenerateTextOptions resolveInvocationOptions({
    required ProviderInvocationOptions? options,
    required ResponseFormat? sharedResponseFormat,
    required ResolvedOpenAIChatModelSettings modelSettings,
  }) {
    final deepSeekOptions =
        resolveDeepSeekGenerateTextOptionsFromInvocation(options);
    if (deepSeekOptions != null) {
      return ResolvedOpenAIGenerateTextOptions(
        common: mergeOpenAIFamilyCommonOptions(
          common: deepSeekOptions.common,
          sharedResponseFormat: sharedResponseFormat,
          modelSettings: modelSettings.common,
          deepseekOptions: deepSeekOptions,
        ),
        deepseek: deepSeekOptions,
      );
    }

    return super.resolveInvocationOptions(
      options: options,
      sharedResponseFormat: sharedResponseFormat,
      modelSettings: modelSettings,
    );
  }
}
