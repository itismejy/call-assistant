import 'package:flutter/material.dart';
import 'package:frontend/backend/generate_first_gemini.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:frontend/backend/upload_file.dart';

Future<bool?> showAcceptRejectDialog(BuildContext context, String text) {
  return showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text("Event Suggestion"),
          content: Text(text),
          actions: [
            TextButton(
              onPressed: () async {
                String? callText = await startCallGemini(text);
                if (callText != null) {
                  Navigator.of(context).pop();
                  Fluttertoast.showToast(msg: "Calling for you!", toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM, backgroundColor: Colors.black, textColor: Colors.white, fontSize: 16.0);
                  writeAndUploadText(callText);
                }
              },
              child: const Text("Accept"),
            ),
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Reject")),
          ],
        ),
  );
}
