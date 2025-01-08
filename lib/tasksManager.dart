import 'dart:io';
import 'dart:convert';

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

  Future<void> removeTask(String date, int index) async {
    if (_data.containsKey(date) && (_data[date] as List).length > index) {
      (_data[date] as List).removeAt(index); // Remove the task at the index
      await save(); // Save the updated data
    }
  }

  Future<void> updateTask(String date, int index, Task task) async {
    if (_data.containsKey(date) && (_data[date] as List).length > index) {
      (_data[date] as List)[index] = task.toJson();
      await save();
    }
  }
}
