import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';


final nameController = TextEditingController();
bool gameHasStarted = false;
int currentScore = 0;
int foodPos = 55;

void submitScore() {
    // GET ACCESS TO THE COLLECTION
    var database = FirebaseFirestore.instance;
    // ADD DATA TO FIREBASE
    database.collection('highscores').add({
      "name": nameController.text,
      "score": currentScore,
    });
  }

