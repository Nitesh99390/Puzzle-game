import 'package:color_pour/game/game_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pour moves the whole matching top run', () {
    final board = <List<int>>[
      [0, 1, 1],
      [1],
      [],
    ];
    expect(PuzzleRules.canPour(board, 0, 1, 4), isTrue);
    final moved = PuzzleRules.pour(board, 0, 1, 4);
    expect(moved, 2);
    expect(board[1], [1, 1, 1]);
    expect(board[0], [0]);
  });

  test('cannot pour onto a different colour', () {
    final board = <List<int>>[
      [0],
      [1],
    ];
    expect(PuzzleRules.canPour(board, 0, 1, 4), isFalse);
  });

  test('hint returns a move that keeps the board solvable', () {
    for (final level in gameLevels.take(8)) {
      final b = LevelGenerator.generate(level);
      final m = PuzzleSolver.hint(b, level.capacity);
      expect(m, isNotNull, reason: 'level ${level.number}');
      expect(PuzzleRules.canPour(b, m!.from, m.to, level.capacity), isTrue);
      PuzzleRules.pour(b, m.from, m.to, level.capacity);
      expect(PuzzleSolver.isSolvable(b, level.capacity), isTrue);
    }
  });

  test('stuck detection reports no useful move for a stuck board', () {
    // Two single colours sitting on top of each other, no empty tube.
    final board = <List<int>>[
      [0, 1],
      [1, 0],
    ];
    expect(PuzzleRules.hasUsefulMove(board, 4), isFalse);
  });

  test('every generated level is solvable', () {
    for (final level in gameLevels) {
      final b = LevelGenerator.generate(level);
      expect(
        PuzzleSolver.isSolvable(b, level.capacity, nodeLimit: 60000),
        isTrue,
        reason: 'level ${level.number}',
      );
    }
  });
}
