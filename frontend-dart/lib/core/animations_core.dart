import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_core.dart';

class AnimationSettingsProvider extends ChangeNotifier {
  bool _pulsingEnabled = true;
  Duration _pulsingDuration = const Duration(seconds: 2);
  double _pulsingIntensity = 1.0;

  bool get pulsingEnabled => _pulsingEnabled;
  Duration get pulsingDuration => _pulsingDuration;
  double get pulsingIntensity => _pulsingIntensity;

  void setPulsingEnabled(bool enabled) {
    if (_pulsingEnabled != enabled) {
      _pulsingEnabled = enabled;
      notifyListeners();
    }
  }

  void setPulsingDuration(Duration duration) {
    if (_pulsingDuration != duration) {
      _pulsingDuration = duration;
      notifyListeners();
    }
  }

  void setPulsingIntensity(double intensity) {
    if (_pulsingIntensity != intensity) {
      _pulsingIntensity = intensity.clamp(0.1, 3.0);
      notifyListeners();
    }
  }
}

class PulsingColorAnimation {
  static const Duration defaultDuration = Duration(seconds: 2);
  
  static Color lightGreen = const Color(0xFF2EF564);
  static Color mediumGreen = AppTheme.primary;
  static Color darkGreen = const Color(0xFF0F7A2E);

  static AnimationController createController({
    required TickerProvider vsync,
    Duration duration = defaultDuration,
  }) {
    return AnimationController(
      duration: duration,
      vsync: vsync,
    )..repeat(reverse: true);
  }

  static Animation<Color?> createColorAnimation(AnimationController controller) {
    return TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(begin: darkGreen, end: mediumGreen),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: mediumGreen, end: lightGreen),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: lightGreen, end: mediumGreen),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: mediumGreen, end: darkGreen),
        weight: 1.0,
      ),
    ]).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));
  }

}

mixin PulsingColorMixin<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  late AnimationController _pulsingController;
  late Animation<Color?> _pulsingColorAnimation;
  late Animation<double> _pulsingIntensityAnimation;
  bool _mixinControllerCreated = false;


  void initializePulsingController({Duration? duration}) {
    if (!_mixinControllerCreated) {
      _pulsingController = PulsingColorAnimation.createController(
        vsync: this, 
        duration: duration ?? PulsingColorAnimation.defaultDuration
      );
      _pulsingColorAnimation = PulsingColorAnimation.createColorAnimation(_pulsingController);
      _pulsingIntensityAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _pulsingController, curve: Curves.easeInOut),
      );
      _mixinControllerCreated = true;
    }
  }

  @override
  void dispose() {
    if (_mixinControllerCreated) {
      _pulsingController.dispose();
    }
    super.dispose();
  }

  Animation<Color?> get pulsingColorAnimation => _pulsingColorAnimation;
  Animation<double> get pulsingIntensityAnimation => _pulsingIntensityAnimation;
  AnimationController get pulsingController => _pulsingController;
}

class PulsingContainer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool enabled;

  const PulsingContainer({
    super.key,
    required this.child,
    this.duration = PulsingColorAnimation.defaultDuration,
    this.enabled = true,
  });

  @override
  State<PulsingContainer> createState() => _PulsingContainerState();
}

class _PulsingContainerState extends State<PulsingContainer>
    with TickerProviderStateMixin, PulsingColorMixin {
  
  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      initializePulsingController(duration: widget.duration);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnimationSettingsProvider>(
      builder: (context, animationSettings, child) {
        if (!widget.enabled || !animationSettings.pulsingEnabled) {
          return widget.child;
        }

        return AnimatedBuilder(
          animation: _pulsingColorAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: _pulsingColorAnimation.value?.withValues(alpha: 0.3 * animationSettings.pulsingIntensity) ?? Colors.transparent,
                    blurRadius: 8 * _pulsingIntensityAnimation.value * animationSettings.pulsingIntensity,
                    spreadRadius: 2 * _pulsingIntensityAnimation.value * animationSettings.pulsingIntensity,
                  ),
                ],
              ),
              child: widget.child,
            );
          },
        );
      },
    );
  }
}

class PulsingIcon extends StatefulWidget {
  final IconData icon;
  final double? size;
  final Duration duration;
  final bool enabled;

  const PulsingIcon({
    super.key,
    required this.icon,
    this.size,
    this.duration = PulsingColorAnimation.defaultDuration,
    this.enabled = true,
  });

  @override
  State<PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<PulsingIcon>
    with TickerProviderStateMixin, PulsingColorMixin {

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      initializePulsingController(duration: widget.duration);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return Icon(widget.icon, size: widget.size, color: AppTheme.primary);
    }

    return AnimatedBuilder(
      animation: _pulsingColorAnimation,
      builder: (context, child) {
        return Icon(
          widget.icon,
          size: widget.size,
          color: _pulsingColorAnimation.value ?? AppTheme.primary,
        );
      },
    );
  }
}

class PulsingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;
  final bool enabled;

  const PulsingText({
    super.key,
    required this.text,
    this.style,
    this.duration = PulsingColorAnimation.defaultDuration,
    this.enabled = true,
  });

  @override
  State<PulsingText> createState() => _PulsingTextState();
}

class _PulsingTextState extends State<PulsingText>
    with TickerProviderStateMixin, PulsingColorMixin {

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      initializePulsingController(duration: widget.duration);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return Text(
        widget.text,
        style: widget.style?.copyWith(color: AppTheme.primary) ?? 
               TextStyle(color: AppTheme.primary),
      );
    }

    return AnimatedBuilder(
      animation: _pulsingColorAnimation,
      builder: (context, child) {
        return Text(
          widget.text,
          style: widget.style?.copyWith(
            color: _pulsingColorAnimation.value ?? AppTheme.primary,
          ) ?? TextStyle(color: _pulsingColorAnimation.value ?? AppTheme.primary),
        );
      },
    );
  }
}

class PulsingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Duration duration;
  final bool enabled;

  const PulsingButton({
    super.key,
    required this.child,
    this.onPressed,
    this.duration = PulsingColorAnimation.defaultDuration,
    this.enabled = true,
  });

  @override
  State<PulsingButton> createState() => _PulsingButtonState();
}

class _PulsingButtonState extends State<PulsingButton>
    with TickerProviderStateMixin, PulsingColorMixin {

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      initializePulsingController(duration: widget.duration);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return ElevatedButton(
        onPressed: widget.onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
        child: widget.child,
      );
    }

    return AnimatedBuilder(
      animation: _pulsingColorAnimation,
      builder: (context, child) {
        return ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: _pulsingColorAnimation.value ?? AppTheme.primary,
            shadowColor: _pulsingColorAnimation.value?.withValues(alpha: 0.5),
            elevation: 4 + (2 * _pulsingIntensityAnimation.value),
          ),
          child: widget.child,
        );
      },
    );
  }
}