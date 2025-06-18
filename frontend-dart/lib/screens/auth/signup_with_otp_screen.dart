// lib/screens/auth/signup_with_otp_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/consolidated_core.dart';
import '../../core/form_helpers.dart';
import '../../widgets/app_widgets.dart';

class SignupWithOtpScreen extends StatefulWidget {
  const SignupWithOtpScreen({Key? key}) : super(key: key);

  @override
  State<SignupWithOtpScreen> createState() => _SignupWithOtpScreenState();
}

class _SignupWithOtpScreenState extends State<SignupWithOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _isLoading = false;
  bool _otpSent = false;
  bool _canResendOtp = true;
  int _resendCountdown = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _buildForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return AppTheme.buildFormCard(
      title: _otpSent ? 'Verify Email' : 'Create Account',
      titleIcon: _otpSent ? Icons.email : Icons.person_add,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (!_otpSent) ...[
              FormHelpers.buildTextFormField(
                controller: _emailController,
                labelText: 'Email',
                prefixIcon: Icons.email,
                validator: AppValidators.email,
              ),
              const SizedBox(height: 16),
              FormHelpers.buildTextFormField(
                controller: _usernameController,
                labelText: 'Username',
                prefixIcon: Icons.person,
                validator: AppValidators.username,
              ),
              const SizedBox(height: 16),
              FormHelpers.buildTextFormField(
                controller: _passwordController,
                labelText: 'Password',
                prefixIcon: Icons.lock,
                obscureText: true,
                validator: AppValidators.password,
              ),
              const SizedBox(height: 24),
              FormHelpers.buildPrimaryButton(
                text: 'Send Verification Code',
                onPressed: _isLoading ? null : _sendOtp,
                isLoading: _isLoading,
                icon: Icons.send,
              ),
            ] else ...[
              AppWidgets.infoBanner(
                title: 'Check Your Email',
                message: 'We sent a verification code to ${_emailController.text}',
                icon: Icons.email,
              ),
              const SizedBox(height: 16),
              FormHelpers.buildTextFormField(
                controller: _otpController,
                labelText: 'Verification Code',
                prefixIcon: Icons.lock,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter verification code';
                  if (!RegExp(r'^\d{6}$').hasMatch(value!)) return 'Code must be 6 digits';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: _canResendOtp ? _sendOtp : null,
                    child: Text(
                      _canResendOtp ? 'Resend Code' : 'Resend in $_resendCountdown s',
                      style: TextStyle(
                        color: _canResendOtp ? AppTheme.primary : Colors.grey,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() {
                      _otpSent = false;
                      _otpController.clear();
                    }),
                    child: const Text('Change Email', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FormHelpers.buildPrimaryButton(
                text: 'Create Account',
                onPressed: _isLoading ? null : _signup,
                isLoading: _isLoading,
                icon: Icons.person_add,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate() && !_otpSent) return;
    
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.sendSignupEmailOtp(_emailController.text);
      
      if (success) {
        setState(() {
          _otpSent = true;
          _canResendOtp = false;
          _resendCountdown = 60;
        });
        
        _startResendCountdown();
        _showSuccess('Verification code sent to ${_emailController.text}');
      } else {
        _showError('Failed to send verification code');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signupWithOtp(
        _usernameController.text,
        _emailController.text,
        _passwordController.text,
        _otpController.text,
      );
      
      if (success) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        _showError('Signup failed. Please check your verification code.');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startResendCountdown() {
    Stream.periodic(const Duration(seconds: 1))
        .take(60)
        .listen((tick) {
      setState(() {
        _resendCountdown = (60 - tick - 1).toInt(); // Fixed: explicitly convert to int
        if (_resendCountdown <= 0) {
          _canResendOtp = true;
        }
      });
    });
  }

  void _showSuccess(String message) {
    AppWidgets.showSnackBar(context, message, backgroundColor: Colors.green);
  }

  void _showError(String message) {
    AppWidgets.showSnackBar(context, message, backgroundColor: AppTheme.error);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}
