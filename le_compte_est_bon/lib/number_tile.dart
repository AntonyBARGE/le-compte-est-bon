enum Operator { add, subtract, multiply, divide }

final Map<Operator, String> _operatorToString = {
  Operator.add: '+',
  Operator.subtract: '-',
  Operator.multiply: '×',
  Operator.divide: '/',
};

final Map<String, Operator> _stringToOperator = _operatorToString.map((key, value) => MapEntry(value, key));

Operator? parseOperator(String opStr) => _stringToOperator[opStr];

String? opToString(Operator? op) => op != null ? _operatorToString[op] : null;

/// Expression represents a node in an expression tree.
/// A leaf node (when operator is null) simply holds a number.
/// A non-leaf node contains an operator and two child expressions.
class Expression {
  final int? value;
  final Operator? operator;
  final Expression? left;
  final Expression? right;

  // Leaf constructor.
  Expression.leaf(this.value)
      : operator = null,
        left = null,
        right = null;

  // Internal node constructor.
  Expression.node(this.operator, this.left, this.right) : value = getResult(operator, left?.value, right?.value);

  static int getResult(Operator? op, int? left, int? right) {
    if (left == null || right == null) return 0;
    switch (op) {
      case Operator.add:
        return left + right;
      case Operator.subtract:
        return (left >= right) ? left - right : 0;
      case Operator.multiply:
        return left * right;
      case Operator.divide:
        return (right != 0 && left % right == 0) ? left ~/ right : 0;
      default:
        return 0;
    }
  }

  bool _isCommutative(Operator op) => op == Operator.add || op == Operator.multiply;
  bool _isAssociative(Operator op) => op == Operator.add || op == Operator.multiply;

  List<Expression> _flatten(Operator op) {
    if (operator == op) {
      return [...left!._flatten(op), ...right!._flatten(op)];
    } else {
      return [this];
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Expression) return false;

    // For leaf nodes, simply compare values.
    if (operator == null || other.operator == null) {
      return value == other.value && operator == other.operator;
    }

    // If computed values differ, the expressions differ.
    if (value != other.value) return false;

    // If both have the same operator and that operator is both commutative and associative,
    // then compare the flattened lists (as multisets).
    if (operator == other.operator && _isAssociative(operator!) && _isCommutative(operator!)) {
      List<Expression> thisFlattened = _flatten(operator!);
      List<Expression> otherFlattened = other._flatten(operator!);
      if (thisFlattened.length != otherFlattened.length) return false;
      // Sort using a canonical property (here, we use hashCode, though in production you might use a better comparator)
      thisFlattened.sort((a, b) => a.hashCode.compareTo(b.hashCode));
      otherFlattened.sort((a, b) => a.hashCode.compareTo(b.hashCode));
      for (int i = 0; i < thisFlattened.length; i++) {
        if (thisFlattened[i] != otherFlattened[i]) return false;
      }
      return true;
    } else {
      // For non-associative (or non-commutative) operators, compare structure.
      return operator == other.operator && left == other.left && right == other.right;
    }
  }

  @override
  int get hashCode {
    // For leaves, just the value.
    if (operator == null) return value.hashCode;
    if (_isAssociative(operator!) && _isCommutative(operator!)) {
      // Flatten for associative and commutative operators.
      var flattened = _flatten(operator!);
      // Create a combined hash that is independent of the order.
      int combinedHash = 0;
      for (var exp in flattened) {
        combinedHash ^= exp.hashCode;
      }
      return operator.hashCode ^ combinedHash;
    } else {
      return operator.hashCode ^ left.hashCode ^ right.hashCode;
    }
  }

  @override
  String toString() {
    if (operator == null) return value.toString();
    return "(${left.toString()} ${opToString(operator)} ${right.toString()})";
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'operator': operator?.toString().split('.').last,
      'left': left?.toJson(),
      'right': right?.toJson(),
    };
  }

  factory Expression.fromJson(Map<String, dynamic> json) {
    if (json['operator'] == null) {
      return Expression.leaf(json['value']);
    }
    return Expression.node(
      parseOperator(json['operator']),
      Expression.fromJson(json['left']),
      Expression.fromJson(json['right']),
    );
  }
}

class NumberTile {
  final int value;
  final Expression expr;
  bool isAlreadyPicked;

  NumberTile(this.value, this.expr, [this.isAlreadyPicked = false]);

  String get path => expr.toString();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is NumberTile && value == other.value && expr == other.expr && isAlreadyPicked == other.isAlreadyPicked;

  @override
  int get hashCode => Object.hash(value, expr, isAlreadyPicked);

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'isAlreadyPicked': isAlreadyPicked,
      'expr': expr.toJson(),
    };
  }

  factory NumberTile.fromJson(Map<String, dynamic> json) {
    return NumberTile(
      json['value'],
      Expression.fromJson(json['expr']),
      json['isAlreadyPicked'],
    );
  }
}

NumberTile combineTiles(NumberTile a, NumberTile b, Operator op) {
  Expression leftExpr = a.expr;
  Expression rightExpr = b.expr;

  Expression newExpr = Expression.node(op, leftExpr, rightExpr);
  int newValue = newExpr.value!;
  return NumberTile(newValue, newExpr);
}

// Helper class to hold a pair of tiles.
class TilePair {
  final NumberTile first;
  final NumberTile second;
  TilePair(this.first, this.second);
}
