import 'package:flutter/material.dart';

import 'calculation_line.dart';
import 'draw_tile.dart';
import 'number_tile.dart';

class CalculationRow extends StatelessWidget {
  final CalculationLine line;
  final Function(CalculationLine) onResultClicked;

  const CalculationRow({
    super.key,
    required this.line,
    required this.onResultClicked,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DrawTile(
          label: '${line.leftValue ?? ''}',
          variant: TileVariant.number,
        ),
        DrawTile(
          label: opToString(line.op) ?? '',
          variant: TileVariant.operator,
        ),
        DrawTile(
          label: '${line.rightValue ?? ''}',
          variant: TileVariant.number,
        ),
        DrawTile(
          label: '=',
          variant: TileVariant.operator,
        ),
        DrawTile(
          label: line.result?.toString() ?? '',
          isAlreadyPicked: (line.isResultUsed && (line.result != 0 && line.result != null)),
          onPressed: () => (line.result != 0 && line.result != null) ? onResultClicked(line) : null,
          variant: TileVariant.numberButton,
        ),
      ],
    );
  }
}
