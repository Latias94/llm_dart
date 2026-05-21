import 'dart:io';

import 'package:test/test.dart';

import '../../tool/run_workspace_package_tests.dart';

void main() {
  group('buildWorkspacePackageTestTargets', () {
    test('includes focused Dart packages and the Flutter package', () {
      final targets = buildWorkspacePackageTestTargets();

      expect(
        targets.map((target) => target.name),
        containsAll([
          'llm_dart_provider',
          'llm_dart_ai',
          'llm_dart_transport',
          'llm_dart_provider_utils',
          'llm_dart_chat',
          'llm_dart_openai',
          'llm_dart_google',
          'llm_dart_anthropic',
          'llm_dart_ollama',
          'llm_dart_elevenlabs',
          'llm_dart_flutter',
        ]),
      );
      expect(targets.length, 11);
    });

    test('uses dart test for Dart packages', () {
      final target = buildWorkspacePackageTestTargets().firstWhere(
        (target) => target.name == 'llm_dart_provider',
      );

      expect(target.executable, 'dart');
      expect(target.arguments, ['test']);
      expect(target.relativeDirectory, 'packages/llm_dart_provider');
    });

    test('uses flutter test for the Flutter package', () {
      final target = buildWorkspacePackageTestTargets().firstWhere(
        (target) => target.name == 'llm_dart_flutter',
      );

      expect(target.executable, Platform.isWindows ? 'flutter.bat' : 'flutter');
      expect(target.arguments, ['test']);
      expect(target.relativeDirectory, 'packages/llm_dart_flutter');
    });
  });
}
