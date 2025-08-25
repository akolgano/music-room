import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_providers.dart';
import '../../core/theme_core.dart';
import '../../core/navigation_core.dart';
import '../../widgets/app_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  var _isLoading = false, _isGetEmail = true, _isGetOtp = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  Widget _buildButton(String text, VoidCallback onPressed, Color color) => ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))),
    child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)));

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black, AppTheme.background], 
          begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: Center(child: SingleChildScrollView(child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 450), child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    isLandscape 
                      ? Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                          Icon(Icons.music_note, size: 60, color: AppTheme.primary),
                          SizedBox(width: 20),
                          Text('Music Room', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2))])
                      : Column(children: const [
                          SizedBox(height: 20),
                          Icon(Icons.music_note, size: 80, color: AppTheme.primary),
                          SizedBox(height: 20),
                          Text('Music Room', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
                          SizedBox(height: 40)]),
                    if (isLandscape) const SizedBox(height: 20),
                    Card(color: AppTheme.surface, elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(padding: const EdgeInsets.all(12.0), child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(_isGetEmail ? 'Forgot Password' : 'Reset Password',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                                textAlign: TextAlign.center),
                              const SizedBox(height: 24),

                              if (_isGetEmail)
                                AppWidgets.textField(
                                  context: context,
                                  controller: _emailController,
                                  labelText: 'Email',
                                  prefixIcon: Icons.email,
                                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter an email'
                                    : value.trim() != value ? 'Email cannot have leading or trailing spaces'
                                    : !RegExp(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$').hasMatch(value) ? 'Enter a valid email address' : null,
                                ),

                              if (_isGetOtp) ...[
                                AppWidgets.textField(
                                  context: context,
                                  controller: _otpController,
                                  labelText: 'OTP Code',
                                  prefixIcon: Icons.lock,
                                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter OTP'
                                    : value.trim() != value ? 'OTP cannot have leading or trailing spaces'
                                    : !RegExp(r'^\d{6}$').hasMatch(value) ? 'OTP must be exactly 6 digits' : null,
                                ),
                                const SizedBox(height: 24),
                                AppWidgets.textField(
                                  context: context,
                                  controller: _passwordController,
                                  labelText: 'Password',
                                  prefixIcon: Icons.lock,
                                  obscureText: true,
                                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter a password'
                                    : value.length < 4 ? 'Password must be at least 4 characters' : null,
                                ),
                              ],

                              const SizedBox(height: 24),
                              _isLoading
                                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                                : Column(children: [
                                    _buildButton(_isGetEmail ? 'Send OTP' : 'Reset Password', _submit, AppTheme.primary),
                                    const SizedBox(height: 24),
                                    _buildButton('Back', () => Navigator.pop(context), AppTheme.surface),
                                  ]),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )))),),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (_isGetEmail) {
        final success = await Provider.of<AuthProvider>(context, listen: false).sendPasswordResetEmail(_emailController.text);
        if (success && mounted) {
          AppWidgets.showSnackBar(context, "OTP sent to your email! Please enter the OTP code and your new password within 5 minutes.", backgroundColor: AppTheme.onSurface);
          setState(() { _isGetOtp = true; _isGetEmail = false; });
        }
      } else if (_isGetOtp) {
        await Provider.of<AuthProvider>(context, listen: false).resetPasswordWithOtp(
          _emailController.text, _otpController.text, _passwordController.text);
        setState(() => _isGetOtp = false);
        if (mounted) {
          AppWidgets.showSnackBar(context, "Password changed successfully!", backgroundColor: AppTheme.onSurface);
          Navigator.pop(context);
        }
      }
    } catch (error) {
      AppLogger.error('Error during password reset', error, null, 'ForgotPasswordScreen');
      if (mounted) AppWidgets.showSnackBar(context, error.toString(), backgroundColor: AppTheme.error);
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() { _emailController.dispose(); _passwordController.dispose(); _otpController.dispose(); super.dispose(); }
}
