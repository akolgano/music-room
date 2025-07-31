import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme_utils.dart';
import '../../core/validators.dart';
import '../../core/constants.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/custom_scrollbar.dart';

class SignupWithOtpScreen extends StatefulWidget {
  const SignupWithOtpScreen({super.key});

  @override
  State<SignupWithOtpScreen> createState() => _SignupWithOtpScreenState();
}

class _SignupWithOtpScreenState extends State<SignupWithOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _isLoading = false;
  int _currentStep = 0; 
  bool _canResendOtp = true;
  int _resendCountdown = 0;
  Timer? _countdownTimer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(backgroundColor: AppTheme.background, title: const Text('Create Account')),
      body: SafeArea(
        child: Center(
          child: CustomSingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400), child: _buildForm()),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return AppTheme.buildFormCard(
      title: _getStepTitle(),
      titleIcon: _getStepIcon(),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (_currentStep == 0) ..._buildEmailStep(),
            if (_currentStep == 1) ..._buildCredentialsStep(),
            if (_currentStep == 2) ..._buildOtpStep(),
          ],
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0: return 'Enter Email';
      case 1: return 'Create Account';
      case 2: return 'Verify Email';
      default: return 'Create Account';
    }
  }

  IconData _getStepIcon() {
    switch (_currentStep) {
      case 0: return Icons.email;
      case 1: return Icons.person_add;
      case 2: return Icons.verified_user;
      default: return Icons.person_add;
    }
  }

  List<Widget> _buildEmailStep() {
    return [
      const Text(
        'Enter your email address to get started',
        style: TextStyle(color: Colors.white70),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 16),
      AppWidgets.textField(
        context: context,
        controller: _emailController,
        labelText: 'Email',
        prefixIcon: Icons.email,
        validator: AppValidators.email,
        onFieldSubmitted: kIsWeb ? (_) => _validateEmail() : null,
      ),
      const SizedBox(height: 24),
      AppWidgets.primaryButton(
        context: context,
        text: 'Continue',
        onPressed: _isLoading ? null : _validateEmail,
        isLoading: _isLoading,
        icon: Icons.arrow_forward,
      ),
    ];
  }

  List<Widget> _buildCredentialsStep() {
    return [
      Text(
        'Create your account for ${_emailController.text}',
        style: const TextStyle(color: Colors.white70),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 16),
      AppWidgets.textField(
        context: context,
        controller: _usernameController,
        labelText: 'Username',
        prefixIcon: Icons.person,
        validator: AppValidators.username,
        onFieldSubmitted: kIsWeb ? (_) => _sendOtp() : null,
      ),
      const SizedBox(height: 16),
      AppWidgets.textField(
        context: context,
        controller: _passwordController,
        labelText: 'Password',
        prefixIcon: Icons.lock,
        obscureText: true,
        validator: AppValidators.password,
        onFieldSubmitted: kIsWeb ? (_) => _sendOtp() : null,
      ),
      const SizedBox(height: 16),
      AppWidgets.textField(
        context: context,
        controller: _confirmPasswordController,
        labelText: 'Confirm Password',
        prefixIcon: Icons.lock,
        obscureText: true,
        validator: (value) {
          if (value?.isEmpty ?? true) return 'Please confirm your password';
          if (value != _passwordController.text) return 'Passwords do not match';
          return null;
        },
        onFieldSubmitted: kIsWeb ? (_) => _sendOtp() : null,
      ),
      const SizedBox(height: 24),
      Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => setState(() {
                _currentStep = 0;
              }),
              child: const Text('Back', style: TextStyle(color: Colors.grey)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: AppWidgets.primaryButton(
              context: context,
              text: 'Send Verification Code',
              onPressed: _isLoading ? null : _sendOtp,
              isLoading: _isLoading,
              icon: Icons.send,
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildOtpStep() {
    return [
      AppWidgets.infoBanner(
        title: 'Check Your Email',
        message: 'We sent a verification code to ${_emailController.text}',
        icon: Icons.email,
      ),
      const SizedBox(height: 16),
      AppWidgets.textField(
        context: context,
        controller: _otpController,
        labelText: 'Verification Code',
        prefixIcon: Icons.lock,
        validator: (value) {
          if (value?.isEmpty ?? true) return 'Please enter verification code';
          if (!RegExp(r'^\d{6}$').hasMatch(value!)) return 'Code must be 6 digits';
          return null;
        },
        onFieldSubmitted: kIsWeb ? (_) => _signup() : null,
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          TextButton(
            onPressed: _canResendOtp ? _sendOtp : null,
            child: Text(
              _canResendOtp ? 'Resend Code' : 'Resend in $_resendCountdown s',
              style: TextStyle(color: _canResendOtp ? AppTheme.primary : Colors.grey),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => setState(() {
              _currentStep = 1;
              _otpController.clear();
              _stopCountdown();
            }),
            child: const Text('Change Details', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      const SizedBox(height: 24),
      Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => setState(() {
                _currentStep = 1;
                _otpController.clear();
                _stopCountdown();
              }),
              child: const Text('Back', style: TextStyle(color: Colors.grey)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: AppWidgets.primaryButton(
              context: context,
              text: 'Create Account',
              onPressed: _isLoading ? null : _signup,
              isLoading: _isLoading,
              icon: Icons.person_add,
            ),
          ),
        ],
      ),
    ];
  }

  Future<void> _validateEmail() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final isEmailAvailable = await authProvider.checkEmailAvailability(_emailController.text);
      if (!isEmailAvailable) {
        _showError('This email is already registered. Please use a different email or try logging in.');
        setState(() => _isLoading = false);
        return;
      }
      
      setState(() {
        _currentStep = 1;
      });
      _showSuccess('Email is available! Please create your account.');
    } catch (e) {
      _showError('Error checking email: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.sendSignupEmailOtp(_emailController.text);
      if (success) {
        setState(() {
          _currentStep = 2;
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
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
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
    _stopCountdown(); 
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (_resendCountdown <= 0) {
        _canResendOtp = true;
        timer.cancel();
        _countdownTimer = null;
        if (mounted) {
          setState(() {});
        }
        return;
      }
      
      setState(() {
        _resendCountdown--;
      });
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _canResendOtp = true;
    _resendCountdown = 0;
  }

  void _showSuccess(String message) {
    AppWidgets.showSnackBar(context, message, backgroundColor: Colors.green);
  }

  void _showError(String message) {
    AppWidgets.showSnackBar(context, message, backgroundColor: AppTheme.error);
  }

  @override
  void dispose() {
    _stopCountdown();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}
