import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarf/presentation/auth/widgets/gradient_button.dart';

void main() {
  testWidgets('GradientButton renders label and handles taps',
      (WidgetTester tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GradientButton(
            label: 'Continue',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
}
