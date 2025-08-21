import 'dart:async'; 
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import '../../providers/music_providers.dart';
import '../../services/player_services.dart';
import '../../services/music_services.dart';
import '../../services/logging_services.dart';
import '../../core/theme_core.dart';
import '../../core/constants_core.dart';
import '../../core/logging_core.dart';
import '../../core/navigation_core.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/sort_widgets.dart';
import '../../models/music_models.dart';
import '../../models/sort_models.dart';
import '../base_screens.dart';

enum LoadingState { idle, searching, addingTracks }

class TrackSearchScreen extends StatefulWidget {
  final String? playlistId;
  final Track? initialTrack;
  final bool isEmbedded; 

  const TrackSearchScreen({
    super.key, 
    this.playlistId, 
    this.initialTrack,
    this.isEmbedded = false, 
  });

  @override
  State<TrackSearchScreen> createState() => _TrackSearchScreenState();
}

class _TrackSearchScreenState extends BaseScreen<TrackSearchScreen> with UserActionLoggingMixin {
  final _searchController = TextEditingController();
  Set<String> _selectedTracks = {};
  bool _isMultiSelectMode = false;
  LoadingState _loadingState = LoadingState.idle;
  List<Playlist> _userPlaylists = [];
  Timer? _searchTimer;
  static const Duration _searchDelay = Duration(milliseconds: 800); 
  static const int _minSearchLength = 2;
  
  static const List<String> _randomSearchSuggestions = [
    'Pop hits', 'Rock classics', 'Jazz fusion', 'Electronic dance', 'Hip hop beats',
    'Indie alternative', 'Country gold', 'R&B smooth', 'Classical symphony', 'Reggae vibes',
    'Folk acoustic', 'Metal hardcore', 'Disco funk', 'Blues soul', 'Ambient chill',
    'Punk energy', 'Trap beats', 'Techno pulse', 'Gospel spirit', 'World music'
  ]; 

  bool get _isAddingToPlaylist => widget.playlistId != null;
  bool get _hasSelection => _selectedTracks.isNotEmpty;
  bool get _canAddTracks => _hasSelection && !_isLoading;
  bool get _isLoading => _loadingState != LoadingState.idle;
  bool get _isSearching => _loadingState == LoadingState.searching; 
  bool get _isAddingTracks => _loadingState == LoadingState.addingTracks;

  MusicPlayerService get _playerService => getProvider<MusicPlayerService>();

  TrackSortOption _searchSortOption = const TrackSortOption(
    field: TrackSortField.name, 
    order: SortOrder.ascending, 
    displayName: 'Track Name (A-Z)', 
    icon: Icons.sort_by_alpha
  );

  @override
  String get screenTitle => 'Search Tracks';

  @override
  bool get showBackButton => !widget.isEmbedded;

  @override
  bool get showMiniPlayer => !widget.isEmbedded; 

  @override
  List<Widget> get actions => _buildAppBarActions();

