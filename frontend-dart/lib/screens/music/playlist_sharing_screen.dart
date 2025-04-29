// screens/music/playlist_sharing_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../models/playlist.dart';

class PlaylistSharingScreen extends StatefulWidget {
  final Playlist playlist;
  
  const PlaylistSharingScreen({Key? key, required this.playlist}) : super(key: key);

  @override
  _PlaylistSharingScreenState createState() => _PlaylistSharingScreenState();
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
      
      await musicProvider.updatePlaylist(
        widget.playlist.id,
        widget.playlist.name,
        widget.playlist.description,
        !_isPublic,
        authProvider.token!,
      );
      
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
      appBar: AppBar(
        title: const Text('Share Playlist'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
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
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Created by: ${widget.playlist.creator}',
                            style: TextStyle(
                              fontSize: 14, 
                              color: Colors.grey[600]
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${widget.playlist.tracks.length} tracks',
                            style: TextStyle(
                              fontSize: 14, 
                              color: Colors.grey[600]
                            ),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Public Playlist'),
                            subtitle: Text(
                              _isPublic
                                  ? 'Anyone with the link can view this playlist'
                                  : 'Only you can see this playlist'
                            ),
                            value: _isPublic,
                            onChanged: (value) => _togglePublicStatus(),
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
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Playlist Link:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(_shareLink ?? 'Generating link...'),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy),
                                    onPressed: () {
                                      // In a real app, copy to clipboard
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
                                fontWeight: FontWeight.bold
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
                                  icon: Icons.social_distance,
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
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.public),
                            title: const Text('Public'),
                            subtitle: const Text('Anyone with the link'),
                            selected: true,
                            selectedColor: Theme.of(context).primaryColor,
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.group),
                            title: const Text('Friends Only'),
                            subtitle: const Text('Only people you follow'),
                            enabled: false,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('This feature is coming soon!'),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.lock),
                            title: const Text('Private'),
                            subtitle: const Text('Only you'),
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
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Enable public sharing to generate a share link',
                              textAlign: TextAlign.center,
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
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
