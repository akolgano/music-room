// widgets/api_error_widget.dart
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isRetrying ? Icons.refresh : Icons.cloud_off,
              size: 64,
              color: isRetrying ? Colors.blue : Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              isRetrying ? 'Retrying Connection...' : 'Connection Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            SizedBox(height: 24),
            if (!isRetrying)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh),
                label: Text('Retry'),
              )
            else
              CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
