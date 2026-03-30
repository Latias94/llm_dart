import 'package:dio/dio.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import '../../core/base_http_provider.dart';
import '../../core/config.dart';

TransportClient createCompatTransport(LLMConfig config) {
  final customTransport =
      config.getExtension<TransportClient>('customTransportClient');
  if (customTransport != null) {
    return customTransport;
  }

  final customDio = config.getExtension<Dio>('customDio');
  if (customDio != null) {
    return DioTransportClient(dio: customDio);
  }

  final dio = BaseHttpProvider.createConfiguredDio(
    baseUrl: config.baseUrl,
    headers: const {},
    config: config,
    timeout: config.timeout,
  );

  return DioTransportClient(dio: dio);
}
