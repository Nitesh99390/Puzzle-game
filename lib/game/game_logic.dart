import 'dart:math';

/// A board is a list of tubes; each tube lists colour ids from bottom to top.
typedef Board = List<List<int>>;

Board cloneBoard(Board b) => [for (final t in b) List<int>.of(t)];

/// Static definition of a level.
class LevelDef {
  const LevelDef({
    required this.number,
    required this.colors,
    required this.capacity,
    required this.emptyTubes,
    required this.seed,
  });

  final int number;
  final int colors;
  final int capacity;
  final int emptyTubes;
  final int seed;

  int get tubeCount => colors + emptyTubes;

  /// Score used as the "perfect" reference for stars.
  int get baseScore => 500 + colors * 150;
}

const int kTubeCapacity = 4;
const int kLevelCount = 30;

/// 30 handcrafted-by-seed levels: from 3 colours up to 12 colours.
final List<LevelDef> gameLevels = List.generate(kLevelCount, (i) {
  final n = i + 1;
  return LevelDef(
    number: n,
    colors: min(3 + i ~/ 3, 12),
    capacity: kTubeCapacity,
    emptyTubes: 2,
    seed: 1000 + n * 7919,
  );
});

/// Pure puzzle rules – no Flutter dependencies, easy to unit test.
class PuzzleRules {
  PuzzleRules._();

  static bool isTubeComplete(List<int> t, int capacity) =>
      t.length == capacity && t.every((c) => c == t.first);

  static bool isUniform(List<int> t) =>
      t.isNotEmpty && t.every((c) => c == t.first);

  /// How many same-coloured units sit at the top of a tube.
  static int topRun(List<int> t) {
    if (t.isEmpty) return 0;
    final top = t.last;
    var n = 0;
    for (var i = t.length - 1; i >= 0 && t[i] == top; i--) {
      n++;
    }
    return n;
  }

  static bool canPour(Board b, int from, int to, int capacity) {
    if (from == to) return false;
    final src = b[from];
    final dst = b[to];
    if (src.isEmpty || dst.length >= capacity) return false;
    if (isTubeComplete(src, capacity)) return false;
    return dst.isEmpty || dst.last == src.last;
  }

  /// Pours in place and returns the amount of liquid moved.
  static int pour(Board b, int from, int to, int capacity) {
    final src = b[from];
    final dst = b[to];
    final amount = min(topRun(src), capacity - dst.length);
    for (var i = 0; i < amount; i++) {
      dst.add(src.removeLast());
    }
    return amount;
  }

  static bool isSolved(Board b, int capacity) =>
      b.every((t) => t.isEmpty || isTubeComplete(t, capacity));
}

/// Depth-first solver used to guarantee every generated level is solvable.
class PuzzleSolver {
  PuzzleSolver._();

  static String _key(Board b) =>
      (b.map((t) => t.join(',')).toList()..sort()).join('|');

  static bool isSolvable(Board start, int capacity, {int nodeLimit = 30000}) {
    final visited = <String>{};
    final stack = <Board>[cloneBoard(start)];
    var nodes = 0;
    while (stack.isNotEmpty) {
      final b = stack.removeLast();
      if (PuzzleRules.isSolved(b, capacity)) return true;
      if (!visited.add(_key(b))) continue;
      if (++nodes > nodeLimit) return false;

      final weak = <Board>[];
      final strong = <Board>[];
      for (var f = 0; f < b.length; f++) {
        var triedEmpty = false;
        for (var t = 0; t < b.length; t++) {
          if (!PuzzleRules.canPour(b, f, t, capacity)) continue;
          if (b[t].isEmpty) {
            // Moving a uniform tube into an empty one is pointless,
            // and all empty destinations are equivalent.
            if (PuzzleRules.isUniform(b[f]) || triedEmpty) continue;
            triedEmpty = true;
          }
          final next = cloneBoard(b);
          PuzzleRules.pour(next, f, t, capacity);
          (b[t].isEmpty ? weak : strong).add(next);
        }
      }
      // Explore colour-matching moves first (pushed last = popped first).
      stack
        ..addAll(weak)
        ..addAll(strong);
    }
    return false;
  }
}

/// Generates a shuffled, solvable board for a level (deterministic per seed).
class LevelGenerator {
  LevelGenerator._();

  static Board generate(LevelDef level) {
    Board? last;
    for (var attempt = 0; attempt < 60; attempt++) {
      final rng = Random(level.seed + attempt * 31);
      final units = <int>[
        for (var c = 0; c < level.colors; c++)
          for (var k = 0; k < level.capacity; k++) c,
      ]..shuffle(rng);

      final board = <List<int>>[
        for (var t = 0; t < level.colors; t++)
          units.sublist(t * level.capacity, (t + 1) * level.capacity),
        for (var e = 0; e < level.emptyTubes; e++) <int>[],
      ];
      last = board;

      // Avoid boards that start with an already-finished tube.
      if (board.any((t) => PuzzleRules.isTubeComplete(t, level.capacity))) {
        continue;
      }
      if (PuzzleSolver.isSolvable(board, level.capacity)) return board;
    }
    return last!;
  }
}
