library;

export 'src/config/phind_config.dart';
export 'src/http/phind_dio_strategy.dart';
export 'src/client/phind_client.dart';
export 'src/chat/phind_chat.dart';
export 'src/provider/phind_provider.dart';
export 'src/factory/phind_provider_factory.dart'
    show PhindProviderFactory, registerPhindProvider;

// Vercel AI-style facade exports (model-centric API).
export 'src/facade/phind_facade.dart'
    show PhindProviderSettings, Phind, createPhind, phind;
