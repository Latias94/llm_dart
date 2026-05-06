import 'dart:io';

import '../../tool/check_transport_boundary_guards.dart' as guard;
import 'package:test/test.dart';

void main() {
  group('check_transport_boundary_guards', () {
    test('passes against the current repository transport package', () async {
      final result = await guard.evaluateTransportBoundaryGuards(
        repoRoot: Directory.current,
      );

      expect(
        result.violations,
        isEmpty,
        reason: result.violations.join('\n'),
      );
    });

    test('reports root or core imports inside transport lib files', () async {
      final repoRoot = await _createTempWorkspace();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'packages/llm_dart_transport/lib/src/example.dart',
        '''
import 'package:llm_dart_core/foundation.dart';

void main() {}
''',
      );

      final result = await guard.evaluateTransportBoundaryGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(
          contains('transport library files must not import or export'),
        ),
      );
    });

    test('reports provider legacy aliases leaking from the public barrel',
        () async {
      final repoRoot = await _createTempWorkspace();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'packages/llm_dart_transport/lib/llm_dart_transport.dart',
        '''
library;

export 'src/common/transport_cancellation.dart'
    show ProviderCancellation, ProviderCancelledException;
''',
      );

      final result = await guard.evaluateTransportBoundaryGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(
          contains(
              'public transport surface must expose TransportCancellation'),
        ),
      );
    });
  });
}

Future<Directory> _createTempWorkspace() async {
  final repoRoot = await Directory.systemTemp.createTemp(
    'llm_dart_transport_boundary_guards_',
  );

  await _writeFile(
    repoRoot,
    'packages/llm_dart_transport/lib/llm_dart_transport.dart',
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
