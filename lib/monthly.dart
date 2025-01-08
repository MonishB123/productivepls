import 'package:flutter/material.dart';
import 'package:productivepls/tasks_manager.dart';
import 'package:productivepls/main.dart';
import 'package:productivepls/weekly.dart';

class MonthlyView extends StatefulWidget {
  @override
  _MonthlyViewState createState() => _MonthlyViewState();
}

class _MonthlyViewState extends State<MonthlyView> {
  late DateTime currentDate;
  late List<int> daysInMonth;
  final TaskStorage storage = TaskStorage();
  late Future<void> _loadDataFuture;

  @override
  void initState() {
    super.initState();
    currentDate = DateTime.now();
    daysInMonth = List.generate(
        DateTime(currentDate.year, currentDate.month + 1, 0).day, (i) => i + 1);
    _loadDataFuture = storage.load(); // Ensure we load the data asynchronously
  }

  // Update the month by adding or subtracting a month
  void _changeMonth(int change) {
    setState(() {
      currentDate = DateTime(currentDate.year, currentDate.month + change, 1);
      daysInMonth = List.generate(
          DateTime(currentDate.year, currentDate.month + 1, 0).day,
          (i) => i + 1);
    });
  }

  Future<bool> _areDailyTasksCompleted(String date) async {
    await storage.load(); // Make sure data is loaded before checking
    List<Task> tasks = storage.getTasksForDate(date);
    for (final task in tasks) {
      if (!task.isCompleted) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly View', style: TextStyle(fontSize: 24)),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.priority_high),
            tooltip: 'Daily View',
            onPressed: () {
              //navigate to weekly page
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => DailyView()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.view_week),
            tooltip: 'Weekly View',
            onPressed: () {
              //navigate to monthly page
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => WeeklyView()));
            },
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _loadDataFuture, // Wait for the data to load before building
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading tasks.'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_left),
                      onPressed: () =>
                          _changeMonth(-1), // Go to the previous month
                    ),
                    Text(
                      '${currentDate.month} / ${currentDate.year}',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_right),
                      onPressed: () => _changeMonth(1), // Go to the next month
                    ),
                  ],
                ),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7, // 7 days in a week
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                    itemCount: daysInMonth.length,
                    itemBuilder: (context, index) {
                      int day = daysInMonth[index];
                      String date =
                          '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

                      return FutureBuilder<bool>(
                        future: _areDailyTasksCompleted(
                            date), // Get completion status
                        builder: (context, taskSnapshot) {
                          if (taskSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          bool completed = taskSnapshot.data ?? false;

                          return GestureDetector(
                            onTap: () {
                              // Navigate to the Daily View for the selected date
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DailyView(date: date),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: completed
                                    ? Colors.green[200]
                                    : Colors.red[200],
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '$day',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show dialog to add task
        },
        backgroundColor: Colors.orange[800],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
