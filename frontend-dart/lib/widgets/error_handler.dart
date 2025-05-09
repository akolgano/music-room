// lib/widgets/error_handler.dart
import 'package:flutter/material.dart';
import '../config/theme.dart';

class ErrorHandler extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool isRetrying;

  const ErrorHandler({
    Key? key,
    required this.message,
    required this.onRetry,
    this.isRetrying = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isRetrying ? Icons.refresh : Icons.cloud_off,
              size: 64,
              color: isRetrying ? AppTheme.primary : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isRetrying ? 'Retrying Connection...' : 'Connection Error',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            if (!isRetrying)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              )
            else
              const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
