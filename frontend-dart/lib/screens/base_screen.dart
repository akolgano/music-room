// lib/screens/base_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/music_provider.dart';

abstract class BaseScreen<T extends StatefulWidget> extends State<T> {
  bool isLoading = false;
  String? errorMessage;

  AuthProvider get auth => Provider.of<AuthProvider>(context, listen: false);
  MusicProvider get music => Provider.of<MusicProvider>(context, listen: false);

  String get screenTitle;
  Widget buildBody();
  
  PreferredSizeWidget? buildAppBar() => AppBar(
    title: Text(screenTitle),
    backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: isLoading ? const Center(child: CircularProgressIndicator()) : buildBody(),
    );
  }

  Future<void> runAsync(Future<void> Function() operation) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await operation();
    } catch (error) {
      setState(() {
        errorMessage = error.toString();
      });
      showError(error.toString());
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
