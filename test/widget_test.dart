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
