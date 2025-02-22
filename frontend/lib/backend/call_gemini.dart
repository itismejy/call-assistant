import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:frontend/backend/system_prompt.dart';
import 'package:http/http.dart' as http;

Future<String?> generateContent(List<Map<String, dynamic>> messages) async {
  // url = GEMINIURL
  final headers = {"Content-Type": "application/json"};

  // Build the contents array using the provided messages
  final contents =
      messages.map((msg) {
        return {
          "role": "user",
          "parts": [
            {"text": "${msg['sender']} ${msg["content"]}"},
          ],
        };
      }).toList();

  print(contents);

  final payload = {
    "generationConfig": {"temperature": 1},
    "systemInstruction": {
      "parts": {"text": getSystemPrompt()},
    },
    "contents": contents,
  };

  try {
    final response = await http.post(Uri.parse(url), headers: headers, body: jsonEncode(payload));

    if (response.statusCode == 200) {
      debugPrint("Response: ${response.body}");
      print(jsonDecode(response.body)['candidates'][0]['content']['parts'][0]['text']);
      return jsonDecode(response.body)['candidates'][0]['content']['parts'][0]['text'];
    } else {
      debugPrint("Error ${response.statusCode}: ${response.body}");
    }
  } catch (e) {
    debugPrint("Exception occurred: $e");
  }
  return null;
}
