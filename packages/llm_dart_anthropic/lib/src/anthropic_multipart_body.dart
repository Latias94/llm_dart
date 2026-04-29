import 'dart:convert';
import 'dart:typed_data';

final class AnthropicMultipartBody {
  final String boundary;
  final Uint8List bytes;

  const AnthropicMultipartBody({
    required this.boundary,
    required this.bytes,
  });

  String get contentType => 'multipart/form-data; boundary=$boundary';
}

AnthropicMultipartBody buildAnthropicMultipartBody({
  required List<AnthropicMultipartField> fields,
}) {
  final boundary = 'llm_dart_${DateTime.now().microsecondsSinceEpoch}';
  final builder = BytesBuilder(copy: false);
  final lineBreak = utf8.encode('\r\n');

  for (final field in fields) {
    builder.add(utf8.encode('--$boundary\r\n'));

    switch (field) {
      case _AnthropicTextField(:final name, :final value):
        builder.add(
          utf8.encode(
            'Content-Disposition: form-data; name="$name"\r\n\r\n',
          ),
        );
        builder.add(utf8.encode(value));
        builder.add(lineBreak);
      case _AnthropicFileField(
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
  return AnthropicMultipartBody(
    boundary: boundary,
    bytes: builder.takeBytes(),
  );
}

sealed class AnthropicMultipartField {
  const AnthropicMultipartField();

  factory AnthropicMultipartField.text({
    required String name,
    required String value,
  }) = _AnthropicTextField;

  factory AnthropicMultipartField.file({
    required String name,
    required String filename,
    required String mediaType,
    required List<int> bytes,
  }) = _AnthropicFileField;
}

final class _AnthropicTextField extends AnthropicMultipartField {
  final String name;
  final String value;

  const _AnthropicTextField({
    required this.name,
    required this.value,
  });
}

final class _AnthropicFileField extends AnthropicMultipartField {
  final String name;
  final String filename;
  final String mediaType;
  final List<int> bytes;

  const _AnthropicFileField({
    required this.name,
    required this.filename,
    required this.mediaType,
    required this.bytes,
  });
}
