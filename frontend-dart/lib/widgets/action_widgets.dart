import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/theme_core.dart';

class TrackActionsWidget extends StatelessWidget {
  final bool showAddButton;
  final bool showPlayButton;
  final VoidCallback? onAdd;
  final VoidCallback? onPlay;
  final VoidCallback? onRemove;
  final bool trackIsPlaying;
  final bool isInPlaylist;

  const TrackActionsWidget({
    super.key,
    required this.showAddButton,
    required this.showPlayButton,
    this.onAdd,
    this.onPlay,
    this.onRemove,
    required this.trackIsPlaying,
    required this.isInPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final actions = <Widget>[];
    
    if (showPlayButton && onPlay != null) {
      actions.add(_buildStyledIconButton(
        trackIsPlaying ? Icons.pause : Icons.play_arrow, 
        colorScheme.primary, 
        20.0, 
        onPlay!
      ));
    }
    
    if (showAddButton && onAdd != null && !isInPlaylist) {
      actions.add(_buildStyledIconButton(
        Icons.add_circle_outline, 
        colorScheme.onSurface, 
        18.0, 
        onAdd!, 
        tooltip: 'Add to Playlist'
      ));
    }
    
    if (isInPlaylist) {
      actions.add(Padding(
        padding: EdgeInsets.all(_responsive(4.0, type: 'w')),
        child: Icon(
          Icons.check_circle, 
          color: Colors.green, 
          size: _responsive(18.0) 
        ),
      ));
    }
    
    if (onRemove != null) {
      actions.add(_buildStyledIconButton(
        Icons.remove_circle_outline, 
        colorScheme.error, 
        18.0, 
        onRemove!
      ));
    }
    
    if (actions.isEmpty) return const SizedBox.shrink();
    final displayedActions = actions.take(2).toList();
    return Row(mainAxisSize: MainAxisSize.min, children: displayedActions);
  }

  static IconButton _buildStyledIconButton(
    IconData icon,
    Color color,
    double size,
    VoidCallback onPressed, {
    String? tooltip,
  }) => IconButton(
    icon: Icon(icon, color: color, size: _responsive(size)),
    onPressed: onPressed,
    tooltip: tooltip,
    padding: EdgeInsets.all(_responsive(4.0, type: 'w')),
    constraints: const BoxConstraints(minWidth: 32, minHeight: 32, maxWidth: 40),
  );

  static double _responsive(double value, {String type = 'sp'}) {
    if (kIsWeb) return value;
    switch (type) {
      case 'w': return value.w.toDouble();
      case 'h': return value.h.toDouble();
      case 'sp': default: return value.sp.toDouble();
    }
  }
}

class AnimatedActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool mini;
  
  const AnimatedActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.mini = false,
  });
  
  @override
  State<AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<AnimatedActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FloatingActionButton(
        onPressed: () {
          _controller.forward().then((_) {
            _controller.reverse();
            widget.onPressed();
          });
        },
        backgroundColor: widget.backgroundColor ?? AppTheme.primary,
        foregroundColor: widget.foregroundColor ?? Colors.white,
        mini: widget.mini,
        tooltip: widget.tooltip,
        child: Icon(widget.icon),
      ),
    );
  }
}

class SpeedDialActionButton extends StatefulWidget {
  final List<SpeedDialOption> options;
  final IconData openIcon;
  final IconData closeIcon;
  final Color? backgroundColor;
  
  const SpeedDialActionButton({
    super.key,
    required this.options,
    this.openIcon = Icons.add,
    this.closeIcon = Icons.close,
    this.backgroundColor,
  });
  
  @override
  State<SpeedDialActionButton> createState() => _SpeedDialActionButtonState();
}

