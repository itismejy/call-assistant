import 'package:frontend/globals/global_variables.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

generateAndSaveUID(String name) async {
  var uuid = Uuid();
  String uniqueId = uuid.v4();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  myUID = uniqueId;
  await prefs.setString('myUID', uniqueId);
  await prefs.setString('myName', name);
}
