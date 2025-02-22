import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

Future<void> writeAndUploadText(String textContent) async {
  // Get a temporary directory to store the file
  Directory tempDir = await getTemporaryDirectory();
  // Generate a timestamp for the file name
  String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
  // Create a file with the current timestamp as its name
  File file = File('${tempDir.path}/$timestamp.txt');

  // Write the provided string to the file
  await file.writeAsString(textContent);

  // Upload the file to Firebase Storage
  await uploadFile(file);
}

Future<void> uploadFile(File file) async {
  // Create a reference to the storage location using the file's name
  Reference storageRef = FirebaseStorage.instance.ref().child('text/${file.uri.pathSegments.last}');

  // Start the file upload
  UploadTask uploadTask = storageRef.putFile(file);

  // Await completion and get the download URL
  TaskSnapshot snapshot = await uploadTask;
  String downloadUrl = await snapshot.ref.getDownloadURL();
  print('File uploaded at: $downloadUrl');
}
