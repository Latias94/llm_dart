import 'dart:convert';
import 'dart:typed_data';

final class SimpleMultipartBody {
  final String boundary;
  final Uint8List bytes;

  const SimpleMultipartBody({
    required this.boundary,
    required this.bytes,
  });

  String get contentType => 'multipart/form-data; boundary=$boundary';
}

SimpleMultipartBody buildSimpleMultipartBody({
  required List<SimpleMultipartField> fields,
}) {
  final boundary = 'llm_dart_${DateTime.now().microsecondsSinceEpoch}';
  final builder = BytesBuilder(copy: false);
  final lineBreak = utf8.encode('\r\n');

  for (final field in fields) {
    builder.add(utf8.encode('--$boundary\r\n'));

    switch (field) {
      case _SimpleTextField(:final name, :final value):
        builder.add(
          utf8.encode(
            'Content-Disposition: form-data; name="$name"\r\n\r\n',
          ),
        );
        builder.add(utf8.encode(value));
        builder.add(lineBreak);
      case _SimpleFileField(
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

  builder.add(utf8.encode('--$boundary--\r\n'));
  return SimpleMultipartBody(
    boundary: boundary,
    bytes: builder.takeBytes(),
  );
}

sealed class SimpleMultipartField {
  const SimpleMultipartField();

  factory SimpleMultipartField.text({
    required String name,
    required String value,
  }) = _SimpleTextField;

  factory SimpleMultipartField.file({
    required String name,
    required String filename,
    required String mediaType,
    required List<int> bytes,
  }) = _SimpleFileField;
}

final class _SimpleTextField extends SimpleMultipartField {
  final String name;
  final String value;

  const _SimpleTextField({
    required this.name,
    required this.value,
  });
}

final class _SimpleFileField extends SimpleMultipartField {
  final String name;
  final String filename;
  final String mediaType;
  final List<int> bytes;

  const _SimpleFileField({
    required this.name,
    required this.filename,
    required this.mediaType,
    required this.bytes,
  });
}
