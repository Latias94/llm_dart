import '../../../builder/llm_builder.dart';
import '../../../core/capability.dart';
import '../../../core/web_search.dart';
import '../../../models/chat_models.dart';
import '../../../models/tool_models.dart';
import '../../../providers/openai/builtin_tools.dart';
import '../../../providers/openai/provider.dart';
import '../config/legacy_config_keys.dart';
import '../config/legacy_provider_options.dart';
import '../providers/openai/assistant_capability.dart';
import '../web_search_presets.dart';
import 'llm_builder_legacy_provider_options.dart';

part 'openai_builder_builds.dart';
part 'openai_builder_presets.dart';
part 'openai_builder_provider_options.dart';
part 'openai_builder_responses_tools.dart';

/// Compatibility-only OpenAI builder DSL for the legacy root provider surface.
///
/// This builder remains public because the repository still keeps the old root
/// `OpenAIProvider` compatibility surface alive, especially for residual APIs
/// such as raw Responses lifecycle helpers.
///
/// New code should usually prefer the stable `AI.openai(...).chatModel(...)`
/// path plus typed provider-owned options from `package:llm_dart/openai.dart`.
class OpenAIBuilder
    with
        _OpenAIBuilderProviderOptions,
        _OpenAIBuilderResponsesTools,
        _OpenAIBuilderPresets,
        _OpenAIBuilderBuilds {
  @override
  final LLMBuilder _baseBuilder;

  OpenAIBuilder(this._baseBuilder);
}
