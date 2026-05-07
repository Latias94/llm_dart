import '../../../../core/capability.dart';
import '../../../../models/chat_models.dart';
import '../../../../models/audio_models.dart';
import '../../../../models/tool_models.dart';
import '../../../../models/image_models.dart';
import '../../../../models/file_models.dart';
import '../../../../models/moderation_models.dart';
import '../../../../providers/openai/config.dart';
import 'assistant_capability.dart';
import 'assistant_models.dart';
import 'assistants.dart';
import 'audio.dart';
import 'chat.dart';
import 'client.dart';
import 'completion.dart';
import 'embeddings.dart';
import 'files.dart';
import 'images.dart';
import 'models.dart';
import 'moderation.dart';
import 'openai_provider_support.dart';
import 'provider_chat_facade.dart';
import 'responses.dart';

part 'provider_compat_assistants.dart';
part 'provider_compat_audio.dart';
part 'provider_compat_chat.dart';
part 'provider_compat_completion.dart';
part 'provider_compat_embeddings.dart';
part 'provider_compat_files.dart';
part 'provider_compat_helpers.dart';
part 'provider_compat_images.dart';
part 'provider_compat_models.dart';
part 'provider_compat_moderation.dart';
part 'provider_compat_provider_capabilities.dart';

/// Compatibility-first root OpenAI provider shell.
///
/// New shared-capability mainlines should prefer the package-owned modern
/// surfaces in `llm_dart_openai` where possible. This root provider remains
/// the migration-era adapter that still hosts residual legacy capability
/// modules and compatibility-facing helper APIs.
class OpenAIProvider
    with
        OpenAIProviderCapabilitiesMixin,
        OpenAIProviderChatMixin,
        OpenAIProviderEmbeddingsMixin,
        OpenAIProviderAudioMixin,
        OpenAIProviderImagesMixin,
        OpenAIProviderFilesMixin,
        OpenAIProviderModelsMixin,
        OpenAIProviderModerationMixin,
        OpenAIProviderAssistantsMixin,
        OpenAIProviderCompletionMixin,
        OpenAIProviderHelpersMixin
    implements
        ChatCapability,
        EmbeddingCapability,
        AudioCapability,
        ImageGenerationCapability,
        FileManagementCapability,
        ModelListingCapability,
        ModerationCapability,
        AssistantCapability,
        CompletionCapability,
        ProviderCapabilities {
  @override
  final OpenAIClient _client;
  final OpenAIConfig config;

  late final OpenAIChat _chat;
  @override
  late final OpenAIProviderChatFacade _chatFacade;
  @override
  late final OpenAIEmbeddings _embeddings;
  @override
  late final OpenAIAudio _audio;
  @override
  late final OpenAIImages _images;
  @override
  late final OpenAIFiles _files;
  @override
  late final OpenAIModels _models;
  @override
  late final OpenAIModeration _moderation;
  @override
  late final OpenAIAssistants _assistants;
  @override
  late final OpenAICompletion _completion;
  @override
  late final OpenAIResponses? _responses;
  @override
  late final OpenAIProviderSupport _support;

  OpenAIProvider(this.config) : _client = OpenAIClient(config) {
    _chat = OpenAIChat(_client, config);
    _embeddings = OpenAIEmbeddings(_client, config);
    _audio = OpenAIAudio(_client, config);
    _images = OpenAIImages(_client, config);
    _files = OpenAIFiles(_client, config);
    _models = OpenAIModels(_client, config);
    _moderation = OpenAIModeration(_client, config);
    _assistants = OpenAIAssistants(_client, config);
    _completion = OpenAICompletion(_client, config);

    _responses =
        config.useResponsesAPI ? OpenAIResponses(_client, config) : null;

    _chatFacade = OpenAIProviderChatFacade(
      config: config,
      chat: _chat,
      responses: _responses,
    );
    _support = OpenAIProviderSupport(
      config: config,
      client: _client,
      chat: _chat,
      embeddings: _embeddings,
      audio: _audio,
    );
  }

  String get providerName => 'OpenAI';

  @override
  String toString() {
    return 'OpenAIProvider('
        'model: ${config.model}, '
        'baseUrl: ${config.baseUrl}'
        ')';
  }
}
