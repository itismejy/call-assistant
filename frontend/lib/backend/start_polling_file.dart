import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:frontend/backend/show_response_dialog.dart';

void startPollingFile(BuildContext context) async {
  Timer.periodic(Duration(seconds: 3), (timer) async {
    try {
      print("polling!");
      // Reference the file in Firebase Storage
      Reference fileRef = FirebaseStorage.instance.ref().child('response/final.txt');

      // Fetch the file data (limit set to 1MB, adjust as needed)
      final data = await fileRef.getData(1024 * 1024);

      if (data != null) {
        // Convert the bytes to a string
        String fileContent = String.fromCharCodes(data);
        print('File content: $fileContent');
        showResponseDialog(context, fileContent);
        timer.cancel();
        return;
      } else {
        print('No data found in file.');
      }
    } catch (e) {
      print('Error fetching file: $e');
    }
  });
}
