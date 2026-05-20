import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_family_common_option_resolver.dart';
import 'resolved_openai_chat_settings.dart';
import 'resolved_openai_options.dart';
import 'xai_options.dart';

final class XAIOptionResolver extends CommonOpenAIOptionResolver {
  const XAIOptionResolver();

  @override
  ResolvedOpenAIGenerateTextOptions resolveInvocationOptions({
    required ProviderInvocationOptions? options,
    required ResponseFormat? sharedResponseFormat,
    required ResolvedOpenAIChatModelSettings modelSettings,
  }) {
    if (options is XAIGenerateTextOptions) {
      return ResolvedOpenAIGenerateTextOptions(
        common: mergeOpenAIFamilyCommonOptions(
          common: options.common,
          sharedResponseFormat: sharedResponseFormat,
          modelSettings: modelSettings.common,
        ),
        xaiSearch: options.search,
      );
    }

    return super.resolveInvocationOptions(
      options: options,
      sharedResponseFormat: sharedResponseFormat,
      modelSettings: modelSettings,
    );
  }
}
