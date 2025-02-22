import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:frontend/backend/create_chatroom.dart';
import 'package:frontend/backend/generate_save_id.dart';
import 'package:frontend/chatroom_page/chat_page.dart';
import 'package:frontend/firebase_options.dart';
import 'package:frontend/globals/global_firebase.dart';
import 'package:frontend/globals/global_variables.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pinput/pinput.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenWidthRatio = screenWidth / prototypeWidth;
    screenHeight = MediaQuery.of(context).size.height;
    screenHeightRatio = screenHeight / prototypeHeight;

    return MaterialApp(debugShowCheckedModeBanner: false, home: const MyHomePage());
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController nameController = TextEditingController();
  final pinController = TextEditingController();
  FocusNode nameFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = true;
  bool showPinPad = false;
  bool isValidPin = false;
  bool joiningRoom = false;
  PinTheme defaultPinTheme = PinTheme(width: 56, height: 56, textStyle: TextStyle(fontSize: 20, color: Colors.black), decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)));

  final focusedBorderColor = Color.fromRGBO(23, 171, 144, 1);
  final fillColor = Color.fromRGBO(243, 246, 249, 0);
  final borderColor = Color.fromRGBO(23, 171, 144, 0.4);
  String errorMessage = "";

  List<ConnectivityResult> connectionStatus = [ConnectivityResult.none];
  final Connectivity connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> connectivitySubscription;
  bool isConnected = false;

  @override
  void initState() {
    initConnectivity();
    connectivitySubscription = Connectivity().onConnectivityChanged.listen(updateConnectionStatus);

    super.initState();
  }

  Future<void> initConnectivity() async {
    try {
      late List<ConnectivityResult> result;

      result = await connectivity.checkConnectivity();
      return updateConnectionStatus(result);
    } catch (e, stacktrace) {
      print(e.toString());
      print(stacktrace.toString());
      return Future.value(null);
    }
  }

  Future<void> updateConnectionStatus(List<ConnectivityResult> result) async {
    print('Connectivity changed: $result');
    if (isConnected == true) {
      return;
    }
    if (result.contains(ConnectivityResult.mobile) || result.contains(ConnectivityResult.wifi) || result.contains(ConnectivityResult.bluetooth) || result.contains(ConnectivityResult.vpn) || result.contains(ConnectivityResult.ethernet) || result.contains(ConnectivityResult.other)) {
      isConnected = true;
      setUp();
    }
    setState(() {
      connectionStatus = result;
    });
  }

  setUp() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    myUID = prefs.getString('myUID') ?? "";
    myName = prefs.getString("myName") ?? "";

    if (myUID == "") {
      print("no uid!");
      generateAndSaveUID("");
      setState(() {
        isLoading = false;
      });
    } else {
      setState(() {
        nameController.text = myName;
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // 4. Dispose the controller when no longer needed.
    nameController.dispose();
    pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          height: screenHeight,
          width: screenWidth,
          child:
              isLoading
                  ? Center(child: CircularProgressIndicator())
                  : Stack(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Enter your name"),
                          SizedBox(height: 40 * screenHeightRatio),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 50 * screenWidthRatio),
                            child: Container(
                              child: TextFormField(
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'No name';
                                  }
                                  return null;
                                },
                                onTapOutside: (event) {
                                  nameFocusNode.unfocus();
                                },
                                controller: nameController,
                                focusNode: nameFocusNode,
                                decoration: InputDecoration(labelText: 'Please enter name', border: OutlineInputBorder()),
                                // 3. Optionally handle text changes.
                                onChanged: (value) {
                                  print('Current text: $value');
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: 60 * screenHeightRatio),

                          InkWell(
                            child: Container(width: screenWidth - 50 * screenWidthRatio * 2, alignment: Alignment.center, padding: EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.lightBlue, borderRadius: BorderRadius.circular(10)), child: Text("Create Room", style: TextStyle(color: Colors.white))),
                            onTap: () async {
                              if (_formKey.currentState!.validate()) {
                                int chatroomID = createChatroom(myUID);
                                await firestore.collection("chatrooms").doc(chatroomID.toString()).set({
                                  "host": myUID,
                                  "members": [myUID],
                                });
                                SharedPreferences prefs = await SharedPreferences.getInstance();
                                myName = nameController.text.trim();
                                await prefs.setString('myName', nameController.text.trim());
                                await firestore.collection("chatrooms").doc(chatroomID.toString()).collection("messages").doc().set({});
                                Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(chatID: chatroomID.toString())));
                              }
                            },
                          ),
                          SizedBox(height: 30 * screenHeightRatio),
                          InkWell(
                            child: Container(width: screenWidth - 50 * screenWidthRatio * 2, alignment: Alignment.center, padding: EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.lightGreen, borderRadius: BorderRadius.circular(10)), child: Text("Join Room", style: TextStyle(color: Colors.white))),
                            onTap: () {
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  showPinPad = true;
                                });
                              }
                            },
                          ),
                        ],
                      ),

                      if (showPinPad) const Opacity(opacity: 0.5, child: ModalBarrier(dismissible: false, color: Colors.black)),

                      if (showPinPad)
                        Center(
                          child: Directionality(
                            // Specify direction if desired
                            textDirection: TextDirection.ltr,
                            child: Container(
                              width: 250 * screenWidthRatio,
                              height: 200,
                              padding: EdgeInsets.all(15),

                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white),
                              child: Column(
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: InkWell(
                                      child: Icon(Icons.close),
                                      onTap: () {
                                        setState(() {
                                          showPinPad = false;
                                        });
                                      },
                                    ),
                                  ),
                                  const Spacer(),

                                  Pinput(
                                    keyboardType: TextInputType.number,
                                    // You can pass your own SmsRetriever implementation based on any package
                                    // in this example we are using the SmartAuth
                                    controller: pinController,
                                    // focusNode: focusNode,
                                    defaultPinTheme: defaultPinTheme,
                                    onTapOutside: (event) {
                                      // Hide keyboard when tapping outside
                                      FocusManager.instance.primaryFocus?.unfocus();
                                    },
                                    errorTextStyle: TextStyle(color: Colors.red),
                                    separatorBuilder: (index) => const SizedBox(width: 8),
                                    validator: (value) {
                                      return value != null && value.length == 4 ? null : 'Fill out the pin!';
                                    },
                                    hapticFeedbackType: HapticFeedbackType.lightImpact,
                                    onCompleted: (pin) async {
                                      debugPrint('onCompleted: $pin');
                                      setState(() {
                                        joiningRoom = true;
                                      });
                                      await Future.delayed(Duration(seconds: 1));
                                      await firestore.collection("chatrooms").doc(pin).get().then((value) async {
                                        isLoading = false;
                                        if (value.exists) {
                                          SharedPreferences prefs = await SharedPreferences.getInstance();
                                          myName = nameController.text.trim();
                                          await prefs.setString('myName', nameController.text.trim());
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(chatID: pin.toString())));
                                        } else {
                                          isValidPin = false;
                                          errorMessage = "Invalid Invite Code!";
                                          setState(() {});
                                        }
                                      });
                                    },
                                    onChanged: (value) {
                                      debugPrint('onChanged: $value');
                                      if (value.length < 4) {
                                        setState(() {
                                          isValidPin = false;
                                        });
                                      }
                                    },
                                    cursor: Column(mainAxisAlignment: MainAxisAlignment.end, children: [Container(margin: const EdgeInsets.only(bottom: 9), width: 22, height: 1, color: focusedBorderColor)]),
                                    focusedPinTheme: defaultPinTheme.copyWith(decoration: defaultPinTheme.decoration!.copyWith(borderRadius: BorderRadius.circular(8), border: Border.all(color: focusedBorderColor))),
                                    submittedPinTheme: defaultPinTheme.copyWith(decoration: defaultPinTheme.decoration!.copyWith(color: fillColor, borderRadius: BorderRadius.circular(19), border: Border.all(color: focusedBorderColor))),
                                    errorPinTheme: defaultPinTheme.copyBorderWith(border: Border.all(color: Colors.red)),
                                  ),
                                  const Spacer(),
                                  Text(errorMessage, style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
        ),
      ),
    );
  }
}
