import 'package:flutter/material.dart';
import 'package:frontend/backend/generate_first_gemini.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:frontend/backend/upload_file.dart';

Future<bool?> showResponseDialog(BuildContext context, String text) {
  return showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text("Successfully set up!"), content: Text(text), actions: [TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("OK"))]));
}
