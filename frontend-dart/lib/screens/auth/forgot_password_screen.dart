// lib/screens/auth/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/core.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  var _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  var _isGetEmail  = true;
  var _isGetOtp = false;
  

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, AppTheme.background],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
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
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Forgot Password',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                            
                              if (_isGetEmail)
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(Icons.email, color: AppTheme.onSurfaceVariant),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: AppTheme.surfaceVariant,
                                  ),
                                  style: const TextStyle(color: Colors.white),
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

                              if (_isGetOtp)
                                  TextFormField(
                                  controller: _otpController,
                                  decoration: InputDecoration(
                                    labelText: 'One Time Passcode',
                                    prefixIcon: Icon(Icons.lock, color: AppTheme.onSurfaceVariant),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: AppTheme.surfaceVariant,
                                  ),
                                  style: const TextStyle(color: Colors.white),
                                  
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

                              if(_isGetOtp)
                                TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: Icon(Icons.lock, color: AppTheme.onSurfaceVariant),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: AppTheme.surfaceVariant,
                                  ),
                                  style: const TextStyle(color: Colors.white),
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a password';
                                    }
                                    if (value.length < 8) {
                                      return 'Password must be at least 8 characters';
                                    }
                                    return null;
                                  },
                                ),
                              const SizedBox(height: 24),
                              if (_isLoading)
                                const Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.primary,
                                  ),
                                )
                              else
                                ElevatedButton(
                                  onPressed: _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(32),
                                    ),
                                  ),
                                  child: Text(
                                    'Submit',
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
                                  onPressed: _cancel,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.surface,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(32),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
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
        await Provider.of<AuthProvider>(context, listen: false).forgotPassword(
            _emailController.text,
        );

        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("OTP Sent to your email! Please input OTP and new password in 5 minutes!"),
          backgroundColor: AppTheme.onSurface,
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'DISMISS',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );

      setState(() {
        _isGetOtp = true;
        _isGetEmail = false;
      });

      }
      else if (_isGetOtp){
        await Provider.of<AuthProvider>(context, listen: false).forgotChangePassword(
            _emailController.text,
            _otpController.text,
            _passwordController.text,
        );

        setState(() {
          _isGetOtp = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Password changed success !"),
          backgroundColor: AppTheme.onSurface,
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'DISMISS',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
        );

        Navigator.pop(context);

      }
      
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppTheme.error,
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'DISMISS',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
    
    setState(() {
      _isLoading = false;
    });
  }


  void _cancel() async {
    Navigator.pop(context);
  }
}
