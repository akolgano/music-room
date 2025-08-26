import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import '../../services/api_services.dart';
import '../../models/api_models.dart';
import '../../core/theme_core.dart';
import '../../core/social_core.dart';
import '../../widgets/app_widgets.dart';
import '../../providers/friend_providers.dart';
import '../../providers/profile_providers.dart';
import '../base_screens.dart';

class UserPageScreen extends StatefulWidget {
  final String userId;
  final String? username;

  const UserPageScreen({super.key, required this.userId, this.username});

  @override
  State<UserPageScreen> createState() => _UserPageScreenState();
}

class _UserPageScreenState extends BaseScreen<UserPageScreen> {
  ProfileByIdResponse? _userProfile;
  bool _isLoading = true, _isFriend = false, _isCurrentUser = false;
  bool _hasPendingOutgoingRequest = false, _hasPendingIncomingRequest = false;

  @override
  String get screenTitle => widget.username ?? 'User Profile';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() => _isLoading = true);
      final apiService = ApiService();
      final userProfile = await apiService.getProfileById(widget.userId, auth.token!);
      _isCurrentUser = auth.userId == widget.userId;
      
      if (!_isCurrentUser) {
        final results = await Future.wait([
          apiService.getFriends(auth.token!),
          apiService.getReceivedInvitations(auth.token!),
          apiService.getSentInvitations(auth.token!),
        ]);
        final friends = results[0] as FriendsResponse;
        final received = results[1] as FriendInvitationsResponse;
        final sent = results[2] as FriendInvitationsResponse;
        
        _isFriend = friends.friends.any((f) => f.id == widget.userId);
        _hasPendingIncomingRequest = received.invitations.any((inv) => 
            (inv['friend_id'] ?? inv['from_user']) == widget.userId);
        _hasPendingOutgoingRequest = sent.invitations.any((inv) => 
            (inv['friend_id'] ?? inv['to_user']) == widget.userId);
      }

      setState(() { _userProfile = userProfile; _isLoading = false; });
      if (kDebugMode) debugPrint('[UserPageScreen] Loaded profile for user ${widget.userId}');
    } catch (e) {
      if (kDebugMode) debugPrint('[UserPageScreen] Error loading user profile: $e');
      setState(() => _isLoading = false);
      showError('Failed to load user profile');
    }
  }

  @override
  Widget buildContent() {
    if (_isLoading) return buildLoadingState(message: 'Loading user profile...');
    if (_userProfile == null) return _buildNotFoundState();
    
    return RefreshIndicator(
      onRefresh: _loadUserProfile,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(4),
        child: Column(children: [
          _buildUserHeader(),
          const SizedBox(height: 16),
          if (!_isCurrentUser) ...[_buildActionButtons(), const SizedBox(height: 16)],
          _buildUserInfo(),
        ]),
      ),
    );
  }

  Widget _buildNotFoundState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.person_off, size: 64, color: Colors.grey),
    const SizedBox(height: 16),
    const Text('User profile not found', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
    const SizedBox(height: 8),
    Text('User ID: ${widget.userId}', style: const TextStyle(color: Colors.grey)),
    const SizedBox(height: 24),
    ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back'))
  ]));

  Widget _buildUserHeader() => AppTheme.buildHeaderCard(
    child: Column(children: [
      _buildAvatar(),
      const SizedBox(height: 16),
      Text(_userProfile!.name ?? _userProfile!.user, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
      const SizedBox(height: 8),
      _buildInfoChip(Icons.alternate_email, _userProfile!.user),
      const SizedBox(height: 8),
      _buildInfoChip(Icons.tag, 'ID: ${widget.userId}'),
    ]),
  );

  Widget _buildInfoChip(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.white, size: 14),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 12))
    ]));

  Widget _buildAvatar() {
    final name = _userProfile!.name ?? _userProfile!.user;
    final initials = _getInitials(name);
    final gradient = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.7), Colors.purple.withValues(alpha: 0.8)]);
    
    final initialsAvatar = Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient),
      child: Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold))));

    return Container(
      width: 120, height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _userProfile!.avatar?.isNotEmpty != true ? gradient : null,
        boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: _userProfile!.avatar?.isNotEmpty == true
          ? ClipOval(child: _userProfile!.avatar!.startsWith('data:')
              ? Image.memory(base64Decode(_userProfile!.avatar!.split(',')[1]), fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => initialsAvatar)
              : Image.network(_userProfile!.avatar!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => initialsAvatar))
          : initialsAvatar,
    );
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ').where((w) => w.isNotEmpty).toList();
    return words.isEmpty ? 'U' : words.length == 1 ? words[0][0].toUpperCase() : '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  Widget _buildStatusText({required IconData icon, required String title, required String subtitle, required Color color}) =>
    ListTile(leading: Icon(icon, color: color), title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)), contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4));

  Widget _buildActionButtons() {
    if (_isCurrentUser) return const SizedBox.shrink();
    return AppWidgets.settingsSection(
      title: 'Friendship Status',
      items: [
        if (_isFriend)
          _buildStatusText(icon: Icons.people, title: 'Friends', subtitle: 'You are friends with this user', color: Colors.green)
        else if (_hasPendingOutgoingRequest)
          _buildStatusText(icon: Icons.schedule, title: 'Friend Request Sent', subtitle: 'Your friend request is pending approval', color: Colors.orange)
        else if (_hasPendingIncomingRequest)
          _buildStatusText(icon: Icons.notification_important, title: 'Friend Request Received', subtitle: 'This user sent you a friend request', color: AppTheme.primary)
        else
          AppWidgets.settingsItem(icon: Icons.person_add, title: 'Send Friend Request', subtitle: 'Send a friend request to this user', color: AppTheme.primary, onTap: _sendFriendRequest),
      ],
    );
  }

  Widget _buildUserInfo() => AppWidgets.settingsSection(
    title: 'Profile Information',
    items: [
      if (_userProfile!.location?.isNotEmpty == true)
        _buildInfoItem(Icons.location_on, 'Location', _userProfile!.location!),
      if (_userProfile!.bio?.isNotEmpty == true)
        _buildInfoItem(Icons.info, 'Bio', _userProfile!.bio!, maxLines: 3),
      if (_userProfile!.phone?.isNotEmpty == true)
        _buildInfoItem(Icons.phone, 'Phone', _userProfile!.phone!),
      if (_userProfile!.friendInfo?.isNotEmpty == true)
        _buildInfoItem(Icons.people, 'Friend Info', _userProfile!.friendInfo!, maxLines: 3),
      if (_userProfile!.musicPreferences?.isNotEmpty == true)
        _buildInfoItem(Icons.music_note, 'Music Preferences', _userProfile!.musicPreferences!.join(', '), maxLines: 2),
    ],
  );

  Widget _buildInfoItem(IconData icon, String title, String value, {int maxLines = 1}) => ListTile(
    leading: Icon(icon, color: AppTheme.primary), title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
    subtitle: Text(value, style: const TextStyle(color: Colors.white70), maxLines: maxLines, overflow: TextOverflow.ellipsis),
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4));

  Future<void> _sendFriendRequest() async {
    final friendProvider = getProvider<FriendProvider>();
    final success = await friendProvider.sendFriendRequest(auth.token!, widget.userId);
    
    if (success) {
      showSuccess('Friend request sent!');
      setState(() => _hasPendingOutgoingRequest = true);
      if (kDebugMode) debugPrint('[UserPageScreen] Friend request sent to user ${widget.userId}');
    } else if (friendProvider.hasError) {
      final errorMessage = friendProvider.errorMessage!;
      if (errorMessage.toLowerCase().contains('already friends')) {
        showError('You are already friends with this user');
        setState(() => _isFriend = true);
      } else {
        showError(errorMessage);
      }
      if (kDebugMode) debugPrint('[UserPageScreen] Error sending friend request: $errorMessage');
    }
  }
}

