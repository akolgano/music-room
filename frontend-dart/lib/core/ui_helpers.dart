// lib/core/ui_helpers.dart
import 'package:flutter/material.dart';
import '../core/consolidated_core.dart';

class UIHelpers {
  static PreferredSizeWidget buildAppBar({required String title, List<Widget>? actions, Widget? leading, bool automaticallyImplyLeading = true}) {
    return AppBar(
      backgroundColor: AppTheme.background,
      title: Text(title),
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
    );
  }
}
