import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:frontend/backend/call_gemini.dart';
import 'package:frontend/backend/show_prompt_dialog.dart';
import 'package:frontend/chatroom_page/capitalize.dart';
import 'package:frontend/chatroom_page/chat_timestamp.dart';
import 'package:frontend/chatroom_page/user_image_widget.dart';
import 'package:frontend/globals/global_firebase.dart';
import 'package:frontend/globals/global_variables.dart';

class ChatPage extends StatefulWidget {
  final String chatID;
  const ChatPage({super.key, required this.chatID});

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  final TextEditingController textEditingController = TextEditingController();
  final ScrollController listScrollController = ScrollController();
  bool fetchingNewMessages = false;
  bool noMoreMessages = false;
  var listMessages = [];
  QuerySnapshot? previousMessages;
  var listPreviousMessages = [];
  List<String> unseenMessagesString = [];
  bool fetchingUnseenMessages = false;
  bool gotLastUnseenMessage = false;
  final chatLimit = 15;
  String name = "";

  String chatID = "";

  FocusNode inputFocusNode = FocusNode();
  double outsidePadding = 20 * screenWidthRatio;
  final GlobalKey sendButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    chatID = widget.chatID;
    listScrollController.addListener(eventChatListener);
  }

  @override
  void dispose() {
    listScrollController.removeListener(eventChatListener);
    textEditingController.dispose();
    listScrollController.dispose();
    inputFocusNode.dispose();
    super.dispose();
  }

  eventChatListener() async {
    double maxScroll = listScrollController.position.maxScrollExtent;
    double currentScroll = listScrollController.position.pixels;
    if (maxScroll == currentScroll && fetchingNewMessages != true) {
      await fetchNewMessages();
    }
  }

  Future<void> _sendMessage() async {
    // if (listMessages.isNotEmpty && widget.contactUID == "_copilot" && listMessages[0]['sent_by'] != "_copilot") {
    //   return;
    // }
    if (textEditingController.text.isNotEmpty) {
      WriteBatch batch = firestore.batch();
      int timestamp = DateTime.now().millisecondsSinceEpoch;

      String message = textEditingController.text;
      setState(() {
        textEditingController.clear();
      });
      print(chatID);
      DocumentReference chatDocRef = firestore.collection("chatrooms").doc(chatID).collection('messages').doc();
      print(myUID);
      batch.set(chatDocRef, {'content': message, 'timestamp': timestamp, 'type': "string", 'sent_by': "$myUID $myName"});

      try {
        await batch.commit();
        print("Batch write successful!");
        setState(() {
          textEditingController.clear();
        });
      } catch (e) {
        print("Error performing batch write: $e");
      }
    }
  }

  Future<QuerySnapshot?> fetchNextList(DocumentSnapshot lastDoc) async {
    QuerySnapshot querySnapshot = await firestore.collection("chatrooms").doc(chatID).collection('messages').orderBy('timestamp', descending: true).limit(chatLimit).startAfterDocument(lastDoc).get();
    if (querySnapshot.docs.isEmpty) {
      return null;
    } else {
      return querySnapshot;
    }
  }

  Future<void> fetchNewMessages() async {
    fetchingNewMessages = true;
    QuerySnapshot? newDocumentList = await fetchNextList(listMessages[listMessages.length - 1]);
    if (newDocumentList != null) {
      noMoreMessages = false;
      if (previousMessages == null) {
        previousMessages = newDocumentList;
        listPreviousMessages = newDocumentList.docs;
      } else {
        listPreviousMessages.addAll(newDocumentList.docs);
      }
    } else {
      noMoreMessages = true;
    }
    setState(() {
      fetchingNewMessages = false;
    });
  }

  chatStreamWidget(String name, String imageURL) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 5 * screenWidthRatio, vertical: 4 * screenHeightRatio),
          child: Row(
            children: [
              SizedBox(width: 15 * screenWidthRatio),
              InkWell(
                child: Icon(Icons.arrow_back_ios),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
              const Spacer(),
              Text("Room: $chatID", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
              const Spacer(),
              InkWell(
                child: Icon(Icons.event),
                onTap: () async {
                  List<Map<String, dynamic>> llmMessages = [];
                  for (var message in listMessages) {
                    llmMessages.add({"sender": message['sent_by'], "content": message['content']});
                  }
                  String? llmResponse = await generateContent(llmMessages);
                  if (llmResponse != null) {
                    print("llmResponse: $llmResponse");
                    showAcceptRejectDialog(context, llmResponse);
                  }
                },
              ),
              SizedBox(width: 15 * screenWidthRatio),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore.collection("chatrooms").doc(chatID).collection('messages').orderBy('timestamp', descending: true).limit(chatLimit).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                print("no data!");
                return Container();
              } else {
                listMessages = snapshot.data!.docs;

                if (listMessages.length < chatLimit) {
                  noMoreMessages = true;
                }
                if (previousMessages != null) {
                  listMessages.addAll(listPreviousMessages);
                }

                return SizedBox(
                  width: screenWidth - 10 * screenWidthRatio,
                  child: ListView.builder(
                    reverse: true,
                    padding: EdgeInsets.zero,
                    controller: listScrollController,
                    itemCount: listMessages.length,
                    itemBuilder: (context, index) {
                      String? timestampString;
                      if ((noMoreMessages && index + 1 == listMessages.length)) {
                        timestampString = getFormattedFirstTimestamp(DateTime.fromMillisecondsSinceEpoch(listMessages[index]['timestamp']));
                      }
                      if (index + 1 >= listMessages.length == false) {
                        timestampString = getFormattedTimestamp(DateTime.fromMillisecondsSinceEpoch(listMessages[index + 1]['timestamp']), DateTime.fromMillisecondsSinceEpoch(listMessages[index]['timestamp']));
                      }

                      Widget chatWidget = ChatMessage(isLastMessage: index == 0 || (index - 1 >= 0 && listMessages[index]['sent_by'] != listMessages[index - 1]['sent_by']), message: listMessages[index]['content'], isSentByMe: (listMessages[index]['sent_by'] ?? "").split(" ")[0] == myUID, name: listMessages[index]['sent_by'] ?? "".split(" ")[1], imageURL: imageURL);
                      return Column(children: [AnimatedSize(duration: Duration(milliseconds: 500), curve: Curves.easeInOut, child: (index == listMessages.length - 1 && !noMoreMessages && listMessages.length >= 15) ? Padding(padding: EdgeInsets.only(top: 15 * screenHeightRatio, bottom: 15 * screenHeightRatio), child: SpinKitCircle(color: Colors.black)) : Container()), SizedBox(height: 5 * screenHeightRatio), if ((noMoreMessages && index == listMessages.length - 1) || ((index + 1 >= listMessages.length || timestampString == null) == false)) Padding(padding: EdgeInsets.only(bottom: 5 * screenHeightRatio), child: Text(timestampString ?? "test")), chatWidget]);
                    },
                  ),
                );
              }
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8 * screenWidthRatio),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  focusNode: inputFocusNode,
                  controller: textEditingController,
                  onChanged: (value) {
                    setState(() {});
                  },
                  // onSubmitted: (value) {
                  //   textEditingController.text += "\n";
                  // },
                  onTapOutside: (event) {
                    print("tap outside");
                    RenderBox renderBox = sendButtonKey.currentContext?.findRenderObject() as RenderBox;
                    Offset buttonPosition = renderBox.localToGlobal(Offset.zero);

                    // Get the size of the send button
                    Size buttonSize = renderBox.size;

                    // Define the Rect for the send button
                    Rect sendButtonRect = Rect.fromLTWH(
                      buttonPosition.dx, // X position (left)
                      buttonPosition.dy, // Y position (top)
                      buttonSize.width, // Width
                      buttonSize.height, // Height
                    );
                    if (sendButtonRect.contains(event.localPosition) == false) {
                      inputFocusNode.unfocus();
                    }
                  },
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      key: sendButtonKey,
                      icon: Icon(
                        Icons.send,
                        color:
                            // ( widget.contactUID == "_copilot" &&
                            //             listMessages.isNotEmpty &&
                            //             listMessages[0]['sent_by'] != "_copilot")
                            //             ||
                            textEditingController.text.trim().isEmpty ? const Color.fromARGB(255, 201, 201, 201) : const Color.fromARGB(255, 77, 35, 194),
                      ),
                      onPressed: () {
                        print("tap send");
                        _sendMessage();
                      },
                    ),
                    hintText: 'Type a message',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        //key: scaffoldKey, drawer: drawerWidget(context),
        body: SafeArea(child: chatStreamWidget(name, "")),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final bool isLastMessage;
  final String message;
  final bool isSentByMe;
  final String imageURL;
  final String name;

  const ChatMessage({super.key, required this.isLastMessage, required this.message, required this.isSentByMe, required this.imageURL, required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [if (isLastMessage && isSentByMe == false) userImageWidget(name, imageURL, 30 * screenHeightRatio, 30 * screenHeightRatio, 15), if (isSentByMe == false) SizedBox(width: (isLastMessage == true ? 5 : 35) * screenWidthRatio), Container(padding: EdgeInsets.symmetric(horizontal: 12 * screenWidthRatio, vertical: 10 * screenHeightRatio), margin: EdgeInsets.symmetric(vertical: 2 * screenHeightRatio), decoration: BoxDecoration(color: isSentByMe ? const Color.fromARGB(255, 146, 144, 249) : Colors.grey[300], borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: isSentByMe ? Radius.circular(20) : Radius.zero, bottomRight: isSentByMe ? Radius.zero : Radius.circular(20))), child: Container(constraints: BoxConstraints(maxWidth: 300), child: SelectableText(message, style: TextStyle(color: isSentByMe ? Colors.white : Colors.black, fontSize: 16)))), if (isSentByMe) SizedBox(width: (isLastMessage == false ? 0 : 5) * screenWidthRatio)],
    );
  }
}
