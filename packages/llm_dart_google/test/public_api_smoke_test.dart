import 'package:llm_dart_google/llm_dart_google.dart';
import 'package:test/test.dart';

void main() {
  test('public API smoke', () {
    expect(registerGoogleProvider, isNotNull);
    expect(createGoogleGenerativeAI, isNotNull);
    expect(google, isNotNull);
  });
}
