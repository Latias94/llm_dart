part of 'client.dart';

String _getEndpointWithAuth(GoogleConfig config, String endpoint) {
  final separator = endpoint.contains('?') ? '&' : '?';
  return '$endpoint${separator}key=${config.apiKey}';
}
