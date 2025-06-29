// lib/screens/friends/friend_request_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friend_provider.dart';
import '../../core/core.dart';
import '../../widgets/app_widgets.dart';
import '../base_screen.dart';

class FriendRequestScreen extends StatefulWidget {
  const FriendRequestScreen({Key? key}) : super(key: key);

  @override
  State<FriendRequestScreen> createState() => _FriendRequestScreenState();
}

class _FriendRequestScreenState extends BaseScreen<FriendRequestScreen> {
  @override
  String get screenTitle => 'Friend Requests';

  @override
  Widget buildContent() {
    return buildConsumerContent<FriendProvider>(
      builder: (context, friendProvider) {
        return buildEmptyState(
          icon: Icons.info_outline,
          title: 'Friend Requests Not Available',
          subtitle: 'The API doesn\'t currently support retrieving pending friend requests. You can still send friend requests to users by their ID.',
          buttonText: 'Add Friends',
          onButtonPressed: () => navigateTo(AppRoutes.addFriend),
        );
      },
    );
  }
}
