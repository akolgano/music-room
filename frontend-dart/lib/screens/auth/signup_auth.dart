import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../providers/auth_providers.dart';
import '../../core/theme_core.dart';
import '../../core/responsive_core.dart';
import '../../core/provider_core.dart';
import '../../core/navigation_core.dart';
import '../../widgets/app_widgets.dart';

class SignupWithOtpScreen extends StatefulWidget {
  const SignupWithOtpScreen({super.key});

  @override
  State<SignupWithOtpScreen> createState() => _SignupWithOtpScreenState();
}

class _SignupWithOtpScreenState extends State<SignupWithOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = {
    'email': TextEditingController(),
    'username': TextEditingController(),
    'password': TextEditingController(),
    'confirmPassword': TextEditingController(),
    'otp': TextEditingController(),
  };
  
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
          child: SingleChildScrollView(
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

  String _getStepTitle() => ['Enter Email', 'Create Account', 'Verify Email'][_currentStep.clamp(0, 2)];
  IconData _getStepIcon() => [Icons.email, Icons.person_add, Icons.verified_user][_currentStep.clamp(0, 2)];

  List<Widget> _buildEmailStep() {
    return [
      const Text('Enter your email address to get started', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      _buildTextField('email', 'Email', Icons.email, AppValidators.email, _validateEmail),
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
      Text('Create your account for ${_controllers['email']!.text}', style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      _buildTextField('username', 'Username', Icons.person, AppValidators.username, _sendOtp),
      const SizedBox(height: 16),
      _buildTextField('password', 'Password', Icons.lock, AppValidators.password, _sendOtp, obscureText: true),
      const SizedBox(height: 16),
      _buildTextField('confirmPassword', 'Confirm Password', Icons.lock, 
        (value) => (value?.isEmpty ?? true) ? 'Please confirm your password' : value != _controllers['password']!.text ? 'Passwords do not match' : null,
        _sendOtp, obscureText: true),
      const SizedBox(height: 24),
      Row(
        children: [
          Expanded(child: TextButton(onPressed: () => setState(() => _currentStep = 0), child: const Text('Back', style: TextStyle(color: Colors.grey)))),
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
        message: 'We sent a verification code to ${_controllers['email']!.text}',
        icon: Icons.email,
      ),
      const SizedBox(height: 16),
      _buildTextField('otp', 'Verification Code', Icons.lock,
        (value) => (value?.isEmpty ?? true) ? 'Please enter verification code' : !RegExp(r'^\d{6}$').hasMatch(value!) ? 'Code must be 6 digits' : null,
        _signup),
      const SizedBox(height: 16),
      Row(
        children: [
          TextButton(
            onPressed: _canResendOtp ? _sendOtp : null,
            child: Text(
              _canResendOtp ? 'Resend Code' : 'Resend in $_resendCountdown s',
              style: TextStyle(
                color: _canResendOtp ? AppTheme.primary : Colors.grey,
                fontSize: MusicAppResponsive.getFontSize(context, 
                  tiny: 12.0, small: 13.0, medium: 14.0, 
                  large: 15.0, xlarge: 16.0, xxlarge: 17.0
                ),
              ),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => _resetToStep(1),
            child: const Text('Change Details', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      const SizedBox(height: 24),
      Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => _resetToStep(1),
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
      
      final isEmailAvailable = await authProvider.checkEmailAvailability(_controllers['email']!.text);
      if (!isEmailAvailable) {
        if (mounted) {
          AppWidgets.showSnackBar(context, 'This email is already registered. Please use a different email or try logging in.', backgroundColor: AppTheme.error);
          setState(() => _isLoading = false);
        }
        return;
      }
      
      if (mounted) {
        setState(() => _currentStep = 1);
        _showSuccess('Email is available! Please create your account.');
      }
    } catch (e) {
      AppLogger.error('Error checking email', e, null, 'SignupWithOtpScreen');
      if (mounted) {
        AppWidgets.showSnackBar(context, 'Error checking email: ${e.toString()}', backgroundColor: AppTheme.error);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.sendSignupEmailOtp(_controllers['email']!.text);
      if (success) {
        if (mounted) {
          setState(() { _currentStep = 2; _canResendOtp = false; _resendCountdown = 60; });
          _startResendCountdown();
          _showSuccess('Verification code sent to ${_controllers['email']!.text}');
        }
      } else {
        if (mounted) {
          AppWidgets.showSnackBar(context, 'Failed to send verification code', backgroundColor: AppTheme.error);
        }
      }
    } catch (e) {
      AppLogger.error('Error sending OTP', e, null, 'SignupWithOtpScreen');
      if (mounted) {
        AppWidgets.showSnackBar(context, 'Error: ${e.toString()}', backgroundColor: AppTheme.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signupWithOtp(
        _controllers['username']!.text,
        _controllers['email']!.text,
        _controllers['password']!.text,
        _controllers['otp']!.text,
      );
      
      if (success) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
      } else {
        if (mounted) {
          AppWidgets.showSnackBar(context, authProvider.errorMessage ?? 'Signup failed. Please check your verification code.', backgroundColor: AppTheme.error);
        }
      }
    } catch (e) {
      AppLogger.error('Error sending OTP', e, null, 'SignupWithOtpScreen');
      if (mounted) {
        AppWidgets.showSnackBar(context, 'Error: ${e.toString()}', backgroundColor: AppTheme.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startResendCountdown() {
    _countdownTimer?.cancel();
    setState(() { _canResendOtp = false; _resendCountdown = 60; });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      if (_resendCountdown <= 0) {
        timer.cancel();
        setState(() { _canResendOtp = true; _countdownTimer = null; });
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  void _showSuccess(String message) => AppWidgets.showSnackBar(context, message, backgroundColor: Colors.green);
  
  void _resetToStep(int step) {
    _countdownTimer?.cancel();
    setState(() {
      _currentStep = step;
      _controllers['otp']!.clear();
      _countdownTimer = null;
      _canResendOtp = true;
      _resendCountdown = 0;
    });
  }

  Widget _buildTextField(String key, String label, IconData icon, FormFieldValidator<String> validator, VoidCallback onSubmit, {bool obscureText = false}) {
    return AppWidgets.textField(
      context: context,
      controller: _controllers[key]!,
      labelText: label,
      prefixIcon: icon,
      obscureText: obscureText,
      validator: validator,
      onFieldSubmitted: kIsWeb ? (_) => onSubmit() : null,
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }
}
