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

    await tester.tap(find.byKey(const Key('tool-approval-send-button')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tool-approval-status')), findsOneWidget);
    expect(find.text('status: awaitingApproval'), findsOneWidget);
    expect(
      find.byKey(Key('tool-approve-$demoProviderApprovalId')),
      findsOneWidget,
    );
    expect(find.byKey(Key('tool-run-$demoLocalToolCallId')), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(Key('tool-approve-$demoProviderApprovalId')),
    );
    await tester.tap(find.byKey(Key('tool-approve-$demoProviderApprovalId')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('status: awaitingTool'), findsOneWidget);
    expect(find.byKey(Key('tool-run-$demoLocalToolCallId')), findsOneWidget);

    await tester
        .ensureVisible(find.byKey(Key('tool-run-$demoLocalToolCallId')));
    await tester.tap(find.byKey(Key('tool-run-$demoLocalToolCallId')));
    await tester.pump();
    await tester.pumpAndSettle();

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
}
