// lib/models/voting_models.dart
import 'package:flutter/material.dart';

class Vote {
  final String id;
  final String trackId;
  final String userId;
  final int voteValue; 
  final DateTime createdAt;

  const Vote({
    required this.id,
    required this.trackId,
    required this.userId,
    required this.voteValue,
    required this.createdAt,
  });

  factory Vote.fromJson(Map<String, dynamic> json) => Vote(
    id: json['id'].toString(),
    trackId: json['track_id'].toString(),
    userId: json['user_id'].toString(),
    voteValue: json['vote_value'] as int,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {'id': id,
    'track_id': trackId,
    'user_id': userId,
    'vote_value': voteValue,
    'created_at': createdAt.toIso8601String(),
  };
}

class VoteStats {
  final int points; 
  final bool userHasVoted;
  final int? userVoteValue;

  const VoteStats({
    required this.points,
    required this.userHasVoted,
    this.userVoteValue,
  });

  factory VoteStats.fromJson(Map<String, dynamic> json) => VoteStats(
    points: json['points'] as int? ?? 0,
    userHasVoted: json['user_has_voted'] as bool? ?? false,
    userVoteValue: json['user_vote_value'] as int?,
  );

  Color get scoreColor {
    if (points > 5) return Colors.green;
    if (points > 0) return Colors.orange;
    return Colors.grey;
  }

  String get displayText {
    if (points == 0) return 'No votes';
    if (points == 1) return '1 vote';
    return '$points votes';
  }
}

enum VotingPermission {
  allowed,
  notInvited,
  outsideTimeWindow,
  outsideLocation,
  noPermission,
}

class VotingRestrictions {
  final String licenseType;
  final bool isInvited;
  final bool isInTimeWindow;
  final bool isInLocation;
  final DateTime? voteStartTime;
  final DateTime? voteEndTime;
  final double? latitude;
  final double? longitude;
  final int? allowedRadiusMeters;

  const VotingRestrictions({
    required this.licenseType,
    required this.isInvited,
    required this.isInTimeWindow,
    required this.isInLocation,
    this.voteStartTime,
    this.voteEndTime,
    this.latitude,
    this.longitude,
    this.allowedRadiusMeters,
  });

  factory VotingRestrictions.fromJson(Map<String, dynamic> json) => VotingRestrictions(
    licenseType: json['license_type'] as String,
    isInvited: json['is_invited'] as bool? ?? true,
    isInTimeWindow: json['is_in_time_window'] as bool? ?? true,
    isInLocation: json['is_in_location'] as bool? ?? true,
    voteStartTime: json['vote_start_time'] != null ? DateTime.parse(json['vote_start_time']) : null,
    voteEndTime: json['vote_end_time'] != null ? DateTime.parse(json['vote_end_time']) : null,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    allowedRadiusMeters: json['allowed_radius_meters'] as int?,
  );

  VotingPermission get permission {
    if (licenseType == 'open') return VotingPermission.allowed;
    if (licenseType == 'invite_only') return isInvited ? VotingPermission.allowed : VotingPermission.notInvited;
    if (licenseType == 'location_time') {
      if (!isInvited) return VotingPermission.notInvited;
      if (!isInTimeWindow) return VotingPermission.outsideTimeWindow;
      if (!isInLocation) return VotingPermission.outsideLocation;
      return VotingPermission.allowed;
    }
    return VotingPermission.noPermission;
  }

  String get restrictionMessage {
    switch (permission) {
      case VotingPermission.allowed:
        return 'You can vote on this playlist';
      case VotingPermission.notInvited:
        return 'You need to be invited to vote on this playlist';
      case VotingPermission.outsideTimeWindow:
        return 'Voting is only allowed during specific hours';
      case VotingPermission.outsideLocation:
        return 'You need to be in the allowed location to vote';
      case VotingPermission.noPermission:
        return 'Voting is not permitted';
    }
  }
}

class PlaylistVotingInfo {
  final String playlistId;
  final VotingRestrictions restrictions;
  final Map<String, VoteStats> trackVotes;

  const PlaylistVotingInfo({
    required this.playlistId,
    required this.restrictions,
    required this.trackVotes,
  });

  factory PlaylistVotingInfo.fromJson(Map<String, dynamic> json) => PlaylistVotingInfo(
    playlistId: json['playlist_id'].toString(),
    restrictions: VotingRestrictions.fromJson(json['restrictions'] as Map<String, dynamic>),
    trackVotes: (json['track_votes'] as Map<String, dynamic>?)?.map(
      (key, value) => MapEntry(key, VoteStats.fromJson(value as Map<String, dynamic>))
    ) ?? {},
  );

  VoteStats? getTrackVotes(String trackId) => trackVotes[trackId];

  bool get canVote => restrictions.permission == VotingPermission.allowed;
}
