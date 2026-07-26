import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_quest/core/widgets/xp_bar.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: SizedBox(width: 200, child: child))),
    );

void main() {
  testWidgets('renders its optional label', (tester) async {
    await tester.pumpWidget(_host(const XpBar(value: 0.5, label: 'XP')));
    await tester.pumpAndSettle();
    expect(find.text('XP'), findsOneWidget);
  });

  testWidgets('renders without a label', (tester) async {
    await tester.pumpWidget(_host(const XpBar(value: 0.3)));
    await tester.pumpAndSettle();
    expect(find.byType(XpBar), findsOneWidget);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('builds with an out-of-range value (clamped, no throw)',
      (tester) async {
    await tester.pumpWidget(_host(const XpBar(value: 1.8)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(XpBar), findsOneWidget);
  });
}
