import 'package:flutter/material.dart';
import 'package:frontend/chatroom_page/get_initials.dart';

Widget userImageWidget(String name, String imageURL, double width, double height, double fontsize) {
  return Container(height: height, width: width, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.lightGreenAccent), child: Center(child: Text(getInitials(name), style: TextStyle(color: Colors.white, fontSize: fontsize))));
}
