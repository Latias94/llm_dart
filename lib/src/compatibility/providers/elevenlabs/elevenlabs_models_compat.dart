import '../../../../core/llm_error.dart';
import '../../../../providers/elevenlabs/client.dart';
import '../../../../providers/elevenlabs/config.dart';

part 'elevenlabs_models_account_support.dart';
part 'elevenlabs_models_query_support.dart';

/// Compatibility-oriented ElevenLabs provider-specific model/admin helper
/// surface.
class ElevenLabsModels {
  final ElevenLabsClient client;
  final ElevenLabsConfig config;

  ElevenLabsModels(this.client, this.config);
}
