import 'package:llm_dart_transport/dio.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart'
    show decodeDioResponseTextStream, Logger, ProviderDioClientFactory;

import '../../../../core/cancellation.dart';
import '../../../../utils/http_response_handler.dart';
import '../../../../providers/google/config.dart';
import '../../http/dio_request_executor.dart';
import 'dio_strategy.dart';

part 'client_http_mixin.dart';
part 'client_identity_support.dart';

/// Core Google HTTP client shared across all capability modules.
///
/// This class provides the foundational HTTP functionality that all
/// Google capability implementations can use.
class GoogleClient with _GoogleClientHttpMixin {
  @override
  final GoogleConfig config;
  @override
  final Logger logger = Logger('GoogleClient');
  @override
  late final Dio dio;
  @override
  late final CompatibilityDioRequestExecutor _requestExecutor;

  GoogleClient(this.config) {
    dio = ProviderDioClientFactory.create(
      strategy: GoogleDioStrategy(),
      config: config,
      overrides: config.dioOverrides,
    );
    _requestExecutor = CompatibilityDioRequestExecutor(
      dio: dio,
      logger: logger,
      mapDioException: (error) async => error,
    );
  }
}
