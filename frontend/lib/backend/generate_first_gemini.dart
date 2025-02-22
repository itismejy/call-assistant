import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:frontend/backend/system_prompt.dart';
import 'package:http/http.dart' as http;

Future<String?> startCallGemini(String eventInput) async {
  // url = GeminiURL
  final headers = {"Content-Type": "application/json"};

  // Build the contents array using the provided messages
  final contents = [
    {
      "role": "user",
      "parts": [
        {"text": "${eventInput}"},
      ],
    },
  ];

  final payload = {
    "generationConfig": {"temperature": 1},
    "systemInstruction": {
      "parts": {
        "text": """Your job is to make a restaurant reservation. If the call history is empty, make a text script for a reservation call to the selected restaurant, including the information:
- Time: based on the availability in the group chat. If there's no time specified in chat, go for any reasonable time.
- Number of people: based on the number of people talking in the chat
- Name: use the name of the last person to talk in the chat
- Phone number: for now just use 206-123-556 as the phone number

YOUR OBJECTIVE:
Output a introduction message to the restaraunt owner. No further details will be provided, make up information if needed.

See example here:
Hi, I'd like to make a reservation for tonight. We'd like to come at 7 PM, and there will be three of us. The name is Jason, and the phone number is 206-123-556,.
""",
      },
    },
    "contents": contents,
  };

  try {
    final response = await http.post(Uri.parse(url), headers: headers, body: jsonEncode(payload));

    if (response.statusCode == 200) {
      debugPrint("GEMINI CALL");
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
