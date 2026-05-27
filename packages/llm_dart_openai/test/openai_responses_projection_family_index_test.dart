import 'dart:io';

import 'package:llm_dart_openai/src/responses/openai_responses_projection_family_index.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI Responses projection family index', () {
    test('uses unique family ids and documents existing modules', () {
      final ids = <String>{};

      for (final family in openAIResponsesProjectionFamilies) {
        expect(family.id, isNotEmpty);
        expect(
          ids.add(family.id),
          isTrue,
          reason: 'duplicate family id ${family.id}',
        );
        expect(family.description, isNotEmpty);
        expect(family.modules, isNotEmpty);
        expect(family.tests, isNotEmpty);

        for (final module in family.modules) {
          expect(
            File(module).existsSync(),
            isTrue,
            reason: '${family.id} module is missing: $module',
          );
        }
        for (final testPath in family.tests) {
          expect(
            File(testPath).existsSync(),
            isTrue,
            reason: '${family.id} test is missing: $testPath',
          );
        }
      }
    });

    test('stays a navigation index rather than a runtime registry', () {
      for (final family in openAIResponsesProjectionFamilies) {
        expect(family.modules, everyElement(startsWith('packages/')));
      }
    });
  });
}
