// lib/screens/friends/add_friend_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friend_provider.dart';
import '../../core/app_core.dart';
import '../../widgets/app_widgets.dart'; 

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({Key? key}) : super(key: key);

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final _userIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _sendFriendRequest() async {
    final userInput = _userIdController.text.trim();
    
    if (userInput.isEmpty) {
      SnackBarUtils.showError(context, 'Please enter a user ID');
      return;
    }

    int? userId;
    try {
      userId = int.parse(userInput);
      if (userId <= 0) {
        SnackBarUtils.showError(context, 'Please enter a valid user ID');
        return;
      }
    } catch (e) {
      SnackBarUtils.showError(context, 'User ID must be a number');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final friendProvider = Provider.of<FriendProvider>(context, listen: false);
      
      final message = await friendProvider.sendFriendRequest(authProvider.token!, userId);
      
      SnackBarUtils.showSuccess(context, message ?? 'Friend request sent successfully!');
      _userIdController.clear();
    } catch (error) {
      String errorMessage = 'Unable to send friend request';
      if (error.toString().contains('not found')) {
        errorMessage = 'User not found. Please check the user ID.';
      } else if (error.toString().contains('already')) {
        errorMessage = 'You\'re already friends with this user or have a pending request.';
      }
      SnackBarUtils.showError(context, errorMessage);
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Add New Friend'),
      ),
      body: SingleChildScrollView(
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
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      color: AppTheme.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: AppTheme.primary, size: 24),
                SizedBox(width: 12),
                Text('Find Music Friends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Connect to share playlists and discover music together. Ask your friends for their Music Room user ID to add them!',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
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
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('Sending request...', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                : AppButton(
                    text: 'Send Friend Request',
                    icon: Icons.send,
                    onPressed: _userIdController.text.isNotEmpty ? _sendFriendRequest : null,
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
}
