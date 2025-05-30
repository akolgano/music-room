// lib/widgets/api_error_widget.dart
import 'package:flutter/material.dart';
import '../core/theme.dart';

class ApiErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final bool isRetrying;
  final String? context; 
  final ErrorType errorType;

  const ApiErrorWidget({
    Key? key,
    required this.message,
    this.onRetry,
    this.isRetrying = false,
    this.context,
    this.errorType = ErrorType.general,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final errorInfo = _getErrorInfo();
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: errorInfo.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: errorInfo.color.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      errorInfo.icon,
                      size: 48,
                      color: errorInfo.color,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            
            Text(
              errorInfo.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            Text(
              message,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            
            if (this.context != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  this.context!,
                  style: const TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 24),
            
            _buildSuggestions(errorInfo),
            const SizedBox(height: 24),
            
            if (onRetry != null) ...[
              if (isRetrying)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        errorInfo.retryingText,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(errorInfo.retryButtonText),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                    if (errorType == ErrorType.connection) ...[
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => _showConnectionHelp(context),
                        icon: const Icon(Icons.help_outline, size: 16),
                        label: const Text('Connection Help'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions(ErrorInfo errorInfo) {
    if (errorInfo.suggestions.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: errorInfo.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: errorInfo.color, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Try these solutions:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...errorInfo.suggestions.map((suggestion) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: errorInfo.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    suggestion,
                    style: const TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  ErrorInfo _getErrorInfo() {
    switch (errorType) {
      case ErrorType.connection:
        return ErrorInfo(
          icon: Icons.wifi_off,
          color: Colors.orange,
          title: 'Connection Problem',
          retryButtonText: 'Try Again',
          retryingText: 'Reconnecting...',
          suggestions: [
            'Check your internet connection',
            'Make sure you\'re connected to Wi-Fi or cellular data',
            'Try moving to an area with better signal',
            'Restart your Wi-Fi router if using Wi-Fi',
          ],
        );
      
      case ErrorType.server:
        return ErrorInfo(
          icon: Icons.cloud_off,
          color: Colors.red,
          title: 'Server Error',
          retryButtonText: 'Retry',
          retryingText: 'Contacting server...',
          suggestions: [
            'The Music Room servers might be temporarily down',
            'Wait a few minutes and try again',
            'Check if other internet services are working',
            'Contact support if the problem persists',
          ],
        );
      
      case ErrorType.authentication:
        return ErrorInfo(
          icon: Icons.lock_outline,
          color: Colors.amber,
          title: 'Login Required',
          retryButtonText: 'Sign In Again',
          retryingText: 'Signing in...',
          suggestions: [
            'Your session may have expired',
            'Sign out and sign back in',
            'Check your username and password',
            'Reset your password if you\'ve forgotten it',
          ],
        );
      
      case ErrorType.notFound:
        return ErrorInfo(
          icon: Icons.search_off,
          color: Colors.blue,
          title: 'Not Found',
          retryButtonText: 'Search Again',
          retryingText: 'Searching...',
          suggestions: [
            'Double-check the spelling',
            'Try different search terms',
            'Make sure the item still exists',
            'Contact the person who shared it with you',
          ],
        );
      
      case ErrorType.permission:
        return ErrorInfo(
          icon: Icons.block,
          color: Colors.purple,
          title: 'Access Denied',
          retryButtonText: 'Try Again',
          retryingText: 'Checking permissions...',
          suggestions: [
            'You might not have permission to access this',
            'Ask the owner to share it with you',
            'Make sure you\'re signed into the correct account',
            'Check if your account has the necessary privileges',
          ],
        );
      
      case ErrorType.general:
      default:
        return ErrorInfo(
          icon: Icons.error_outline,
          color: AppTheme.error,
          title: 'Something Went Wrong',
          retryButtonText: 'Try Again',
          retryingText: 'Retrying...',
          suggestions: [
            'Close and reopen the app',
            'Check your internet connection',
            'Wait a moment and try again',
            'Restart your device if the problem continues',
          ],
        );
    }
  }

  void _showConnectionHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Connection Help', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Troubleshooting Steps:',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._getConnectionSteps().map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_getConnectionSteps().indexOf(step) + 1}.',
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      step,
                      style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onRetry!();
              },
              child: const Text('Try Again'),
            ),
        ],
      ),
    );
  }

  List<String> _getConnectionSteps() {
    return [
      'Check if other apps can connect to the internet',
      'Toggle your Wi-Fi off and on, or switch between Wi-Fi and cellular data',
      'Move closer to your Wi-Fi router or to an area with better cell signal',
      'Restart the Music Room app completely',
      'If using Wi-Fi, try forgetting and reconnecting to your network',
      'Restart your device if nothing else works',
    ];
  }
}

enum ErrorType {
  general,
  connection,
  server,
  authentication,
  notFound,
  permission,
}

class ErrorInfo {
  final IconData icon;
  final Color color;
  final String title;
  final String retryButtonText;
  final String retryingText;
  final List<String> suggestions;

  ErrorInfo({
    required this.icon,
    required this.color,
    required this.title,
    required this.retryButtonText,
    required this.retryingText,
    required this.suggestions,
  });
}
