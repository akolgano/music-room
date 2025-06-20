// lib/widgets/network_connectivity_widget.dart
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/core.dart';

class NetworkConnectivityWidget extends StatefulWidget {
  final Widget child;
  
  const NetworkConnectivityWidget({Key? key, required this.child}) : super(key: key);

  @override
  State<NetworkConnectivityWidget> createState() => _NetworkConnectivityWidgetState();
}

class _NetworkConnectivityWidgetState extends State<NetworkConnectivityWidget> {
  bool _isConnected = true;
  bool _showBanner = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _onConnectivityChanged(results);
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    _isConnected = results.isNotEmpty && !results.contains(ConnectivityResult.none);
    
    if (mounted) {
      setState(() {
        if (!_isConnected) _showBanner = true;
        else if (wasConnected != _isConnected) _showBanner = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_showBanner) _buildConnectivityBanner(),
        Expanded(child: widget.child),
      ],
    );
  }

  Widget _buildConnectivityBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      color: _isConnected ? Colors.green : Colors.red,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_isConnected ? Icons.wifi : Icons.wifi_off, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            _isConnected ? 'Back online' : 'No internet connection',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          if (_isConnected) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _showBanner = false),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}
