// lib/services/playlist_conflict_resolver.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';

enum ConflictType { trackMove, trackAdd, trackRemove, trackUpdate }

class PlaylistOperation {
  final String id;
  final String userId;
  final String username;
  final ConflictType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int version;

  PlaylistOperation({
    required this.id,
    required this.userId,
    required this.username,
    required this.type,
    required this.data,
    required this.timestamp,
    required this.version,
  });

  factory PlaylistOperation.fromJson(Map<String, dynamic> json) => PlaylistOperation(
    id: json['id'].toString(),
    userId: json['user_id'].toString(),
    username: json['username'] ?? 'User',
    type: ConflictType.values.firstWhere((t) => t.name == json['type'], orElse: () => ConflictType.trackUpdate),
    data: json['data'] ?? {},
    timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    version: json['version'] ?? 1,
  );
}

class PlaylistConflictResolver {
  final Map<String, List<PlaylistOperation>> _pendingOperations = {};
  final StreamController<String> _conflictNotifications = StreamController.broadcast();
  
  Stream<String> get conflictNotifications => _conflictNotifications.stream;

  List<PlaylistOperation> resolveMoveConflicts(
    List<PlaylistOperation> operations,
    List<PlaylistTrack> currentTracks,
  ) {
    operations.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    final List<PlaylistOperation> validOperations = [];
    var workingTracks = List<PlaylistTrack>.from(currentTracks);
    
    for (final operation in operations) {
      if (operation.type == ConflictType.trackMove) {
        final oldIndex = operation.data['old_index'] as int;
        final newIndex = operation.data['new_index'] as int;
        
        if (oldIndex < workingTracks.length && 
            workingTracks[oldIndex].trackId == operation.data['track_id']) {
          
          final track = workingTracks.removeAt(oldIndex);
          final adjustedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
          workingTracks.insert(adjustedNewIndex.clamp(0, workingTracks.length), track);
          
          validOperations.add(operation);
        } else {
          _conflictNotifications.add(
            'Track move by ${operation.username} conflicts with recent changes'
          );
        }
      }
    }
    
    return validOperations;
  }

  bool detectSimultaneousEdit(PlaylistOperation operation, List<PlaylistOperation> recentOps) {
    const simultaneousThreshold = Duration(seconds: 2);
    
    return recentOps.any((recentOp) =>
      recentOp.userId != operation.userId &&
      operation.timestamp.difference(recentOp.timestamp).abs() < simultaneousThreshold
    );
  }

  Map<String, dynamic> createOperationalTransform(
    PlaylistOperation localOp,
    PlaylistOperation remoteOp,
  ) {
    if (localOp.type == ConflictType.trackMove && remoteOp.type == ConflictType.trackMove) {
      final localOldIndex = localOp.data['old_index'] as int;
      final localNewIndex = localOp.data['new_index'] as int;
      final remoteOldIndex = remoteOp.data['old_index'] as int;
      final remoteNewIndex = remoteOp.data['new_index'] as int;
      
      int transformedOldIndex = localOldIndex;
      int transformedNewIndex = localNewIndex;
      
      if (remoteOldIndex <= localOldIndex) {
        transformedOldIndex--;
      }
      if (remoteNewIndex <= localNewIndex) {
        transformedNewIndex++;
      }
      
      return {
        'old_index': transformedOldIndex,
        'new_index': transformedNewIndex,
        'track_id': localOp.data['track_id'],
      };
    }
    
    return localOp.data;
  }

  void dispose() {
    _conflictNotifications.close();
  }
}
