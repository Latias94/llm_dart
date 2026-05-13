import 'dart:io';

import 'package:test/test.dart';

import '../../tool/check_provider_replay_metadata_guards.dart' as guard;

void main() {
  group('check_provider_replay_metadata_guards', () {
    test('passes against the current repository root', () async {
      final result = await guard.evaluateProviderReplayMetadataGuards(
        repoRoot: Directory.current,
      );

      expect(
        result.violations,
        isEmpty,
        reason: result.violations.join('\n'),
      );
    });
  });
}
