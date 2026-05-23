import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_family_common_option_resolver.dart';
import 'openai_family_invocation_options.dart';
import 'resolved_openai_chat_settings.dart';
import 'resolved_openai_options.dart';

final class XAIOptionResolver extends CommonOpenAIOptionResolver {
  const XAIOptionResolver();

  @override
  ResolvedOpenAIGenerateTextOptions resolveInvocationOptions({
    required ProviderInvocationOptions? options,
    required ResponseFormat? sharedResponseFormat,
    required ResolvedOpenAIChatModelSettings modelSettings,
  }) {
    final xaiOptions = resolveXAIGenerateTextInvocationOptions(options);
    if (xaiOptions != null) {
      return ResolvedOpenAIGenerateTextOptions(
        common: mergeOpenAIFamilyCommonOptions(
          common: xaiOptions.common,
          sharedResponseFormat: sharedResponseFormat,
          modelSettings: modelSettings.common,
        ),
        xaiSearch: xaiOptions.search,
      );
    }

    return super.resolveInvocationOptions(
      options: options,
      sharedResponseFormat: sharedResponseFormat,
      modelSettings: modelSettings,
    );
  }
}