class SocialNetworkLinkScreen extends StatefulWidget {
  const SocialNetworkLinkScreen({super.key});
  @override 
  State<SocialNetworkLinkScreen> createState() => _SocialNetworkLinkScreenState();
}

class _SocialNetworkLinkScreenState extends BaseScreen<SocialNetworkLinkScreen> {
  @override
  String get screenTitle => 'Link Social Network';
  @override
  bool get showMiniPlayer => false;
  @override                                                                 
  void initState() {     
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => SocialLoginUtils.initialize());
  }

  Future<void> _linkSocial(String provider, ProfileProvider profileProvider) async {
    if (auth.token == null) return showError('Not authenticated');
    try {
      final success = provider == 'Google' 
        ? await profileProvider.googleLink(auth.token)
        : await profileProvider.facebookLink(auth.token);
      if (success) {
        await profileProvider.loadProfile(auth.token);
        showSuccess('$provider account linked successfully!');
      }
    } catch (e) {
      showError('Failed to link $provider account');
    }
  }

  @override
  Widget buildContent() => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(5),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: AppTheme.buildFormCard(
          title: 'Link with Social Network', 
          titleIcon: Icons.link, 
          context: context,
          child: buildConsumerContent<ProfileProvider>(
            builder: (context, profileProvider) => Column(children: [
              AppWidgets.infoBanner(
                title: profileProvider.socialType != null ? 'Connected' : 'Link Social Account',
                message: profileProvider.socialType != null 
                  ? 'Your account is linked to ${profileProvider.socialType!}'
                  : 'Connect your social media account for easier sign-in',
                icon: profileProvider.socialType != null ? Icons.check_circle : Icons.info,
                color: profileProvider.socialType != null ? Colors.green : null,
              ),
              const SizedBox(height: 16),
              Row(children: ['Google', 'Facebook'].map((provider) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: provider == 'Facebook' ? 8 : 0, right: provider == 'Google' ? 8 : 0),
                  child: SocialLoginButton(
                    provider: provider,
                    onPressed: profileProvider.isLoading ? null : () => _linkSocial(provider, profileProvider),
                    isLoading: profileProvider.isLoading,
                  ),
                ),
              )).toList()),
              if (profileProvider.isLoading) ...[
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: AppTheme.primary),
              ],
              const SizedBox(height: 24),
              AppWidgets.secondaryButton(context: context, text: 'Go Back', onPressed: navigateBack, icon: Icons.arrow_back),
            ]),
          ),
        ),
      ),
    ),
  );
}