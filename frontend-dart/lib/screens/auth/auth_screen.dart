// lib/screens/auth/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../base_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends BaseScreen<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;

  @override
  String get screenTitle => 'Music Room';
  
  @override
  PreferredSizeWidget? buildAppBar() => null;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget buildBody() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black, AppTheme.background],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              children: [
                const Icon(Icons.music_note, size: 80, color: AppTheme.primary),
                const SizedBox(height: 20),
                const Text(
                  'Music Room',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
                ),
                const SizedBox(height: 40),
                _buildForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Card(
      color: AppTheme.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                _isLogin ? 'Sign In' : 'Create Account',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                style: const TextStyle(color: Colors.white),
                validator: (v) => v?.isEmpty ?? true ? 'Please enter username' : null,
              ),
              const SizedBox(height: 16),
              if (!_isLogin) ...[
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Please enter email';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v!)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                style: const TextStyle(color: Colors.white),
                obscureText: true,
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Please enter password';
                  if (v!.length < 8) return 'Password must be at least 8 characters';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: Text(_isLogin ? 'SIGN IN' : 'SIGN UP'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(_isLogin ? 'Create an account' : 'Already have an account? Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    await runAsync(() async {
      if (_isLogin) {
        await auth.login(_usernameController.text, _passwordController.text);
      } else {
        await auth.signup(_usernameController.text, _emailController.text, _passwordController.text);
      }
      showSuccess(_isLogin ? 'Login successful' : 'Account created successfully');
    });
  }
}
