import '../core/config.dart';
import '../core/config_extensions.dart';
import 'llm_logger.dart';

/// Resolve the configured [LLMLogger] from an [LLMConfig].
LLMLogger resolveLogger(LLMConfig config) {
  return config.getExtension<LLMLogger>(LLMConfigKeys.logger) ??
      const NoopLLMLogger();
}
