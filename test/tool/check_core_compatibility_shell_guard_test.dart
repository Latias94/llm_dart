import 'dart:io';

import '../../tool/check_core_compatibility_shell_guard.dart' as guard;
import 'package:test/test.dart';

void main() {
  group('check_core_compatibility_shell_guard', () {
    test('passes against the current repository core shell', () async {
      final result = await guard.evaluateCoreCompatibilityShellGuard(
        repoRoot: Directory.current,
      );

      expect(
        result.violations,
        isEmpty,
        reason: result.violations.join('\n'),
      );
    });

    test('allows approved compatibility typedefs', () async {
      final repoRoot = await _createTempCoreShell();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'packages/llm_dart_core/lib/src/common/transport_cancellation.dart',
        '''
import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;

export 'package:llm_dart_provider/llm_dart_provider.dart'
    show ProviderCancellation, ProviderCancelledException;

typedef TransportCancellation = provider.ProviderCancellation;
typedef TransportCancelledException = provider.ProviderCancelledException;
''',
      );

      final result = await guard.evaluateCoreCompatibilityShellGuard(
        repoRoot: repoRoot,
      );

      expect(
        result.violations,
        isEmpty,
        reason: result.violations.join('\n'),
      );
    });

    test('reports concrete implementation in core shell', () async {
      final repoRoot = await _createTempCoreShell();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'packages/llm_dart_core/lib/src/model/example.dart',
        '''
class CoreOwnedModel {
  const CoreOwnedModel();
}
''',
      );

      final result = await guard.evaluateCoreCompatibilityShellGuard(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(
          contains('llm_dart_core is a compatibility shell'),
        ),
      );
    });

    test('reports unapproved typedefs in core shell', () async {
      final repoRoot = await _createTempCoreShell();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'packages/llm_dart_core/lib/src/model/legacy_alias.dart',
        '''
typedef LegacyModelAlias = Object;
''',
      );

      final result = await guard.evaluateCoreCompatibilityShellGuard(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(
          contains('unexpected typedef `LegacyModelAlias`'),
        ),
      );
    });
  });
}

Future<Directory> _createTempCoreShell() async {
  final repoRoot = await Directory.systemTemp.createTemp(
    'llm_dart_core_shell_guard_',
  );

  await _writeFile(
    repoRoot,
    'packages/llm_dart_core/lib/llm_dart_core.dart',
    '''
library;

export 'foundation.dart';
''',
  );
  await _writeFile(
    repoRoot,
    'packages/llm_dart_core/lib/foundation.dart',
    '''
library;

export 'src/common/transport_cancellation.dart';
''',
  );

  return repoRoot;
}

Future<void> _writeFile(
  Directory repoRoot,
  String relativePath,
  String content,
) async {
  final file = File('${repoRoot.path}${Platform.pathSeparator}$relativePath');
  await file.parent.create(recursive: true);
  await file.writeAsString(content);
}
