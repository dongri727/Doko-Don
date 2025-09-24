import 'package:flutter/material.dart';
import 'theme.dart';
import 'top_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Doko Don",
      theme: ThemeData(
        appBarTheme: TaikoTheme.appBarTheme,
        floatingActionButtonTheme: TaikoTheme.floatingActionButtonTheme,
      ),

      home: TopPage(),
    );
  }
}

