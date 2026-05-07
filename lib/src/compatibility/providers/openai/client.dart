import 'package:llm_dart_transport/dio.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart'
    show
        decodeDioResponseTextStream,
        Level,
        LogSanitizer,
        Logger,
        ProviderDioClientFactory,
        bindDioCancellation;

import '../../../../core/cancellation.dart' show TransportCancellation;
import '../../../../core/llm_error.dart';
import '../../../../models/chat_models.dart';
import '../../../../providers/openai/config.dart';
import '../../../../utils/http_response_handler.dart';
import 'client_error_support.dart';
import 'client_message_support.dart';
import 'client_sse_support.dart';
import 'config_views.dart';
import 'dio_strategy.dart';

part 'client_codec_mixin.dart';
part 'client_http_mixin.dart';
part 'client_identity_mixin.dart';

/// Core OpenAI HTTP client shared across all capability modules
///
/// This class provides the foundational HTTP functionality that all
/// OpenAI capability implementations can use. It handles:
/// - Authentication and headers
/// - Request/response processing
/// - Error handling
/// - SSE stream parsing
/// - Provider-specific configurations
class OpenAIClient
    with
        _OpenAIClientIdentityMixin,
        _OpenAIClientCodecMixin,
        _OpenAIClientHttpMixin {
  @override
  final OpenAIConfig config;
  @override
  final Logger logger = Logger('OpenAIClient');
  @override
  late final Dio dio;
  @override
  late final OpenAISseChunkParser _sseChunkParser;
  @override
  late final OpenAIClientMessageCodec _messageCodec;
  @override
  late final OpenAIClientErrorAdapter _errorAdapter;

  OpenAIClient(this.config) {
    // Use unified Dio client factory with OpenAI-specific strategy
    dio = ProviderDioClientFactory.create(
      strategy: OpenAIDioStrategy(),
      config: config,
      overrides: config.dioOverrides,
    );
    _sseChunkParser = OpenAISseChunkParser(logger);
    _messageCodec = OpenAIClientMessageCodec(
      usesResponsesApi: config.responsesCompat.enabled,
    );
    _errorAdapter = OpenAIClientErrorAdapter(logger);
  }
}
