import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInCore {
  static final GoogleSignIn _instance = GoogleSignIn(
    scopes: ['email', 'profile', 'openid'],
    serverClientId: kIsWeb ? null : '554843341079-nd7ljiruh4nokmuts9pot0no1kavtv5d.apps.googleusercontent.com',
  );

  static GoogleSignIn get instance => _instance;
}