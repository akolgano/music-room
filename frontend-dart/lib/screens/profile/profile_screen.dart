// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(authProvider),
            const SizedBox(height: 24),
            _buildAccountSection(authProvider),
            const SizedBox(height: 20),
            _buildMusicPreferencesSection(),
            const SizedBox(height: 20),
            _buildSocialSection(),
            const SizedBox(height: 20),
            _buildPrivacySection(),
            const SizedBox(height: 20),
            _buildSupportSection(),
            const SizedBox(height: 20),
            _buildAccountActionsSection(authProvider),
            const SizedBox(height: 100), 
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(AuthProvider authProvider) {
    return Card(
      color: AppTheme.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.7)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.black,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.surface, width: 2),
                    ),
                    child: const Icon(
                      Icons.music_note,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Text(
              authProvider.username ?? 'Music Lover',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_user, size: 14, color: AppTheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Music Room Member',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(Icons.library_music, '0', 'Playlists'),
                Container(width: 1, height: 30, color: AppTheme.surfaceVariant),
                _buildStatItem(Icons.people, '0', 'Friends'),
                Container(width: 1, height: 30, color: AppTheme.surfaceVariant),
                _buildStatItem(Icons.favorite, '0', 'Liked Songs'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String count, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection(AuthProvider authProvider) {
    return _buildSection(
      'Account Information',
      Icons.account_circle,
      [
        _buildListTile(
          Icons.person_outline,
          'Username',
          authProvider.username ?? 'Not set',
          'Your unique identifier on Music Room',
          onTap: () => _showEditDialog('Username', authProvider.username ?? ''),
        ),
        _buildListTile(
          Icons.email_outlined,
          'Email Address',
          'user@example.com', 
          'Used for account recovery and notifications',
          onTap: () => _showEditDialog('Email', 'user@example.com'),
        ),
        _buildListTile(
          Icons.fingerprint,
          'User ID',
          authProvider.userId ?? 'Unknown',
          'Share this with friends to add you',
          trailing: IconButton(
            icon: const Icon(Icons.copy, color: AppTheme.primary, size: 18),
            onPressed: () => _copyToClipboard(authProvider.userId ?? ''),
            tooltip: 'Copy User ID',
          ),
        ),
      ],
    );
  }

  Widget _buildMusicPreferencesSection() {
    return _buildSection(
      'Music Preferences',
      Icons.tune,
      [
        _buildListTile(
          Icons.music_note,
          'Favorite Genres',
          'Not set',
          'Help us recommend music you\'ll love',
          onTap: () => _showComingSoon('Genre preferences'),
        ),
        _buildListTile(
          Icons.volume_up,
          'Audio Quality',
          'High (320kbps)',
          'Choose your preferred streaming quality',
          onTap: () => _showAudioQualityDialog(),
        ),
        _buildListTile(
          Icons.download,
          'Download Settings',
          'Wi-Fi only',
          'Control when music downloads automatically',
          onTap: () => _showComingSoon('Download settings'),
        ),
      ],
    );
  }

  Widget _buildSocialSection() {
    return _buildSection(
      'Social & Sharing',
      Icons.people,
      [
        _buildListTile(
          Icons.public,
          'Profile Visibility',
          'Friends Only',
          'Control who can see your profile',
          onTap: () => _showPrivacyDialog(),
        ),
        _buildListTile(
          Icons.playlist_play,
          'Default Playlist Privacy',
          'Private',
          'New playlists will be private by default',
          onTap: () => _showPlaylistPrivacyDialog(),
        ),
        _buildListTile(
          Icons.share,
          'Activity Sharing',
          'Enabled',
          'Share your listening activity with friends',
          trailing: Switch(
            value: true,
            onChanged: (value) => _showComingSoon('Activity sharing'),
            activeColor: AppTheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacySection() {
    return _buildSection(
      'Privacy & Security',
      Icons.security,
      [
        _buildListTile(
          Icons.lock_outline,
          'Change Password',
          'Last updated 30 days ago',
          'Keep your account secure',
          onTap: () => _showComingSoon('Password change'),
        ),
        _buildListTile(
          Icons.visibility_off,
          'Data & Privacy',
          'Manage your data',
          'Control what data we collect and how it\'s used',
          onTap: () => _showDataPrivacyDialog(),
        ),
        _buildListTile(
          Icons.block,
          'Blocked Users',
          'No blocked users',
          'Manage users you\'ve blocked',
          onTap: () => _showComingSoon('Blocked users'),
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return _buildSection(
      'Help & Support',
      Icons.help_outline,
      [
        _buildListTile(
          Icons.help_center,
          'Help Center',
          'Get answers to common questions',
          null,
          onTap: () => _showComingSoon('Help center'),
        ),
        _buildListTile(
          Icons.feedback,
          'Send Feedback',
          'Help us improve Music Room',
          null,
          onTap: () => _showFeedbackDialog(),
        ),
        _buildListTile(
          Icons.bug_report,
          'Report a Problem',
          'Something not working right?',
          null,
          onTap: () => _showComingSoon('Bug reporting'),
        ),
        _buildListTile(
          Icons.info_outline,
          'About Music Room',
          'Version ${AppConstants.version}',
          null,
          onTap: () => _showAboutDialog(),
        ),
      ],
    );
  }

  Widget _buildAccountActionsSection(AuthProvider authProvider) {
    return _buildSection(
      'Account Actions',
      Icons.settings,
      [
        _buildListTile(
          Icons.logout,
          'Sign Out',
          'Sign out of your account',
          'You\'ll need to sign in again to access your music',
          onTap: () => _showSignOutDialog(authProvider),
          textColor: Colors.orange,
        ),
        _buildListTile(
          Icons.delete_forever,
          'Delete Account',
          'Permanently delete your account',
          'This action cannot be undone',
          onTap: () => _showDeleteAccountDialog(),
          textColor: Colors.red,
        ),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Card(
      color: AppTheme.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(
    IconData icon,
    String title,
    String subtitle,
    String? description, {
    VoidCallback? onTap,
    Widget? trailing,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: textColor ?? Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor ?? Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: textColor?.withOpacity(0.7) ?? AppTheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant.withOpacity(0.8),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right, color: AppTheme.onSurfaceVariant, size: 18),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(String field, String currentValue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Edit $field', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: TextEditingController(text: currentValue),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: field,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Changes will be saved to your account.',
              style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showComingSoon('Profile editing');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to sign out?',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              'You\'ll need to enter your username and password to sign in again.',
              style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stay Signed In'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              authProvider.logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently delete your account and all your data.',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'This includes:',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 4),
            Text(
              '• All your playlists and saved music\n• Your friends and social connections\n• Your listening history and preferences\n• Your account information',
              style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
            ),
            SizedBox(height: 12),
            Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep My Account'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showComingSoon('Account deletion');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Forever', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.schedule, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('$feature is coming soon!'),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copyToClipboard(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.copy, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('User ID copied to clipboard!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAudioQualityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Audio Quality', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildQualityOption('Low (128kbps)', 'Uses less data', false),
            _buildQualityOption('Medium (192kbps)', 'Balanced quality and data usage', false),
            _buildQualityOption('High (320kbps)', 'Best quality, uses more data', true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityOption(String title, String description, bool selected) {
    return RadioListTile<bool>(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(description, style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
      value: selected,
      groupValue: true,
      onChanged: (value) {},
      activeColor: AppTheme.primary,
    );
  }

  void _showPrivacyDialog() {
    _showComingSoon('Privacy settings');
  }

  void _showPlaylistPrivacyDialog() {
    _showComingSoon('Playlist privacy settings');
  }

  void _showDataPrivacyDialog() {
    _showComingSoon('Data privacy settings');
  }

  void _showFeedbackDialog() {
    _showComingSoon('Feedback form');
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.version,
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.music_note, color: Colors.black, size: 32),
      ),
      children: [
        const Text('Music Room brings people together through music. Create playlists, share with friends, and discover new songs collaboratively.'),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
