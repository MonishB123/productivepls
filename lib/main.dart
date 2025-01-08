import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_size/window_size.dart';

void main() {
  //set fixed windows size
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    setWindowTitle("productivepls");
    const prefSize = Size(900, 1200);
    setWindowMaxSize(prefSize);
    setWindowMinSize(prefSize);
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
      home: DailyView(),
    );
  }
}

class DailyView extends StatelessWidget {
  final List<String> tasks = [
    "Finish Flutter project",
    "Review pull requests",
    "Prepare for meeting",
    "Work out for 30 mins",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Todo List',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.orange[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Daily View',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
              ),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 2.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: ListTile(
                      leading: Checkbox(
                        value: false,
                        onChanged: (bool? value) {},
                        activeColor: Colors.orange,
                      ),
                      title: Text(tasks[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.orange[800],
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
