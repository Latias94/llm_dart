/// Legacy OpenAI helper APIs.
///
/// 这些方法是早期直接把其他服务当作 OpenAI 兼容端点来用的快捷函数，
/// 新代码应优先使用：
/// - `ai().openRouter()` / `ai().groq()` / `ai().deepseek()` 等新的 Builder
/// - 或 OpenAI-compatible provider 配置（`llm_dart_openai_compatible`）
///
/// 本文件仅通过 re-export 暴露这些已有的 helper，方便老代码显式
/// `import 'package:llm_dart/legacy/openai_legacy.dart';` 使用。
library;

export '../providers/openai/openai.dart'
    show
        createOpenRouterProvider,
        createGroqProvider,
        createDeepSeekProvider,
        createCopilotProvider,
        createTogetherProvider;
