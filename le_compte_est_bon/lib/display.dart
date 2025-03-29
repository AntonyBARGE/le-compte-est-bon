import 'package:flutter/material.dart';
import 'package:le_compte_est_bon/custom_tile.dart';

void main() {
  runApp(MaterialApp(theme: ThemeData.dark(), home: Scaffold(body: CalculationDisplay())));
}

class CalculationDisplay extends StatelessWidget {
  const CalculationDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    // Example values; you can replace these with dynamic values from your CalculationLine.
    final leftValue = 25;
    final op = '-';
    final rightValue = 10;
    final result1 = 15;
    final leftValue2 = 15;
    final op2 = '+';
    final rightValue2 = 4;
    final result2 = 19;
    final displayColor = Colors.blue;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Clickable tile
          CustomTile(
            variant: TileVariant.number,
            label: '',
          ),
          // Clickable tile
          CustomTile(
            variant: TileVariant.number,
            label: '1',
          ),
          // Clickable but disabled tile
          CustomTile(
            variant: TileVariant.numberButton,
            label: '2',
          ),
          // Non-clickable tile (e.g. operator)
          CustomTile(
            variant: TileVariant.operator,
            label: '+',
          ),
          // Empty non-clickable tile
          const CustomTile(
            variant: TileVariant.operator,
            label: '',
          ), // Empty non-clickable tile
          const CustomTile(
            variant: TileVariant.operatorButton,
            label: '-',
          ),
        ],
      ),
    );
  }
}

class BracketPainter extends CustomPainter {
  final Color color;

  BracketPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    // Draw a horizontal bracket. This is just an example – you can customize it.
    // Starting from top left, draw a vertical line, then a horizontal line, then a vertical line.
    path.moveTo(0, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);

    // Optionally, add extra decoration or adjust the path to mimic the exact style.
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(BracketPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
