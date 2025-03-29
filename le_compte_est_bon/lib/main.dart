import 'dart:math';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:le_compte_est_bon/calculation_line.dart';
import 'package:le_compte_est_bon/draw_tile.dart';
import 'package:le_compte_est_bon/number_tile.dart';
import 'package:le_compte_est_bon/result_board.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final Random _random = Random();
  List<NumberTile> _draw = [];
  int _targetNumber = 0;
  List<NumberTile> _solutions = [];
  List<CalculationLine> _lines = [];
  int _numberOfBestSolutions = 0;
  NumberTile? _shortestSolution;
  NumberTile? _longestSolution;
  List<NumberTile> bestSolutions = [];
  int activeCarouselIndex = 0;

  @override
  void initState() {
    super.initState();
    _generateDraw();
  }

  void _generateDraw() {
    _numberOfBestSolutions = 0;
    _clearCalculRows();
    final List<int> bigTiles = [25, 50, 75, 100];
    final List<int> smallTiles = List.generate(10, (i) => i + 1);
    List<int> tiles = [...smallTiles, ...smallTiles, ...bigTiles];
    tiles.shuffle(_random);

    setState(() {
      _draw = [];
      _solutions = [];
      _draw.addAll(tiles.take(6).map((n) => NumberTile(n, Expression.leaf(n), false)));
      _targetNumber = 100 + _random.nextInt(900);
      _shortestSolution = null;
      _longestSolution = null;
    });
  }

  void _clearCalculRows() {
    setState(() {
      _lines = List.generate(5, (index) => CalculationLine());
      for (var tile in _draw) {
        tile.isAlreadyPicked = false;
      }
    });
  }

  Future<void> _calculateSolution() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(color: Colors.deepPurple),
      ),
    );

    _solutions = await _exploreAndSortSolutions();

    // Deduplicate best solutions based on the expression equality.
    Set<Expression> uniqueExpressions = {};
    int bestValue = _solutions.first.value;
    bestSolutions.clear();
    bestSolutions.addAll(_solutions.where((s) => s.value == bestValue && uniqueExpressions.add(s.expr)).toList());

    bestSolutions.sort((a, b) => a.expr.toString().length.compareTo(b.expr.toString().length));

    setState(() {
      _numberOfBestSolutions = uniqueExpressions.length;
      _shortestSolution = bestSolutions.first;
      _longestSolution = bestSolutions.last;
      _clearCalculRows();
      _getInputsFromResult(_longestSolution?.expr);
    });

    // ignore: use_build_context_synchronously
    Navigator.of(context).pop();
  }

  Future<List<NumberTile>> _exploreAndSortSolutions() async {
    return await compute(exploreAndSortSolutionsIsolate, {
      'tiles': _draw.map((tile) => tile.toJson()).toList(),
      'target': _targetNumber,
    });
  }

  void onNumberPressed(NumberTile? tile) {
    if (tile == null) return;
    for (var line in _lines) {
      if (!line.isComplete) {
        setState(() {
          tile.isAlreadyPicked = line.addInput(tile.value);
        });
        break;
      }
    }
  }

  void onOperatorPressed(Operator op) {
    NumberTile? lastResult = _getResultTiles().last;
    setState(() {
      for (var line in _lines) {
        if (!line.isComplete) {
          // If the line is empty and a last result is available, use it.
          if (line.isEmpty && lastResult != null) {
            line.addInput(lastResult.value);
          }
          line.setOperator(op);
          break;
        }
      }
    });
  }

  void onCancelPressed() {
    setState(() {
      for (int i = _lines.length - 1; i >= 0; i--) {
        if (!_lines[i].isEmpty) {
          int? removedValue = _lines[i].removeLastInput();
          if (removedValue != null) {
            int index = _draw.indexWhere((tile) => tile.value == removedValue && tile.isAlreadyPicked);
            if (index != -1) {
              _draw[index].isAlreadyPicked = false;
            }
          }
          break;
        }
      }
    });
  }

  /// Retrieves the result of the last complete CalculationLine.
  List<NumberTile?> _getResultTiles() {
    List<NumberTile?> results = [];
    for (var line in _lines) {
      if (line.isComplete) {
        final resultTile = NumberTile(line.result!, Expression.leaf(line.result!));
        results.add(resultTile);
      } else {
        results.add(null);
      }
    }
    return results;
  }

  void _getInputsFromResult(Expression? expr) {
    if (expr == null || expr.operator == null) return;

    if (expr.right?.operator != null) {
      _getInputsFromResult(expr.right!);
    }

    if (expr.left?.operator != null) {
      _getInputsFromResult(expr.left!);
    }

    final List<NumberTile?> availableTiles = [..._draw, ..._getResultTiles()];

    final leftTile = availableTiles.firstWhere((tile) => (tile?.value == expr.left?.value && tile?.isAlreadyPicked == false));
    final rightTile = availableTiles.firstWhere((tile) => (tile?.value == expr.right?.value && tile?.isAlreadyPicked == false));

    onNumberPressed(leftTile);
    onOperatorPressed(expr.operator!);
    onNumberPressed(rightTile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0).add(EdgeInsets.only(top: 6)),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              const SizedBox(height: 20),
              _numberOfBestSolutions == 0
                  ? ResultBoard(
                      lines: _lines,
                      onResultClicked: (clickedLine) {
                        setState(() {
                          clickedLine.isResultUsed = true;
                        });
                        onNumberPressed(NumberTile(
                          clickedLine.result!,
                          Expression.leaf(clickedLine.result!),
                          true,
                        ));
                      })
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CarouselSlider.builder(
                          itemCount: _numberOfBestSolutions,
                          itemBuilder: (context, index, realIndex) {
                            return ResultBoard(
                                lines: _lines,
                                onResultClicked: (clickedLine) {
                                  setState(() {
                                    clickedLine.isResultUsed = true;
                                  });
                                  onNumberPressed(NumberTile(
                                    clickedLine.result!,
                                    Expression.leaf(clickedLine.result!),
                                    true,
                                  ));
                                });
                          },
                          options: CarouselOptions(
                            height: 320,
                            viewportFraction: 1,
                            onPageChanged: (index, reason) {
                              setState(() {
                                activeCarouselIndex = index;
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  for (var tile in _draw) {
                                    tile.isAlreadyPicked = false;
                                  }
                                  _getInputsFromResult(bestSolutions[index].expr);
                                });
                              });
                            },
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_numberOfBestSolutions > 1)
                              Text(
                                '<   ',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            AnimatedSmoothIndicator(
                              activeIndex: activeCarouselIndex,
                              count: _numberOfBestSolutions,
                              effect: ExpandingDotsEffect(
                                dotWidth: 8,
                                dotHeight: 8,
                                activeDotColor: const Color.fromARGB(255, 247, 241, 78),
                              ),
                            ),
                            if (_numberOfBestSolutions > 1) ...{
                              Text(
                                ' / $_numberOfBestSolutions',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                ' >',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            }
                          ],
                        ),
                      ],
                    ),
              Spacer(),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: Operator.values
                      .map((value) => DrawTile(
                            label: opToString(value)!,
                            onPressed: () => onOperatorPressed(value),
                            variant: TileVariant.operatorButton,
                          ))
                      .toList(),
                ),
              ),
              Text(
                '$_targetNumber',
                style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _draw
                    .map(
                      (tile) => DrawTile(
                        label: '${tile.value}',
                        onPressed: () => onNumberPressed(tile),
                        isAlreadyPicked: tile.isAlreadyPicked,
                        variant: TileVariant.numberButton,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 40),
                    onPressed: _generateDraw,
                  ),
                  IconButton(
                    icon: const Icon(Icons.lightbulb, size: 40),
                    onPressed: _calculateSolution,
                  ),
                  IconButton(
                    icon: const Icon(Icons.undo, size: 40),
                    onPressed: onCancelPressed,
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class LeCompteEstBonApp extends StatelessWidget {
  const LeCompteEstBonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Le Compte Est Bon',
      theme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}

List<NumberTile> exploreAndSortSolutionsIsolate(Map<String, dynamic> args) {
  List<NumberTile> tiles = (args['tiles'] as List).map((t) => NumberTile.fromJson(t as Map<String, dynamic>)).toList();
  int target = args['target'];
  Map<String, List<NumberTile>> memo = {};

  String memoKey(List<NumberTile> tiles) {
    List<int> sortedValues = tiles.map((t) => t.value).toList()..sort();
    return sortedValues.join(",");
  }

  List<NumberTile> exploreSolutions(List<NumberTile> tiles, int target) {
    if (tiles.length == 1) return tiles;
    String key = memoKey(tiles);
    if (memo.containsKey(key)) return memo[key]!;

    List<NumberTile> solutions = [];

    for (int i = 0; i < tiles.length; i++) {
      for (int j = i + 1; j < tiles.length; j++) {
        NumberTile a = tiles[i];
        NumberTile b = tiles[j];
        List<MapEntry<Operator, bool Function()>> operations = [
          MapEntry(Operator.add, () => true),
          MapEntry(Operator.multiply, () => true),
          MapEntry(Operator.subtract, () => a.value >= b.value),
          MapEntry(Operator.divide, () => b.value != 0 && a.value % b.value == 0),
        ];
        for (var opEntry in operations) {
          if (!opEntry.value()) continue;

          NumberTile resultTile = combineTiles(a, b, opEntry.key);
          List<NumberTile> newNumbers = List.from(tiles)
            ..remove(a)
            ..remove(b)
            ..add(resultTile);

          if (resultTile.value == target) {
            solutions.add(resultTile);
          } else {
            solutions.addAll(exploreSolutions(newNumbers, target));
          }
        }
      }
    }

    memo[key] = solutions;
    return solutions;
  }

  List<NumberTile> sols = exploreSolutions(tiles, target);

  sols.sort((a, b) {
    int valueDiff = (a.value - target).abs().compareTo((b.value - target).abs());
    if (valueDiff == 0) {
      return a.expr.toString().length.compareTo(b.expr.toString().length);
    }
    return valueDiff;
  });

  return sols;
}

void main() {
  runApp(const LeCompteEstBonApp());
}
