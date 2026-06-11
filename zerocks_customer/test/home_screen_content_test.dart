import 'package:flutter_test/flutter_test.dart';
import 'package:zerocks_customer/features/home/screens/home_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('HomeDashboard renders content', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeDashboard(),
        ),
      ),
    );
    await tester.pump();
    
    final textFinder = find.text('Zerocks');
    expect(textFinder, findsOneWidget);
  });
}
