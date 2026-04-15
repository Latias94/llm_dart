import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/flutter_tool_approval_demo.dart';
import '../example/tool_approval_demo_support.dart';

void main() {
  testWidgets('tool approval demo walks approval then local tool flow',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(900, 1000));

    await tester.pumpWidget(const ToolApprovalMaterialChatApp());

    await _sendInitialMessage(tester);

    expect(find.byKey(const Key('tool-approval-status')), findsOneWidget);
    expect(find.text('status: awaitingApproval'), findsOneWidget);
    expect(
      find.byKey(Key('tool-approve-$demoProviderApprovalId')),
      findsOneWidget,
    );
    expect(find.byKey(Key('tool-run-$demoLocalToolCallId')), findsOneWidget);

    await _approveProviderAction(tester);

    expect(find.text('status: awaitingTool'), findsOneWidget);
    expect(find.byKey(Key('tool-run-$demoLocalToolCallId')), findsOneWidget);

    await _runLocalTool(tester);

    expect(find.text('status: ready'), findsOneWidget);
    expect(
      find.textContaining('Tool orchestration completed'),
      findsOneWidget,
    );
    expect(
      find.textContaining('The provider-side browser action was approved.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Local weather returned Tokyo, 24 C, clear.'),
      findsOneWidget,
    );
  });

  testWidgets(
      'tool approval demo restores awaitingApproval snapshots and continues',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(900, 1000));

    await tester.pumpWidget(const ToolApprovalMaterialChatApp());

    await _sendInitialMessage(tester);
    expect(find.text('status: awaitingApproval'), findsOneWidget);

    await _saveSnapshot(tester);
    expect(
        find.byKey(const Key('tool-approval-saved-chat-id')), findsOneWidget);

    await _restoreSnapshot(tester);
    expect(find.text('status: awaitingApproval'), findsOneWidget);
    expect(find.text('restoreCount: 1'), findsOneWidget);

    await _approveProviderAction(tester);
    expect(find.text('status: awaitingTool'), findsOneWidget);

    await _runLocalTool(tester);
    expect(find.text('status: ready'), findsOneWidget);
    expect(
      find.textContaining('The provider-side browser action was approved.'),
      findsOneWidget,
    );
  });

  testWidgets(
      'tool approval demo restores awaitingTool snapshots and continues',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(900, 1000));

    await tester.pumpWidget(const ToolApprovalMaterialChatApp());

    await _sendInitialMessage(tester);
    await _approveProviderAction(tester);
    expect(find.text('status: awaitingTool'), findsOneWidget);

    await _saveSnapshot(tester);
    await _restoreSnapshot(tester);
    expect(find.text('status: awaitingTool'), findsOneWidget);
    expect(find.text('restoreCount: 1'), findsOneWidget);

    await _runLocalTool(tester);
    expect(find.text('status: ready'), findsOneWidget);
    expect(
      find.textContaining('Local weather returned Tokyo, 24 C, clear.'),
      findsOneWidget,
    );
  });
}

Future<void> _sendInitialMessage(WidgetTester tester) async {
  await tester
      .ensureVisible(find.byKey(const Key('tool-approval-send-button')));
  await tester.tap(find.byKey(const Key('tool-approval-send-button')));
  await tester.pump();
  await tester.pumpAndSettle();
}

Future<void> _approveProviderAction(WidgetTester tester) async {
  await tester.ensureVisible(
    find.byKey(Key('tool-approve-$demoProviderApprovalId')),
  );
  await tester.tap(find.byKey(Key('tool-approve-$demoProviderApprovalId')));
  await tester.pump();
  await tester.pumpAndSettle();
}

Future<void> _runLocalTool(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(Key('tool-run-$demoLocalToolCallId')));
  await tester.tap(find.byKey(Key('tool-run-$demoLocalToolCallId')));
  await tester.pump();
  await tester.pumpAndSettle();
}

Future<void> _saveSnapshot(WidgetTester tester) async {
  await tester
      .ensureVisible(find.byKey(const Key('tool-approval-save-button')));
  await tester.tap(find.byKey(const Key('tool-approval-save-button')));
  await tester.pump();
  await tester.pumpAndSettle();
}

Future<void> _restoreSnapshot(WidgetTester tester) async {
  await tester
      .ensureVisible(find.byKey(const Key('tool-approval-restore-button')));
  await tester.tap(find.byKey(const Key('tool-approval-restore-button')));
  await tester.pump();
  await tester.pumpAndSettle();
}
