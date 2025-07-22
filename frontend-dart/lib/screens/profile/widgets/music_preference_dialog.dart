import 'package:flutter/material.dart';
import '../../../core/theme_utils.dart';

class MusicPreferenceDialog extends StatefulWidget {
  final List<Map<String, dynamic>> availablePreferences;
  final List<int> selectedIds;

  const MusicPreferenceDialog({
    super.key,
    required this.availablePreferences, 
    required this.selectedIds
  });

  @override
  State<MusicPreferenceDialog> createState() => _MusicPreferenceDialogState();
}

class _MusicPreferenceDialogState extends State<MusicPreferenceDialog> {
  late List<int> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: const Text('Select Music Preferences', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.availablePreferences.length,
          itemBuilder: (context, index) {
            final preference = widget.availablePreferences[index];
            final id = preference['id'] as int;
            final name = preference['name'] as String;
            final isSelected = _selectedIds.contains(id);

            return CheckboxListTile(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedIds.add(id);
                  } else {
                    _selectedIds.remove(id);
                  }
                });
              },
              title: Text(name, style: const TextStyle(color: Colors.white)),
              activeColor: AppTheme.primary,
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: const Text('Cancel', style: TextStyle(color: Colors.grey))
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedIds),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary, 
            foregroundColor: Colors.black
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}