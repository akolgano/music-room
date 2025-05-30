// lib/screens/friends/add_friend_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../core/theme.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({Key? key}) : super(key: key);

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final _userIdController = TextEditingController();
  bool _isLoading = false;
  String? _lastSearchedUser;

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _sendFriendRequest() async {
    final userInput = _userIdController.text.trim();
    
    if (userInput.isEmpty) {
      _showSnackBar('Please enter a user ID to send a friend request', isError: true);
      return;
    }

    int? userId;
    try {
      userId = int.parse(userInput);
      if (userId <= 0) {
        _showSnackBar('Please enter a valid user ID (positive number)', isError: true);
        return;
      }
    } catch (e) {
      _showSnackBar('User ID must be a number', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _lastSearchedUser = userInput;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final friendProvider = Provider.of<FriendProvider>(context, listen: false);
      
      final message = await friendProvider.sendFriendRequest(
        authProvider.token!,
        userId,
      );
      
      _showSnackBar(
        message ?? 'Friend request sent successfully! They\'ll see your request and can accept it.',
        isError: false,
      );
      
      _userIdController.clear();
      setState(() {
        _lastSearchedUser = null;
      });
    } catch (error) {
      String errorMessage = 'Unable to send friend request';
      if (error.toString().contains('not found')) {
        errorMessage = 'User not found. Please check the user ID and try again.';
      } else if (error.toString().contains('already')) {
        errorMessage = 'You\'re already friends with this user or have a pending request.';
      }
      _showSnackBar(errorMessage, isError: true);
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add New Friend'),
            Text(
              'Connect with other Music Room users',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.onSurfaceVariant,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 24),
            _buildSearchCard(),
            const SizedBox(height: 24),
            _buildHowItWorksCard(),
            const SizedBox(height: 24),
            _buildComingSoonCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      color: AppTheme.primary.withOpacity(0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.people,
                    color: Colors.black,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find Music Friends',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Connect to share playlists and discover music together',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Icon(Icons.lightbulb, color: AppTheme.primary, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ask your friends for their Music Room user ID to add them!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
    return Card(
      color: AppTheme.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.search, color: AppTheme.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Send Friend Request',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Enter User ID',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask your friend for their user ID number. You can find your own ID in your profile settings.',
              style: TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _userIdController,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.surfaceVariant,
                labelText: 'Friend\'s User ID',
                hintText: 'e.g., 12345',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primary),
                ),
                prefixIcon: const Icon(Icons.person_search, color: AppTheme.onSurfaceVariant),
                suffixIcon: _userIdController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.onSurfaceVariant),
                        onPressed: () {
                          _userIdController.clear();
                          setState(() {});
                        },
                        tooltip: 'Clear input',
                      )
                    : null,
              ),
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() {}),
              enabled: !_isLoading,
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Sending request to user $_lastSearchedUser...',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _userIdController.text.isNotEmpty ? _sendFriendRequest : null,
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text('Send Friend Request'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: AppTheme.surfaceVariant,
                      disabledForegroundColor: AppTheme.onSurfaceVariant,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksCard() {
    return Card(
      color: AppTheme.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.help_outline, color: AppTheme.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'How Friend Requests Work',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStep(
              1,
              'Find Their User ID',
              'Ask your friend for their Music Room user ID number.',
            ),
            _buildStep(
              2,
              'Send Request',
              'Enter their user ID above and tap "Send Friend Request".',
            ),
            _buildStep(
              3,
              'Wait for Acceptance',
              'Your friend will receive a notification and can accept your request.',
            ),
            _buildStep(
              4,
              'Start Sharing Music!',
              'Once accepted, you can share playlists and discover music together.',
            ),
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
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonCard() {
    return Card(
      color: AppTheme.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.rocket_launch, color: Colors.orange, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Coming Soon',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFeaturePreview(
              Icons.search,
              'Search by Username',
              'Find friends by searching their username instead of user ID.',
            ),
            _buildFeaturePreview(
              Icons.contacts,
              'Contact Integration',
              'Import friends from your phone contacts who also use Music Room.',
            ),
            _buildFeaturePreview(
              Icons.qr_code,
              'QR Code Sharing',
              'Share a QR code for others to scan and instantly add you as a friend.',
            ),
            _buildFeaturePreview(
              Icons.share,
              'Invite via Link',
              'Send invitation links through text, email, or social media.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturePreview(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppTheme.error : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 5 : 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}
