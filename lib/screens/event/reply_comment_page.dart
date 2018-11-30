import 'package:flutter/material.dart';
import 'package:youroccasions/models/event_comment.dart';
import 'package:youroccasions/screens/event/comment_input.dart';
import 'package:youroccasions/screens/event/comment_tile.dart';
import 'package:youroccasions/screens/event/reply_tile.dart';


class ReplyCommentPage extends StatelessWidget {
  final EventComment eventComment;

  ReplyCommentPage({Key key, @required this.eventComment}) 
    : super(key: key);

    

  String _getTimeAway() {
    Duration period = DateTime.now().difference(eventComment.date);
    String result = "";
    if (period.inDays != 0) {
      if (period.inDays < 7 ) {
        result += "${period.inDays} day" + ((period.inDays > 1) ? "s ago" : " ago");
      }
      else {
        result += "${(period.inDays / 7).round()} week" + ((period.inDays / 7 > 1) ? "s ago" : " ago");
      }
    }
    else if (period.inHours != 0) {
      result += "${period.inHours} hour" + ((period.inHours > 1) ? "s ago" : " ago");
    }
    else {
      result += "${period.inMinutes} minute" + ((period.inMinutes > 1) ? "s ago" :  " ago");
    }

    return result;
  }

  List<Widget> _buildListViewContent() {
    TextEditingController commentController = TextEditingController();
    FocusNode commentNode = FocusNode();
    List<Widget> result = List<Widget>();

    result.addAll([
      CommentTile(
        image: NetworkImage("https://cdn0.iconfinder.com/data/icons/avatar-15/512/ninja-512.png"),
        messsage: eventComment.message,
        onTap: () {},
        onTapReply: () {},
        postTime: eventComment.date,
        userName: eventComment.authorId,
      ),
      Divider(
        height: 1,
      ),
      CommentInput(
        hintText: "Add a public reply",
        avatarRadius: 30,
        commentNode: commentNode, 
        commentController: commentController, 
        onPostComment: () {},
      ),
      Divider(
        height: 1,
      ),
    ]);

    int count = 0;
    eventComment.replies.forEach((reply) {
      result.add(
        ReplyTile(
          image: NetworkImage("https://cdn0.iconfinder.com/data/icons/avatar-15/512/ninja-512.png"),
          messsage: "reply $count",
          onTap: () {},
          onTapReply: () {},
          postTime: DateTime.now().subtract(Duration(days: 3)),
          userName: "Ninja $count",
        )
      );
      count++;
    });

    return result;

  }

  // void _onCommentInputChange(){
  //   print(commentController.text);
  // }

  @override
  Widget build(BuildContext context) {
    // String timeAway = DateTime.now().difference(eventComment.date).inHours.toString() + " hours ago";

    
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: ListView(
          children: _buildListViewContent(),
        ),
      ),
    );
  }

}