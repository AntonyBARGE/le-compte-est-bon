import 'package:flutter/material.dart';

enum TileVariant {
  numberButton,
  operatorButton,
  number,
  operator,
}

class DrawTile extends StatelessWidget {
  final TileVariant variant;
  final String label;
  final VoidCallback? onPressed;
  final bool isAlreadyPicked;

  const DrawTile({
    super.key,
    required this.variant,
    required this.label,
    this.isAlreadyPicked = false,
    this.onPressed,
  });

  bool get _isOperator => (variant == TileVariant.operator || variant == TileVariant.operatorButton);

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = Colors.deepPurple.shade300;
    Color textColor = Colors.white;
    double width = MediaQuery.of(context).size.width / 4;
    double height = 54;
    switch (variant) {
      case TileVariant.numberButton:
        backgroundColor = Colors.deepPurple.shade300;
        break;
      case TileVariant.operatorButton:
        width = width / 2;
        backgroundColor = Colors.deepPurple.shade500;
        break;
      case TileVariant.number:
        width = MediaQuery.of(context).size.width / 5;
        backgroundColor = const Color.fromARGB(255, 44, 24, 80);
        break;
      case TileVariant.operator:
        width = width / 2 - 8;
        break;
    }

    return Padding(
      padding: variant == TileVariant.operator ? EdgeInsets.zero : const EdgeInsets.all(4.0),
      child: Stack(
        children: [
          SizedBox(
            width: width,
            height: height,
            child: GestureDetector(
              onTap: onPressed,
              child: Container(
                decoration: variant == TileVariant.operator
                    ? null
                    : BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                padding: EdgeInsets.symmetric(vertical: _isOperator ? 4 : 8),
                child: Text(
                  (label.isEmpty && _isOperator) ? "•" : label,
                  style: TextStyle(
                    fontSize: _isOperator ? 32 : 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          if (isAlreadyPicked)
            CustomPaint(
              size: Size(width, height),
              painter: CrossPainter(),
            ),
        ],
      ),
    );
  }
}

class CrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromARGB(255, 247, 241, 78)
      ..strokeWidth = 5;

    canvas.drawLine(Offset(size.width - 10, 10), Offset(10, size.height - 10), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
