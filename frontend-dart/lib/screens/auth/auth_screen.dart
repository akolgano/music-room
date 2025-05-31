// lib/screens/auth/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../widgets/widgets.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validation.dart';
import '../../utils/snackbar_utils.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override 
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              color: AppTheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildForm(),
                      const SizedBox(height: 24),
                      _buildSubmitButton(),
                      const SizedBox(height: 16),
                      _buildToggleButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.music_note, size: 32, color: Colors.black),
        ),
        const SizedBox(height: 16),
        Text(
          _isLogin ? 'Welcome Back' : 'Join Music Room',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        AppTextField(
          controller: _usernameController,
          labelText: 'Username',
          prefixIcon: Icons.person,
          validator: (v) => Validators.required(v, 'username'),
        ),
        if (!_isLogin) ...[
          const SizedBox(height: 16),
          AppTextField(
            controller: _emailController,
            labelText: 'Email',
            prefixIcon: Icons.email,
            validator: Validators.email,
          ),
        ],
        const SizedBox(height: 16),
        AppTextField(
          controller: _passwordController,
          labelText: 'Password',
          prefixIcon: Icons.lock,
          obscureText: !_isPasswordVisible,
          validator: Validators.password,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const LoadingWidget(message: 'Please wait...');
        }
        
        return ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: Text(_isLogin ? 'Sign In' : 'Sign Up'),
        );
      },
    );
  }

  Widget _buildToggleButton() {
    return TextButton(
      onPressed: () => setState(() => _isLogin = !_isLogin),
      child: Text(_isLogin ? 'Create an account' : 'Already have an account?'),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    bool success;
    
    if (_isLogin) {
      success = await auth.login(_usernameController.text, _passwordController.text);
    } else {
      success = await auth.signup(_usernameController.text, _emailController.text, _passwordController.text);
    }
    
    if (success) {
      SnackBarUtils.showSuccess(context, 'Welcome to Music Room!');
    } else if (auth.hasError) {
      SnackBarUtils.showError(context, auth.errorMessage!);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
