import 'package:le_compte_est_bon/number_tile.dart';

/// A CalculationLine holds the user’s input (for one row) as a simple three-part operation.
class CalculationLine {
  Expression expression = Expression.node(null, null, null);

  int? get leftValue => expression.left?.value;
  set leftValue(int? newValue) => expression = Expression.node(
        expression.operator,
        newValue == null ? null : Expression.leaf(newValue),
        expression.right,
      );

  Operator? get op => expression.operator;
  set op(Operator? newOp) => expression = Expression.node(
        newOp,
        expression.left,
        expression.right,
      );

  int? get rightValue => expression.right?.value;
  set rightValue(int? newValue) => expression = Expression.node(
        expression.operator,
        expression.left,
        newValue == null ? null : Expression.leaf(newValue),
      );

  int? get result => expression.value;

  bool get isComplete => leftValue != null && op != null && rightValue != null;
  bool get isEmpty => leftValue == null && op == null && rightValue == null;

  bool isResultUsed = false;

  /// Called when a number tile is pressed.
  bool addInput(int input) {
    if (leftValue == null) {
      leftValue = input;
      return true;
    } else if (op != null && rightValue == null) {
      rightValue = input;
      return true;
    }
    return false;
  }

  /// Called when an operator is pressed.
  void setOperator(Operator operator) {
    if (leftValue != null && op == null) {
      op = operator;
    }
  }

  /// Remove the last input (right operand, then operator, then left operand).
  int? removeLastInput() {
    if (rightValue != null) {
      int removed = rightValue!;
      rightValue = null;
      return removed;
    } else if (op != null) {
      op = null;
      return null;
    } else if (leftValue != null) {
      int removed = leftValue!;
      leftValue = null;
      return removed;
    }
    return null;
  }
}
