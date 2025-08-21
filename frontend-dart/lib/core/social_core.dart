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

  @override
  Widget build(BuildContext context) {
    late IconData icon;
    late Color color;
    
    switch (provider.toLowerCase()) {
      case 'google':
        icon = Icons.g_mobiledata;
        color = Colors.red;
        break;
      case 'facebook':
        icon = Icons.facebook;
        color = Colors.blue;
        break;
      default:
        throw ArgumentError('Unsupported social login provider: $provider');
    }

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

class SocialSharingUtils {

  static Future<void> shareToSocial({
    required String platform,
    required String content,
    String? url,
    String? imageUrl,
  }) async {
    AppLogger.debug('Sharing to $platform: $content', 'SocialSharingUtils');
    
    switch (platform.toLowerCase()) {
      case 'facebook':
        await _shareToFacebook(content, url, imageUrl);
        break;
      case 'twitter':
        await _shareToTwitter(content, url);
        break;
      case 'instagram':
        await _shareToInstagram(imageUrl ?? '');
        break;
      case 'whatsapp':
        await _shareToWhatsApp(content, url);
        break;
      default:
        throw ArgumentError('Unsupported platform: $platform');
    }
  }
  
  static Future<void> _shareToFacebook(String content, String? url, String? imageUrl) async {

    AppLogger.debug('Facebook share: $content', 'SocialSharingUtils');
  }
  
  static Future<void> _shareToTwitter(String content, String? url) async {

    AppLogger.debug('Twitter share: $content', 'SocialSharingUtils');
  }
  
  static Future<void> _shareToInstagram(String imageUrl) async {

    AppLogger.debug('Instagram share: $imageUrl', 'SocialSharingUtils');
  }
  
  static Future<void> _shareToWhatsApp(String content, String? url) async {

    AppLogger.debug('WhatsApp share: $content', 'SocialSharingUtils');
  }
  
  static String generateShareUrl(String platform, Map<String, String> params) {
    switch (platform.toLowerCase()) {
      case 'facebook':
        return 'https://www.facebook.com/sharer/sharer.php?u=${params['url']}';
      case 'twitter':
        return 'https://twitter.com/intent/tweet?text=${params['text']}&url=${params['url']}';
      case 'linkedin':
        return 'https://www.linkedin.com/sharing/share-offsite/?url=${params['url']}';
      case 'whatsapp':
        return 'https://wa.me/?text=${params['text']} ${params['url']}';
      default:
        return '';
    }
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
              child: avatarUrl == null
                  ? Text(
                      username.isNotEmpty ? username[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 32),
                    )
                  : null,
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

class SocialShareButton extends StatelessWidget {
  final String platform;
  final String content;
  final String? url;
  final VoidCallback? onShare;
  
  const SocialShareButton({
    super.key,
    required this.platform,
    required this.content,
    this.url,
    this.onShare,
  });
  
  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    
    switch (platform.toLowerCase()) {
      case 'facebook':
        icon = Icons.facebook;
        color = const Color(0xFF1877F2);
        break;
      case 'twitter':
        icon = Icons.share;
        color = const Color(0xFF1DA1F2);
        break;
      case 'whatsapp':
        icon = Icons.phone;
        color = const Color(0xFF25D366);
        break;
      case 'instagram':
        icon = Icons.camera_alt;
        color = const Color(0xFFE4405F);
        break;
      default:
        icon = Icons.share;
        color = AppTheme.primary;
    }
    
    return IconButton(
      icon: Icon(icon),
      color: color,
      onPressed: () async {
        await SocialSharingUtils.shareToSocial(
          platform: platform,
          content: content,
          url: url,
        );
        onShare?.call();
      },
      tooltip: 'Share on $platform',
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
                  child: avatarUrl == null
                      ? Text(username.isNotEmpty ? username[0].toUpperCase() : '?')
                      : null,
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
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
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
