import '../../../../core/capability.dart';
import '../../../../models/chat_models.dart';
import '../../../../models/tool_models.dart';
import '../../../../models/image_models.dart';
import '../../../../providers/google/config.dart';
import 'client.dart';
import 'chat.dart';
import 'embeddings.dart';
import 'images.dart';
import 'tts.dart';

part 'provider_compat_chat.dart';
part 'provider_compat_embeddings.dart';
part 'provider_compat_images.dart';
part 'provider_compat_provider_capabilities.dart';
part 'provider_compat_tts.dart';

/// Compatibility-first root Google provider shell.
///
/// New shared-capability mainlines should prefer the package-owned modern
/// surfaces in `llm_dart_google` where possible. This root provider remains the
/// migration-era adapter that preserves legacy capability interfaces and the
/// residual Google-specific capability modules still hosted by the root
/// package.
class GoogleProvider
    with
        _GoogleProviderCapabilities,
        _GoogleProviderChat,
        _GoogleProviderEmbeddings,
        _GoogleProviderImages,
        _GoogleProviderTTS
    implements
        ChatCapability,
        EmbeddingCapability,
        ImageGenerationCapability,
        GoogleTTSCapability,
        ProviderCapabilities {
  final GoogleClient _client;
  @override
  final GoogleConfig config;

  // Capability modules.
  @override
  late final GoogleChat _chat;
  @override
  late final GoogleEmbeddings _embeddings;
  @override
  late final GoogleImages _images;
  @override
  late final GoogleTTS _tts;

  GoogleProvider(this.config) : _client = GoogleClient(config) {
    _chat = GoogleChat(_client, config);
    _embeddings = GoogleEmbeddings(_client, config);
    _images = GoogleImages(_client, config);
    _tts = GoogleTTS(_client, config);
  }
}
