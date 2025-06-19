// lib/screens/friends/add_friend_screen.dart
import 'package:flutter/material.dart';
import '../../providers/friend_provider.dart';
import '../../core/core.dart';
import '../../utils/app_utils.dart';
import '../base_screen.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({Key? key}) : super(key: key);

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends BaseScreen<AddFriendScreen> 
    with AsyncOperationStateMixin<AddFriendScreen> {
  
  final _userIdController = TextEditingController();

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
          AppUtils.buildInfoCard(
            title: 'Find Music Friends',
            message: 'Connect to share playlists and discover music together. Ask your friends for their Music Room user ID to add them!',
            icon: Icons.people,
          ),
          const SizedBox(height: 16),
          AppUtils.buildTextFieldCard(
            title: 'Send Friend Request',
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
            child: ElevatedButton.icon(
              onPressed: _userIdController.text.isNotEmpty && !isLoading ? _sendFriendRequest : null,
              icon: isLoading 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              label: Text(isLoading ? 'Sending...' : 'Send Friend Request'),
            ),
          ),
          const SizedBox(height: 16),
          _buildHowItWorksCard(),
        ],
      ),
    );
  }

  Widget _buildHowItWorksCard() {
    return AppUtils.buildInfoCard(
      title: 'How It Works',
      message: '1. Get their user ID\n2. Enter it above\n3. They accept your request\n4. Start sharing music!',
      icon: Icons.help_outline,
      color: Colors.blue,
    );
  }

  Future<void> _sendFriendRequest() async {
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

    final success = await executeBool(
      operation: () async {
        final friendProvider = getProvider<FriendProvider>();
        await friendProvider.sendFriendRequest(auth.token!, userId!);
        _userIdController.clear();
      },
      successMessage: 'Friend request sent successfully!',
      errorMessage: 'Unable to send friend request',
    );
  }
}
