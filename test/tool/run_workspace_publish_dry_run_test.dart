import 'package:test/test.dart';

import '../../tool/run_workspace_publish_dry_run.dart';

void main() {
  group('extractPublishDryRunSummary', () {
    test('parses warnings and hints', () {
      final summary = extractPublishDryRunSummary(
        'Package has 0 warnings and 7 hints.',
      );

      expect(summary, isNotNull);
      expect(summary!.warnings, 0);
      expect(summary.hints, 7);
    });

    test('parses warnings without hints', () {
      final summary = extractPublishDryRunSummary(
        'Package has 1 warning.',
      );

      expect(summary, isNotNull);
      expect(summary!.warnings, 1);
      expect(summary.hints, 0);
    });

    test('returns null when no summary is present', () {
      expect(
        extractPublishDryRunSummary('Publishing package...'),
        isNull,
      );
    });
  });
}
