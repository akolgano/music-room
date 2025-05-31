// lib/providers/profile_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';


class ProfileProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  String? _userId;
  String? _username;
  String? _userEmail;
  String? _socialEmail;
  String? _socialName;
  String? _socialType;
  String? _socialId;
  bool _isPasswordUsable = false;
  bool _isLoading = false;
  String? _errorMessage;

  String? get userId => _userId;
  String? get username => _username;
  String? get userEmail => _userEmail;
  String? get socialEmail => _socialEmail;
  String? get socialName => _socialName;
  String? get socialType => _socialType;
  String? get socialId => _socialId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isPasswordUsable => _isPasswordUsable;
  
  GoogleSignIn? googleSignIn;


  ProfileProvider() {

    if (!kIsWeb) {
      googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile', 'openid'],
      clientId: dotenv.env['GOOGLE_CLIENT_ID_APP'],
      );
    }

  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void resetValues(){
    _userId = null;
    _username = null;
    _userEmail = null;
    _isPasswordUsable = false;
    _socialType = null;
    _socialEmail = null;
    _socialName = null;
    _socialId = null;

}

  Future<bool> loadProfile(String? token) async{
    try{

      _isLoading = true;
      _errorMessage = null;
      resetValues();
      notifyListeners();

      final data = await _apiService.getUser(token);

      _userId = data['id'];
      _username = data['username'];
      _userEmail = data['email'];
      _isPasswordUsable = data['is_password_usable'] as bool;
      
      final hasSocialAccount = data['has_social_account'] as bool;
      if (hasSocialAccount){
        final social = data['social'] as Map<String, dynamic>;
        _socialType = social['type'];
        _socialEmail = social['social_email'];
        _socialName = social['social_name'];
        _socialId = social['social_id'];
      }

      _isLoading = false;
      notifyListeners();
      return true;
    }
    catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }

  }


  Future<bool> userPasswordChange(String? token, String currentPassword, String newPassword) async {
    try{
    
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _apiService.userPasswordChange(token, currentPassword, newPassword);

      _isLoading = false;
      notifyListeners();
      return true;
    }
    catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }


  Future<bool> facebookLink(String? token) async {
    try{
        _isLoading = true;
        _errorMessage = null;
        notifyListeners();

        final LoginResult result = await FacebookAuth.instance.login();
        if (result.status == LoginStatus.success) {
          final fbAccessToken = result.accessToken!.tokenString;

          await _apiService.facebookLink(token, fbAccessToken);

          _isLoading = false;
          notifyListeners();
          return true;
        }
        else {
          _errorMessage = "Facebook login failed !";
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } catch (e) {
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
        return false;
      }
  }

  Future<bool> googleLinkWeb(String? token, GoogleSignInUserData? account) async {
    try{
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      var idToken = account?.idToken;

      if (idToken == null) {
        _errorMessage = "Google login failed !";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _apiService.googleLink('web', token, idToken);
      
      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }

  }

  Future<bool> googleLinkApp(String? token) async {
    try{
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final user = await googleSignIn?.signIn();

      if (user == null) {
        _errorMessage = "Google login failed !";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final auth = await user.authentication;
      final idToken = auth.idToken;

      if (idToken == null) {
        _errorMessage = "Google login failed !";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _apiService.googleLink('app', token, idToken);
      
      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
        return false;
    }
  }
}