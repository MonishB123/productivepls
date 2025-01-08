import 'package:productivepls/main.dart';
import 'package:flutter/material.dart';
import 'package:productivepls/tasksManager.dart';
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
      DateTime startOfWeek =
          DateTime.parse(currentWeekStartDate).subtract(Duration(days: 7));
      currentWeekStartDate = _getStartOfWeek(startOfWeek);
      currentWeekEndDate = _getEndOfWeek(startOfWeek);
      weeklyTasks = _loadWeeklyTasks();
    });
  }

  // Navigate to the next week
  void _nextWeek() {
    setState(() {
      DateTime startOfWeek =
          DateTime.parse(currentWeekStartDate).add(Duration(days: 7));
      currentWeekStartDate = _getStartOfWeek(startOfWeek);
      currentWeekEndDate = _getEndOfWeek(startOfWeek);
      weeklyTasks = _loadWeeklyTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weekly Tasks'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _previousWeek, // Navigate to the previous week
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _nextWeek, // Navigate to the next week
          ),
        ],
      ),
      body: FutureBuilder<Map<String, List<Task>>>(
        future: weeklyTasks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading tasks.'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No tasks for this week.'));
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => DailyView(date: dateString)),
                  );
                },
                child: Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$dayOfWeek, $dateString',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[800],
                              ),
                        ),
                        SizedBox(height: 8),
                        taskList.isEmpty
                            ? Text('No tasks for today.',
                                style: TextStyle(color: Colors.grey))
                            : Column(
                                children: taskList.map((task) {
                                  return ListTile(
                                    title: Text(
                                      task.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: task.isCompleted
                                            ? Colors.green
                                            : Colors.black,
                                      ),
                                    ),
                                    leading: Checkbox(
                                      value: task.isCompleted,
                                      onChanged: (bool? value) {
                                        // Update task completion status
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