class _SpeedDialActionButtonState extends State<SpeedDialActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isOpen = false;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ...widget.options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          
          return ScaleTransition(
            scale: CurvedAnimation(
              parent: _expandAnimation,
              curve: Interval(
                0.0,
                1.0 - index * 0.1,
                curve: Curves.easeOut,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (option.label != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(4.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4.0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        option.label!,
                        style: ThemeUtils.getCaptionStyle(context),
                      ),
                    ),
                  const SizedBox(width: 8.0),
                  FloatingActionButton(
                    mini: true,
                    backgroundColor: option.backgroundColor ?? AppTheme.primary,
                    foregroundColor: option.foregroundColor ?? Colors.white,
                    onPressed: () {
                      _toggle();
                      option.onTap();
                    },
                    child: Icon(option.icon),
                  ),
                ],
              ),
            ),
          );
        }),
        FloatingActionButton(
          backgroundColor: widget.backgroundColor ?? AppTheme.primary,
          onPressed: _toggle,
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _expandAnimation,
          ),
        ),
      ],
    );
  }
}

class SpeedDialOption {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? foregroundColor;
  
  const SpeedDialOption({
    required this.icon,
    this.label,
    required this.onTap,
    this.backgroundColor,
    this.foregroundColor,
  });
}

class ActionMenuWidget extends StatelessWidget {
  final List<ActionMenuItem> items;
  final IconData icon;
  final String? tooltip;
  
  const ActionMenuWidget({
    super.key,
    required this.items,
    this.icon = Icons.more_vert,
    this.tooltip,
  });
  
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(icon),
      tooltip: tooltip ?? 'More options',
      onSelected: (value) {
        final item = items.firstWhere((item) => item.value == value);
        item.onTap();
      },
      itemBuilder: (context) => items.map((item) {
        return PopupMenuItem<String>(
          value: item.value,
          enabled: item.enabled,
          child: Row(
            children: [
              if (item.icon != null) ...[
                Icon(
                  item.icon,
                  size: 20.0,
                  color: item.enabled
                      ? (item.isDestructive ? Colors.red : null)
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(width: 12.0),
              ],
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: item.enabled
                        ? (item.isDestructive ? Colors.red : null)
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class ActionMenuItem {
  final String value;
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool enabled;
  final bool isDestructive;
  
  const ActionMenuItem({
    required this.value,
    required this.label,
    this.icon,
    required this.onTap,
    this.enabled = true,
    this.isDestructive = false,
  });
}

class SwipeActionWidget extends StatelessWidget {
  final Widget child;
  final List<SwipeAction> leftActions;
  final List<SwipeAction> rightActions;
  final double actionWidth;
  
  const SwipeActionWidget({
    super.key,
    required this.child,
    this.leftActions = const [],
    this.rightActions = const [],
    this.actionWidth = 80.0,
  });
  
  @override
  Widget build(BuildContext context) {
    if (leftActions.isEmpty && rightActions.isEmpty) {
      return child;
    }
    
    return Dismissible(
      key: UniqueKey(),
      background: _buildBackground(context, leftActions, true),
      secondaryBackground: _buildBackground(context, rightActions, false),
      confirmDismiss: (direction) async {
        final actions = direction == DismissDirection.startToEnd
            ? leftActions
            : rightActions;
        
        if (actions.isNotEmpty) {
          final action = actions.first;
          action.onTap();
          return action.autoDismiss;
        }
        
        return false;
      },
      child: child,
    );
  }
  
  Widget _buildBackground(
    BuildContext context,
    List<SwipeAction> actions,
    bool isLeft,
  ) {
    if (actions.isEmpty) {
      return Container();
    }
    
    final action = actions.first;
    
    return Container(
      color: action.backgroundColor ?? AppTheme.primary,
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: EdgeInsets.symmetric(horizontal: _responsive(20.0, type: 'w')),
      child: Icon(
        action.icon,
        color: action.foregroundColor ?? Colors.white,
        size: _responsive(24.0),
      ),
    );
  }
  
  static double _responsive(double value, {String type = 'sp'}) {
    if (kIsWeb) return value;
    switch (type) {
      case 'w':
        return value.w;
      case 'h':
        return value.h;
      case 'sp':
      default:
        return value.sp;
    }
  }
}

class SwipeAction {
  final IconData icon;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool autoDismiss;
  
  const SwipeAction({
    required this.icon,
    required this.onTap,
    this.backgroundColor,
    this.foregroundColor,
    this.autoDismiss = false,
  });
}