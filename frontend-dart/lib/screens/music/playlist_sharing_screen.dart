// lib/screens/music/playlist_sharing_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../models/playlist.dart';
import '../../core/theme.dart';

class PlaylistSharingScreen extends StatefulWidget {
  final Playlist playlist;
  
  const PlaylistSharingScreen({Key? key, required this.playlist}) : super(key: key);

  @override
  State<PlaylistSharingScreen> createState() => _PlaylistSharingScreenState();
}

class _PlaylistSharingScreenState extends State<PlaylistSharingScreen> {
  bool _isLoading = false;
  bool _isPublic = false;
  String? _shareLink;
  
  @override
  void initState() {
    super.initState();
    _isPublic = widget.playlist.isPublic;
    
    if (_isPublic) {
      _generateShareLink();
    }
  }
  
  Future<void> _generateShareLink() async {
    setState(() {
      _isLoading = true;
    });
    
    await Future.delayed(const Duration(milliseconds: 800));
    
    setState(() {
      _shareLink = 'musicroom://playlists/${widget.playlist.id}';
      _isLoading = false;
    });
  }
  
  Future<void> _togglePublicStatus() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      
      final success = await musicProvider.changePlaylistVisibility(
        widget.playlist.id,
        !_isPublic,
        authProvider.token!,
      );
      
      if (success) {
        setState(() {
          _isPublic = !_isPublic;
          
          if (_isPublic) {
            _generateShareLink();
          } else {
            _shareLink = null;
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isPublic 
                ? 'Playlist is now public and can be shared' 
                : 'Playlist is now private'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update playlist visibility'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update playlist visibility: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  Future<void> _sharePlaylist() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing link: $_shareLink'),
        action: SnackBarAction(
          label: 'Copy',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Link copied to clipboard')),
            );
          },
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Share Playlist'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: AppTheme.surface,
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.playlist.name,
                            style: const TextStyle(
                              fontSize: 22, 
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Created by: ${widget.playlist.creator}',
                            style: const TextStyle(
                              fontSize: 14, 
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${widget.playlist.tracks.length} tracks',
                            style: const TextStyle(
                              fontSize: 14, 
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Public Playlist', style: TextStyle(color: Colors.white)),
                            subtitle: Text(
                              _isPublic
                                  ? 'Anyone with the link can view this playlist'
                                  : 'Only you can see this playlist',
                              style: const TextStyle(color: AppTheme.onSurfaceVariant),
                            ),
                            value: _isPublic,
                            onChanged: (value) => _togglePublicStatus(),
                            activeColor: AppTheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_isPublic) ...[
                    const Text(
                      'Share Options',
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: AppTheme.surface,
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Playlist Link:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _shareLink ?? 'Generating link...',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, color: Colors.white),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Link copied to clipboard')
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Share via:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildShareButton(
                                  icon: Icons.message,
                                  label: 'Message',
                                  color: Colors.blue,
                                ),
                                _buildShareButton(
                                  icon: Icons.email,
                                  label: 'Email',
                                  color: Colors.red,
                                ),
                                _buildShareButton(
                                  icon: Icons.share,
                                  label: 'Social',
                                  color: Colors.purple,
                                ),
                                _buildShareButton(
                                  icon: Icons.more_horiz,
                                  label: 'More',
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Who can see this playlist',
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: AppTheme.surface,
                      elevation: 2,
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.public, color: Colors.white),
                            title: const Text('Public', style: TextStyle(color: Colors.white)),
                            subtitle: const Text('Anyone with the link', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                            selected: true,
                            selectedTileColor: AppTheme.primary.withOpacity(0.1),
                          ),
                          const Divider(height: 1, color: AppTheme.surfaceVariant),
                          ListTile(
                            leading: const Icon(Icons.group, color: Colors.white),
                            title: const Text('Friends Only', style: TextStyle(color: Colors.white)),
                            subtitle: const Text('Only people you follow', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                            enabled: false,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('This feature is coming soon!'),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1, color: AppTheme.surfaceVariant),
                          ListTile(
                            leading: const Icon(Icons.lock, color: Colors.white),
                            title: const Text('Private', style: TextStyle(color: Colors.white)),
                            subtitle: const Text('Only you', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                            onTap: () => _togglePublicStatus(),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.lock,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'This playlist is currently private',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Enable public sharing to generate a share link',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
  
  Widget _buildShareButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return InkWell(
      onTap: _sharePlaylist,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              radius: 20,
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
