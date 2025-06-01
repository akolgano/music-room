// lib/screens/music/deezer_track_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../services/music_player_service.dart';
import '../../models/track.dart';
import '../../widgets/music_player_widget.dart';
import '../../core/theme.dart';
import '../../core/dimensions.dart';
import '../../core/app_strings.dart';
import 'track_search_screen.dart'; 

class DeezerTrackDetailScreen extends StatefulWidget {
  final String trackId;
  
  const DeezerTrackDetailScreen({Key? key, required this.trackId}) : super(key: key);

  @override
  State<DeezerTrackDetailScreen> createState() => _DeezerTrackDetailScreenState();
}

class _DeezerTrackDetailScreenState extends State<DeezerTrackDetailScreen> {
  bool _isLoading = true;
  Track? _track;
  String? _previewUrl;
  String? _errorMessage;
  Color _dominantColor = AppTheme.primary;

  static const List<Color> _colorPalette = [
    Color(0xFF1DB954), 
    Color(0xFFFF6B6B), 
    Color(0xFF4ECDC4), 
    Color(0xFF45B7D1), 
    Color(0xFF96CEB4), 
    Color(0xFFFFEAA7), 
    Color(0xFFDDA0DD), 
    Color(0xFF77DD77),
    Color(0xFF836FFF),
    Color(0xFFFFB347),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTrackDetails();
    });
  }

  Future<void> _loadTrackDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      _track = await musicProvider.getDeezerTrack(widget.trackId);
      
      if (_track != null && _track!.deezerTrackId != null) {
        _previewUrl = await musicProvider.getDeezerTrackPreviewUrl(_track!.deezerTrackId!);
        
        if (_track!.imageUrl != null && _track!.imageUrl!.isNotEmpty) {
          _extractDominantColor(_track!.imageUrl!);
        } else {
          _extractDominantColor(widget.trackId); 
        }
      } else if (_track == null) {
        _errorMessage = "Track details could not be loaded.";
      }
      
    } catch (error) {
      _errorMessage = error.toString();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _extractDominantColor(String inputStringForHash) {
    final hash = inputStringForHash.hashCode.abs();
    final colorIndex = hash % _colorPalette.length;
    
    if (mounted) {
      setState(() {
        _dominantColor = _colorPalette[colorIndex];
      });
    }
  }
  
  void _playTrack() {
    if (_track != null && _previewUrl != null && _previewUrl!.isNotEmpty) {
      final playerService = Provider.of<MusicPlayerService>(context, listen: false);
      playerService.playTrack(_track!, _previewUrl!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.noPreviewAvailable),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    final playerService = Provider.of<MusicPlayerService>(context);
    final bool isCurrentTrack = _track != null && playerService.currentTrack?.id == _track!.id;

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: _dominantColor,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      child: Scaffold(
        backgroundColor: AppTheme.background,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(AppStrings.trackDetails),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _dominantColor.withOpacity(0.8),
                  _dominantColor.withOpacity(0.1),
                ],
              ),
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : _errorMessage != null
                ? _buildErrorView()
                : _track == null
                    ? const Center(
                        child: Text(
                          'Track not found', 
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : _buildTrackContent(authProvider, musicProvider, playerService, isCurrentTrack),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline, 
              size: AppDimensions.iconXXXLarge, 
              color: AppTheme.error,
            ),
            SizedBox(height: AppDimensions.paddingMedium),
            Text(
              AppStrings.error,
              style: TextStyle(
                fontSize: AppDimensions.textLarge, 
                fontWeight: FontWeight.bold, 
                color: Colors.white,
              ),
            ),
            SizedBox(height: AppDimensions.paddingSmall),
            Text(
              _errorMessage ?? 'An unknown error occurred.', 
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppDimensions.paddingLarge),
            ElevatedButton(
              onPressed: _loadTrackDetails,
              style: ElevatedButton.styleFrom(backgroundColor: _dominantColor),
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
    )
    );
  }

  Widget _buildTrackContent(
    AuthProvider authProvider,
    MusicProvider musicProvider,
    MusicPlayerService playerService,
    bool isCurrentTrack,
  ) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeroSection(),
                _buildActionButtons(authProvider, musicProvider),
              ],
            ),
          ),
        ),
        if (isCurrentTrack)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.background.withOpacity(0.0),
                  _dominantColor.withOpacity(0.1),
                ],
              ),
            ),
            child: const MusicPlayerWidget(mini: true),
          ),
      ],
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _dominantColor.withOpacity(0.3),
            AppTheme.background,
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppDimensions.paddingLarge, 
          120, 
          AppDimensions.paddingLarge, 
          AppDimensions.paddingXLarge,
        ),
        child: Column(
          children: [
            _buildAlbumArt(),
            SizedBox(height: AppDimensions.paddingXLarge),
            _buildTrackInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumArt() {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: _dominantColor.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
        child: _track!.imageUrl != null && _track!.imageUrl!.isNotEmpty
            ? Image.network(
                _track!.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultAlbumArt(),
              )
            : _buildDefaultAlbumArt(),
      ),
    );
  }

  Widget _buildDefaultAlbumArt() {
    return Container(
      color: AppTheme.surfaceVariant,
      child: Icon(
        Icons.music_note,
        size: AppDimensions.iconXXXLarge,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTrackInfo() {
    return Column(
      children: [
        Text(
          _track!.name,
          style: TextStyle(
            fontSize: AppDimensions.textHeading,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppDimensions.paddingSmall),
        Text(
          _track!.artist,
          style: TextStyle(
            fontSize: AppDimensions.textXLarge,
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppDimensions.paddingSmall),
        Text(
          '${AppStrings.album}: ${_track!.album}', 
          style: TextStyle(
            fontSize: AppDimensions.textMedium,
            color: Colors.white.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionButtons(AuthProvider authProvider, MusicProvider musicProvider) {
    final playerService = Provider.of<MusicPlayerService>(context);
    final isCurrentTrack = _track != null && playerService.currentTrack?.id == _track!.id;

    return Padding(
      padding: EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        children: [
          _buildPlayButton(isCurrentTrack, playerService),
          SizedBox(height: AppDimensions.paddingMedium),
          _buildSecondaryButtons(authProvider, musicProvider),
          if (_track?.url != null && _track!.url.isNotEmpty) ...[
            SizedBox(height: AppDimensions.paddingMedium),
            _buildOpenInDeezerButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayButton(bool isCurrentTrack, MusicPlayerService playerService) {
    return Container(
      width: double.infinity,
      height: AppDimensions.buttonHeightLarge,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_dominantColor, _dominantColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
        boxShadow: [
          BoxShadow(
            color: _dominantColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: isCurrentTrack 
            ? playerService.togglePlay
            : _playTrack,
        icon: Icon(
          isCurrentTrack && playerService.isPlaying
              ? Icons.pause
              : Icons.play_arrow,
          size: AppDimensions.iconLarge,
        ),
        label: Text(
          isCurrentTrack && playerService.isPlaying
              ? AppStrings.pausePreview
              : AppStrings.playPreview,
          style: TextStyle(
            fontSize: AppDimensions.textLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButtons(AuthProvider authProvider, MusicProvider musicProvider) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _addToLibrary(authProvider, musicProvider),
            icon: const Icon(Icons.add),
            label: const Text(AppStrings.addToLibrary),
            style: OutlinedButton.styleFrom(
              foregroundColor: _dominantColor,
              side: BorderSide(color: _dominantColor),
              padding: EdgeInsets.symmetric(vertical: AppDimensions.paddingSmall),
            ),
          ),
        ),
        SizedBox(width: AppDimensions.paddingSmall),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _addToPlaylist(),
            icon: const Icon(Icons.playlist_add),
            label: const Text(AppStrings.addToPlaylist),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
              padding: EdgeInsets.symmetric(vertical: AppDimensions.paddingSmall),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOpenInDeezerButton() {
    return OutlinedButton.icon(
      onPressed: _openInDeezer,
      icon: const Icon(Icons.open_in_new),
      label: const Text(AppStrings.openInDeezer),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white),
        minimumSize: Size(double.infinity, AppDimensions.buttonHeight),
      ),
    );
  }

  Future<void> _addToLibrary(AuthProvider authProvider, MusicProvider musicProvider) async {
    if (_track == null || _track!.deezerTrackId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Track details not available to add to library.'), backgroundColor: AppTheme.error),
      );
      return;
    }
    try {
      await musicProvider.addTrackFromDeezer(
        _track!.deezerTrackId!,
        authProvider.token!,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppStrings.addedToLibrary),
          backgroundColor: _dominantColor,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppStrings.error}: $error'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _addToPlaylist() {
    if (_track == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Track details not available to add to playlist.'), backgroundColor: AppTheme.error),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrackSearchScreen(
          initialTrack: _track, 
        ),
      ),
    );
  }

  void _openInDeezer() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Opening Deezer link requires adding the url_launcher package and implementing the logic.',
        ),
      ),
    );
  }
}
