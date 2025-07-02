import 'dart:typed_data';

import 'package:screen_capturer/screen_capturer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

IconButton Screenshot_Button() {
  return IconButton(
    icon: const Icon(Icons.add_a_photo),
    onPressed: () async {
      try {
        // Prompt screen capture
        CapturedData? capturedData = await screenCapturer.capture(
          mode: CaptureMode.region,
          copyToClipboard: true,
          silent: false,
        );

        // Load Gemini key
        await dotenv.load();
        final String geminiKey = dotenv.get("GEMINI_API_KEY") ?? "";
        if (geminiKey.isEmpty) {
          print("Missing GEMINI_API_KEY");
          return;
        }

        Gemini model =
            Gemini.init(apiKey: geminiKey, disableAutoUpdateModelName: true);

        model.listModels().then((models) {
          for (GeminiModel model in models) {
            print(model.name);
          }
        })

            /// list
            .catchError((e) => print('listModels'));

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
If this is an event that I should put on my calendar, return a JSON object with the following keys:
events (contains a list of event), event (contains a string called description and a string date in YYYY-MM-DD format),
else return only the string null
""",
          modelName: "gemini-2.0-flash",
          images: [screenshot],
        );

        print(result?.content?.toJson()['parts'][0]['text'] ?? "error");
      } catch (e, stackTrace) {
        print("Error: $e\n$stackTrace");
      }
    },
  );
}
