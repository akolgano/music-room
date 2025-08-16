import 'package:flutter/material.dart';

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