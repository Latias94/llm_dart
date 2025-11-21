/// Legacy OpenAI-compatible provider defaults.
///
/// 新代码应优先使用 `OpenAICompatibleProviderProfiles`（来自
/// `llm_dart_openai_compatible` 包）获取更细粒度的模型/能力信息。
///
/// 这里仅为历史代码提供 `OpenAICompatibleDefaults` 的显式导入路径：
/// `import 'package:llm_dart/legacy/openai_compatible_defaults.dart';`.
library;

export '../core/provider_defaults.dart' show OpenAICompatibleDefaults;
