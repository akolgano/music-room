import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, debugPrint;
import '../providers/profile_providers.dart';
import '../providers/auth_providers.dart';
import '../core/theme_core.dart';

class ProfileAvatarWidget extends StatelessWidget {
  final ProfileProvider profileProvider;
  final AuthProvider auth;
  final VoidCallback onSuccess;
  final Function(String) onError;

  const ProfileAvatarWidget({
    super.key,
    required this.profileProvider,
    required this.auth,
    required this.onSuccess,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: profileProvider.isLoading 
          ? null 
          : () => _showEnlargedAvatar(context),
      child: Stack(
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: profileProvider.avatarUrl?.isNotEmpty == true
                  ? null
                  : LinearGradient(begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.7)],
                    ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: profileProvider.avatarUrl?.isNotEmpty == true
                ? ClipOval(
                    child: profileProvider.avatarUrl!.startsWith('data:')
                        ? Image.memory(
                            base64Decode(profileProvider.avatarUrl!.split(',')[1]),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildInitialsAvatar(),
                          )
                        : Image.network(
                            profileProvider.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildInitialsAvatar(),
                          ),
                  )
                : _buildInitialsAvatar(),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: profileProvider.isLoading 
                  ? null 
                  : () => _showEnlargedAvatar(context),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: profileProvider.isLoading 
                      ? Colors.grey 
                      : AppTheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: profileProvider.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.camera_alt, color: Colors.black, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _generateInitials() {
    final name = profileProvider.name ?? profileProvider.username ?? 'User';
    if (name.isEmpty) return 'U';
    
    final words = name.trim().split(' ').where((word) => word.isNotEmpty).toList();
    if (words.isEmpty) return 'U';
    
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'.toUpperCase();
    }
  }

  Widget _buildInitialsAvatar() {
    return Container(
      width: 100,
      height: 100,
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
          _generateInitials(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _editAvatar(BuildContext context, [String? sourceType]) async {
    try {
      sourceType ??= await _showImageSourceDialog(context);
      if (sourceType == null) return;

      if (sourceType == 'remove') {
        await profileProvider.deleteAvatar(auth.token);
        onSuccess();
        return;
      }

      Uint8List imageBytes = Uint8List(0);
      String mimeType = 'image/jpeg';

      if (sourceType == 'random_cat') {
        if (kDebugMode) {
          debugPrint('[ProfileAvatarWidget] Fetching random cat picture');
        }
        
        try {
          http.Response? response;
          String? imageUrl;
          
          final catApis = [
            {'url': 'https://api.thecatapi.com/v1/images/search', 'type': 'json'},
            {'url': 'https://cataas.com/cat', 'type': 'direct'},
            {'url': 'https://cdn2.thecatapi.com/images/0XYvRd7oD.jpg', 'type': 'direct'},
          ];
          
          for (final api in catApis) {
            try {
              if (kDebugMode) {
                debugPrint('[ProfileAvatarWidget] Trying cat API: ${api['url']}');
              }
              
              response = await http.get(
                Uri.parse(api['url']!),
                headers: {'User-Agent': 'Music Room App'},
              ).timeout(const Duration(seconds: 15));
              
              if (response.statusCode == 200) {
                if (api['type'] == 'json') {
                  final jsonData = jsonDecode(response.body);
                  if (jsonData is List && jsonData.isNotEmpty) {
                    imageUrl = jsonData[0]['url'];
                    if (imageUrl != null) {
                      final imageResponse = await http.get(
                        Uri.parse(imageUrl),
                        headers: {'User-Agent': 'Music Room App'},
                      ).timeout(const Duration(seconds: 15));
                      
                      if (imageResponse.statusCode == 200 && imageResponse.bodyBytes.isNotEmpty) {
                        imageBytes = imageResponse.bodyBytes;
                        mimeType = 'image/jpeg';
                        if (kDebugMode) {
                          debugPrint('[ProfileAvatarWidget] Successfully fetched cat picture from JSON API: ${imageBytes.length} bytes');
                        }
                        break;
                      }
                    }
                  }
                } else {
                  if (response.bodyBytes.isNotEmpty) {
                    imageBytes = response.bodyBytes;
                    mimeType = 'image/jpeg';
                    if (kDebugMode) {
                      debugPrint('[ProfileAvatarWidget] Successfully fetched cat picture from direct API: ${imageBytes.length} bytes');
                    }
                    break;
                  }
                }
              }
            } catch (e) {
              if (kDebugMode) {
                debugPrint('[ProfileAvatarWidget] Failed with API ${api['url']}: $e');
              }
              continue;
            }
          }
          
          if (imageBytes.isEmpty) {
            throw Exception('All cat picture APIs failed to return valid images');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[ProfileAvatarWidget] Error fetching cat picture: $e');
          }
          onError('Failed to fetch cat picture. Please check your internet connection and try again.');
          return;
        }
      } else {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery, 
          maxWidth: 512, 
          maxHeight: 512, 
          imageQuality: 80
        );
        if (image == null) return;

        if (kIsWeb) {
          imageBytes = await image.readAsBytes();
        } else {
          final File file = File(image.path);
          imageBytes = await file.readAsBytes();
        }
        mimeType = image.mimeType ?? 'image/jpeg';
      }

      if (imageBytes.length > 5 * 1024 * 1024) {
        onError('Image too large. Please choose an image smaller than 5MB.');
        return;
      }

      final String base64Image = base64Encode(imageBytes);

      if (kDebugMode) {
        debugPrint('[ProfileAvatarWidget] Uploading avatar: size=${imageBytes.length} bytes, type=$mimeType');
        debugPrint('[ProfileAvatarWidget] Base64 image length: ${base64Image.length}');
        debugPrint('[ProfileAvatarWidget] Auth token: ${auth.token != null ? 'present' : 'null'}');
      }

      final success = await profileProvider.updateProfile(
        auth.token,
        avatarBase64: base64Image,
        mimeType: mimeType,
      );
      
      if (kDebugMode) {
        debugPrint('[ProfileAvatarWidget] Avatar upload result: $success');
      }

      if (success) {
        onSuccess();
      } else {
        onError('Failed to update avatar - check network connection and try again');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProfileAvatarWidget] Avatar upload error: $e');
      }
      String errorMessage = 'Error updating avatar: ';
      if (e.toString().contains('DioException')) {
        if (e.toString().contains('401')) {
          errorMessage = 'Authentication failed - please login again';
        } else if (e.toString().contains('413')) {
          errorMessage = 'Image too large - please choose a smaller image';
        } else if (e.toString().contains('400')) {
          errorMessage = 'Invalid image format - please try a different image';
        } else if (e.toString().contains('500')) {
          errorMessage = 'Server error - please try again later';
        } else {
          errorMessage = 'Network error - check your connection';
        }
      } else {
        errorMessage += e.toString();
      }
      onError(errorMessage);
    }
  }

  Future<void> _showEnlargedAvatar(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  color: Colors.black54,
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: profileProvider.avatarUrl?.isNotEmpty == true
                            ? null
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.7)],
                              ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: profileProvider.avatarUrl?.isNotEmpty == true
                          ? ClipOval(
                              child: profileProvider.avatarUrl!.startsWith('data:')
                                  ? Image.memory(
                                      base64Decode(profileProvider.avatarUrl!.split(',')[1]),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          _buildEnlargedInitialsAvatar(),
                                    )
                                  : Image.network(
                                      profileProvider.avatarUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          _buildEnlargedInitialsAvatar(),
                                    ),
                            )
                          : _buildEnlargedInitialsAvatar(),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildActionButton(
                            icon: Icons.photo_library,
                            label: kIsWeb ? 'Choose File' : 'Gallery',
                            color: AppTheme.primary,
                            onTap: () {
                              Navigator.pop(context);
                              _editAvatar(context, 'gallery');
                            },
                          ),
                          const SizedBox(width: 16),
                          _buildActionButton(
                            icon: Icons.pets,
                            label: 'Random Cat',
                            color: AppTheme.primary,
                            onTap: () {
                              Navigator.pop(context);
                              _editAvatar(context, 'random_cat');
                            },
                          ),
                          const SizedBox(width: 16),
                          _buildActionButton(
                            icon: Icons.delete,
                            label: 'Remove',
                            color: Colors.red,
                            onTap: () {
                              Navigator.pop(context);
                              _editAvatar(context, 'remove');
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnlargedInitialsAvatar() {
    return Container(
      width: 280,
      height: 280,
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
          _generateInitials(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 80,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _showImageSourceDialog(BuildContext context) async {
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text(
            'Select Image Source',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppTheme.primary),
                title: Text(
                  kIsWeb ? 'Choose File' : 'Gallery',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.pets, color: AppTheme.primary),
                title: const Text(
                  'Random Cat Picture',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.pop(context, 'random_cat'),
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Remove Avatar',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => Navigator.pop(context, 'remove'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

}