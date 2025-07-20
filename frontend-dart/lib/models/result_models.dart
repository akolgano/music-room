class BatchLibraryAddResult {
  final int totalTracks;
  final int successCount;
  final int failureCount;
  final List<String> errors;
  final List<String> successfulTracks;

  const BatchLibraryAddResult({required this.totalTracks, required this.successCount, required this.failureCount, this.errors = const [], this.successfulTracks = const []});

  bool get hasErrors => failureCount > 0;
  bool get hasPartialSuccess => successCount > 0 && failureCount > 0;
  bool get isCompleteSuccess => successCount == totalTracks && failureCount == 0;
  
  String get summaryMessage {
    if (isCompleteSuccess) { return 'All $totalTracks tracks added to your library successfully!'; }
    else if (hasPartialSuccess) { return '$successCount/$totalTracks tracks added to your library'; }
    else { return 'Failed to add tracks to your library'; }
  }

  String get detailedMessage {
    final parts = <String>[];
    if (successCount > 0) { parts.add('$successCount added'); }
    if (failureCount > 0) { parts.add('$failureCount failed'); }
    return parts.join(', ');
  }

  List<String> get successSample {
    return successfulTracks.take(3).toList();
  }

  List<String> get errorSample {
    return errors.take(3).toList();
  }
}

class SocialLoginResult {
  final bool success;
  final String? token;
  final String? provider;
  final String? error;

  const SocialLoginResult._({required this.success, this.token, this.provider, this.error});

  factory SocialLoginResult.success(String token, String provider) => 
      SocialLoginResult._(success: true, token: token, provider: provider);

  factory SocialLoginResult.error(String error) => 
      SocialLoginResult._(success: false, error: error);
}

class AddTrackResult {
  final bool success;
  final String message;
  final bool isDuplicate;

  const AddTrackResult({ required this.success, required this.message, this.isDuplicate = false });

  factory AddTrackResult.fromJson(Map<String, dynamic> json) => AddTrackResult(
    success: json['success'] as bool,
    message: json['message'] as String,
    isDuplicate: json['is_duplicate'] ?? false,
  );
}

class BatchAddResult {
  final int totalTracks;
  final int successCount;
  final int duplicateCount;
  final int failureCount;
  final List<String> errors;

  const BatchAddResult({
    required this.totalTracks,
    required this.successCount,
    required this.duplicateCount,
    required this.failureCount,
    this.errors = const [],
  });

  factory BatchAddResult.fromJson(Map<String, dynamic> json) => BatchAddResult(
    totalTracks: json['total_tracks'] as int,
    successCount: json['success_count'] as int,
    duplicateCount: json['duplicate_count'] as int,
    failureCount: json['failure_count'] as int,
    errors: (json['errors'] as List<dynamic>?)?.cast<String>() ?? [],
  );

  bool get hasErrors => failureCount > 0;
  bool get hasPartialSuccess => successCount > 0 && failureCount > 0;
  bool get isCompleteSuccess => successCount == totalTracks;
  
  String get summaryMessage {
    if (isCompleteSuccess) { return 'All $totalTracks tracks added successfully!'; }
    else if (hasPartialSuccess) { return '$successCount/$totalTracks tracks added successfully'; }
    else { return 'Failed to add tracks to playlist'; }
  }

  String get detailedMessage {
    final parts = <String>[];
    if (successCount > 0) { parts.add('$successCount added'); }
    if (duplicateCount > 0) { parts.add('$duplicateCount duplicates'); }
    if (failureCount > 0) { parts.add('$failureCount failed'); }
    return parts.join(', ');
  }
}