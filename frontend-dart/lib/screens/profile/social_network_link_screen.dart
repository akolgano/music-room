// lib/screens/auth/social_network_link_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_core.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;


class SocialNetworkLinkScreen extends StatefulWidget {
  const SocialNetworkLinkScreen({Key? key}) : super(key: key);

  @override State<SocialNetworkLinkScreen> createState() => _SocialNetworkLinkScreenState();
}

class _SocialNetworkLinkScreenState extends State<SocialNetworkLinkScreen> {
  final _formKey = GlobalKey<FormState>();
  //bool isLink = false;
  
  final googleSignInPlugin = GoogleSignInPlatform.instance as GoogleSignInPlugin;

  @override                                                                 
  void initState() {     
    super.initState();

    /*final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    profileProvider.loadProfile(authProvider.token);
    profileProvider.clearError();
    if (profileProvider.socialType != null){
      setState((){isLink = true;});
    }*/

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
    bool success = false;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token == null) return;

    success = await Provider.of<ProfileProvider>(context, listen: false).googleLinkWeb(authProvider.token, account);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Linked successful'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              children: [
                const Icon(Icons.music_note, size: 80, color: AppTheme.primary),
                const SizedBox(height: 20),
                const Text('Music Room', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
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
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        return Card(
          color: AppTheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                
                children: [
                    Text('Link with Social Network',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
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
                  ],
                  const SizedBox(height: 16),

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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
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
                    onPressed: _cancel,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Go Back'),
                  ),
                ],


              ),
            ),
          ),
        );
      },
    );
  }


  @override
  void dispose() {
    super.dispose();
  }
    
  void _cancel() async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await profileProvider.loadProfile(authProvider.token);
    Navigator.pop(context);
  }

  void _loginWithSocial(String provider) async {

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token == null) return;

    bool success = false;
  
    if (provider == "Facebook") {
      success = await profileProvider.facebookLink(authProvider.token);
    }
    else if (provider == "Google") {
      success = await profileProvider.googleLinkApp(authProvider.token);
    }

    if (success) {

      //setState(() {isLink = true;});

      //profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      //authProvider = Provider.of<AuthProvider>(context, listen: false);
      profileProvider.loadProfile(authProvider.token);

      //Navigator.pushReplacement(
      //  context,
      //  MaterialPageRoute(builder: (context) => SocialNetworkLinkScreen()),
      //);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Link successful'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

}
