// lib/widgets/base_form_widget.dart
import 'package:flutter/material.dart';
import '../core/app_core.dart';

class BaseFormWidget extends StatefulWidget {
  final String title;
  final List<Widget> children;
  final VoidCallback? onSubmit;
  final bool isLoading;
  final String? errorMessage;
  final String submitButtonText;

  const BaseFormWidget({
    Key? key,
    required this.title,
    required this.children,
    this.onSubmit,
    this.isLoading = false,
    this.errorMessage,
    this.submitButtonText = 'Save',
  }) : super(key: key);

  @override
  State<BaseFormWidget> createState() => _BaseFormWidgetState();
}

class _BaseFormWidgetState extends State<BaseFormWidget> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: AppTheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                
                if (widget.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                ...widget.children,
                
                const SizedBox(height: 24),
                
                widget.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : ElevatedButton(
                      onPressed: widget.onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text(widget.submitButtonText),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
