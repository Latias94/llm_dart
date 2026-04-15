import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/flutter_http_reconnect_demo.dart';

void main() {
  testWidgets('http reconnect demo resumes after a transport error',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(900, 1000));

    await tester.pumpWidget(const HttpReconnectMaterialChatApp());

    await tester.tap(find.byKey(const Key('http-reconnect-send-button')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('http-reconnect-status')), findsOneWidget);
    expect(find.text('status: error'), findsOneWidget);
    expect(find.textContaining('socket closed during demo stream'),
        findsOneWidget);
    expect(find.textContaining('Connection lost after '), findsOneWidget);
    expect(find.textContaining('Progress: 50%'), findsOneWidget);

    await tester
        .ensureVisible(find.byKey(const Key('http-reconnect-resume-button')));
    await tester.tap(find.byKey(const Key('http-reconnect-resume-button')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('status: ready'), findsOneWidget);
    expect(find.textContaining('Connection lost after resume succeeds.'),
        findsOneWidget);
    expect(find.textContaining('Progress: 100%'), findsOneWidget);
    expect(
        find.textContaining('Reconnect: flutter / attempts=1'), findsOneWidget);
    expect(
        find.textContaining('socket closed during demo stream'), findsNothing);
  });
}
