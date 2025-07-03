import 'package:productivepls/tasks_manager.dart';
import 'package:productivepls/weekly.dart';

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import 'package:screen_capturer/screen_capturer.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'dart:ffi';
import 'package:win32/win32.dart';

int? _appWindowHandle;

void hideWindow() {
  final hwnd =
      GetForegroundWindow(); // Gets the handle of the current active window
  if (hwnd != 0) {
    _appWindowHandle = hwnd; // Store the handle
    ShowWindow(hwnd, SW_HIDE);
    print('Window hidden.');
  } else {
    print('Could not get foreground window handle.');
  }
}

void showWindow() {
  if (_appWindowHandle != null && _appWindowHandle != 0) {
    ShowWindow(_appWindowHandle!, SW_SHOW);
    // Add this line to bring the window to the foreground and give it focus
    SetForegroundWindow(_appWindowHandle!);
    print('Window shown.');
    _appWindowHandle = null;
  } else {
    print('No window handle stored or window already shown/never hidden.');
  }
}

IconButton Screenshot_Button(BuildContext context) {
  return IconButton(
    icon: const Icon(Icons.add_a_photo),
    onPressed: () async {
      hideWindow(); // Hide the app before capturing

      await Future.delayed(const Duration(milliseconds: 300));

      // Prompt screen capture
      CapturedData? capturedData = await screenCapturer.capture(
        mode: CaptureMode.region,
        copyToClipboard: true,
        silent: false,
      );

      showWindow(); // 🔼 Show the app after capture

      // Load Gemini key
      await dotenv.load();
      final String geminiKey = dotenv.get("GEMINI_API_KEY");
      if (geminiKey.isEmpty) {
        print("Missing GEMINI_API_KEY");
        return;
      }

      Gemini model =
          Gemini.init(apiKey: geminiKey, disableAutoUpdateModelName: true);

      // model.listModels().then((models) {
      //   for (GeminiModel model in models) {
      //     print(model.name);
      //   }
      // })

      /// list
      // .catchError((e) => print('listModels'));

      Uint8List? screenshot;

      // Try to use captured data first
      if (capturedData != null && capturedData.imageBytes != null) {
        screenshot = capturedData.imageBytes!;
      }

      // If capture failed, try clipboard as fallback
      if (screenshot == null) {
        await Future.delayed(Duration(milliseconds: 300)); // small wait
        screenshot = await screenCapturer.readImageFromClipboard();

        if (screenshot != null) {
          print("Fallback: Used image from clipboard");
        } else {
          print("Both capture and clipboard failed.");
          return;
        }
      }

      // Send to Gemini
      final result = await model.textAndImage(
        text: """
If this is an event that I should put on my calendar, return a JSON object (no formatting, raw text) with the following keys:
events (contains a list of event), event (contains a short key string called description (include the hour and minute if provided and not midnight) and a the key string date in YYYY-MM-DD format, ONLY IF NO DATE IS PROVIDED (MAKE SURE TO CHECK IF A DATE ISNT GIVEN PLEASE), use if no date is provided, use the current date, ${DateFormat('yyyy-MM-dd').format(DateTime.now())}),
else return only the string null.
""",
        modelName: "gemini-2.5-flash-lite-preview-06-17",
        images: [screenshot],
      );
      String response =
          result?.content?.toJson()['parts'][0]['text'] ?? "error";

      if (response == "null") {
        return;
      }
      dynamic jsonResponse = jsonDecode(response);
      print(jsonResponse['events']);

      List<Event> tasks = [];
      for (dynamic event in jsonResponse['events']) {
        tasks.add(Event(title: event['description'], dateTime: event['date']));
      }

      TaskStorage manager = TaskStorage();
      manager.load();

      showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext dialogContext) {
            List<Event> dialogTasks = List<Event>.from(tasks);

            return StatefulBuilder(builder: (context, setState) {
              return Center(
                child: Container(
                  width: 350,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F6F8),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Material(
                            child: Text(
                              'New Task Assignments',
                              style: TextStyle(
                                color: Color(0xFF5D576B),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: Color(0xFF5D576B)),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Task List
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            children: dialogTasks
                                .map((task) => TaskCard(
                                      task: task,
                                      onAccept: () {
                                        setState(() {
                                          dialogTasks.remove(task);
                                        });
                                        manager.addTask(task.dateTime,
                                            Task(name: task.title));
                                      },
                                      onDecline: () {
                                        setState(() {
                                          dialogTasks.remove(task);
                                        });
                                      },
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Add All to Calendar Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC8BFD1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            for (Event event in dialogTasks) {
                              manager.addTask(
                                  event.dateTime, Task(name: event.title));
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => WeeklyView()));
                            }
                          },
                          child: const Text(
                            'Add All to Calendar',
                            style: TextStyle(color: Color(0xFF5D576B)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            });
          }).then((_) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => WeeklyView()));
      });
    },
  );
}

class TaskCard extends StatelessWidget {
  final Event task;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const TaskCard({
    super.key,
    required this.task,
    this.onAccept,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            child: Text(task.title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF5D576B))),
          ),
          const SizedBox(height: 4),
          Material(
              child: Text(task.dateTime,
                  style: const TextStyle(color: Color(0xFF5D576B)))),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA8D0A1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: onAccept,
                  child: const Text(
                    'Accept',
                    style: TextStyle(color: Color(0xFFF8F6F8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE0B3B3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: onDecline,
                  child: const Text(
                    'Decline',
                    style: TextStyle(color: Color(0xFFF8F6F8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Event {
  final String title;
  final String dateTime;

  Event({required this.title, required this.dateTime});
}
