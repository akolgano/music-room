// lib/services/track_sorting_service.dart
import '../models/models.dart';
import '../models/sort_models.dart';

class TrackSortingService {
  static List<PlaylistTrack> sortTracks(
    List<PlaylistTrack> tracks,
    TrackSortOption sortOption,
  ) {
    final sortedTracks = List<PlaylistTrack>.from(tracks);
    
    switch (sortOption.field) {
      case TrackSortField.position:
        sortedTracks.sort((a, b) {
          final comparison = a.position.compareTo(b.position);
          return sortOption.order == SortOrder.ascending ? comparison : -comparison;
        });
        break;
        
      case TrackSortField.name:
        sortedTracks.sort((a, b) {
          final aName = a.track?.name ?? a.name;
          final bName = b.track?.name ?? b.name;
          final comparison = aName.toLowerCase().compareTo(bName.toLowerCase());
          return sortOption.order == SortOrder.ascending ? comparison : -comparison;
        });
        break;
        
      case TrackSortField.artist:
        sortedTracks.sort((a, b) {
          final aArtist = a.track?.artist ?? '';
          final bArtist = b.track?.artist ?? '';
          final comparison = aArtist.toLowerCase().compareTo(bArtist.toLowerCase());
          return sortOption.order == SortOrder.ascending ? comparison : -comparison;
        });
        break;
        
      case TrackSortField.album:
        sortedTracks.sort((a, b) {
          final aAlbum = a.track?.album ?? '';
          final bAlbum = b.track?.album ?? '';
          final comparison = aAlbum.toLowerCase().compareTo(bAlbum.toLowerCase());
          return sortOption.order == SortOrder.ascending ? comparison : -comparison;
        });
        break;
        
      case TrackSortField.dateAdded:
        sortedTracks.sort((a, b) {
          final comparison = a.position.compareTo(b.position);
          return sortOption.order == SortOrder.ascending ? comparison : -comparison;
        });
        break;
    }
    
    return sortedTracks;
  }

  static List<Track> sortTracksByField(List<Track> tracks, TrackSortOption sortOption) {
    final sortedTracks = List<Track>.from(tracks);
    
    switch (sortOption.field) {
      case TrackSortField.position:
        break;
        
      case TrackSortField.name:
        sortedTracks.sort((a, b) {
          final comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          return sortOption.order == SortOrder.ascending ? comparison : -comparison;
        });
        break;
        
      case TrackSortField.artist:
        sortedTracks.sort((a, b) {
          final comparison = a.artist.toLowerCase().compareTo(b.artist.toLowerCase());
          return sortOption.order == SortOrder.ascending ? comparison : -comparison;
        });
        break;
        
      case TrackSortField.album:
        sortedTracks.sort((a, b) {
          final comparison = a.album.toLowerCase().compareTo(b.album.toLowerCase());
          return sortOption.order == SortOrder.ascending ? comparison : -comparison;
        });
        break;
        
      case TrackSortField.dateAdded:
        break;
    }
    
    return sortedTracks;
  }
}
