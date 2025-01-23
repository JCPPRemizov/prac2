import 'dart:convert';
import 'dart:io';

const int FIELD_LENGTH = 10;

class Player {
  String name = "";
  List<List<String>> playerField = List.generate(FIELD_LENGTH, 
      (_) => List.generate(FIELD_LENGTH, (_) => "[ ]", growable: false),
      growable: false);
  List<List<String>> playerBattleField = List.generate(FIELD_LENGTH, 
      (_) => List.generate(FIELD_LENGTH, (_) => "[ ]", growable: false),
      growable: false);
  int hits = 0;
  int misses = 0;
  int totalMoves = 0;
}

enum Position {
  horizontal,
  vertical;
}

enum Direction {
  left,
  right,
  up,
  down;
}

class Vector {
  int x = 0;
  int y = 0;
}

const List<List<int>> shipTypeAmount = [[1, 4], [2, 3], [3, 2], [4, 1]];

void main() {
  Player firstPlayer = Player();
  Player secondPlayer = Player();

  print("Игрок 1, пожалуйста, введите свое имя:");
  firstPlayer.name = stdin.readLineSync(encoding: utf8)!;

  print("Игрок 2, пожалуйста, введите свое имя:");
  secondPlayer.name = stdin.readLineSync(encoding: utf8)!;

  print("${firstPlayer.name}, заполните свое поле!");
  firstPlayer.playerField = fillPlayerBoard(firstPlayer.playerField);

  print("${secondPlayer.name}, заполните свое поле!");
  secondPlayer.playerField = fillPlayerBoard(secondPlayer.playerField);

  playGame(firstPlayer, secondPlayer);
}

void printBoard(List<List<String>> board) {
  for (var row in board) {
    print(row.join());
  }
}

List<List<String>> fillPlayerBoard(List<List<String>> board) {
  for (var ship in shipTypeAmount) {
    int shipCount = ship[0];
    int shipSize = ship[1];

    for (int i = 0; i < shipCount; i++) {
      while (true) {
        print("Расставляем $shipSize-палубный корабль ($shipCount осталось):");
        printBoard(board);

        print("Введите координаты X и Y через пробел:");
        Vector coord = coordInput();

        if (!isValidCoordinate(coord, board)) {
          print("Неверные координаты или место занято. Попробуйте снова.");
          continue;
        }

        if (shipSize > 1) {
          print("Выберите ориентацию корабля: 1. Горизонтально, 2. Вертикально:");
          Position position = intInput() == 1 ? Position.horizontal : Position.vertical;

          print("Выберите направление: 1. Влево/Вверх, 2. Вправо/Вниз:");
          Direction direction = position == Position.horizontal
              ? (intInput() == 1 ? Direction.left : Direction.right)
              : (intInput() == 1 ? Direction.up : Direction.down);

          if (!placeShip(board, coord, shipSize, position, direction)) {
            print("Невозможно разместить корабль в выбранной позиции. Попробуйте снова.");
            continue;
          }
        } else {
          board[coord.y][coord.x] = "[1]";
        }

        break;
      }
    }
  }

  return board;
}

bool isValidCoordinate(Vector coord, List<List<String>> board) {
  return coord.x >= 0 && coord.x < FIELD_LENGTH &&
         coord.y >= 0 && coord.y < FIELD_LENGTH &&
         board[coord.y][coord.x] == "[ ]";
}

bool placeShip(List<List<String>> board, Vector coord, int size, Position position, Direction direction) {
  for (int i = 0; i < size; i++) {
    int x = coord.x + (position == Position.horizontal ? (direction == Direction.right ? i : -i) : 0);
    int y = coord.y + (position == Position.vertical ? (direction == Direction.down ? i : -i) : 0);

    if (x < 0 || x >= FIELD_LENGTH || y < 0 || y >= FIELD_LENGTH || board[y][x] != "[ ]") {
      return false;
    }
  }

  for (int i = 0; i < size; i++) {
    int x = coord.x + (position == Position.horizontal ? (direction == Direction.right ? i : -i) : 0);
    int y = coord.y + (position == Position.vertical ? (direction == Direction.down ? i : -i) : 0);
    board[y][x] = "[$size]";
  }

  return true;
}

void playGame(Player firstPlayer, Player secondPlayer) {
  print("Игра началась!\nПервым ходит ${firstPlayer.name}");
  Player currentPlayer = firstPlayer;
  Player opponentPlayer = secondPlayer;

  while (true) {
    print("Поле игрока ${currentPlayer.name}:");
    printBoard(currentPlayer.playerBattleField);

    print("${currentPlayer.name}, введите координаты для атаки (X и Y через пробел):");
    Vector coord = coordInput();

    if (!isValidCoordinate(coord, currentPlayer.playerBattleField)) {
      print("Неверные координаты или вы уже стреляли сюда. Попробуйте снова.");
      continue;
    }

    currentPlayer.totalMoves++;

    if (opponentPlayer.playerField[coord.y][coord.x] != "[ ]") {
      print("Попадание! Корабль противника поврежден.");
      currentPlayer.playerBattleField[coord.y][coord.x] = "[X]";
      opponentPlayer.playerField[coord.y][coord.x] = "[X]";
      currentPlayer.hits++;

      if (checkAllShipsDestroyed(opponentPlayer.playerField)) {
        print("Игрок ${currentPlayer.name} победил! Все корабли противника уничтожены.");
        saveStatistics(firstPlayer, secondPlayer);
        break;
      }

      // Игрок сохраняет ход
      continue;
    } else {
      print("Мимо! Вы промахнулись.");
      currentPlayer.playerBattleField[coord.y][coord.x] = "[O]";
      currentPlayer.misses++;
    }

    Player temp = currentPlayer;
    currentPlayer = opponentPlayer;
    opponentPlayer = temp;
  }
}

bool checkAllShipsDestroyed(List<List<String>> board) {
  for (var row in board) {
    if (row.any((cell) => cell != "[ ]" && cell != "[X]")) {
      return false;
    }
  }
  return true;
}

void saveStatistics(Player firstPlayer, Player secondPlayer) async {
  final file = File('game-stat/game_statistics.txt');
  var statDir = Directory("game-stat");
  if (!await statDir.exists()){
    Directory("game-stat").create();
  }
  final now = DateTime.now();
  final result = "Дата: $now\n" +
      "Игрок 1: ${firstPlayer.name}\n" +
      "  Попадания: ${firstPlayer.hits}, Промахи: ${firstPlayer.misses}, Ходы: ${firstPlayer.totalMoves}\n" +
      "Игрок 2: ${secondPlayer.name}\n" +
      "  Попадания: ${secondPlayer.hits}, Промахи: ${secondPlayer.misses}, Ходы: ${secondPlayer.totalMoves}\n\n";
  file.writeAsStringSync(result, mode: FileMode.append);
}

Vector coordInput() {
  while (true) {
    print("Введите X и Y через пробел:");
    String? input = stdin.readLineSync();
    if (input != null) {
      List<String> parts = input.split(' ');
      if (parts.length == 2) {
        try {
          return Vector()
            ..x = int.parse(parts[0])
            ..y = int.parse(parts[1]);
        } catch (_) {
          print("Ошибка: введите только целые числа.");
        }
      } else {
        print("Ошибка: введите ровно два числа через пробел.");
      }
    }
  }
}

int intInput() {
  while (true) {
    String? input = stdin.readLineSync();
    if (input != null) {
      int? value = int.tryParse(input);
      if (value != null) return value;
    }
    print("Введите корректное число.");
  }
}