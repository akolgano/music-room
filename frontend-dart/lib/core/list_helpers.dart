// lib/core/list_helpers.dart
import 'package:flutter/material.dart';
import 'consolidated_core.dart';

class ListHelpers {
  static Widget buildRefreshableList<T>({
    required List<T> items,
    required Widget Function(T, int) itemBuilder,
    required Future<void> Function() onRefresh,
    Widget? emptyState,
    EdgeInsets? padding,
  }) {
    if (items.isEmpty && emptyState != null) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(height: 600, child: emptyState),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: padding ?? const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) => itemBuilder(items[index], index),
      ),
    );
  }

  static Widget buildTabContent({
    required List<Tab> tabs,
    required List<Widget> tabViews,
    TabController? controller,
  }) {
    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          TabBar(
            controller: controller,
            labelColor: AppTheme.primary,
            unselectedLabelColor: Colors.grey,
            tabs: tabs,
          ),
          Expanded(
            child: TabBarView(
              controller: controller,
              children: tabViews,
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildGridView<T>({
    required List<T> items,
    required Widget Function(T) itemBuilder,
    int crossAxisCount = 2,
    double mainAxisSpacing = 8,
    double crossAxisSpacing = 8,
    bool shrinkWrap = true,
  }) {
    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => itemBuilder(items[index]),
    );
  }
}
