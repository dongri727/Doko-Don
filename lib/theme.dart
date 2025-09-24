import 'package:flutter/material.dart';

class TaikoTheme {
  static AppBarTheme appBarTheme = AppBarTheme(
    backgroundColor: Color(0x80ffd700), 
    elevation: 6,
    shadowColor: Colors.blueGrey[50],
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      bottom: Radius.circular(8))),
  );
  static FloatingActionButtonThemeData floatingActionButtonTheme = const FloatingActionButtonThemeData(
    backgroundColor: Color(0x80ffd700),
  );
}
