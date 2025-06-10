// lib/screens/friends/add_friend_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friend_provider.dart';
import '../../core/app_core.dart';
import '../../widgets/common_widgets.dart';
import '../base_screen.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({Key? key}) : super(key: key);

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends BaseScreen<AddFriendScreen> {
  final _userIdController = TextEditingController();
  bool _isScreenLoading = false;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 24),
          _buildSearchCard(),
          const SizedBox(height: 24),
          _buildHowItWorksCard(),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return InfoBanner(
      title: 'Find Music Friends',
      message: 'Connect to share playlists and discover music together. Ask your friends for their Music Room user ID to add them!',
      icon: Icons.people,
    );
  }

  Widget _buildSearchCard() {
    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.search, color: AppTheme.primary, size: 20),
                SizedBox(width: 8),
                Text('Send Friend Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
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
            const SizedBox(height: 20),
            AppButton(
              text: 'Send Friend Request',
              icon: Icons.send,
              onPressed: _userIdController.text.isNotEmpty ? _sendFriendRequest : null,
              isLoading: _isScreenLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksCard() {
    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.help_outline, color: AppTheme.primary, size: 20),
                SizedBox(width: 8),
                Text('How Friend Requests Work', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 16),
            _buildStep(1, 'Find Their User ID', 'Ask your friend for their Music Room user ID number.'),
            _buildStep(2, 'Send Request', 'Enter their user ID above and tap "Send Friend Request".'),
            _buildStep(3, 'Wait for Acceptance', 'Your friend will receive a notification and can accept your request.'),
            _buildStep(4, 'Start Sharing Music!', 'Once accepted, you can share playlists and discover music together.'),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(number.toString(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
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

    setState(() => _isScreenLoading = true);

    await runAsyncAction(
      () async {
        final friendProvider = Provider.of<FriendProvider>(context, listen: false);
        await friendProvider.sendFriendRequest(auth.token!, userId!);
        _userIdController.clear();
      },
      successMessage: 'Friend request sent successfully!',
      errorMessage: 'Unable to send friend request',
    );

    setState(() => _isScreenLoading = false);
  }
}