  @override
  Widget? get floatingActionButton => _buildFloatingActionButton();

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  void _initializeScreen() {
    if (widget.initialTrack != null) {
      _searchController.text = widget.initialTrack!.name;
      WidgetsBinding.instance.addPostFrameCallback((_) => _performSearch());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkFirstVisitAndSetRandomSearch());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUserPlaylists());
  }

  Future<void> _checkFirstVisitAndSetRandomSearch() async {
    try {
      final box = await Hive.openBox('app_preferences');
      final hasVisitedSearch = box.get('has_visited_search_screen', defaultValue: false) as bool;
      
      if (!hasVisitedSearch && widget.isEmbedded) {
        final random = Random();
        final randomSuggestion = _randomSearchSuggestions[random.nextInt(_randomSearchSuggestions.length)];
        
        setState(() {
          _searchController.text = randomSuggestion;
        });
        
        await box.put('has_visited_search_screen', true);
        await box.close();
        
        AppLogger.debug('First visit to search screen - set random suggestion: $randomSuggestion', 'TrackSearchScreen');
      } else {
        await box.close();
      }
    } catch (e) {
      AppLogger.error('Failed to check first visit status', e, null, 'TrackSearchScreen');
    }
  }

  @override
  Widget buildContent() {
    return Consumer<MusicProvider>(
      builder: (context, music, _) => Column(
        children: [
          _buildSearchHeader(music),
          if (_isAddingToPlaylist && _isMultiSelectMode) _buildQuickActions(),
          if (_isAddingTracks) _buildProgressIndicator(),
          Expanded(child: _buildResults(music.searchResults)),
        ],
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    final actions = <Widget>[];
    if (_isAddingToPlaylist && _isMultiSelectMode && _hasSelection) {
      actions.add(IconButton(
        icon: const Icon(Icons.add_circle, color: AppTheme.primary),
        onPressed: _canAddTracks ? _addSelectedTracks : null,
        tooltip: 'Add Selected (${_selectedTracks.length})',
      ));
    }
    if (_isAddingToPlaylist) {
      actions.add(TextButton(
        onPressed: _isLoading ? null : _toggleMultiSelectMode,
        child: Text(
          _isMultiSelectMode ? 'Cancel' : 'Multi-Select', 
          style: const TextStyle(color: AppTheme.primary)
        ),
      ));
    }
    actions.add(IconButton(
      icon: const Icon(Icons.clear), 
      onPressed: _clearSearch, 
      tooltip: 'Clear Search'
    )); 
    return actions;
  }

  Widget _buildSearchHeader(MusicProvider musicProvider) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.1), 
            blurRadius: 4, 
            offset: const Offset(0, 2)
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isAddingToPlaylist) _buildPlaylistBanner(), 
          _buildSearchRow(musicProvider)
        ],
      ),
    );
  }

  Widget _buildSearchRow(MusicProvider musicProvider) {
    return Row(
      children: [
        Expanded(
          child: AppWidgets.textField(
            context: context,
            controller: _searchController,
            labelText: '',
            hintText: _isAddingToPlaylist ? 'Search Deezer tracks to add to playlist' : 'Search Deezer tracks',
            prefixIcon: Icons.search,
            onChanged: _onSearchTextChanged, 
          ),
        ),
        const SizedBox(width: 8),
        AppWidgets.primaryButton(
          context: context,
          text: 'Search',
          onPressed: _searchController.text.isNotEmpty ? _performSearch : null,
          isLoading: _isSearching,
          icon: Icons.search,
          fullWidth: false,
        ),
      ],
    );
  }

  Widget _buildPlaylistBanner() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.playlist_add, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Adding tracks to playlist',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (_isMultiSelectMode) _buildSelectionBadge(),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSelectionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${_selectedTracks.length} selected',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    if (!_isAddingToPlaylist || getProvider<MusicProvider>().searchResults.isEmpty) {
      return const SizedBox.shrink();
    }

    final actions = [
      ('Select All', Icons.select_all, _selectAllTracks),
      ('Clear', Icons.clear_all, _clearSelection),
      (_isMultiSelectMode ? 'Done' : 'Select', 
       _isMultiSelectMode ? Icons.check_box : Icons.check_box_outline_blank, 
       _toggleMultiSelectMode),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Row(
        children: actions.map((action) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: ElevatedButton.icon(
              onPressed: action.$3,
              icon: Icon(action.$2, size: 16),
              label: Text(action.$1),
              style: ElevatedButton.styleFrom(
                backgroundColor: action.$1.contains('Done') && _isMultiSelectMode 
                  ? AppTheme.primary 
                  : AppTheme.surface,
                foregroundColor: action.$1.contains('Done') && _isMultiSelectMode 
                  ? Colors.black 
                  : Colors.white,
                side: BorderSide(
                  color: action.$1.contains('Done') && _isMultiSelectMode 
                    ? AppTheme.primary 
                    : Colors.white54
                ),
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            Text(
              'Adding ${_selectedTracks.length} tracks...',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (!_isAddingToPlaylist) return null;
    if (_isMultiSelectMode && _hasSelection) {
      return FloatingActionButton.extended(
        onPressed: _canAddTracks ? _addSelectedTracks : null,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.black,
        icon: _isAddingTracks 
          ? const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
            )
          : const Icon(Icons.playlist_add),
        label: Text(_isAddingTracks ? 'Adding...' : 'Add ${_selectedTracks.length} tracks'),
      );
    }
    if (!_isMultiSelectMode) {
      return FloatingActionButton(
        onPressed: _toggleMultiSelectMode,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.black,
        tooltip: 'Select multiple tracks',
        child: const Icon(Icons.playlist_add),
      );
    }
    return null;
  }

  void _setLoadingState(LoadingState state) {
    setState(() {
      _loadingState = state;
    });
  }

  void _onSearchTextChanged(String value) {
    setState(() {}); 
    _searchTimer?.cancel();
    if (value.trim().length < _minSearchLength) {
      getProvider<MusicProvider>().clearSearchResults();
      return;
    }
    _searchTimer = Timer(_searchDelay, () {
      if (mounted && _searchController.text.trim().length >= _minSearchLength) {
        _performSearch(isAutoSearch: true);
      }
    });
  }

  Future<void> _performSearch({bool isAutoSearch = false}) async {
    if (!mounted || _searchController.text.trim().length < _minSearchLength) return;
    
    final query = _searchController.text.trim();
    logSearch(query, metadata: {
      'is_auto_search': isAutoSearch,
      'query_length': query.length,
      'playlist_id': widget.playlistId,
    });
    
    await runAsyncAction(
      () async {
        _setLoadingState(LoadingState.searching);
        await getProvider<MusicProvider>().searchDeezerTracks(query);
      },
      errorMessage: isAutoSearch ? null : 'Search failed. Please try again.',
    );
    _setLoadingState(LoadingState.idle);
  }

  Widget _buildResults(List<Track> tracks) {
    if (tracks.isEmpty && _searchController.text.isEmpty) {
      return AppWidgets.emptyState(icon: Icons.search, title: 'Ready to find music?', 
        subtitle: 'Start typing to search Deezer tracks automatically!'
      );
    }

    if (tracks.isEmpty && _searchController.text.isNotEmpty) {
      if (_searchController.text.length < _minSearchLength) {
        return AppWidgets.emptyState(
          icon: Icons.edit,
          title: 'Keep typing...',
          subtitle: 'Type at least $_minSearchLength characters to start searching',
        );
      } else {
        return AppWidgets.emptyState(icon: Icons.search_off, title: 'No tracks found', subtitle: 'Try different keywords',
          buttonText: 'Clear Search',
          onButtonPressed: _clearSearch,
        );
      }
    }
   
    final sortedTracks = TrackSortingService.sortTrackList(tracks, _searchSortOption);

    return Column(
      children: [
        if (tracks.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${tracks.length} results', style: const TextStyle(color: Colors.grey)),
                SortButton(currentSort: _searchSortOption, onPressed: _showSearchSortOptions, showLabel: true),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 8), 
            itemCount: sortedTracks.length, 
            itemBuilder: (ctx, i) => _buildTrackItem(sortedTracks[i])
          ),
        ),
      ],
    );
  }

  Widget _buildTrackItem(Track track) {
    final isInPlaylist = _isTrackInPlaylist(track.id);
    return TrackCardWidget(
      track: track,
      isSelected: _selectedTracks.contains(track.id),
      isInPlaylist: isInPlaylist,
      showVotingControls: _isAddingToPlaylist,
      playlistContext: _isAddingToPlaylist ? 'Playlist' : null,
      playlistId: _isAddingToPlaylist ? widget.playlistId : null,
      onTap: () => _handleTrackTap(track),
      onSelectionChanged: _isMultiSelectMode ? (value) => _toggleSelection(track.id) : null,
      onAdd: !_isMultiSelectMode && !isInPlaylist ? () => _handleAddTrack(track) : null, 
      onPlay: () => _playTrack(track),
      showAddButton: true,
    ); 
  }

  void _toggleMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) _selectedTracks.clear();
    });
  }

  void _selectAllTracks() {
    setState(() {
      _selectedTracks = getProvider<MusicProvider>().searchResults
          .where((track) => !_isTrackInPlaylist(track.id))
          .map((track) => track.id)
          .toSet();
      _isMultiSelectMode = true;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedTracks.clear();
      _isMultiSelectMode = false;
    });
  }

  void _toggleSelection(String trackId) {
    setState(() {
      if (_selectedTracks.contains(trackId)) {
        _selectedTracks.remove(trackId);
      } else {
        _selectedTracks.add(trackId);
      }
    });
  }

  bool _isTrackInPlaylist(String trackId) {
    return getProvider<MusicProvider>().isTrackInPlaylist(trackId);
  }

  void _clearSearch() {
    _searchController.clear();
    _searchTimer?.cancel(); 
    _clearSelection();
    getProvider<MusicProvider>().clearSearchResults();
    _setLoadingState(LoadingState.idle);
  }

  void _handleTrackTap(Track track) {
    if (_isMultiSelectMode) {
      _toggleSelection(track.id);
    } else if (_isAddingToPlaylist && !_isTrackInPlaylist(track.id)) {
      _addTrackToPlaylist(widget.playlistId!, track);
    } else {
      _playTrack(track);
    }
  }

  Future<void> _handleAddTrack(Track track) async {
    logUserAction(
      actionType: UserActionType.addToPlaylist,
      description: 'Added track to playlist: ${track.name}',
      metadata: {
        'track_id': track.id,
        'playlist_id': widget.playlistId,
        'track_name': track.name,
        'artist': track.artist,
        'is_adding_to_specific_playlist': _isAddingToPlaylist,
      }
    );
    
    if (_isAddingToPlaylist) {
      await _addTrackObjectToPlaylist(widget.playlistId!, track);
    } else {
      await _showPlaylistSelectionDialog(track);
    }
  }

  Future<void> _addTrackObjectToPlaylist(String playlistId, Track track) async {
    await runAsyncAction(
      () async {
        final musicProvider = getProvider<MusicProvider>();
        final result = await musicProvider.addTrackObjectToPlaylist(playlistId, track, auth.token!);
        if (!result.success) throw Exception(result.message);
      },
      successMessage: 'Added "${track.name}" to playlist!',
      errorMessage: 'Failed to add track to playlist',
    );
  }

  Future<void> _loadUserPlaylists() async {
    await runAsyncAction(
      () async {
        await getProvider<MusicProvider>().fetchAllPlaylists(auth.token!);
        _userPlaylists = getProvider<MusicProvider>().playlists;
      },
      errorMessage: 'Failed to load playlists',
    );
  }

  Future<void> _playTrack(Track track) async {
    final isPlaying = _playerService.currentTrack?.id == track.id;
    logUserAction(
      actionType: isPlaying ? UserActionType.pauseMusic : UserActionType.playMusic,
      description: isPlaying ? 'Paused track: ${track.name}' : 'Playing track: ${track.name}',
      metadata: {
        'track_id': track.id,
        'track_name': track.name,
        'artist': track.artist,
        'is_toggle': _playerService.currentTrack?.id == track.id,
      }
    );
    
    await runAsyncAction(
      () async {
        if (_playerService.currentTrack?.id == track.id) {
          await _playerService.togglePlay();
          return;
        }
        String? previewUrl = track.previewUrl;
        if (previewUrl == null && track.deezerTrackId != null) {
          final fullTrackDetails = await getProvider<MusicProvider>().getDeezerTrack(track.deezerTrackId!, auth.token!);
          if (fullTrackDetails?.previewUrl != null) {
            previewUrl = fullTrackDetails!.previewUrl;
          }
        }
        if (previewUrl?.isNotEmpty == true) {
          await _playerService.playTrack(track, previewUrl!);
          _showMessage('Playing preview of "${track.name}"', isError: false);
        } else {
          _showMessage('No preview available for this track');
        }
      },
      errorMessage: 'Failed to play preview',
    );
  }

  Future<void> _addTrackToPlaylist(String playlistId, Track track) async {
    await runAsyncAction(
      () async {
        final musicProvider = getProvider<MusicProvider>();
        final result = await musicProvider.addTrackObjectToPlaylist(playlistId, track, auth.token!);
        if (!result.success) throw Exception(result.message);
        if (mounted) await musicProvider.fetchPlaylistTracks(playlistId, auth.token!);
      },
      successMessage: 'Added "${track.name}" to playlist!',
      errorMessage: 'Failed to add track to playlist',
    );
  }

  Future<void> _addSelectedTracks() async {
    if (!_isAddingToPlaylist || !_hasSelection) return;
    _setLoadingState(LoadingState.addingTracks);
    try {
      final result = await getProvider<MusicProvider>().addMultipleTracksToPlaylist(
        playlistId: widget.playlistId!,
        trackIds: _selectedTracks.toList(),
        token: auth.token!, 
        onProgress: (current, total) {},
      );
      _showMessage('Added ${result.successCount} tracks to playlist!', isError: false);
      if (result.duplicateCount > 0) _showMessage('${result.duplicateCount} tracks were already in playlist', isError: false);
      if (result.failureCount > 0) _showMessage('${result.failureCount} tracks failed to add');
      _clearSelection();
      final musicProvider = getProvider<MusicProvider>();
      await musicProvider.fetchPlaylistTracks(widget.playlistId!, auth.token!);
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showMessage('Failed to add tracks: $e');
    } finally {
      _setLoadingState(LoadingState.idle);
    }
  }

  Future<void> _showPlaylistSelectionDialog(Track track) async {
    if (_userPlaylists.isEmpty) {
      _showMessage('No playlists or events available. Create a playlist first.');
      return;
    }
    
    final regularPlaylists = _userPlaylists.where((p) => !p.isEvent).toList();
    final eventPlaylists = _userPlaylists.where((p) => p.isEvent).toList();
    
    final List<String> items = [];
    final List<IconData> icons = [];
    
    if (regularPlaylists.isNotEmpty) {
      items.add('📚 PLAYLISTS');
      icons.add(Icons.playlist_play);
      for (final playlist in regularPlaylists) {
        items.add('  ${playlist.name}');
        icons.add(Icons.library_music);
      }
    }
    
    if (eventPlaylists.isNotEmpty) {
      items.add('🎉 EVENTS');
      icons.add(Icons.event);
      for (final event in eventPlaylists) {
        items.add('  ${event.name}');
        icons.add(Icons.event_available);
      }
    }
    
    items.addAll(['Create New Playlist', 'Create New Event']);
    icons.addAll([Icons.add, Icons.event_note]);
    
    final selectedIndex = await _showSelectionDialog(
      title: 'Add Track To',
      items: items,
      icons: icons,
    );
    
    if (selectedIndex != null) {
      await _handlePlaylistSelection(selectedIndex, track, regularPlaylists, eventPlaylists);
    }
  }

  Future<void> _handlePlaylistSelection(int selectedIndex, Track track, 
      List<Playlist> regularPlaylists, List<Playlist> eventPlaylists) async {
    int currentIndex = 0;
    
    if (regularPlaylists.isNotEmpty) {
      currentIndex++;
      
      if (selectedIndex <= currentIndex + regularPlaylists.length - 1) {
        final playlistIndex = selectedIndex - currentIndex;
        await _addTrackToPlaylist(regularPlaylists[playlistIndex].id, track);
        return;
      }
      currentIndex += regularPlaylists.length;
    }
    
    if (eventPlaylists.isNotEmpty) {
      currentIndex++;
      
      if (selectedIndex <= currentIndex + eventPlaylists.length - 1) {
        final eventIndex = selectedIndex - currentIndex;
        await _addTrackToPlaylist(eventPlaylists[eventIndex].id, track);
        return;
      }
      currentIndex += eventPlaylists.length;
    }
    
    if (selectedIndex == currentIndex) {
      await _createNewPlaylistAndAddTrack(track);
    } else if (selectedIndex == currentIndex + 1) {
      await _createNewEventAndAddTrack(track);
    }
  }

  Future<void> _createNewEventAndAddTrack(Track track) async {
    final eventName = await AppWidgets.showTextInputDialog(
      context, 
      title: 'Create New Event',
      hintText: 'Enter event name',
      validator: (value) => AppValidators.required(value, 'event name'),
    );
    
    if (eventName != null && eventName.trim().isNotEmpty) {
      await runAsyncAction(
        () async {
          final musicProvider = getProvider<MusicProvider>();
          
          final newEventId = await musicProvider.createPlaylist(
            eventName.trim(),
            '',
            false,
            auth.token!,
            'open',
            true,
          );
          
          await _addTrackToPlaylist(newEventId!, track);
        },
        successMessage: 'Track added to new event "$eventName"',
        errorMessage: 'Failed to create event and add track',
      );
    }
  }

  Future<void> _createNewPlaylistAndAddTrack(Track track) async {
    final playlistName = await AppWidgets.showTextInputDialog(
      context, 
      title: 'Create New Playlist',
      hintText: 'Enter playlist name',
      validator: (value) => AppValidators.required(value, 'playlist name'),
    );
    if (playlistName?.isNotEmpty == true) {
      await runAsyncAction(
        () async {
          _setLoadingState(LoadingState.addingTracks);
          final playlistId = await getProvider<MusicProvider>().createPlaylist(
            playlistName!, 
            'Created while adding "${track.name}"', 
            true, 
            auth.token!,
            'open',
            false,
          );
        if (playlistId?.isNotEmpty == true) {
          final result = await getProvider<MusicProvider>().addTrackToPlaylist(playlistId!, track.id, auth.token!);
          if (result.success) {
            _showMessage('Created playlist "$playlistName" and added "${track.name}"!', isError: false);
            await _loadUserPlaylists();
          } else {
            throw Exception(result.message);
          }
        }
        _setLoadingState(LoadingState.idle);
      },
      successMessage: 'Playlist created and track added!',
      errorMessage: 'Failed to create playlist',
      );
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    if (isError) {
      showError(message);
    } else {
      showSuccess(message);
    }
  }

  void _showSearchSortOptions() {
    final searchSortOptions = TrackSortOption.defaultOptions
        .where((option) => option.field != TrackSortField.position && option.field != TrackSortField.dateAdded)
        .toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface, 
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  const Icon(Icons.sort, color: AppTheme.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Sort Search Results',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
            ),
            ...searchSortOptions.map((option) {
              final isSelected = option == _searchSortOption;
              return ListTile(
                leading: Icon(
                  option.icon, 
                  color: isSelected ? AppTheme.primary : Colors.white70
                ),
                title: Text(
                  option.displayName,
                  style: TextStyle(
                    color: isSelected ? AppTheme.primary : Colors.white,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: AppTheme.primary)
                    : null,
                onTap: () {
                  setState(() {
                    _searchSortOption = option;
                  });
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<int?> _showSelectionDialog({required String title, required List<String> items, List<IconData>? icons}) async {
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true, 
            itemCount: items.length,
            itemBuilder: (context, index) => ListTile(
              leading: Container(
                width: 40, 
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2), 
                  borderRadius: BorderRadius.circular(8)
                ),
                child: Icon(icons?[index] ?? Icons.music_note, color: AppTheme.primary),
              ),
              title: Text(items[index], style: const TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, index),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Cancel', style: TextStyle(color: Colors.grey))
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchTimer?.cancel(); 
    _searchController.dispose();
    super.dispose();
  }
}
