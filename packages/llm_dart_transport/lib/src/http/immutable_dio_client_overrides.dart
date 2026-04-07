import 'package:dio/dio.dart';

import 'provider_dio_client_factory.dart';

/// Immutable transport-owned implementation of [DioClientOverrides].
final class ImmutableDioClientOverrides implements DioClientOverrides {
  @override
  final bool bypassSslVerification;

  @override
  final String? certificatePath;

  @override
  final Duration? connectionTimeout;

  @override
  final Dio? customDio;

  @override
  final Map<String, String> customHeaders;

  @override
  final bool enableHttpLogging;

  @override
  final String? proxyUrl;

  @override
  final Duration? receiveTimeout;

  @override
  final Duration? sendTimeout;

  @override
  final Duration? timeout;

  const ImmutableDioClientOverrides({
    this.bypassSslVerification = false,
    this.certificatePath,
    this.connectionTimeout,
    this.customDio,
    this.customHeaders = const <String, String>{},
    this.enableHttpLogging = false,
    this.proxyUrl,
    this.receiveTimeout,
    this.sendTimeout,
    this.timeout,
  });
}
