import 'package:flutter/material.dart';
import '../models/community_model.dart';

class CommunityChatScreen extends StatelessWidget {
  final EventCommunityModel community;

  const CommunityChatScreen({super.key, required this.community});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(community.eventTitle)),
      body: Center(child: Text('Chat screen for ${community.eventTitle}')),
    );
  }
}
