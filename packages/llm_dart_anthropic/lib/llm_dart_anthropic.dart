library;

export 'src/config/anthropic_config.dart';
export 'src/client/anthropic_client.dart';
export 'src/provider/anthropic_provider.dart';
export 'src/mcp/anthropic_mcp_models.dart';
export 'src/models/anthropic_models.dart';
export 'src/chat/anthropic_chat.dart';
export 'src/files/anthropic_files.dart';
export 'src/request/anthropic_request_builder.dart';
export 'src/http/anthropic_dio_strategy.dart';
export 'src/factory/anthropic_provider_factory.dart'
    show AnthropicProviderFactory, registerAnthropicProvider;

// Vercel AI-style facade exports (model-centric API).
export 'src/facade/anthropic_facade.dart'
    show
        AnthropicProviderSettings,
        Anthropic,
        AnthropicTools,
        createAnthropic,
        anthropic;
