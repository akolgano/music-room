// lib/providers/profile_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import '../services/profile_api_service.dart';


class ProfileProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final ProfileApiService _profileApiService = ProfileApiService();
  
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
  String? _avatar;
  String? _gender;
  String? _location;
  String? _bio;
  String? _firstName;
  String? _lastName;
  String? _phone;
  String? _street;
  String? _country;
  String? _postalCode;
  DateTime? _dob;
  List<String>? _hobbies;
  String? _friendInfo;
  List<String>? _musicPreferences;
  

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
  String? get avatar => _avatar;
  String? get gender => _gender;
  String? get location => _location;
  String? get bio => _bio;
  String? get firstName => _firstName;
  String? get lastName => _lastName;
  String? get phone => _phone;
  String? get street => _street;
  String? get country => _country;
  String? get postalCode => _postalCode;
  DateTime? get dob => _dob;
  List<String>? get hobbies => _hobbies;
  String? get friendInfo => _friendInfo;
  List<String>? get musicPreferences => _musicPreferences;
  
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
    _avatar = null;
    _gender = null;
    _location = null;
    _bio = null;
    _firstName = null;
    _lastName = null;
    _phone = null;
    _street = null;
    _country = null;
    _postalCode = null;
    _dob = null;
    _hobbies = null;
    _friendInfo = null;
    _musicPreferences = null;
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

      final profilePublic = await _profileApiService.getProfilePublic(token);
      _avatar = profilePublic['avatar'];
      _gender = profilePublic['gender'];
      _location = profilePublic['location'];
      _bio = profilePublic['bio'];

      final profilePrivate = await _profileApiService.getProfilePrivate(token);
      _firstName = profilePrivate['first_name'];
      _lastName = profilePrivate['last_name'];
      _phone = profilePrivate['phone'];
      _street = profilePrivate['street'];
      _country = profilePrivate['country'];
      _postalCode = profilePrivate['postal_code'];

      final profileFriend = await _profileApiService.getProfileFriend(token);
      _hobbies = profileFriend ['hobbies'];
      _friendInfo = profileFriend ['friend_info'];
      final dobDb = profileFriend ['dob'];
      if (dobDb != null){
        _dob = DateTime.parse(dobDb);
      }

      final profileMusic = await _profileApiService.getProfileMusic(token);
      _musicPreferences = profileMusic['music_preferences'];

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

  Future<bool> updateAvatar(String? token, String? avatarBase64, String? mimeType) async {
    try{
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _profileApiService.updateAvatar(token, avatarBase64, mimeType);
      
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

  Future<bool> updatePublicBasic(String? token, String? gender, String? location) async {
    try{
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _profileApiService.updatePublicBasic(token, gender, location);
      
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

  Future<bool> updatePublicBio(String? token, String? bio) async {
    try{
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _profileApiService.updatePublicBio(token, bio);
      
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

  Future<bool> updatePrivateInfo(String? token, String? firstName, String? lastName, String? phone, String? street, String? country, String? postalCode) async {
    try{
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _profileApiService.updatePrivateInfo(token, firstName, lastName, phone, street, country, postalCode);
      
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

  Future<bool> updateFriendInfo(String? token, String? dob, List<String>? hobbies, String? friendInfo) async {
    try{
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _profileApiService.updateFriendInfo(token, dob, hobbies, friendInfo);
      
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

  Future<bool> updateMusicPreferences(String? token, List<String>? musicPreferences) async {
    try{
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _profileApiService.updateMusicPreferences(token, musicPreferences);
      
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