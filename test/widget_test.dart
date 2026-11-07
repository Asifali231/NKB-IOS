import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nikah_blessing/User_Home_Pages/user_main.dart';

void main() {
  testWidgets('NoScrollPageView follows its controller', (tester) async {
    final controller = PageController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: NoScrollPageView(
          controller: controller,
          children: const [
            Text('Explore'),
            Text('Requests'),
          ],
        ),
      ),
    );

    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Requests'), findsNothing);

    controller.jumpToPage(1);
    await tester.pumpAndSettle();

    expect(find.text('Explore'), findsNothing);
    expect(find.text('Requests'), findsOneWidget);
  });
}
