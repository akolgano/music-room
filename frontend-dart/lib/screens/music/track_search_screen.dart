// lib/screens/music/track_search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../models/track.dart';
import '../../core/theme.dart';
import '../../widgets/common_widgets.dart';
import 'deezer_track_detail_screen.dart';

class TrackSearchScreen extends StatefulWidget {
  final String? playlistId;
  final Track? initialTrack;
  final bool searchDeezer;

  const TrackSearchScreen({
    Key? key, 
    this.playlistId,
    this.initialTrack,
    this.searchDeezer = true,
  }) : super(key: key);

  @override
  State<TrackSearchScreen> createState() => _TrackSearchScreenState();
}

class _TrackSearchScreenState extends State<TrackSearchScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  bool _searchDeezer = true;
  Set<String> _selectedTracks = {};
  bool _isMultiSelectMode = false;

  @override
  void initState() {
    super.initState();
    _searchDeezer = widget.searchDeezer;
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = Provider.of<MusicProvider>(context);
    final tracks = musicProvider.searchResults;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.playlistId != null ? 'Add Music to Playlist' : 'Search for Music',
              style: const TextStyle(fontSize: 16),
            ),
            if (widget.playlistId != null)
              const Text(
                'Find songs to add to your playlist',
                style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
              ),
          ],
        ),
        actions: _buildAppBarActions(),
      ),
      body: Column(
        children: [
          _buildSearchSection(),
          _buildSearchModeSelector(),
          if (_isMultiSelectMode && _selectedTracks.isNotEmpty)
            _buildSelectionBar(),
          Expanded(child: _buildResultsSection(tracks)),
        ],
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      if (_isMultiSelectMode)
        TextButton.icon(
          onPressed: () {
            setState(() {
              _isMultiSelectMode = false;
              _selectedTracks.clear();
            });
          },
          icon: const Icon(Icons.close, color: Colors.white, size: 16),
          label: const Text('Cancel', style: TextStyle(color: Colors.white, fontSize: 12)),
        )
      else
        TextButton.icon(
          onPressed: () {
            setState(() {
              _isMultiSelectMode = true;
            });
          },
          icon: const Icon(Icons.checklist, color: Colors.white, size: 16),
          label: const Text('Multi-Select', style: TextStyle(color: Colors.white, fontSize: 12)),
        ),
    ];
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Search for Songs',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _searchController,
                  labelText: 'Song, artist, or album',
                  hintText: 'e.g., "Bohemian Rhapsody Queen" or "Imagine Dragons"',
                  prefixIcon: Icons.search,
                  onChanged: (_) {},
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _performSearch,
                icon: const Icon(Icons.search, size: 18),
                label: const Text('Search'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ],
          ),
          if (widget.playlistId != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.playlist_add, color: AppTheme.primary, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Songs you select will be added to your playlist',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchModeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppTheme.surfaceVariant,
      child: Row(
        children: [
          const Icon(Icons.tune, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Search in:',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.library_music, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Deezer', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                    subtitle: const Text(
                      'Millions of songs',
                      style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 10),
                    ),
                    value: true,
                    groupValue: _searchDeezer,
                    onChanged: (value) => setState(() => _searchDeezer = value!),
                    activeColor: AppTheme.primary,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.storage, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Local', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                    subtitle: const Text(
                      'Your saved music',
                      style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 10),
                    ),
                    value: false,
                    groupValue: _searchDeezer,
                    onChanged: (value) => setState(() => _searchDeezer = value!),
                    activeColor: AppTheme.primary,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppTheme.primary.withOpacity(0.1),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: AppTheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '${_selectedTracks.length} song${_selectedTracks.length == 1 ? '' : 's'} selected',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (widget.playlistId != null)
            ElevatedButton.icon(
              onPressed: _addSelectedTracksToPlaylist,
              icon: const Icon(Icons.playlist_add, size: 16),
              label: const Text('Add to Playlist'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _addSelectedTracksToLibrary,
              icon: const Icon(Icons.library_add, size: 16),
              label: const Text('Add to Library'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsSection(List<Track> tracks) {
    if (_isLoading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.primary),
          const SizedBox(height: 16),
          Text(
            'Searching ${_searchDeezer ? 'Deezer' : 'your library'}...',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      );
    }

    if (_searchController.text.isEmpty) {
      return _buildSearchPrompt();
    }

    if (tracks.isEmpty) {
      return _buildNoResultsState();
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppTheme.surface,
          child: Row(
            children: [
              Icon(
                _searchDeezer ? Icons.library_music : Icons.storage,
                color: AppTheme.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Found ${tracks.length} song${tracks.length == 1 ? '' : 's'} in ${_searchDeezer ? 'Deezer' : 'your library'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_isMultiSelectMode) ...[
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedTracks.length == tracks.length) {
                        _selectedTracks.clear();
                      } else {
                        _selectedTracks.addAll(tracks.map((t) => t.id));
                      }
                    });
                  },
                  child: Text(
                    _selectedTracks.length == tracks.length ? 'Deselect All' : 'Select All',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: tracks.length,
            itemBuilder: (ctx, i) => _buildTrackItem(tracks[i], i),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ready to find music?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter a song title, artist name, or album to get started',
              style: TextStyle(color: AppTheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Search Tips:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('• Use quotes for exact phrases: "Bohemian Rhapsody"', 
                       style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
                  Text('• Include artist name: "Imagine Dragons Thunder"', 
                       style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
                  Text('• Try different spellings if you don\'t find what you want', 
                       style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No songs found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t find any songs matching "${_searchController.text}" in ${_searchDeezer ? 'Deezer' : 'your library'}',
              style: const TextStyle(color: AppTheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Try these suggestions:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('• Check your spelling', 
                           style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
                  const Text('• Use fewer, more general words', 
                           style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
                  const Text('• Try searching for the artist name only', 
                           style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
                  if (!_searchDeezer)
                    const Text('• Switch to Deezer search for more songs', 
                             style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!_searchDeezer)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchDeezer = true;
                  });
                  _performSearch();
                },
                icon: const Icon(Icons.library_music, size: 16),
                label: const Text('Search Deezer Instead'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackItem(Track track, int index) {
    final isSelected = _selectedTracks.contains(track.id);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isSelected ? AppTheme.primary.withOpacity(0.1) : AppTheme.surface,
      elevation: isSelected ? 4 : 1,
      child: InkWell(
        onTap: () => _handleTrackTap(track),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  _buildTrackLeading(track, isSelected),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.person, size: 12, color: AppTheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                track.artist,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (track.album.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.album, size: 12, color: AppTheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  track.album,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.onSurfaceVariant.withOpacity(0.7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (_searchDeezer && track.previewUrl != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.preview, size: 12, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                'Preview available',
                                style: TextStyle(fontSize: 10, color: Colors.green),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_isMultiSelectMode)
                    Checkbox(
                      value: isSelected, 
                      onChanged: (value) => _toggleTrackSelection(track.id),
                      activeColor: AppTheme.primary,
                    )
                ],
              ),
              if (!_isMultiSelectMode) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (track.deezerTrackId != null)
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => _viewTrackDetails(track),
                          icon: const Icon(Icons.info_outline, size: 16),
                          label: const Text('Details', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                          ),
                        ),
                      ),
                    if (track.deezerTrackId != null && 
                        (widget.playlistId != null || track.previewUrl != null))
                      const SizedBox(width: 8),
                    if (track.previewUrl != null)
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => _playPreview(track),
                          icon: const Icon(Icons.play_arrow, size: 16),
                          label: const Text('Preview', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                          ),
                        ),
                      ),
                    if (track.previewUrl != null && widget.playlistId != null)
                      const SizedBox(width: 8),
                    if (widget.playlistId != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _addSingleTrackToPlaylist(track),
                          icon: const Icon(Icons.playlist_add, size: 16),
                          label: const Text('Add', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _addSingleTrackToLibrary(track),
                          icon: const Icon(Icons.library_add, size: 16),
                          label: const Text('Save', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackLeading(Track track, bool isSelected) {
    if (track.imageUrl != null && track.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          track.imageUrl!, 
          width: 40, 
          height: 40, 
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackImage(isSelected)
        ),
      );
    }
    return _buildFallbackImage(isSelected);
  }

  Widget _buildFallbackImage(bool isSelected) {
    if (isSelected && _isMultiSelectMode) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.check_circle, color: Colors.white, size: 20),
      );
    }
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.music_note, color: AppTheme.onSurfaceVariant, size: 20),
    );
  }

  void _handleTrackTap(Track track) {
    if (_isMultiSelectMode) {
      _toggleTrackSelection(track.id);
    } else if (track.deezerTrackId != null) {
      _viewTrackDetails(track);
    }
  }

  void _toggleTrackSelection(String trackId) {
    setState(() {
      if (_selectedTracks.contains(trackId)) {
        _selectedTracks.remove(trackId);
      } else {
        _selectedTracks.add(trackId);
      }
    });
  }

  void _performSearch() async {
    if (_searchController.text.trim().isEmpty) {
      _showSnackBar('Please enter something to search for', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      
      if (_searchDeezer) {
        await musicProvider.searchDeezerTracks(_searchController.text);
      } else {
        await musicProvider.searchTracks(_searchController.text);
      }
    } catch (error) {
      _showSnackBar('Search failed. Please check your connection and try again.', isError: true);
    }

    setState(() => _isLoading = false);
  }

  void _playPreview(Track track) {
    _showSnackBar('Preview playback coming soon!');
  }

  void _addSingleTrackToPlaylist(Track track) async {
    if (widget.playlistId == null) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);

      if (track.deezerTrackId != null && _searchDeezer) {
        await musicProvider.addTrackFromDeezer(track.deezerTrackId!, authProvider.token!);
      }

      await musicProvider.addTrackToPlaylist(widget.playlistId!, track.id, authProvider.token!);
      _showSnackBar('Added "${track.name}" to your playlist!');
    } catch (error) {
      _showSnackBar('Unable to add track. Please try again.', isError: true);
    }
  }

  void _addSingleTrackToLibrary(Track track) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);

      if (track.deezerTrackId != null && _searchDeezer) {
        await musicProvider.addTrackFromDeezer(track.deezerTrackId!, authProvider.token!);
        _showSnackBar('Added "${track.name}" to your music library!');
      } else {
        _showSnackBar('This track is already in your library');
      }
    } catch (error) {
      _showSnackBar('Unable to add track to library. Please try again.', isError: true);
    }
  }

  void _addSelectedTracksToPlaylist() async {
    if (_selectedTracks.isEmpty || widget.playlistId == null) return;

    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final tracks = musicProvider.searchResults.where((t) => _selectedTracks.contains(t.id)).toList();

    try {
      for (final track in tracks) {
        if (track.deezerTrackId != null && _searchDeezer) {
          await musicProvider.addTrackFromDeezer(track.deezerTrackId!, authProvider.token!);
        }
        await musicProvider.addTrackToPlaylist(widget.playlistId!, track.id, authProvider.token!);
      }

      _showSnackBar('Successfully added ${tracks.length} songs to your playlist!');
      setState(() {
        _selectedTracks.clear();
        _isMultiSelectMode = false;
      });
    } catch (error) {
      _showSnackBar('Some tracks could not be added. Please try again.', isError: true);
    }
  }

  void _addSelectedTracksToLibrary() async {
    if (_selectedTracks.isEmpty) return;

    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final tracks = musicProvider.searchResults.where((t) => _selectedTracks.contains(t.id)).toList();

    try {
      int addedCount = 0;
      for (final track in tracks) {
        if (track.deezerTrackId != null && _searchDeezer) {
          await musicProvider.addTrackFromDeezer(track.deezerTrackId!, authProvider.token!);
          addedCount++;
        }
      }

      if (addedCount > 0) {
        _showSnackBar('Added $addedCount songs to your library!');
      } else {
        _showSnackBar('Selected tracks are already in your library');
      }

      setState(() {
        _selectedTracks.clear();
        _isMultiSelectMode = false;
      });
    } catch (error) {
      _showSnackBar('Some tracks could not be added to your library.', isError: true);
    }
  }

  void _viewTrackDetails(Track track) {
    if (track.deezerTrackId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DeezerTrackDetailScreen(
            trackId: track.deezerTrackId!,
          ),
        ),
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : Colors.green,
        behavior: SnackBarBehavior.floating,
        action: isError ? SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ) : null,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
