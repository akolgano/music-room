import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme_core.dart';
import '../providers/beacon_providers.dart';
import '../services/beacon_services.dart';

class BeaconStatusWidget extends StatelessWidget {
  final bool compact;
  final VoidCallback? onTap;
  
  const BeaconStatusWidget({
    super.key,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Consumer<BeaconProvider>(
    builder: (context, beaconProvider, child) {
      if (!beaconProvider.isInitialized) return const SizedBox.shrink();
      final isScanning = beaconProvider.isScanning;
      final beaconCount = beaconProvider.discoveredBeacons.length;
      final nearbyCount = beaconProvider.nearbyBeacons.length;
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(compact ? 8 : 12),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isScanning ? Colors.blue.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.3)),
          ),
          child: compact ? _buildCompactContent(isScanning, nearbyCount) : _buildFullContent(isScanning, beaconCount, nearbyCount),
        ),
      );
    },
  );

  Widget _buildCompactContent(bool isScanning, int nearbyCount) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(isScanning ? Icons.bluetooth_searching : Icons.bluetooth_disabled, color: isScanning ? Colors.blue : Colors.grey, size: 16),
      if (nearbyCount > 0) ...[const SizedBox(width: 4), Text('$nearbyCount', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))],
    ],
  );

  Widget _buildFullContent(bool isScanning, int beaconCount, int nearbyCount) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(children: [
        Icon(isScanning ? Icons.bluetooth_searching : Icons.bluetooth_disabled, color: isScanning ? Colors.blue : Colors.grey, size: 20),
        const SizedBox(width: 8),
        Text('Beacon Status', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      ]),
      const SizedBox(height: 8),
      Text(isScanning ? 'Scanning Active' : 'Scanning Stopped', style: TextStyle(color: isScanning ? Colors.green : Colors.grey, fontSize: 12)),
      if (beaconCount > 0) Text('$beaconCount discovered, $nearbyCount nearby', style: const TextStyle(color: Colors.grey, fontSize: 12)),
    ],
  );
}

class BeaconProximityIndicator extends StatelessWidget {
  final BeaconInfo beacon;
  final double size;
  
  const BeaconProximityIndicator({
    super.key,
    required this.beacon,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final (color, icon) = beacon.isImmediate ? (Colors.green, Icons.near_me) : 
                          beacon.isNear ? (Colors.orange, Icons.location_on) : 
                          beacon.isFar ? (Colors.red, Icons.location_searching) : 
                          (Colors.grey, Icons.bluetooth);
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(color: color, width: 1),
      ),
      child: Icon(icon, color: color, size: size * 0.6),
    );
  }
}

class NearbyBeaconsCard extends StatelessWidget {
  final VoidCallback? onViewAll;
  
  const NearbyBeaconsCard({
    super.key,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) => Consumer<BeaconProvider>(
    builder: (context, beaconProvider, child) {
      final nearbyBeacons = beaconProvider.nearbyBeacons;
      if (nearbyBeacons.isEmpty) return const SizedBox.shrink();
      return Card(
          color: AppTheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    const Icon(Icons.bluetooth_searching, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text('Nearby Beacons (${nearbyBeacons.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ]),
                  if (onViewAll != null) TextButton(onPressed: onViewAll, child: const Text('View All', style: TextStyle(color: Colors.blue))),
                ]),
                const SizedBox(height: 12),
                ...nearbyBeacons.take(3).map((beacon) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      BeaconProximityIndicator(beacon: beacon, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Major: ${beacon.major}, Minor: ${beacon.minor}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                        Text('${beacon.distance.toStringAsFixed(1)}m • ${beacon.proximity}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ])),
                    ],
                  ),
                )),
                if (nearbyBeacons.length > 3) Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('+ ${nearbyBeacons.length - 3} more beacons', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

class BeaconConnectionDialog extends StatefulWidget {
  final String title;
  final String? playlistId;
  final VoidCallback? onConnect;
  
  const BeaconConnectionDialog({
    super.key,
    this.title = 'Connect to Beacon',
    this.playlistId,
    this.onConnect,
  });

  @override
  State<BeaconConnectionDialog> createState() => _BeaconConnectionDialogState();
}

class _BeaconConnectionDialogState extends State<BeaconConnectionDialog> {
  bool _isConnecting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: Text(widget.title, style: const TextStyle(color: Colors.white)),
      content: Consumer<BeaconProvider>(
        builder: (context, beaconProvider, child) {
          if (_isConnecting) {
            return const Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Connecting to beacon...', style: TextStyle(color: Colors.white)),
            ]);
          }

          final nearbyBeacons = beaconProvider.nearbyBeacons;
          if (nearbyBeacons.isEmpty) {
            return const Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.bluetooth_disabled, color: Colors.grey, size: 48),
              SizedBox(height: 16),
              Text('No beacons found nearby.\nMake sure Bluetooth is enabled and beacons are in range.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            ]);
          }

          return Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Select a beacon to connect:', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            ...nearbyBeacons.take(5).map((beacon) => _buildBeaconOption(beacon, beaconProvider)),
          ]);
        },
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel'))],
    );
  }

  Widget _buildBeaconOption(BeaconInfo beacon, BeaconProvider beaconProvider) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: BeaconProximityIndicator(beacon: beacon),
    title: Text('Major: ${beacon.major}, Minor: ${beacon.minor}', style: const TextStyle(color: Colors.white, fontSize: 14)),
    subtitle: Text('${beacon.distance.toStringAsFixed(1)}m • ${beacon.proximity}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
    onTap: () => _connectToBeacon(beacon, beaconProvider),
  );

  Future<void> _connectToBeacon(BeaconInfo beacon, BeaconProvider beaconProvider) async {
    setState(() => _isConnecting = true);
    try {
      widget.onConnect?.call();
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.of(context).pop(beacon);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to connect: ${e.toString()}')));
        setState(() => _isConnecting = false);
      }
    }
  }
}