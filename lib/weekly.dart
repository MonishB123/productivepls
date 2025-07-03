import 'package:productivepls/monthly.dart';
import 'package:productivepls/daily.dart';
import 'package:productivepls/screenshotbutton.dart';

import 'package:flutter/material.dart';
import 'package:productivepls/tasks_manager.dart';
import 'package:intl/intl.dart';

class WeeklyView extends StatefulWidget {
  @override
  _WeeklyViewState createState() => _WeeklyViewState();
}

class _WeeklyViewState extends State<WeeklyView> {
  late String currentWeekStartDate;
  late String currentWeekEndDate;
  final TaskStorage storage = TaskStorage();
  late Future<Map<String, List<Task>>> weeklyTasks;

  @override
  void initState() {
    super.initState();
    // Get the start and end date of the current week
    currentWeekStartDate = _getStartOfWeek(DateTime.now());
    currentWeekEndDate = _getEndOfWeek(DateTime.now());
    weeklyTasks = _loadWeeklyTasks();
  }

  Future<Map<String, List<Task>>> _loadWeeklyTasks() async {
    await storage.load(); // Load data from file
    Map<String, List<Task>> tasks = {};

    // Load tasks for each day in the week
    for (int i = 0; i < 7; i++) {
      DateTime day =
          DateTime.parse(currentWeekStartDate).add(Duration(days: i));
      String dateString = DateFormat('yyyy-MM-dd').format(day);
      tasks[dateString] = storage.getTasksForDate(dateString);
    }
    return tasks;
  }

  // Get the start date of the week
  String _getStartOfWeek(DateTime date) {
    DateTime startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    return DateFormat('yyyy-MM-dd').format(startOfWeek);
  }

  // Get the end date of the week
  String _getEndOfWeek(DateTime date) {
    DateTime endOfWeek = date.add(Duration(days: 7 - date.weekday));
    return DateFormat('yyyy-MM-dd').format(endOfWeek);
  }

  // Navigate to the previous week
  void _previousWeek() {
    setState(() {
      DateTime startOfWeek = DateTime.parse(currentWeekStartDate)
          .subtract(const Duration(days: 7));
      currentWeekStartDate = _getStartOfWeek(startOfWeek);
      currentWeekEndDate = _getEndOfWeek(startOfWeek);
      weeklyTasks = _loadWeeklyTasks();
    });
  }

  // Navigate to the next week
  void _nextWeek() {
    setState(() {
      DateTime startOfWeek =
          DateTime.parse(currentWeekStartDate).add(const Duration(days: 7));
      currentWeekStartDate = _getStartOfWeek(startOfWeek);
      currentWeekEndDate = _getEndOfWeek(startOfWeek);
      weeklyTasks = _loadWeeklyTasks();
    });
  }

  //Add new task for a day
  void _addTask(BuildContext context, String date) async {
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
                  storage.addTask(date, newTask);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => WeeklyView()),
                  );
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

  void _toggleTaskCompletion(String date, int index) async {
    if ((await weeklyTasks)[date] != null) {
      // Access the task list safely
      Task task = (await weeklyTasks)[date]![
          index]; // Use `!` because null check is already done
      task.isCompleted = !task.isCompleted;
      await storage.updateTask(date, index, task);
      setState(() {
        weeklyTasks = _loadWeeklyTasks(); // Reload the tasks after updating
      });
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Tasks'),
        backgroundColor: const Color.fromARGB(255, 237, 228, 216),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _previousWeek, // Navigate to the previous week
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _nextWeek, // Navigate to the next week
          ),
          IconButton(
            icon: const Icon(Icons.priority_high),
            tooltip: 'Daily View',
            onPressed: () {
              //navigate to weekly page
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => DailyView()));
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
          Screenshot_Button(context),
        ],
      ),
      body: FutureBuilder<Map<String, List<Task>>>(
        future: weeklyTasks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading tasks.'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tasks for this week.'));
          }

          Map<String, List<Task>> tasks = snapshot.data!;

          return ListView.builder(
            itemCount: 7,
            itemBuilder: (context, index) {
              DateTime day = DateTime.parse(currentWeekStartDate)
                  .add(Duration(days: index));
              String dateString = DateFormat('yyyy-MM-dd').format(day);
              List<Task> taskList = tasks[dateString] ?? [];
              String dayOfWeek = DateFormat('EEEE').format(day);

              return GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => DailyView(date: dateString)),
                  );
                },
                child: Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              // Day and Task display
                              '$dayOfWeek, $dateString',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: (dateString ==
                                            DateFormat('yyyy-MM-dd')
                                                .format(DateTime.now()))
                                        ? const Color.fromARGB(
                                            255, 143, 148, 140)
                                        : const Color.fromARGB(
                                            255, 150, 161, 163),
                                  ),
                            ),
                            Container(
                              //Button to add Tasks
                              height: 25,
                              width: 25,
                              child: FloatingActionButton(
                                elevation: 0,
                                heroTag: 'addTask-$dateString',
                                onPressed: () {
                                  _addTask(context, dateString);
                                },
                                backgroundColor: (dateString ==
                                        DateFormat('yyyy-MM-dd')
                                            .format(DateTime.now()))
                                    ? const Color.fromARGB(255, 143, 148, 140)
                                    : const Color.fromARGB(255, 150, 161, 163),
                                child:
                                    const Icon(Icons.add, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        taskList.isEmpty
                            ? const Text('No tasks for today.',
                                style: TextStyle(color: Colors.grey))
                            : Column(
                                children: taskList.asMap().entries.map((entry) {
                                  final index = entry.key; // Get the index
                                  final task = entry.value; // Get the task
                                  return ListTile(
                                    title: Text(
                                      task.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                      ),
                                    ),
                                    leading: Checkbox(
                                      activeColor:
                                          const Color.fromARGB(255, 95, 94, 94),
                                      value: task.isCompleted,
                                      onChanged: (bool? value) {
                                        // Use the index here
                                        _toggleTaskCompletion(
                                            dateString, index);
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
