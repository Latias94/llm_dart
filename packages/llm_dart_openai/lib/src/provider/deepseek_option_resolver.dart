import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'deepseek_options.dart';
import 'openai_family_common_option_resolver.dart';
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
    if (options is DeepSeekGenerateTextOptions) {
      return ResolvedOpenAIGenerateTextOptions(
        common: mergeOpenAIFamilyCommonOptions(
          common: options.common,
          sharedResponseFormat: sharedResponseFormat,
          modelSettings: modelSettings.common,
          deepseekOptions: options,
        ),
        deepseek: options,
      );
    }

    return super.resolveInvocationOptions(
      options: options,
      sharedResponseFormat: sharedResponseFormat,
      modelSettings: modelSettings,
    );
  }
}
