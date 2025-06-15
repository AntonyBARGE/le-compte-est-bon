import 'dart:math';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:le_compte_est_bon/best_result_board.dart';
import 'package:le_compte_est_bon/calculation_line.dart';
import 'package:le_compte_est_bon/draw_tile.dart';
import 'package:le_compte_est_bon/loading_barrier.dart';
import 'package:le_compte_est_bon/number_tile.dart';
import 'package:le_compte_est_bon/result_board.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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
  NumberTile? _longestSolution;
  List<NumberTile> bestSolutions = [];
  int activeCarouselIndex = 0;
  final List<NumberTile> _cachedSolutions = [];
  bool isLoading = false;
  int _activeTaskId = 0;

  @override
  void initState() {
    super.initState();
    _generateDraw();
  }

  void _generateDraw() {
    _activeTaskId++;
    _numberOfBestSolutions = 0;
    _clearCalculRows();
    setState(() {
      _cachedSolutions.clear();
    });
    final List<int> bigTiles = [25, 50, 75, 100];
    final List<int> smallTiles = List.generate(10, (i) => i + 1);
    List<int> tiles = [...smallTiles, ...smallTiles, ...bigTiles];
    tiles.shuffle(_random);

    setState(() {
      _draw = [];
      _solutions = [];
      _draw.addAll(tiles.take(6).map((n) => NumberTile(n, Expression.leaf(n), false)));
      _targetNumber = 100 + _random.nextInt(900);
      _longestSolution = null;
    });

    _calculateSolution(isHidden: true);
  }

  void _clearCalculRows() {
    setState(() {
      _lines = List.generate(5, (index) => CalculationLine());
      for (var tile in _draw) {
        tile.isAlreadyPicked = false;
      }
    });
  }

  Future<void> _calculateSolution({bool isHidden = false}) async {
    final int taskIdAtStart = _activeTaskId;

    void processSolutions(List<NumberTile> solutions) {
      if (taskIdAtStart != _activeTaskId) return; // Aborted due to new draw

      // Deduplicate best solutions based on the expression equality.
      Set<Expression> uniqueExpressions = {};
      int bestValue = solutions.first.value;
      bestSolutions.clear();
      bestSolutions.addAll(solutions.where((s) => s.value == bestValue && uniqueExpressions.add(s.expr)).toList());

      // Sort best solutions by the length of their expression.
      bestSolutions.sort((a, b) => a.expr.toString().length.compareTo(b.expr.toString().length));

      setState(() {
        _numberOfBestSolutions = uniqueExpressions.length;
        _longestSolution = bestSolutions.last;
        // Set carousel starting index to the longest best solution.
        activeCarouselIndex = bestSolutions.length - 1;
        _clearCalculRows();
        _getInputsFromResult(_longestSolution?.expr);
      });
    }

    if (!isHidden) {
      setState(() {
        isLoading = true;
      });
    }

    if (_cachedSolutions.isEmpty) {
      _solutions = await _exploreAndSortSolutions();
      if (taskIdAtStart != _activeTaskId) return; // Aborted, don't update state
      setState(() {
        _cachedSolutions.addAll(_solutions);
      });
    }

    if (!isHidden && taskIdAtStart == _activeTaskId) {
      processSolutions(_cachedSolutions);
      setState(() {
        isLoading = false;
      });
    }
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
    int lastResultIndex = _getResultTiles().lastIndexWhere((result) => result != null);
    int? lastResult;
    if (lastResultIndex != -1) {
      lastResult = _lines[lastResultIndex].result;
    }
    setState(() {
      for (var line in _lines) {
        if (!line.isComplete) {
          // If the line is empty and a last result is available, use it.
          if (line.isEmpty && lastResult != null) {
            line.addInput(lastResult);
            _lines[lastResultIndex].isResultUsed = true;
          }
          line.setOperator(op);
          break;
        }
      }
    });
  }

  void onCancelPressed() {
    setState(() {
      if (bestSolutions.isNotEmpty) {
        _numberOfBestSolutions = 0;
        bestSolutions.clear();
        _clearCalculRows();
      } else {
        for (int i = _lines.length - 1; i >= 0; i--) {
          if (!_lines[i].isEmpty) {
            int? removedValue = _lines[i].removeLastInput();
            if (removedValue != null) {
              int index = _draw.indexWhere((tile) => tile.value == removedValue && tile.isAlreadyPicked);
              if (index != -1) {
                _draw[index].isAlreadyPicked = false;
              } else {
                int usedResultIndex = _lines.lastIndexWhere((line) => line.result == removedValue);
                _lines[usedResultIndex].isResultUsed = false;
              }
            }
            break;
          }
        }
      }
    });
  }

  /// Retrieves the result tiles at the end of the CalculationLine.
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

    int currentLineIndex = _lines.lastIndexWhere((line) => !line.isEmpty) + 1;

    int leftIndex = _draw.indexWhere((tile) => (tile.value == expr.left?.value && tile.isAlreadyPicked == false));
    if (leftIndex != -1) {
      onNumberPressed(_draw[leftIndex]);
    } else {
      // If it's not in the drawn tiles, it's in the results
      leftIndex = _lines.lastIndexWhere((line) => line.result == expr.left?.value);
      setState(() {
        _lines[leftIndex].isResultUsed = _lines[currentLineIndex].addInput(expr.left?.value ?? 0);
      });
    }

    onOperatorPressed(expr.operator!);

    int rightIndex = _draw.indexWhere((tile) => (tile.value == expr.right?.value && tile.isAlreadyPicked == false));
    if (rightIndex != -1) {
      onNumberPressed(_draw[rightIndex]);
    } else {
      // If it's not in the drawn tiles, it's in the results
      rightIndex = _lines.lastIndexWhere((line) => line.result == expr.right?.value);
      setState(() {
        _lines[rightIndex].isResultUsed = _lines[currentLineIndex].addInput(expr.right?.value ?? 0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalPages = _numberOfBestSolutions;
    int windowSize = 15;
    int startPage = totalPages;
    if (totalPages > windowSize) {
      // Center the active index in the window as much as possible.
      startPage = activeCarouselIndex - windowSize ~/ 2;
      // Make sure the startPage is within bounds.
      if (startPage < 0) startPage = 0;
      if (startPage + windowSize > totalPages) startPage = totalPages - windowSize;
    }
    int displayedActiveIndex = activeCarouselIndex - startPage;
    int dotCount = totalPages < windowSize ? totalPages : windowSize;

    return LoadingBarrier(
      isBusy: isLoading,
      onClose: () => setState(() {
        isLoading = false;
      }),
      duration: Duration(milliseconds: 300),
      busyBuilder: (context) => Center(
        child: CircularProgressIndicator(color: Colors.deepPurple),
      ),
      child: Scaffold(
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
                              return BestSolutionBoard(
                                expr: bestSolutions[index].expr,
                                onResultClicked: (clickedLine) {},
                              );
                            },
                            options: CarouselOptions(
                              initialPage: activeCarouselIndex,
                              height: 320,
                              viewportFraction: 1,
                              onPageChanged: (index, reason) {
                                setState(() {
                                  activeCarouselIndex = index;
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
                                activeIndex: displayedActiveIndex,
                                count: dotCount,
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
                      icon: Icon(
                        Icons.lightbulb,
                        size: 40,
                        color: _cachedSolutions.isEmpty ? Theme.of(context).iconTheme.color!.withValues(alpha: 0.3) : null,
                      ),
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
      ),
    );
  }
}

class LeCompteEstBonApp extends StatelessWidget {
  const LeCompteEstBonApp({super.key});

  @override
  Widget build(BuildContext context) {
    WakelockPlus.enable();

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

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

  // A canonical memo key which is order independent.
  String memoKey(List<NumberTile> currentTiles) {
    // Use a canonical representation of the tile: value and a normalized expression string.
    List<String> keyParts = currentTiles.map((t) => "${t.value}:${t.expr.toString()}").toList();
    keyParts.sort(); // sort to ensure order independence
    return keyParts.join(",");
  }

  List<NumberTile> exploreSolutions(List<NumberTile> currentTiles, int target) {
    if (currentTiles.length == 1) return currentTiles;
    String key = memoKey(currentTiles);
    if (memo.containsKey(key)) return memo[key]!;

    List<NumberTile> solutions = [];

    for (int i = 0; i < currentTiles.length; i++) {
      for (int j = i + 1; j < currentTiles.length; j++) {
        NumberTile a = currentTiles[i];
        NumberTile b = currentTiles[j];

        // List to hold pairs along with the operation to apply.
        List<MapEntry<Operator, TilePair>> operations = [];

        // Commutative: addition & multiplication.
        operations.add(MapEntry(Operator.add, TilePair(a, b)));
        operations.add(MapEntry(Operator.multiply, TilePair(a, b)));

        // Non-commutative: subtraction.
        if (a.value > b.value) {
          operations.add(MapEntry(Operator.subtract, TilePair(a, b)));
        } else if (b.value > a.value) {
          operations.add(MapEntry(Operator.subtract, TilePair(b, a)));
        }
        // Non-commutative: division.
        if (b.value != 0 && a.value % b.value == 0) {
          operations.add(MapEntry(Operator.divide, TilePair(a, b)));
        } else if (a.value != 0 && b.value % a.value == 0) {
          operations.add(MapEntry(Operator.divide, TilePair(b, a)));
        }

        // Process all valid operations.
        for (var opEntry in operations) {
          Operator op = opEntry.key;
          TilePair tilePair = opEntry.value;
          NumberTile resultTile = combineTiles(tilePair.first, tilePair.second, op);

          // Create new state of tiles: remove the two used tiles and add the result.
          List<NumberTile> newTiles = List.from(currentTiles);
          // Remove in descending order to avoid index issues.
          newTiles.removeAt(j);
          newTiles.removeAt(i);
          newTiles.add(resultTile);

          // If we hit the target, add the result; else, keep exploring.
          if (resultTile.value == target) {
            solutions.add(resultTile);
          } else {
            solutions.addAll(exploreSolutions(newTiles, target));
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
