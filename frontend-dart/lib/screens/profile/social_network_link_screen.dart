// lib/screens/profile/social_network_link_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../core/app_core.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SocialNetworkLinkScreen extends StatefulWidget {
  const SocialNetworkLinkScreen({Key? key}) : super(key: key);

  @override 
  State<SocialNetworkLinkScreen> createState() => _SocialNetworkLinkScreenState();
}

class _SocialNetworkLinkScreenState extends State<SocialNetworkLinkScreen> {
  final googleSignInPlugin = GoogleSignInPlatform.instance as GoogleSignInPlugin;

  @override                                                                 
  void initState() {     
    super.initState();
    if (kIsWeb) {
      _initializeGoogleSignInWeb();
    }
  }

  Future<void> _initializeGoogleSignInWeb() async {
    await googleSignInPlugin.initWithParams(
      SignInInitParameters(
        clientId: dotenv.env['GOOGLE_CLIENT_ID_WEB'],
        scopes: ['email', 'profile', 'openid'],
      ),
    );

    googleSignInPlugin.userDataEvents?.listen((GoogleSignInUserData? account) {
      if (account != null) {
        _googleLinkWeb(account);
      }
    });
  }

  Future<void> _googleLinkWeb(GoogleSignInUserData? account) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token == null) return;

    bool success = await Provider.of<ProfileProvider>(context, listen: false).googleLinkWeb(authProvider.token, account);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link successful'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Link Social Network'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Card(
              color: AppTheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Consumer<ProfileProvider>(
                  builder: (context, profileProvider, child) {
                    return Column(
                      children: [
                        const Text(
                          'Link with Social Network',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)
                        ),
                        const SizedBox(height: 24),
                        
                        if (profileProvider.hasError) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    profileProvider.errorMessage ?? 'An error occurred',
                                    style: const TextStyle(color: Colors.red, fontSize: 14),
                                  ),
                                ),  
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        if (profileProvider.socialType != null) ...[
                          Text('Connected to ${profileProvider.socialType!}'),
                          const SizedBox(height: 16),
                        ],

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (kIsWeb)
                              googleSignInPlugin.renderButton()
                            else
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _loginWithSocial('Google'),
                                  icon: const Icon(Icons.g_mobiledata),
                                  label: const Text('GOOGLE'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    side: const BorderSide(color: Colors.white),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _loginWithSocial('Facebook'),
                                icon: const Icon(Icons.facebook),
                                label: const Text('FACEBOOK'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(color: Colors.white),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        if (profileProvider.isLoading)
                          const CircularProgressIndicator(color: AppTheme.primary),

                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: () async {
                            final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            await profileProvider.loadProfile(authProvider.token);
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(foregroundColor: Colors.white),
                          child: const Text('Go Back'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
    
  void _loginWithSocial(String provider) async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token == null) return;

    bool success = false;
  
    if (provider == "Facebook") {
      success = await profileProvider.facebookLink(authProvider.token);
    } else if (provider == "Google") {
      success = await profileProvider.googleLinkApp(authProvider.token);
    }

    if (success) {
      profileProvider.loadProfile(authProvider.token);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link successful'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
