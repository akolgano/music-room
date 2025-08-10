import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../providers/friend_providers.dart';
import '../../widgets/app_widgets.dart';
import '../../core/theme_core.dart';
import '../../core/constants_core.dart';
import '../base_screens.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends BaseScreen<AddFriendScreen> {
  final _userIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); 

  @override
  String get screenTitle => 'Add New Friend';

  @override
  List<Widget> get actions => [
    TextButton.icon(
      onPressed: () => navigateTo(AppRoutes.friendRequests),
      icon: const Icon(Icons.inbox, color: AppTheme.primary),
      label: const Text('Requests', style: TextStyle(color: AppTheme.primary)),
    ),
  ];

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  @override
  Widget buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          AppTheme.buildFormCard(
            title: 'Add Friend by User ID', 
            titleIcon: Icons.person_add,
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  AppWidgets.textField(
                    context: context,
                    controller: _userIdController, 
                    labelText: 'User ID',
                    hintText: 'e.g., 4270552b-1e03-4f35-980c-723b52b91d10',
                    prefixIcon: Icons.person_search,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Please enter a user ID';
                      return null;
                    },
                    onChanged: (value) => setState(() {}),
                    onFieldSubmitted: kIsWeb ? (_) => _sendFriendRequest() : null,
                  ),
                  const SizedBox(height: 16),
                  buildConsumerContent<FriendProvider>(
                    builder: (context, friendProvider) {
                      final userId = _userIdController.text.trim();
                      final showButtons = userId.isNotEmpty;
                      
                      return Column(
                        children: [
                          if (showButtons) ...[
                            SizedBox(
                              width: double.infinity,
                              child: AppWidgets.primaryButton(
                                context: context,
                                text: 'View Profile',
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.userPage,
                                  arguments: {
                                    'userId': userId,
                                    'username': null,
                                  },
                                ),
                                icon: Icons.person,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: AppWidgets.primaryButton(
                              context: context,
                              text: friendProvider.isLoading ? 'Sending...' : 'Send Request',
                              onPressed: _userIdController.text.isNotEmpty && !friendProvider.isLoading 
                                ? _sendFriendRequest 
                                : null, 
                              icon: Icons.send,
                              isLoading: friendProvider.isLoading,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }


  Future<void> _sendFriendRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userInput = _userIdController.text.trim();
    if (userInput.isEmpty) {
      showError('Please enter a user ID');
      return;
    }

    final userId = userInput;

    if (userId == auth.userId) {
      showError('You cannot add yourself as a friend');
      return;
    }

    await runAsyncAction(
      () async {
        final friendProvider = getProvider<FriendProvider>();
        await friendProvider.fetchAllFriendData(auth.token!);
        
        final isAlreadyFriend = friendProvider.friends.any((friend) => friend.id == userId);
        if (isAlreadyFriend) {
          throw Exception('This user is already your friend');
        }
        
        final sentInvitations = friendProvider.sentInvitations;
        final alreadySent = sentInvitations.any((invitation) {
          final toUserId = friendProvider.getToUserId(invitation);
          final status = friendProvider.getInvitationStatus(invitation);
          return toUserId == userId && status == 'pending';
        });
        
        if (alreadySent) {
          throw Exception('You already sent a friend request to this user');
        }
        
        final receivedInvitations = friendProvider.receivedInvitations;
        final hasReceivedRequest = receivedInvitations.any((invitation) {
          final fromUserId = friendProvider.getFromUserId(invitation);
          final status = friendProvider.getInvitationStatus(invitation);
          return fromUserId == userId && status == 'pending';
        });
        
        if (hasReceivedRequest) {
          throw Exception('This user has already sent you a friend request. Check your pending requests.');
        }
        
        await friendProvider.sendFriendRequest(auth.token!, userId);
        _userIdController.clear();
      },
      successMessage: 'Friend request sent successfully!',
    );
  }
}
