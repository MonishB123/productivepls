import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_size/window_size.dart';
import 'package:productivepls/weekly.dart';

void main() {
  //set fixed windows size
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    setWindowTitle("productivepls");
    const prefSize = Size(900, 1250);
    setWindowMaxSize(prefSize);
    setWindowMinSize(prefSize);
    setWindowFrame(Rect.fromLTWH(100, 100, prefSize.width, prefSize.height));
  }
  runApp(TodoApp());
}

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Productive Pls',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.orange[50],
      ),
      home: WeeklyView(),
    );
  }
}
