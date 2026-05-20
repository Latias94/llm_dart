import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'elevenlabs_model_call_support.dart';
import 'elevenlabs_shared.dart';
import 'elevenlabs_voice_catalog_models.dart';

export 'elevenlabs_voice_catalog_models.dart' show ElevenLabsVoice;

final class ElevenLabsVoiceCatalogSettings {
  final Map<String, String> headers;

  const ElevenLabsVoiceCatalogSettings({
    this.headers = const {},
  });
}

final class ElevenLabsVoiceCatalogClient {
  final String apiKey;
  final String baseUrl;
  final TransportClient transport;
  final ElevenLabsVoiceCatalogSettings settings;

  ElevenLabsVoiceCatalogClient({
    required this.apiKey,
    required this.transport,
    String? baseUrl,
    this.settings = const ElevenLabsVoiceCatalogSettings(),
  }) : baseUrl = normalizeElevenLabsBaseUrl(baseUrl);

  Uri get voicesUri => Uri.parse('$baseUrl/voices');

  Future<List<ElevenLabsVoice>> listVoices({
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    return sendElevenLabsModelRequest(
      transport: transport,
      request: TransportRequest(
        uri: voicesUri,
        method: TransportMethod.get,
        headers: {
          'xi-api-key': apiKey,
          'accept': 'application/json',
          ...settings.headers,
          if (headers != null) ...headers,
        },
        timeout: timeout,
        maxRetries: maxRetries,
        cancellation: cancellation,
        responseType: TransportResponseType.json,
      ),
      decode: (body, _) {
        final json = decodeElevenLabsJsonObject(
          body,
          responseName: 'voice catalog',
        );
        return decodeElevenLabsVoiceList(json);
      },
    );
  }
}
