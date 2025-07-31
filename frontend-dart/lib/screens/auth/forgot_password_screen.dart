import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme_utils.dart';
import '../../widgets/app_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  var _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  var _isGetEmail = true;
  var _isGetOtp = false;

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(prefixIcon, color: AppTheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: AppTheme.surfaceVariant,
      ),
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
    );
  }

  void _showSnackBarWithAction({
    required String message,
    required Color backgroundColor,
    required String actionLabel,
  }) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: actionLabel,
            textColor: Colors.white,
            onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.black, AppTheme.background], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 450),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isLandscape) ...[
                      const SizedBox(height: 20),
                      const Icon(Icons.music_note, size: 80, color: AppTheme.primary),
                      const SizedBox(height: 20),
                      const Text(
                        'Music Room',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                    if (isLandscape) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.music_note,
                            size: 60,
                            color: AppTheme.primary,
                          ),
                          SizedBox(width: 20),
                          Text(
                            'Music Room',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                    Card(
                      color: AppTheme.surface,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _isGetEmail ? 'Forgot Password' : 'Reset Password',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),

                              if (_isGetEmail)
                                _buildTextFormField(
                                  controller: _emailController,
                                  labelText: 'Email',
                                  prefixIcon: Icons.email,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter an email';
                                    }
                                    if (value.trim() != value) {
                                      return 'Email cannot have leading or trailing spaces';
                                    }
                                    if (!RegExp(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$').hasMatch(value)) {
                                      return 'Enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),

                              if (_isGetOtp) ...[
                                _buildTextFormField(
                                  controller: _otpController,
                                  labelText: 'OTP Code',
                                  prefixIcon: Icons.lock,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter OTP';
                                    }
                                    if (value.trim() != value) {
                                      return 'OTP cannot have leading or trailing spaces';
                                    }
                                    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
                                      return 'OTP must be exactly 6 digits';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                _buildTextFormField(
                                  controller: _passwordController,
                                  labelText: 'Password',
                                  prefixIcon: Icons.lock,
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Please enter a password';
                                    if (value.length < 4) return 'Password must be at least 4 characters';
                                    return null;
                                  },
                                ),
                              ],

                              const SizedBox(height: 24),

                              if (_isLoading)
                                const Center(
                                  child: CircularProgressIndicator(color: AppTheme.primary),
                                )
                              else
                                ElevatedButton(
                                  onPressed: _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(32),
                                    ),
                                  ),
                                  child: Text(
                                    _isGetEmail ? 'Send OTP' : 'Reset Password',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 24),

                              if (!_isLoading)
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.surface,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(32),
                                    ),
                                  ),
                                  child: Text(
                                    'Back',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isGetEmail) {
        final success = await Provider.of<AuthProvider>(context, listen: false).forgotPassword(
          _emailController.text,
        );

        if (success && mounted) {
          AppWidgets.showSnackBar(context, "OTP sent to your email! Please enter the OTP code and your new password within 5 minutes.", backgroundColor: AppTheme.onSurface);
          setState(() {
            _isGetOtp = true;
            _isGetEmail = false;
          });
        }
      } else if (_isGetOtp) {
        await Provider.of<AuthProvider>(context, listen: false).forgotChangePassword(
          _emailController.text,
          _otpController.text,
          _passwordController.text,
        );

        setState(() {
          _isGetOtp = false;
        });

        _showSnackBarWithAction(
          message: "Password changed successfully!",
          backgroundColor: AppTheme.onSurface,
          actionLabel: 'OK',
        );

        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (error) {
      _showSnackBarWithAction(
        message: error.toString(),
        backgroundColor: AppTheme.error,
        actionLabel: 'DISMISS',
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}
