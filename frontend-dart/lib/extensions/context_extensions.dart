// lib/extensions/context_extensions.dart
import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../providers/music_provider.dart';
import '../services/music_player_service.dart';
import 'package:provider/provider.dart';

extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  NavigatorState get navigator => Navigator.of(this);
  ScaffoldMessengerState get scaffoldMessenger => ScaffoldMessenger.of(this);
  
  AuthProvider get authProvider => Provider.of<AuthProvider>(this, listen: false);
  MusicProvider get musicProvider => Provider.of<MusicProvider>(this, listen: false);
  MusicPlayerService get playerService => Provider.of<MusicPlayerService>(this, listen: false);
  
  void showSnackBar({required String message, Color? backgroundColor}) {
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }
  
  void showErrorSnackBar(String message) {
    showSnackBar(message: message, backgroundColor: Colors.red);
  }
  
  void showSuccessSnackBar(String message) {
    showSnackBar(message: message, backgroundColor: Colors.green);
  }
}
