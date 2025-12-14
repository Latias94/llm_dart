import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:test/test.dart';

void main() {
  test('public API smoke', () {
    expect(DioClientFactory.new, isNotNull);
    expect(SSELineBuffer.new, isNotNull);
    expect(Utf8StreamDecoder.new, isNotNull);
  });
}
