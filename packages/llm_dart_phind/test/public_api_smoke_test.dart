import 'package:llm_dart_phind/llm_dart_phind.dart';
import 'package:test/test.dart';

void main() {
  test('public API smoke', () {
    expect(registerPhindProvider, isNotNull);
    expect(createPhind, isNotNull);
    expect(phind, isNotNull);
  });
}
