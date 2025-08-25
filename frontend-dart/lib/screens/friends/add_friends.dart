import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../providers/friend_providers.dart';
import '../../widgets/app_widgets.dart';
import '../../core/theme_core.dart';
import '../../core/provider_core.dart';
import '../base_screens.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends BaseScreen<AddFriendScreen> {
  final _userIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); 
  static final _uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

  @override
  String get screenTitle => 'Add New Friend';

  @override
  List<Widget> get actions => [TextButton.icon(
    onPressed: () => navigateTo(AppRoutes.friendRequests),
    icon: const Icon(Icons.inbox, color: AppTheme.primary),
    label: const Text('Requests', style: TextStyle(color: AppTheme.primary)),
  )];

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  String? _validateUuid(String? value) {
    if (value?.isEmpty ?? true) return 'Please enter a user ID';
    return !_uuidRegex.hasMatch(value!.trim()) ? 'Please enter a valid UUID format' : null;
  }

  Widget _buildButton({required String text, VoidCallback? onPressed, required IconData icon, bool isLoading = false}) =>
    SizedBox(
      width: double.infinity,
      child: AppWidgets.primaryButton(
        context: context,
        text: text,
        onPressed: onPressed,
        icon: icon,
        isLoading: isLoading,
      ),
    );

  @override
  Widget buildContent() => SingleChildScrollView(
    padding: const EdgeInsets.all(4),
    child: Column(children: [
      AppTheme.buildFormCard(
        title: 'Add Friend by User ID', 
        titleIcon: Icons.person_add,
        child: Form(
          key: _formKey,
          child: Column(children: [
            AppWidgets.textField(
              context: context,
              controller: _userIdController, 
              labelText: 'User ID',
              hintText: 'e.g., 4270552b-1e03-4f35-980c-723b52b91d10',
              prefixIcon: Icons.person_search,
              validator: _validateUuid,
              onChanged: (value) => setState(() {}),
              onFieldSubmitted: kIsWeb ? (_) => _sendFriendRequest() : null,
            ),
            const SizedBox(height: 16),
            buildConsumerContent<FriendProvider>(
              builder: (context, friendProvider) {
                final userId = _userIdController.text.trim();
                return Column(children: [
                  if (userId.isNotEmpty) ...[
                    _buildButton(
                      text: 'View Profile',
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.userPage, 
                        arguments: {'userId': userId, 'username': null}),
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildButton(
                    text: friendProvider.isLoading ? 'Sending...' : 'Send Request',
                    onPressed: userId.isNotEmpty && !friendProvider.isLoading ? _sendFriendRequest : null,
                    icon: Icons.send,
                    isLoading: friendProvider.isLoading,
                  ),
                ]);
              },
            ),
          ]),
        ),
      ),
      const SizedBox(height: 16),
    ]),
  );

  Future<void> _sendFriendRequest() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = _userIdController.text.trim();
    if (userId == auth.userId) return showError('You cannot add yourself as a friend');

    await runAsyncAction(
      () async {
        final friendProvider = getProvider<FriendProvider>();
        await Future.wait([
          friendProvider.fetchFriends(auth.token!),
          friendProvider.fetchReceivedInvitations(auth.token!),
          friendProvider.fetchSentInvitations(auth.token!),
        ]);
        
        if (friendProvider.friends.any((f) => f.id == userId)) 
          throw Exception('This user is already your friend');
        
        if (friendProvider.sentInvitations.any((inv) => 
            friendProvider.getToUserId(inv) == userId && friendProvider.getInvitationStatus(inv) == 'pending'))
          throw Exception('You already sent a friend request to this user');
        
        if (friendProvider.receivedInvitations.any((inv) => 
            friendProvider.getFromUserId(inv) == userId && friendProvider.getInvitationStatus(inv) == 'pending'))
          throw Exception('This user has already sent you a friend request. Check your pending requests.');
        
        if (!await friendProvider.sendFriendRequest(auth.token!, userId))
          throw Exception(friendProvider.errorMessage ?? 'Failed to send friend request');
        _userIdController.clear();
      },
      successMessage: 'Friend request sent successfully!',
    );
  }
}