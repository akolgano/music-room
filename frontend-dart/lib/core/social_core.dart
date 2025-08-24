import 'dart:async';
import 'navigation_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme_core.dart';
import '../widgets/core_widgets.dart';

class SocialLoginUtils {
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;    
    
    try {
      final fbAppId = dotenv.env['FACEBOOK_APP_ID'];
      if (kIsWeb && fbAppId?.isNotEmpty == true) {
        await FacebookAuth.instance.webAndDesktopInitialize(
          appId: fbAppId!, 
          cookie: true, 
          xfbml: true, 
          version: "v18.0"
        );
      }
      
      _isInitialized = true;
      AppLogger.debug('Social login initialization completed successfully', 'SocialLoginUtils');
    } catch (e) {
      AppLogger.debug('Social login initialization error: $e', 'SocialLoginUtils');
      rethrow;
    }
  }

}

class SocialLoginButton extends StatelessWidget {
  final String provider;
  final VoidCallback? onPressed;
  final bool isLoading;

  const SocialLoginButton({super.key, required this.provider, this.onPressed, this.isLoading = false});

  static final _providerConfig = {
    'google': (Icons.g_mobiledata, Colors.red),
    'facebook': (Icons.facebook, const Color(0xFF1877F2)),
  };

  @override
  Widget build(BuildContext context) {
    final config = _providerConfig[provider.toLowerCase()];
    if (config == null) throw ArgumentError('Unsupported social login provider: $provider');
    final (icon, color) = config;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF282828), 
          foregroundColor: Colors.white,
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
        child: isLoading 
          ? SizedBox(
              width: 20, height: 20, 
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(color)),
            ) 
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Continue with $provider',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }
}

class SocialProfileWidget extends StatelessWidget {
  final String username;
  final String? avatarUrl;
  final String? bio;
  final int followersCount;
  final int followingCount;
  final VoidCallback? onFollowPressed;
  final bool isFollowing;
  
  const SocialProfileWidget({
    super.key,
    required this.username,
    this.avatarUrl,
    this.bio,
    this.followersCount = 0,
    this.followingCount = 0,
    this.onFollowPressed,
    this.isFollowing = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: avatarUrl == null ? Text(username.isEmpty ? '?' : username[0].toUpperCase(), style: const TextStyle(fontSize: 32)) : null,
            ),
            const SizedBox(height: 12),
            Text(
              '@$username',
              style: ThemeUtils.getSubheadingStyle(context).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (bio != null && bio!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                bio!,
                style: ThemeUtils.getCaptionStyle(context),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn(context, 'Followers', followersCount),
                _buildStatColumn(context, 'Following', followingCount),
              ],
            ),
            if (onFollowPressed != null) ...[
              const SizedBox(height: 16),
              AppWidgets.primaryButton(
                context: context,
                text: isFollowing ? 'Following' : 'Follow',
                onPressed: onFollowPressed,
                icon: isFollowing ? Icons.check : Icons.person_add,
                fullWidth: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatColumn(BuildContext context, String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: ThemeUtils.getSubheadingStyle(context).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: ThemeUtils.getCaptionStyle(context),
        ),
      ],
    );
  }
}

class SocialActivityItem extends StatelessWidget {
  final String username;
  final String? avatarUrl;
  final String activity;
  final DateTime timestamp;
  final Widget? content;
  final List<SocialAction>? actions;
  
  const SocialActivityItem({
    super.key,
    required this.username,
    this.avatarUrl,
    required this.activity,
    required this.timestamp,
    this.content,
    this.actions,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl!)
                      : null,
                  child: avatarUrl == null ? Text(username.isEmpty ? '?' : username[0].toUpperCase()) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: ThemeUtils.getBodyStyle(context).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatTimestamp(timestamp),
                        style: ThemeUtils.getCaptionStyle(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              activity,
              style: ThemeUtils.getBodyStyle(context),
            ),
            if (content != null) ...[
              const SizedBox(height: 8),
              content!,
            ],
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: actions!.map((action) => _buildAction(context, action)).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildAction(BuildContext context, SocialAction action) {
    return TextButton.icon(
      icon: Icon(action.icon, size: 18),
      label: Text(action.label),
      onPressed: action.onTap,
      style: TextButton.styleFrom(
        foregroundColor: action.isActive ? AppTheme.primary : null,
      ),
    );
  }
  
  String _formatTimestamp(DateTime timestamp) {
    final d = DateTime.now().difference(timestamp);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    if (d.inDays < 1) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}

class SocialAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  
  const SocialAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });
}
