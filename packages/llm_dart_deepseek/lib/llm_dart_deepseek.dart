library;

export 'src/config/deepseek_config.dart';
export 'src/client/deepseek_client.dart';
export 'src/provider/deepseek_provider.dart';
export 'src/chat/deepseek_chat.dart';
export 'src/models/deepseek_models.dart';
export 'src/http/deepseek_dio_strategy.dart';
export 'src/error/deepseek_error_handler.dart';
export 'src/completion/deepseek_completion.dart';
export 'src/factory/deepseek_provider_factory.dart'
    show DeepSeekProviderFactory, registerDeepSeekProvider;

// Vercel AI-style facade exports (model-centric API).
export 'src/facade/deepseek_facade.dart'
    show DeepSeekProviderSettings, DeepSeek, createDeepSeek, deepseek;
