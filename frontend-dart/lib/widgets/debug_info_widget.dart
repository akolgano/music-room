// lib/widgets/debug_info_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/api_debug_helper.dart';

class DebugInfoWidget extends StatelessWidget {
  final String? errorMessage;
  final String? errorDetails;
  final VoidCallback? onRetry;

  const DebugInfoWidget({
    Key? key,
    this.errorMessage,
    this.errorDetails,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!ApiDebugHelper.debugMode) {
      return _buildSimpleError(context);
    }

    return _buildDebugError(context);
  }

  Widget _buildSimpleError(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  errorMessage ?? 'An error occurred',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDebugError(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Card(
            color: Colors.red.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bug_report, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'DEBUG MODE - API Error',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage ?? 'An unknown error occurred',
                    style: TextStyle(color: Colors.red[600]),
                  ),
                ],
              ),
            ),
          ),
          
          if (errorDetails != null && errorDetails!.isNotEmpty)
            Card(
              child: ExpansionTile(
                title: const Text('Debug Details'),
                leading: const Icon(Icons.info_outline),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: SelectableText(
                            errorDetails!,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _copyToClipboard(context),
                                icon: const Icon(Icons.copy, size: 16),
                                label: const Text('Copy Details'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showFullDebugDialog(context),
                                icon: const Icon(Icons.fullscreen, size: 16),
                                label: const Text('Full View'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[600],
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (onRetry != null) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry Request'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _toggleDebugMode(context),
                      icon: Icon(ApiDebugHelper.debugMode ? Icons.visibility_off : Icons.visibility),
                      label: Text(ApiDebugHelper.debugMode ? 'Hide Debug' : 'Show Debug'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    if (errorDetails != null) {
      Clipboard.setData(ClipboardData(text: errorDetails!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debug details copied to clipboard'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showFullDebugDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bug_report, color: Colors.red),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Full Debug Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    errorDetails ?? 'No debug details available',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _copyToClipboard(context),
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy All'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleDebugMode(BuildContext context) {
    ApiDebugHelper.debugMode = !ApiDebugHelper.debugMode;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ApiDebugHelper.debugMode 
            ? 'Debug mode enabled - detailed logging active'
            : 'Debug mode disabled - basic error messages only'
        ),
        backgroundColor: ApiDebugHelper.debugMode ? Colors.green : Colors.orange,
      ),
    );
  }
}

extension DebugInfoExtension on Widget {
  Widget withDebugInfo({
    String? errorMessage,
    String? errorDetails,
    VoidCallback? onRetry,
  }) {
    if (errorMessage != null) {
      return Column(
        children: [
          DebugInfoWidget(
            errorMessage: errorMessage,
            errorDetails: errorDetails,
            onRetry: onRetry,
          ),
          Expanded(child: this),
        ],
      );
    }
    return this;
  }
}
