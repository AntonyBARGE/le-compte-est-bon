import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le_compte_est_bon/calculation_row.dart';
import 'package:le_compte_est_bon/main.dart';

void main() {
  testWidgets('Initial state shows target number and calculation rows', (WidgetTester tester) async {
    await tester.pumpWidget(const LeCompteEstBonApp());

    // Verify that the target number is displayed.
    expect(find.byKey(const Key('targetNumber')), findsOneWidget);

    // Verify that 5 CalculationRow widgets are present.
    expect(find.byType(CalculationRow), findsNWidgets(5));

    // Verify that refresh, calculate, and undo buttons exist.
    expect(find.byKey(const Key('refreshButton')), findsOneWidget);
    expect(find.byKey(const Key('calculateButton')), findsOneWidget);
    expect(find.byKey(const Key('undoButton')), findsOneWidget);
  });
}
