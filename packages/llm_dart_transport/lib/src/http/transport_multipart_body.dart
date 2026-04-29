import 'dart:convert';
import 'dart:typed_data';

final class TransportMultipartBody {
  final String boundary;
  final Uint8List bytes;

  const TransportMultipartBody({
    required this.boundary,
    required this.bytes,
  });

  String get contentType => 'multipart/form-data; boundary=$boundary';
}

TransportMultipartBody buildTransportMultipartBody({
  required List<TransportMultipartField> fields,
  String? boundary,
}) {
  final effectiveBoundary =
      boundary ?? 'llm_dart_${DateTime.now().microsecondsSinceEpoch}';
  final builder = BytesBuilder(copy: false);
  final lineBreak = utf8.encode('\r\n');

  for (final field in fields) {
    builder.add(utf8.encode('--$effectiveBoundary\r\n'));

    switch (field) {
      case _TransportTextField(:final name, :final value):
        builder.add(
          utf8.encode(
            'Content-Disposition: form-data; name="$name"\r\n\r\n',
          ),
        );
        builder.add(utf8.encode(value));
        builder.add(lineBreak);
      case _TransportFileField(
          :final name,
          :final filename,
          :final mediaType,
          :final bytes,
        ):
        builder.add(
          utf8.encode(
            'Content-Disposition: form-data; name="$name"; filename="$filename"\r\n',
          ),
        );
        builder.add(utf8.encode('Content-Type: $mediaType\r\n\r\n'));
        builder.add(bytes);
        builder.add(lineBreak);
    }
  }

  builder.add(utf8.encode('--$effectiveBoundary--\r\n'));
  return TransportMultipartBody(
    boundary: effectiveBoundary,
    bytes: builder.takeBytes(),
  );
}

sealed class TransportMultipartField {
  const TransportMultipartField();

  factory TransportMultipartField.text({
    required String name,
    required String value,
  }) = _TransportTextField;

  factory TransportMultipartField.file({
    required String name,
    required String filename,
    required String mediaType,
    required List<int> bytes,
  }) = _TransportFileField;
}

final class _TransportTextField extends TransportMultipartField {
  final String name;
  final String value;

  const _TransportTextField({
    required this.name,
    required this.value,
  });
}

final class _TransportFileField extends TransportMultipartField {
  final String name;
  final String filename;
  final String mediaType;
  final List<int> bytes;

  const _TransportFileField({
    required this.name,
    required this.filename,
    required this.mediaType,
    required this.bytes,
  });
}
