import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart'
    as provider_utils;

/// Legacy HTTP provider base class。
///
/// 为保持向后兼容，继续暴露一个 BaseHttpProvider，但实际别名为
/// `llm_dart_provider_utils` 中的实现，避免两个不同定义产生行为分叉。
/// 新代码应直接依赖 provider_utils 中的 HTTP 工具。
@Deprecated(
  'Use DioClientFactory and BaseProviderDioStrategy in '
  'llm_dart_provider_utils instead of BaseHttpProvider.',
)
typedef BaseHttpProvider = provider_utils.BaseHttpProvider;
