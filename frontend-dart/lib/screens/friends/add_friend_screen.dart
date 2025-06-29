// lib/screens/friends/add_friend_screen.dart
import 'package:flutter/material.dart';
import '../../providers/friend_provider.dart';
import '../../core/core.dart';
import '../../widgets/app_widgets.dart'; 
import '../base_screen.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({Key? key}) : super(key: key);

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends BaseScreen<AddFriendScreen> {
  final _userIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); 

  @override
  String get screenTitle => 'Add New Friend';

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  @override
  Widget buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          AppWidgets.infoBanner(
            title: 'Send Friend Request',
            message: 'Enter the user ID of the person you want to add as a friend. They will need to accept your request.',
            icon: Icons.people,
          ),
          const SizedBox(height: 16),
          AppTheme.buildFormCard(
            title: 'Add Friend by User ID',
            titleIcon: Icons.person_add,
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  AppWidgets.textField(
                    controller: _userIdController, 
                    labelText: 'Friend\'s User ID',
                    hintText: 'e.g., 12345',
                    prefixIcon: Icons.person_search,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Please enter a user ID';
                      final userId = int.tryParse(value!);
                      if (userId == null || userId <= 0) return 'Please enter a valid user ID';
                      return null;
                    },
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: AppWidgets.primaryButton(
                      text: 'Send Friend Request',
                      onPressed: _userIdController.text.isNotEmpty ? _sendFriendRequest : null, icon: Icons.send,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppWidgets.infoBanner(
            title: 'Important Note',
            message: 'Friend requests are sent directly to the user. Since the API doesn\'t support retrieving pending requests, the recipient will need to manage requests through their own interface.',
            icon: Icons.info_outline,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          AppWidgets.infoBanner(
            title: 'How It Works',
            message: '1. Get their user ID\n2. Enter it above\n3. Send the request\n4. They accept your request\n5. Start sharing music!',
            icon: Icons.help_outline,
            color: Colors.blue,
          ),
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

    int? userId;
    try {
      userId = int.parse(userInput);
      if (userId <= 0) {
        showError('Please enter a valid user ID');
        return;
      }
    } catch (e) {
      showError('User ID must be a number');
      return;
    }

    if (userId.toString() == auth.userId) {
      showError('You cannot add yourself as a friend');
      return;
    }

    await runAsyncAction(
      () async {
        final friendProvider = getProvider<FriendProvider>();
        await friendProvider.sendFriendRequest(auth.token!, userId!);
        _userIdController.clear();
      },
      successMessage: 'Friend request sent successfully!',
      errorMessage: 'Unable to send friend request',
    );
  }
}
