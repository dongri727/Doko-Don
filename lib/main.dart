import 'package:flutter/material.dart';
import 'utils/theme.dart';
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
      title: "DoDon",
      theme: ThemeData(
        appBarTheme: TaikoTheme.appBarTheme,
        floatingActionButtonTheme: TaikoTheme.floatingActionButtonTheme,
      ),
      debugShowCheckedModeBanner: false,
      home: TopPage(),
    );
  }
}

