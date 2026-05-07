import '../../../../core/capability.dart';
import '../../../../core/llm_error.dart';
import '../../../../models/audio_models.dart';
import '../../../../models/chat_models.dart';
import '../../../../models/tool_models.dart';
import '../../../../providers/elevenlabs/client.dart' show ElevenLabsClient;
import '../../../../providers/elevenlabs/config.dart';
import 'elevenlabs_audio_compat.dart' show ElevenLabsAudio;
import 'elevenlabs_models_compat.dart' show ElevenLabsModels;
import 'shell_support.dart';

part 'provider_compat_audio_shortcuts.dart';
part 'provider_compat_chat_support.dart';
part 'provider_compat_info_support.dart';
part 'provider_compat_audio.dart';
part 'provider_compat_chat.dart';
part 'provider_compat_info.dart';
part 'provider_compat_models.dart';

/// Compatibility-first root ElevenLabs provider shell.
///
/// New shared-capability mainlines should prefer the package-owned modern
/// surfaces in `llm_dart_community` where possible. This root provider remains
/// the migration-era adapter that preserves legacy audio capability interfaces,
/// fallback routing, and residual provider-shaped APIs such as voice catalogs,
/// realtime flows, and account/model helpers.
class ElevenLabsProvider
    with
        _ElevenLabsProviderChat,
        _ElevenLabsProviderAudio,
        _ElevenLabsProviderInfo,
        _ElevenLabsProviderModels
    implements ChatCapability, AudioCapability {
  final ElevenLabsConfig config;
  @override
  final ElevenLabsCompatShellSupport _compatShell;
  @override
  final _ElevenLabsUnsupportedChatSupport _chatSupport =
      const _ElevenLabsUnsupportedChatSupport();
  @override
  late final _ElevenLabsProviderAudioShortcuts _audioShortcuts =
      _ElevenLabsProviderAudioShortcuts(_compatShell);
  @override
  late final _ElevenLabsProviderInfoSupport _providerInfo =
      _ElevenLabsProviderInfoSupport(config: config);

  ElevenLabsProvider(this.config)
      : _compatShell = ElevenLabsCompatShellSupport(config: config);

  ElevenLabsClient get client => _compatShell.client;
  ElevenLabsAudio get audio => _compatShell.audio;
  ElevenLabsModels get models => _compatShell.models;
}
