import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_quest/core/widgets/stat_pill.dart';

Widget _host(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('shows the value and icon', (tester) async {
    await tester.pumpWidget(
      _host(
        const StatPill(
          icon: Icons.bolt,
          value: '250',
          color: Colors.amber,
        ),
      ),
    );
    expect(find.text('250'), findsOneWidget);
    expect(find.byIcon(Icons.bolt), findsOneWidget);
  });

  testWidgets('shows the optional label when provided', (tester) async {
    await tester.pumpWidget(
      _host(
        const StatPill(
          icon: Icons.favorite,
          value: '80',
          color: Colors.red,
          label: 'HP',
        ),
      ),
    );
    expect(find.text('80'), findsOneWidget);
    expect(find.text('HP'), findsOneWidget);
  });

  testWidgets('omits the label when not provided', (tester) async {
    await tester.pumpWidget(
      _host(
        const StatPill(icon: Icons.star, value: '5', color: Colors.blue),
      ),
    );
    expect(find.text('5'), findsOneWidget);
    // Only the value Text is present, no label Text.
    expect(find.byType(Text), findsOneWidget);
  });
}
