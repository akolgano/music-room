import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import '../../services/api_service.dart';
import '../../models/api_models.dart';
import '../../core/theme_utils.dart';
import '../../widgets/app_widgets.dart';
import '../base_screen.dart';

class UserPageScreen extends StatefulWidget {
  final int userId;
  final String? username;

  const UserPageScreen({
    super.key,
    required this.userId,
    this.username,
  });

  @override
  State<UserPageScreen> createState() => _UserPageScreenState();
}

class _UserPageScreenState extends BaseScreen<UserPageScreen> {
  ProfileByIdResponse? _userProfile;
  bool _isLoading = true;
  bool _isFriend = false;
  bool _isCurrentUser = false;

  @override
  String get screenTitle => widget.username ?? 'User Profile';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final apiService = ApiService();
      final userProfile = await apiService.getProfileById(widget.userId, auth.token!);
      
      _isCurrentUser = auth.userId == widget.userId.toString();
      
      if (!_isCurrentUser) {
        final friendsResponse = await apiService.getFriends(auth.token!);
        _isFriend = friendsResponse.friends.contains(widget.userId);
      }

      setState(() {
        _userProfile = userProfile;
        _isLoading = false;
      });

      if (kDebugMode) {
        debugPrint('[UserPageScreen] Loaded profile for user ${widget.userId}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UserPageScreen] Error loading user profile: $e');
      }
      setState(() {
        _isLoading = false;
      });
      showError('Failed to load user profile');
    }
  }

  @override
  Widget buildContent() {
    if (_isLoading) {
      return buildLoadingState(message: 'Loading user profile...');
    }

    if (_userProfile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'User profile not found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'User ID: ${widget.userId}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUserProfile,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildUserHeader(),
            const SizedBox(height: 16),
            if (!_isCurrentUser) ...[
              _buildActionButtons(),
              const SizedBox(height: 16),
            ],
            _buildUserInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return AppTheme.buildHeaderCard(
      child: Column(
        children: [
          _buildAvatar(),
          const SizedBox(height: 16),
          Text(
            _userProfile!.name ?? _userProfile!.user,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.alternate_email, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  _userProfile!.user,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.tag, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  'ID: ${widget.userId}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
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

  Widget _buildAvatar() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _userProfile!.avatar?.isNotEmpty == true
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primary,
                  AppTheme.primary.withValues(alpha: 0.7),
                ],
              ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _userProfile!.avatar?.isNotEmpty == true
          ? ClipOval(
              child: _userProfile!.avatar!.startsWith('data:')
                  ? Image.memory(
                      base64Decode(_userProfile!.avatar!.split(',')[1]),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildInitialsAvatar(),
                    )
                  : Image.network(
                      _userProfile!.avatar!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildInitialsAvatar(),
                    ),
            )
          : _buildInitialsAvatar(),
    );
  }

  Widget _buildInitialsAvatar() {
    final name = _userProfile!.name ?? _userProfile!.user;
    final initials = _getInitials(name);

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary,
            AppTheme.primary.withValues(alpha: 0.7),
            Colors.purple.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    
    final words = name.trim().split(' ').where((word) => word.isNotEmpty).toList();
    if (words.isEmpty) return 'U';
    
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'.toUpperCase();
    }
  }

  Widget _buildActionButtons() {
    if (_isCurrentUser) return const SizedBox.shrink();

    return AppWidgets.settingsSection(
      title: 'Actions',
      items: [
        AppWidgets.settingsItem(
          icon: _isFriend ? Icons.person_remove : Icons.person_add,
          title: _isFriend ? 'Remove Friend' : 'Send Friend Request',
          subtitle: _isFriend 
              ? 'Remove this user from your friends list'
              : 'Send a friend request to this user',
          color: _isFriend ? Colors.orange : AppTheme.primary,
          onTap: _isFriend ? _removeFriend : _sendFriendRequest,
        ),
      ],
    );
  }

  Widget _buildUserInfo() {
    return AppWidgets.settingsSection(
      title: 'Profile Information',
      items: [
        if (_userProfile!.location?.isNotEmpty == true)
          _buildInfoItem(
            icon: Icons.location_on,
            title: 'Location',
            value: _userProfile!.location!,
          ),
        if (_userProfile!.bio?.isNotEmpty == true)
          _buildInfoItem(
            icon: Icons.info,
            title: 'Bio',
            value: _userProfile!.bio!,
            maxLines: 3,
          ),
        if (_userProfile!.phone?.isNotEmpty == true)
          _buildInfoItem(
            icon: Icons.phone,
            title: 'Phone',
            value: _userProfile!.phone!,
          ),
        if (_userProfile!.friendInfo?.isNotEmpty == true)
          _buildInfoItem(
            icon: Icons.people,
            title: 'Friend Info',
            value: _userProfile!.friendInfo!,
            maxLines: 3,
          ),
        if (_userProfile!.musicPreferences?.isNotEmpty == true)
          _buildInfoItem(
            icon: Icons.music_note,
            title: 'Music Preferences',
            value: _userProfile!.musicPreferences!.join(', '),
            maxLines: 2,
          ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    int maxLines = 1,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(color: Colors.white70),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Future<void> _sendFriendRequest() async {
    try {
      final apiService = ApiService();
      await apiService.sendFriendRequest(widget.userId, auth.token!);
      showSuccess('Friend request sent!');
      
      if (kDebugMode) {
        debugPrint('[UserPageScreen] Friend request sent to user ${widget.userId}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UserPageScreen] Error sending friend request: $e');
      }
      
      if (e.toString().contains('already sent')) {
        showError('Friend request already sent');
      } else if (e.toString().contains('already friends')) {
        showError('You are already friends with this user');
        setState(() {
          _isFriend = true;
        });
      } else {
        showError('Failed to send friend request');
      }
    }
  }

  Future<void> _removeFriend() async {
    final confirmed = await showConfirmDialog(
      'Remove Friend',
      'Are you sure you want to remove ${_userProfile!.name ?? _userProfile!.user} from your friends list?',
      isDangerous: true,
    );

    if (!confirmed) return;

    try {
      final apiService = ApiService();
      await apiService.removeFriend(widget.userId, auth.token!);
      showSuccess('Friend removed');
      
      setState(() {
        _isFriend = false;
      });

      if (kDebugMode) {
        debugPrint('[UserPageScreen] Removed friend ${widget.userId}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UserPageScreen] Error removing friend: $e');
      }
      showError('Failed to remove friend');
    }
  }
}