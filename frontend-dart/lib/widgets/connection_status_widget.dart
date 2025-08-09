import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';
import '../core/theme_utils.dart';

class ConnectionStatusBanner extends StatelessWidget {
  final Widget child;

  const ConnectionStatusBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, _) {
        return Column(
          children: [
            if (connectivity.isDisconnected)
              Container(
                width: double.infinity,
                color: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No connection to server',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    TextButton(
                      onPressed: () => connectivity.forceCheck(),
                      child: const Text(
                        'Retry',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}

class ConnectionStatusIndicator extends StatelessWidget {
  final bool showText;
  final bool compact;

  const ConnectionStatusIndicator({
    super.key,
    this.showText = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, _) {
        late Color color;
        late IconData icon;

        switch (connectivity.connectionStatus) {
          case ConnectionStatus.connected:
            color = Colors.green;
            icon = Icons.wifi;
            break;
          case ConnectionStatus.disconnected:
            color = Colors.red;
            icon = Icons.wifi_off;
            break;
          case ConnectionStatus.checking:
            color = Colors.orange;
            icon = Icons.wifi_find;
            break;
        }

        if (compact) {
          return Icon(
            icon,
            color: color,
            size: 20,
          );
        }

        return GestureDetector(
          onTap: () => _showConnectionDialog(context, connectivity),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: showText ? 12 : 8,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 16),
                if (showText) ...[
                  const SizedBox(width: 6),
                  Text(
                    connectivity.connectionStatusText,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showConnectionDialog(BuildContext context, ConnectivityProvider connectivity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ConnectionStatusIndicator(showText: false, compact: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    connectivity.detailedStatusText,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (connectivity.isDisconnected)
              const Text(
                'Some features may not work while offline. Changes will be saved locally when possible.',
                style: TextStyle(color: Colors.orange),
              ),
          ],
        ),
        actions: [
          if (connectivity.isDisconnected)
            TextButton(
              onPressed: () {
                connectivity.forceCheck();
                Navigator.of(context).pop();
              },
              child: const Text('Retry Connection'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class ConnectionStatusCard extends StatelessWidget {
  const ConnectionStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, _) {
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ConnectionStatusIndicator(showText: false, compact: true),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Server Connection',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  connectivity.detailedStatusText,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (connectivity.isDisconnected) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => connectivity.forceCheck(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Connection'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}