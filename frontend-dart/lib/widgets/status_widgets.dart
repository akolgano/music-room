import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_providers.dart';

class ConnectionStatusBanner extends StatelessWidget {
  final Widget child;
  const ConnectionStatusBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Consumer<ConnectivityProvider>(
    builder: (context, connectivity, _) => Column(children: [
      if (connectivity.isDisconnected)
        Container(
          width: double.infinity,
          color: Colors.red.shade700,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(children: [
            const Icon(Icons.wifi_off, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            const Expanded(child: Text('No connection to server', style: TextStyle(color: Colors.white, fontSize: 14))),
            TextButton(
              onPressed: () => connectivity.checkConnection(),
              child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
      Expanded(child: child),
    ]),
  );
}

class ConnectionStatusIndicator extends StatelessWidget {
  final bool showText, compact;
  const ConnectionStatusIndicator({super.key, this.showText = true, this.compact = false});

  @override
  Widget build(BuildContext context) => Consumer<ConnectivityProvider>(
    builder: (context, connectivity, _) {
      final (color, icon) = switch (connectivity.connectionStatus) {
        ConnectionStatus.connected => (Colors.green, Icons.wifi),
        ConnectionStatus.disconnected => (Colors.red, Icons.wifi_off),
        ConnectionStatus.checking => (Colors.orange, Icons.wifi_find),
      };
      if (compact) return Icon(icon, color: color, size: 20);

      return GestureDetector(
        onTap: () => showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Connection Status'),
            content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(connectivity.detailedStatusText, style: Theme.of(context).textTheme.bodyMedium)),
              ]),
              const SizedBox(height: 16),
              if (connectivity.isDisconnected)
                const Text('Some features may not work while offline. Changes will be saved locally when possible.', 
                  style: TextStyle(color: Colors.orange)),
            ]),
            actions: [
              if (connectivity.isDisconnected)
                TextButton(
                  onPressed: () { connectivity.checkConnection(); Navigator.of(context).pop(); },
                  child: const Text('Retry Connection'),
                ),
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
            ],
          ),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: showText ? 12 : 8, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 16),
            if (showText) ...[
              const SizedBox(width: 6),
              Text(connectivity.connectionStatusText, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ]),
        ),
      );
    },
  );
}
