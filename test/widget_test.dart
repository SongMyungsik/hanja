import 'package:flutter_test/flutter_test.dart';

import 'package:hanja/main.dart';

void main() {
  testWidgets('Splash screen shows title and start button', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('千字文'), findsOneWidget);
    expect(find.text('천자문 학습'), findsOneWidget);
    expect(find.text('시작하기'), findsOneWidget);
  });

  testWidgets('Tapping start navigates to the hanja list', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('시작하기'));
    await tester.pump();
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
    await tester.pump();

    expect(find.text('천자문 목록'), findsOneWidget);
  });
}
