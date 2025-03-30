import 'package:flutter/material.dart';
import 'package:le_compte_est_bon/calculation_line.dart';
import 'package:le_compte_est_bon/number_tile.dart';
import 'package:le_compte_est_bon/result_board.dart';

class BestSolutionBoard extends StatelessWidget {
  final Expression expr;
  final void Function(CalculationLine) onResultClicked;

  const BestSolutionBoard({super.key, required this.expr, required this.onResultClicked});

  List<CalculationLine> _buildCalculationLines(Expression expr) {
    // Create a fresh list of calculation lines.
    List<CalculationLine> lines = List.generate(5, (index) => CalculationLine());

    void populateLines(Expression e) {
      if (e.operator == null) return;
      // Process the right branch first if it contains an operator.
      if (e.right != null && e.right!.operator != null) {
        populateLines(e.right!);
      }
      // Process the left branch next if it contains an operator.
      if (e.left != null && e.left!.operator != null) {
        populateLines(e.left!);
      }
      // Get the next available calculation line.
      int currentLineIndex = lines.indexWhere((line) => line.isEmpty);
      if (currentLineIndex == -1) return;
      lines[currentLineIndex].addInput(e.left?.value ?? 0);
      lines[currentLineIndex].setOperator(e.operator!);
      lines[currentLineIndex].addInput(e.right?.value ?? 0);
    }

    populateLines(expr);
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final solutionLines = _buildCalculationLines(expr);
    return ResultBoard(
      lines: solutionLines,
      onResultClicked: onResultClicked,
    );
  }
}
