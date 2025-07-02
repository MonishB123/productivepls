import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import 'package:productivepls/tasks_manager.dart';
import 'package:productivepls/weekly.dart';
import 'package:productivepls/monthly.dart';

class DailyView extends StatefulWidget {
  String? date;
  DailyView({Key? key, this.date}) : super(key: key);

  @override
  _DailyViewState createState() => _DailyViewState();
}

class _DailyViewState extends State<DailyView> {
  late String currentDate;
  final TaskStorage storage = TaskStorage();
  late Future<List<Task>> tasks;

  @override
  void initState() {
    super.initState();
    currentDate = widget.date ?? DateTime.now().toString().split(' ')[0];
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
          title: const Text('Add New Task'),
          content: TextField(
            onChanged: (value) {
              taskName = value;
            },
            decoration: const InputDecoration(hintText: 'Enter task name'),
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
              child: const Text('Add'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _deleteTask(int index) async {
    List<Task> taskList = await tasks;
    taskList.removeAt(index); // Remove task from the list
    storage.removeTask(currentDate, index);
    // Update the storage after deleting the task
    await storage.save();
    setState(() {
      tasks = _loadTasks(); // Reload tasks after deleting
    });
  }

  void _changeDate(KeyEvent keyEvent) {
    setState(() {
      if (keyEvent is KeyDownEvent &&
          keyEvent.logicalKey == LogicalKeyboardKey.arrowUp) {
        // Navigate to the previous day
        currentDate = _getPreviousDate(currentDate);
        tasks = _loadTasks(); // Reload tasks for the new date
      } else if (keyEvent is KeyDownEvent &&
          keyEvent.logicalKey == LogicalKeyboardKey.arrowDown) {
        // Navigate to the next day
        currentDate = _getNextDate(currentDate);
        tasks = _loadTasks(); // Reload tasks for the new date
      } else if (keyEvent is KeyDownEvent &&
          keyEvent.logicalKey == LogicalKeyboardKey.altLeft) {
        _addTask(context);
      }
    });
  }

  String _getPreviousDate(String date) {
    DateTime current = DateFormat('yyyy-MM-dd').parse(date);
    DateTime previousDay = current.subtract(const Duration(days: 1));
    return DateFormat('yyyy-MM-dd').format(previousDay);
  }

  String _getNextDate(String date) {
    DateTime current = DateFormat('yyyy-MM-dd').parse(date);
    DateTime nextDay = current.add(const Duration(days: 1));
    return DateFormat('yyyy-MM-dd').format(nextDay);
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (keyEvent) {
        _changeDate(keyEvent); // Update date based on key event
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Tasks for $currentDate'),
          backgroundColor: Color.fromARGB(255, 237, 228, 216),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.view_week),
              tooltip: 'Weekly View',
              onPressed: () {
                //navigate to weekly page
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => WeeklyView()));
              },
            ),
            IconButton(
              icon: const Icon(Icons.calendar_month),
              tooltip: 'Monthly View',
              onPressed: () {
                //navigate to monthly page
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => MonthlyView()));
              },
            ),
          ],
        ),
        body: FutureBuilder<List<Task>>(
          future: tasks,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text('Error loading tasks.'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No tasks for today.'));
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
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      _deleteTask(index); // Delete task when "X" is pressed
                    },
                  ),
                );
              },
            );
          },
        ),
        // FloatingActionButton to add tasks
        floatingActionButton: FloatingActionButton(
          elevation: 0,
          onPressed: () {
            _addTask(context); // Show dialog to add task
          },
          backgroundColor: const Color.fromARGB(163, 232, 222, 208),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
