import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/flutter_material_chat_demo.dart';

void main() {
  testWidgets('material chat demo shows backend-owned provider plan',
      (tester) async {
    await tester.pumpWidget(const BackendHintMaterialChatApp());

    await tester
        .tap(find.byKey(const Key('backend-profile-openai-web-search')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('backend-hint-message-field')),
      'Summarize the rollout status.',
    );
    await tester.tap(find.byKey(const Key('backend-hint-send-button')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('user'), findsOneWidget);
    expect(find.text('assistant'), findsOneWidget);
    expect(find.textContaining('backend-owned openai routing'), findsOneWidget);
    expect(
      find.textContaining('Backend plan: openai / gpt-4.1-mini'),
      findsOneWidget,
    );
  });
}
