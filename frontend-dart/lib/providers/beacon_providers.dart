import 'dart:async';
import '../core/provider_core.dart';
import '../core/navigation_core.dart';
import '../core/locator_core.dart';
import '../services/beacon_services.dart';

class BeaconProvider extends BaseProvider {
  final BeaconService _beaconService = getIt<BeaconService>();
  
  List<BeaconInfo> _discoveredBeacons = [];
  BeaconInfo? _nearestBeacon;
  bool _isScanning = false;
  bool _isInitialized = false;
  String? _selectedPlaylistId;
  
  StreamSubscription? _beaconsSubscription;
  StreamSubscription? _beaconEnteredSubscription;
  StreamSubscription? _beaconExitedSubscription;
  StreamSubscription? _scanningStateSubscription;

  List<BeaconInfo> get discoveredBeacons => List.unmodifiable(_discoveredBeacons);
  BeaconInfo? get nearestBeacon => _nearestBeacon;
  bool get isScanning => _isScanning;
  bool get isInitialized => _isInitialized;
  String? get selectedPlaylistId => _selectedPlaylistId;
  
  List<BeaconInfo> get nearbyBeacons => _beaconService.getNearbyBeacons();
  List<BeaconInfo> get immediateBeacons => _beaconService.discoveredBeacons.where((beacon) => beacon.isImmediate).toList();

  Future<bool> initializeBeacons() async {
    if (_isInitialized) return true;
    
    return await executeBool(
      () async {
        final success = await _beaconService.initialize();
        if (success) {
          _setupSubscriptions();
          _isInitialized = true;
        } else {
          throw Exception('Failed to initialize beacon service');
        }
      },
      successMessage: 'Beacon service initialized',
    );
  }

  void _setupSubscriptions() {
    _beaconsSubscription = _beaconService.beaconsStream.listen(
      _handleBeaconsUpdate,
      onError: _handleStreamError,
    );

    _beaconEnteredSubscription = _beaconService.beaconEnteredStream.listen(
      _handleBeaconEntered,
      onError: _handleStreamError,
    );

    _beaconExitedSubscription = _beaconService.beaconExitedStream.listen(
      _handleBeaconExited,
      onError: _handleStreamError,
    );

    _scanningStateSubscription = _beaconService.scanningStateStream.listen(
      _handleScanningStateChange,
      onError: _handleStreamError,
    );
  }

  Future<bool> startScanning({List<BeaconRegionConfig>? regions}) async {
    if (!_isInitialized) {
      final initialized = await initializeBeacons();
      if (!initialized) return false;
    }

    return await executeBool(
      () async {
        final success = await _beaconService.startScanning(regions: regions);
        if (!success) {
          throw Exception('Failed to start beacon scanning');
        }
      },
      successMessage: 'Started scanning for beacons',
    );
  }

  Future<void> stopScanning() async {
    await _beaconService.stopScanning();
  }

  Future<bool> startMonitoringPlaylistRegion(String playlistId) async {
    _selectedPlaylistId = playlistId;
    
    final regions = [
      BeaconRegionConfig(
        identifier: 'playlist-$playlistId',
        uuid: 'E2C56DB5-DFFB-48D2-B060-D0F5A71096E0',
        major: int.tryParse(playlistId.replaceAll(RegExp(r'\D'), '').substring(0, 4)) ?? 1,
      ),
    ];

    return await executeBool(
      () async {
        final success = await _beaconService.startMonitoring(regions);
        if (!success) {
          throw Exception('Failed to start monitoring playlist region');
        }
      },
      successMessage: 'Started monitoring playlist region',
    );
  }

  Future<void> stopMonitoring() async {
    await _beaconService.stopMonitoring();
    _selectedPlaylistId = null;
  }

  void _handleBeaconsUpdate(List<BeaconInfo> beacons) {
    _discoveredBeacons = beacons;
    _updateNearestBeacon();
    notifyListeners();
  }

  void _handleBeaconEntered(BeaconInfo beacon) {
    AppLogger.info('Beacon entered range: ${beacon.identifier}', 'BeaconProvider');
    notifyListeners();
  }

  void _handleBeaconExited(BeaconInfo beacon) {
    AppLogger.info('Beacon exited range: ${beacon.identifier}', 'BeaconProvider');
    if (_nearestBeacon?.identifier == beacon.identifier) {
      _updateNearestBeacon();
    }
    notifyListeners();
  }

  void _handleScanningStateChange(bool scanning) {
    _isScanning = scanning;
    notifyListeners();
  }

  void _handleStreamError(dynamic error) {
    AppLogger.error('Beacon stream error: $error', null, null, 'BeaconProvider');
    setError('Beacon service error: ${error.toString()}');
  }

  void _updateNearestBeacon() {
    if (_discoveredBeacons.isEmpty) {
      _nearestBeacon = null;
      return;
    }

    final nearby = _discoveredBeacons
        .where((beacon) => beacon.isNearby)
        .toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));

    _nearestBeacon = nearby.isNotEmpty ? nearby.first : null;
  }

  BeaconInfo? getBeaconForPlaylist(String playlistId) {
    final expectedMajor = int.tryParse(playlistId.replaceAll(RegExp(r'\D'), '').substring(0, 4)) ?? 1;
    
    try {
      return _discoveredBeacons.firstWhere(
        (beacon) => beacon.major == expectedMajor,
      );
    } catch (e) {
      return null;
    }
  }

  bool isUserNearPlaylist(String playlistId) {
    final beacon = getBeaconForPlaylist(playlistId);
    return beacon != null && beacon.isNearby;
  }

  @override
  void dispose() {
    _beaconsSubscription?.cancel();
    _beaconEnteredSubscription?.cancel();
    _beaconExitedSubscription?.cancel();
    _scanningStateSubscription?.cancel();
    
    _beaconService.dispose();
    super.dispose();
  }
}
