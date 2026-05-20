import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('LLM Dart Library Entry Point', () {
    group('Library exports', () {
      test('shared core exports are available', () {
        expect(UserPromptMessage, isA<Type>());
        expect(GenerateTextOptions, isA<Type>());
        expect(CallOptions, isA<Type>());
        expect(JsonSchema, isA<Type>());
      });

      test('transport exports are available', () {
        expect(TransportClient, isA<Type>());
        expect(TransportRequest, isA<Type>());
        expect(TransportException, isA<Type>());
      });
    });
  });
}
