import 'dart:io';
import 'dart:convert';

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

class Task {
  String name;
  bool isCompleted;

  Task({required this.name, this.isCompleted = false});

  Map<String, dynamic> toJson() => {
        'name': name,
        'is_completed': isCompleted,
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        name: json['name'],
        isCompleted: json['is_completed'],
      );
}

class TaskStorage {
  static const String _filePath = 'tasks.json';
  Map<String, dynamic> _data = {
    'currview': 'daily',
  };

  Future<void> load() async {
    try {
      final file = File(_filePath);
      if (await file.exists()) {
        final contents = await file.readAsString();
        _data = json.decode(contents);
      }
    } catch (e) {
      print('Error loading tasks: $e');
    }
  }

  Future<void> save() async {
    try {
      final file = File(_filePath);
      await file.writeAsString(json.encode(_data));
    } catch (e) {
      print('Error saving tasks: $e');
    }
  }

  List<Task> getTasksForDate(String date) {
    final List<dynamic> tasks = _data[date] ?? [];
    return tasks.map((task) => Task.fromJson(task)).toList();
  }

  Future<void> addTask(String date, Task task) async {
    if (!_data.containsKey(date)) {
      _data[date] = [];
    }
    (_data[date] as List).add(task.toJson());
    await save();
  }

  Future<void> updateTask(String date, int index, Task task) async {
    if (_data.containsKey(date) && (_data[date] as List).length > index) {
      (_data[date] as List)[index] = task.toJson();
      await save();
    }
  }
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

//Daily View Structure
class DailyView extends StatefulWidget {
  @override
  _DailyViewState createState() => _DailyViewState();
}

class _DailyViewState extends State<DailyView> {
  String currentDate = DateTime.now().toString().split(' ')[0];
  final TaskStorage storage = TaskStorage();
  late Future<List<Task>> tasks;

  @override
  void initState() {
    super.initState();
    tasks = _loadTasks();
  }

  Future<List<Task>> _loadTasks() async {
    await storage.load(); // Load data from file
    return storage.getTasksForDate(currentDate);
  }

  void _toggleTaskCompletion(int index) async {
    // Accessing the task list through the FutureBuilder's snapshot
    List<Task> taskList = await tasks;
    Task task = taskList[index];
    task.isCompleted = !task.isCompleted;
    await storage.updateTask(currentDate, index, task);
    setState(() {
      tasks = _loadTasks(); // Reload the tasks after updating
    });
  }

  void _addTask(BuildContext context) async {
    String taskName = ''; // Store the input task name

    // Show dialog to get the task name
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Task'),
          content: TextField(
            onChanged: (value) {
              taskName = value;
            },
            decoration: InputDecoration(hintText: 'Enter task name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (taskName.isNotEmpty) {
                  // Add task to storage if name is not empty
                  Task newTask = Task(name: taskName);
                  storage.addTask(currentDate, newTask);
                  setState(() {
                    tasks = _loadTasks(); // Reload tasks after adding
                  });
                  Navigator.pop(context);
                }
              },
              child: Text('Add'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tasks for $currentDate'),
      ),
      body: FutureBuilder<List<Task>>(
        future: tasks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading tasks.'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No tasks for today.'));
          }

          List<Task> taskList = snapshot.data!;

          return ListView.builder(
            itemCount: taskList.length,
            itemBuilder: (context, index) {
              final task = taskList[index];
              return ListTile(
                title: Text(task.name),
                leading: Checkbox(
                  value: task.isCompleted,
                  onChanged: (bool? value) {
                    _toggleTaskCompletion(index); // Use index to toggle
                  },
                ),
              );
            },
          );
        },
      ),
      // FloatingActionButton to add tasks
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addTask(context); // Show dialog to add task
        },
        backgroundColor: Colors.orange[800],
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
