// lib/test/google_signin_test.dart
import 'package:flutter/material.dart';
import '../core/core.dart';

class GoogleSignInTestScreen extends StatefulWidget {
  const GoogleSignInTestScreen({Key? key}) : super(key: key);

  @override
  State<GoogleSignInTestScreen> createState() => _GoogleSignInTestScreenState();
}

class _GoogleSignInTestScreenState extends State<GoogleSignInTestScreen> {
  bool _isLoading = false;
  String? _result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Sign-In Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _testGoogleSignIn,
              child: _isLoading 
                ? const CircularProgressIndicator()
                : const Text('Test Google Sign-In'),
            ),
            const SizedBox(height: 20),
            if (_result != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_result!),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _testGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      await SocialLoginUtils.initialize();
      final result = await SocialLoginUtils.loginWithGoogle();
      
      setState(() {
        _result = result.success 
          ? 'Success! Token: ${result.token?.substring(0, 50)}...'
          : 'Error: ${result.error}';
      });
    } catch (e) {
      setState(() {
        _result = 'Exception: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
