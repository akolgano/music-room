import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/animations_core.dart';

class StateWidgets {
  static double _responsiveWidth(double value) => value.w;
  static double _responsiveHeight(double value) => value.h;
  
  static TextStyle _secondaryStyle(BuildContext context) => 
      Theme.of(context).textTheme.bodyMedium!.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)
      );
  
  static Widget _buildWithTheme(Widget Function(BuildContext context, ThemeData theme, ColorScheme colorScheme) builder) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        return builder(context, theme, colorScheme);
      },
    );
  }

  static Widget loading([String? message]) {
    return _buildWithTheme((context, theme, colorScheme) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            if (message != null) ...[
              SizedBox(height: _responsiveHeight(12.0)), 
              Text(message, style: _secondaryStyle(context))
            ],
          ],
        ),
      );
    });
  }

  static Widget emptyState({
    required IconData icon,
    required String title,
    String? subtitle,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) {
    return Builder(builder: (context) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final hasFiniteHeight = constraints.maxHeight.isFinite;
          final isConstrained = hasFiniteHeight && constraints.maxHeight < 200;
          final iconSize = (isConstrained ? 24.0 : 64.0).sp;
          final titleSize = (isConstrained ? 12.0 : 18.0).sp;
          final spacing = _responsiveHeight(isConstrained ? 4.0 : 12.0);
          final padding = _responsiveWidth(isConstrained ? 8.0 : 32.0);
          
          Widget content = Padding(
            padding: EdgeInsets.all(padding),
            child: EmptyStateContentWidget(
              icon: icon,
              title: title,
              subtitle: subtitle,
              buttonText: buttonText,
              onButtonPressed: onButtonPressed,
              isConstrained: isConstrained,
              iconSize: iconSize,
              titleSize: titleSize,
              spacing: spacing,
            ),
          );
          
          if (!hasFiniteHeight) {
            return Center(child: content);
          } else if (constraints.maxHeight > 0) {
            return SizedBox(
              height: constraints.maxHeight,
              child: isConstrained
                  ? SingleChildScrollView(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(child: content),
                        ),
                      ),
                    )
                  : Center(child: content),
            );
          } else {
            return SizedBox(height: 150, child: Center(child: content));
          }
        },
      );
    });
  }

  static Widget errorState({required String message, VoidCallback? onRetry, String? retryText}) {
    return _buildWithTheme((context, theme, colorScheme) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(_responsiveWidth(32.0)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64.0.sp, color: colorScheme.error),
              SizedBox(height: _responsiveHeight(12.0)),
              Text(
                message,
                style: TextStyle(color: colorScheme.onSurface, fontSize: 18.0.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                SizedBox(height: _responsiveHeight(16.0)),
                ElevatedButton(
                  onPressed: onRetry,
                  child: Text(retryText ?? 'Retry'),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  static Widget buildErrorScreen(String message) {
    return Builder(
      builder: (context) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: const Text('Error'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyStateContentWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final bool isConstrained;
  final double iconSize;
  final double titleSize;
  final double spacing;

  const EmptyStateContentWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.buttonText,
    this.onButtonPressed,
    required this.isConstrained,
    required this.iconSize,
    required this.titleSize,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
        SizedBox(height: spacing),
        Text(
          title,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          SizedBox(height: spacing / 2),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: titleSize * 0.8,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
        if (buttonText != null && onButtonPressed != null) ...[
          SizedBox(height: spacing * 1.5),
          if (!isConstrained)
            ElevatedButton(
              onPressed: onButtonPressed,
              child: Text(buttonText!, style: TextStyle(fontSize: titleSize * 0.9)),
            )
          else
            TextButton(
              onPressed: onButtonPressed,
              child: Text(buttonText!, style: TextStyle(fontSize: titleSize * 0.8)),
            ),
        ],
      ],
    );
  }
}

class NetworkConnectivityWidget extends StatefulWidget {
  final Widget child;
  
  const NetworkConnectivityWidget({super.key, required this.child});

  @override
  State<NetworkConnectivityWidget> createState() => _NetworkConnectivityWidgetState();
}

class _NetworkConnectivityWidgetState extends State<NetworkConnectivityWidget> with TickerProviderStateMixin, PulsingColorMixin {
  bool _isConnected = true;
  bool _showBanner = false;

  @override
  void initState() {
    super.initState();
    initializePulsingController();
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    if (mounted) {
      _onConnectivityChanged(results);
    }
    Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    _isConnected = results.isNotEmpty && !results.contains(ConnectivityResult.none);
    
    if (mounted) {
      setState(() {
        if (!_isConnected) {
          _showBanner = true;
        } else if (wasConnected != _isConnected) {
          _showBanner = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [if (_showBanner) _buildConnectivityBanner(), Expanded(child: widget.child)],
    );
  }

  Widget _buildConnectivityBanner() {
    if (_isConnected) {
      return AnimatedBuilder(
        animation: pulsingColorAnimation,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(4),
            color: pulsingColorAnimation.value ?? Colors.green,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Back online',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _showBanner = false),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ],
            ),
          );
        },
      );
    } else {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(4),
        color: Colors.red,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              'No internet connection',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}