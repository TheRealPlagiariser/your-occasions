import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

import 'package:youroccasions/controllers/event_category_controller.dart';
import 'package:youroccasions/controllers/friend_list_controller.dart';
import 'package:youroccasions/models/event_comment.dart';
import 'package:youroccasions/models/friend_list.dart';
import 'package:youroccasions/screens/event/comment_input.dart';
import 'package:youroccasions/screens/event/comment_tile.dart';
import 'package:youroccasions/screens/event/reply_comment_page.dart';
import 'package:youroccasions/screens/event/share_user_card.dart';

import 'package:youroccasions/screens/home/home.dart';
import 'package:youroccasions/screens/event/update_event.dart';
import 'package:youroccasions/models/event.dart';
import 'package:youroccasions/controllers/event_controller.dart';
import 'package:youroccasions/screens/user/user_profile.dart';
import 'package:youroccasions/models/user.dart';
import 'package:youroccasions/controllers/user_controller.dart';
import 'package:youroccasions/models/data.dart';
import 'package:youroccasions/utilities/secret.dart';




class ShareEventScreen extends StatefulWidget {
  final Event event;

  ShareEventScreen(this.event);

  @override
  ShareEventScreenState createState() => ShareEventScreenState();
  
}

class ShareEventScreenState extends State<ShareEventScreen>{
  FocusNode _messageNode = FocusNode();
  TextEditingController _messageController = TextEditingController();
  List<User> _friends;
  Map<String, bool> _sendStatus = Map();



  @override
  initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    super.dispose();
    _messageNode.dispose();
    _messageController.dispose();
  }

  _launchURL() async {
    // 44.691171,-73.467087
    // 44.693532,-73.467489
    // 44.6911032,-73.46672079999999
    String url2 = "google.navigation:q=44.691171,-73.467087";
    String url3 = "http://maps.google.com/?q=44.691171,-73.467087";
    String url4 = "https://www.google.com/maps/@?api=1&map_action=map&q=44.693532,-73.467489";
    String url5 = "https://www.google.com/maps/search/?api=1&query=47.5951518,-122.3316393&query_place_id=ChIJKxjxuaNqkFQR3CK6O1HNNqY";
    String url6 = "https://www.google.com/maps/search/?api=1&query=44.6911032,-73.46672079999999";
    const url = 'https://flutter.io';
    if (await canLaunch(url6)) {
      await launch(url6);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future _sendEmail(String recipient) async {
    String username = SHARE_EMAIL;
    String password = SHARE_PASSWORD;

    final smtpServer = gmail(username, password);
  
    // Create our message.
    final message = Message()
      ..from = Address(username, 'Your Occasions App')
      ..recipients.add(recipient)
      ..subject = '${Dataset.currentUser.value.name} invited you to go to an event'
      ..html = "<h1>Test</h1>\n<p>This is automated email. Does not reply</p>";

    final sendReports = await send(message, smtpServer);
    if (sendReports[0].validationProblems != null) {
      print("Error sending email");
    }
    
  }

  Future<void> _refresh() async {
    await _getFriendList();
  }

  Future _getFriendList() async {
    FriendListController flc = FriendListController();
    UserController uc = UserController();
    List<User> users = List<User>();
    var fl = await flc.getFriendList(userId: Dataset.currentUser.value.id);
    for (FriendList item in fl) {
      User u = await uc.getUserWithId(item.friendId);
      users.add(u);
      _sendStatus[u.id] = false;
    }
    setState(() {
      _friends = users;
    });
  }

  Widget _buildMessageInput() {
    return SizedBox(
      child: TextFormField(
        focusNode: _messageNode,
        controller: _messageController,
        textInputAction: TextInputAction.next,
        keyboardType: TextInputType.text,
        validator: (name) => (name.length < 6) ? "Please provide a message with at least 6 characters" : null,
        autofocus: false,
        maxLines: null, /// Extend as type
        onFieldSubmitted: (term) {
          _messageNode.unfocus();
        },
        maxLengthEnforced: false,
        decoration: InputDecoration(
          hintText: "Write a message",
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
      ));
  }

  List<Widget> _buildFriendCards() {
    List<Widget> result = List<Widget>();

    _friends.forEach((friend) {
      result.add(
        ShareUserCard(
          user: friend,
          onSend: _sendStatus[friend.id] ? null : 
          () {
            _sendEmail(friend.email);
            setState(() {
              _sendStatus[friend.id] = true;
            });
            print(_sendStatus);
          }
        )
      );
    });

    return result;
  }

  List<Widget> _buildListViewContent() {
    List<Widget> result = List<Widget>();
    var screen = MediaQuery.of(context).size;
    
    if (_friends.isEmpty) {
      result.add(SizedBox(
        height: screen.height * 0.6,
        child: Center(
          child: Text(
            "You have no friend to share the event"
          ),
        ),
      ));
    }
    else {
      result.addAll(_buildFriendCards());
    }


    return result;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.arrow_back,
            color: Colors.black,
          ),
        ),
        title: Text("SHARE TO",
          style: TextStyle(
            color: Colors.black
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _buildMessageInput(),
            RaisedButton(
              onPressed: () {
                _launchURL();
              },
              child: Text("Open Map"),
            ),
            Expanded(
              child: _friends == null ? Center(child: CircularProgressIndicator(),) :
                ListView(
                  children: _buildListViewContent(),
                ),
            )
          ],
        )
      )
    );
  }
}

