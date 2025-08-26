import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme_core.dart';
import '../../widgets/app_widgets.dart';
import '../../providers/beacon_providers.dart';
import '../../services/beacon_services.dart';
import '../base_screens.dart';

class BeaconAdminScreen extends StatefulWidget {
  const BeaconAdminScreen({super.key});

  @override
  State<BeaconAdminScreen> createState() => _BeaconAdminScreenState();
}

class _BeaconAdminScreenState extends BaseScreen<BeaconAdminScreen> {
  late BeaconProvider _beaconProvider;
  final _playlistIdController = TextEditingController();

  @override
  String get screenTitle => 'Beacon Management';

  @override
  List<Widget> get actions => [
    IconButton(
      icon: Icon(_beaconProvider.isScanning ? Icons.pause : Icons.play_arrow),
      onPressed: _toggleScanning,
      tooltip: _beaconProvider.isScanning ? 'Stop Scanning' : 'Start Scanning',
    ),
    IconButton(
      icon: const Icon(Icons.refresh),
      onPressed: _refreshBeacons,
      tooltip: 'Refresh',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _beaconProvider = Provider.of<BeaconProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeBeacons());
  }

  Future<void> _initializeBeacons() async => await _beaconProvider.initializeBeacons();

  Future<void> _toggleScanning() async => _beaconProvider.isScanning 
      ? await _beaconProvider.stopScanning() 
      : await _beaconProvider.startScanning();

  Future<void> _refreshBeacons() async {
    if (_beaconProvider.isScanning) {
      await _beaconProvider.stopScanning();
      await Future.delayed(const Duration(milliseconds: 500));
      await _beaconProvider.startScanning();
    }
  }

  Future<void> _startPlaylistMonitoring() async {
    final playlistId = _playlistIdController.text.trim();
    if (playlistId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a playlist ID')),
      );
      return;
    }

    await _beaconProvider.startMonitoringPlaylistRegion(playlistId);
  }

  @override
  Widget buildContent() {
    return Consumer<BeaconProvider>(
      builder: (context, beaconProvider, child) {
        _beaconProvider = beaconProvider;
        if (beaconProvider.isLoading) {
          return buildLoadingState(message: 'Initializing beacons...');
        }
        if (beaconProvider.hasError) {
          return buildErrorState(
              message: beaconProvider.errorMessage ?? 'Unknown error occurred',
              onRetry: _initializeBeacons);
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_buildStatusCard(beaconProvider), const SizedBox(height: 16),
              _buildPlaylistMonitoringCard(beaconProvider), const SizedBox(height: 16),
              _buildDiscoveredBeaconsCard(beaconProvider)],
          ));
      });
  }

  Widget _buildStatusCard(BeaconProvider beaconProvider) {
    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  beaconProvider.isScanning ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
                  color: beaconProvider.isScanning ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Beacon Status',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatusRow('Initialized', beaconProvider.isInitialized ? 'Yes' : 'No'),
            _buildStatusRow('Scanning', beaconProvider.isScanning ? 'Active' : 'Stopped'),
            _buildStatusRow('Discovered Beacons', '${beaconProvider.discoveredBeacons.length}'),
            _buildStatusRow('Nearby Beacons', '${beaconProvider.nearbyBeacons.length}'),
            if (beaconProvider.nearestBeacon != null)
              _buildStatusRow(
                'Nearest Beacon', 
                '${beaconProvider.nearestBeacon!.distance.toStringAsFixed(1)}m away'
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );

  Widget _buildPlaylistMonitoringCard(BeaconProvider beaconProvider) {
    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Playlist Region Monitoring',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            AppWidgets.textField(
              context: context,
              controller: _playlistIdController,
              labelText: 'Playlist ID',
              hintText: 'Enter playlist ID to monitor',
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter this field' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppWidgets.primaryButton(
                    context: context,
                    text: 'Start Monitoring',
                    onPressed: beaconProvider.isLoading ? null : _startPlaylistMonitoring,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppWidgets.secondaryButton(
                    context: context,
                    text: 'Stop Monitoring',
                    onPressed: beaconProvider.isLoading ? null : () => beaconProvider.stopMonitoring(),
                  ),
                ),
              ],
            ),
            if (beaconProvider.selectedPlaylistId != null) ...[
              const SizedBox(height: 8),
              Text(
                'Currently monitoring: ${beaconProvider.selectedPlaylistId}',
                style: const TextStyle(color: Colors.green, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveredBeaconsCard(BeaconProvider beaconProvider) {
    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Discovered Beacons',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (beaconProvider.discoveredBeacons.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text('No beacons discovered\nStart scanning to find nearby beacons',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                ))
            else
              ...beaconProvider.discoveredBeacons.map(_buildBeaconTile),
          ],
        ),
      ),
    );
  }

  Widget _buildBeaconTile(BeaconInfo beacon) {
    final statusColor = beacon.isImmediate ? Colors.green
        : beacon.isNear ? Colors.orange
        : beacon.isFar ? Colors.red : Colors.grey;
    final statusIcon = beacon.isImmediate ? Icons.near_me
        : beacon.isNear ? Icons.location_on
        : beacon.isFar ? Icons.location_searching : Icons.bluetooth;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(
          'Major: ${beacon.major}, Minor: ${beacon.minor}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'UUID: ${beacon.uuid}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text('Distance: ${beacon.distance.toStringAsFixed(1)}m  |  RSSI: ${beacon.rssi} dBm',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        trailing: Chip(
          label: Text(
            beacon.proximity.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          backgroundColor: statusColor.withValues(alpha: 0.2),
          side: BorderSide(color: statusColor, width: 1),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _playlistIdController.dispose();
    super.dispose();
  }
}