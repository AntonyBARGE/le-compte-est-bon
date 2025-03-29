import 'package:flutter/material.dart';
import 'package:le_compte_est_bon/calculation_line.dart';
import 'package:le_compte_est_bon/calculation_row.dart';

// ignore: must_be_immutable
class ResultBoard extends StatelessWidget {
  ResultBoard({super.key, required this.lines, required this.onResultClicked});

  List<CalculationLine> lines;
  final Function(CalculationLine) onResultClicked;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: lines
          .map((line) => CalculationRow(
                line: line,
                onResultClicked: onResultClicked,
              ))
          .toList(),
    );
  }
}
