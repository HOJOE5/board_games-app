import 'package:flutter/material.dart';
import 'ui/home_screen.dart';

void main() {
  runApp(const BoardGamesApp());
}

class BoardGamesApp extends StatelessWidget {
  const BoardGamesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Board Games App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}
