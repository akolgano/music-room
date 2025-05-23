// lib/widgets/api_error_widget.dart
import 'package:flutter/material.dart';

class ApiErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool isRetrying;

  const ApiErrorWidget({
    Key? key,
    required this.message,
    required this.onRetry,
    this.isRetrying = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isRetrying ? Icons.refresh : Icons.cloud_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isRetrying ? 'Retrying...' : 'Connection Error',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            if (!isRetrying)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            if (isRetrying)
              const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
