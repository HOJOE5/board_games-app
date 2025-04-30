// lib/main.dart
import 'package:flutter/material.dart';
import 'ui/home_screen.dart';

void main() => runApp(const GameHubApp());

class GameHubApp extends StatelessWidget {
  const GameHubApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Board Games App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}
