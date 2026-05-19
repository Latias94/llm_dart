import 'package:dio/dio.dart';

import 'transport_client.dart';

final class DioTransportResponseSupport {
  const DioTransportResponseSupport();

  ResponseType toDioResponseType(TransportResponseType responseType) {
    return switch (responseType) {
      TransportResponseType.json => ResponseType.json,
      TransportResponseType.plainText => ResponseType.plain,
      TransportResponseType.bytes => ResponseType.bytes,
    };
  }

  String toDioMethod(TransportMethod method) {
    return switch (method) {
      TransportMethod.get => 'GET',
      TransportMethod.post => 'POST',
      TransportMethod.put => 'PUT',
      TransportMethod.patch => 'PATCH',
      TransportMethod.delete => 'DELETE',
    };
  }

  Map<String, String> flattenHeaders(Map<String, List<String>> headers) {
    return Map<String, String>.fromEntries(
      headers.entries.map(
        (entry) => MapEntry(entry.key, entry.value.join(',')),
      ),
    );
  }

  bool isSuccessStatus(int? statusCode) {
    return statusCode != null && statusCode >= 200 && statusCode < 300;
  }
}
