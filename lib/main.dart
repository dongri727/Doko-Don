import 'package:flutter/material.dart';
import 'home_page.dart';

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
        useMaterial3: true,
        primarySwatch: Colors.green,
      ),

      home: HomePage(),
    );
  }
}

