import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:snake_game/constants.dart';
import 'package:snake_game/controllers/game_controller.dart';
import 'package:snake_game/controllers/highscore_tile.dart';
import 'package:snake_game/models/blank_pixel.dart';
import 'package:snake_game/models/food_pixel.dart';
import 'package:snake_game/models/snake_pixel.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

// ignore: camel_case_types, constant_identifier_names
enum snake_direction { UP, DOWN, LEFT, RIGHT }

class _HomePageState extends State<HomePage> {
  // GRID DIMENSIONS
  int rowSize = 10;
  int totalNumberOfSquares = 100;

  // SNAKE POSITION
  List<int> snakePos = [
    0,
    1,
    2,
  ];

  // SNAKE DIRECTION IS INITALLY TO THE RIGHT
  var currentDirection = snake_direction.RIGHT;

  // HIGHSCORE LIST
  // ignore: non_constant_identifier_names
  List<String> highscore_DocIds = [];
  late final Future? letsGetDocIds;

  @override
  void initState() {
    letsGetDocIds = getDocId();
    super.initState();
  }

  Future getDocId() async {
    await FirebaseFirestore.instance
        .collection("highscores")
        .orderBy("score", descending: true)
        .limit(10)
        .get()
        .then((value) => value.docs.forEach((element) {
              highscore_DocIds.add(element.reference.id);
            }));
  }

  //START GAME
  void startGame() {
    gameHasStarted = true;
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      setState(() {
        // KEEP THE SNAKE MOVING
        moveSnake();

        // CHECK IF THE GAME IS OVER
        if (gameOver()) {
          timer.cancel();
          // DISPLAY A MESSAGE TO THE USER
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return AlertDialog(
                  title: const Text(
                    'Game Over!',
                  ),
                  content: Column(
                    children: [
                      Text('Your score is: $currentScore'),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          hintText: 'Enter name',
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    MaterialButton(
                      onPressed: () {
                        Navigator.pop(context);
                        submitScore();
                        newGame();
                      },
                      color: Colors.pink,
                      child: const Text(
                        'Submit',
                        style: TextStyle(
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                );
              });
        }
      });
    });
  }

  Future newGame() async {
    highscore_DocIds = [];
    await getDocId();
    setState(() {
      snakePos = [
        0,
        1,
        2,
      ];
      foodPos = Random().nextInt(totalNumberOfSquares) + 1;
      gameHasStarted = false;
      currentScore = 0;
      currentDirection = snake_direction.RIGHT;
    });
  }

  void eatFood() {
    currentScore++;
    // MAKING SURE THE NEW FOOD IS NOT WHERE THE SNAKE IS
    while (snakePos.contains(foodPos)) {
      foodPos = Random().nextInt(totalNumberOfSquares);
    }
  }

  void moveSnake() {
    switch (currentDirection) {
      case snake_direction.RIGHT:
        {
          // ADD A HEAD
          // IF SNAKE IS AT THE RIGHT WALL, NEED TO READJUST
          if (snakePos.last % rowSize == 9) {
            snakePos.add(snakePos.last + 1 - rowSize);
          } else {
            snakePos.add(snakePos.last + 1);
          }
        }

        break;
      case snake_direction.LEFT:
        {
          // IF SNAKE IS AT THE RIGHT WALL, NEED TO READJUST
          if (snakePos.last % rowSize == 0) {
            snakePos.add(snakePos.last - 1 + rowSize);
          } else {
            snakePos.add(snakePos.last - 1);
          }
        }

        break;
      case snake_direction.UP:
        {
          // ADD A HEAD
          if (snakePos.last < rowSize) {
            snakePos.add(snakePos.last - rowSize + totalNumberOfSquares);
          } else {
            snakePos.add(snakePos.last - rowSize);
          }
        }

        break;
      case snake_direction.DOWN:
        {
          // ADD A HEAD
          if (snakePos.last + rowSize > totalNumberOfSquares) {
            snakePos.add(snakePos.last + rowSize - totalNumberOfSquares);
          } else {
            snakePos.add(snakePos.last + rowSize);
          }
        }

        break;
      default:
    }

    // SNAKE IS EATING FOOD
    if (snakePos.last == foodPos) {
      eatFood();
    } else {
      // REMOVE TAIL
      snakePos.removeAt(0);
    }
  }

  // GAME OVER
  bool gameOver() {
    // GAME IS OVER WHEN SNAKE HITS ITSELF
    // THIS OCCURS WHEN SNAKEPOS IS DUPLICATED

    // THIS LIST IS THE BODY OF THE SNAKE, NO HEAD
    List<int> bodySnake = snakePos.sublist(0, snakePos.length - 1);

    if (bodySnake.contains(snakePos.last)) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // GET THE SCREEN WIDTH
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SizedBox(
        width: screenWidth > 400 ? 400 : screenWidth,
        child: Column(
          children: [
            // SCORES
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // CURRENT SCORE
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Current Score',
                          style: TextStyle(
                            color: textColor,
                          ),
                        ),
                        Text(
                          currentScore.toString(),
                          style: const TextStyle(
                            fontSize: 36,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // HIGHSCORES
                  Expanded(
                    child: gameHasStarted
                        ? Container()
                        : FutureBuilder(
                            future: letsGetDocIds,
                            builder: (context, snapshot) {
                              return ListView.builder(
                                itemCount: highscore_DocIds.length,
                                itemBuilder: ((context, index) {
                                  return HighScoreTile(
                                    documentId: highscore_DocIds[index],
                                  );
                                }),
                              );
                            },
                          ),
                  )
                ],
              ),
            ),

            // GAME GRID
            Expanded(
              flex: 3,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  if (details.delta.dy > 0 &&
                      currentDirection != snake_direction.UP) {
                    currentDirection = snake_direction.DOWN;
                  } else if (details.delta.dy < 0 &&
                      currentDirection != snake_direction.DOWN) {
                    currentDirection = snake_direction.UP;
                  }
                },
                onHorizontalDragUpdate: (details) {
                  if (details.delta.dx > 0 &&
                      currentDirection != snake_direction.LEFT) {
                    currentDirection = snake_direction.RIGHT;
                  } else if (details.delta.dx < 0 &&
                      currentDirection != snake_direction.RIGHT) {
                    currentDirection = snake_direction.LEFT;
                  }
                },
                child: GridView.builder(
                  itemCount: totalNumberOfSquares,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: rowSize,
                  ),
                  itemBuilder: ((context, index) {
                    if (snakePos.contains(index)) {
                      return const SnakePixel();
                    } else if (foodPos == index) {
                      return const FoodPixel();
                    } else {
                      return const BlankPixel();
                    }
                  }),
                ),
              ),
            ),

            // PLAY BUTTON
            Expanded(
              child: Container(
                child: Center(
                  child: MaterialButton(
                    onPressed: gameHasStarted ? () {} : startGame,
                    color: gameHasStarted ? Colors.grey : buttonColor,
                    child: const Text(
                      'PLAY',
                      style: TextStyle(
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
