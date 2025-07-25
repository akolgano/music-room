import 'package:form_validator/form_validator.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

class AppValidators {
  static String? required(String? value, [String? fieldName]) =>
      ValidationBuilder().required('Please enter ${fieldName ?? 'this field'}').build()(value);
  
  static String? email(String? value) =>
      ValidationBuilder().email('Please enter a valid email address').build()(value);
  
  static String? password(String? value, [int minLength = 8]) =>
      ValidationBuilder().minLength(minLength, 'Password must be at least $minLength characters').build()(value);
  
  static String? username(String? value) =>
      ValidationBuilder()
          .minLength(3, 'Username must be at least 3 characters')
          .maxLength(30, 'Username must be less than 30 characters')
          .regExp(RegExp(r'^[a-zA-Z0-9_]+$'), 'Username can only contain letters, numbers, and underscores').build()(value);

  static String? phoneNumber(String? value, [bool required = false]) {
    if (!required && (value?.isEmpty ?? true)) { return null; }
    if (value == null || value.trim().isEmpty) { return required ? 'Please enter a phone number' : null; }
    try {
      final phoneNumber = PhoneNumber.parse(value.trim());
      if (phoneNumber.isValid()) { return null; }
      else { return 'Please enter a valid phone number'; }
    } catch (e) {
      return 'Please enter a valid phone number';
    }
  }
  
  static String? playlistName(String? value) =>
      ValidationBuilder().maxLength(100, 'Playlist name must be less than 100 characters').build()(value);
  
  static String? description(String? value) =>
      value != null && value.length > 500 ? 'Description must be less than 500 characters' : null;
  
  static String? name(String? value) =>
      ValidationBuilder().maxLength(100, 'Name must be less than 100 characters').build()(value);
  
  static String? bio(String? value) =>
      ValidationBuilder().maxLength(500, 'Bio must be less than 500 characters').build()(value);
  
  static String? location(String? value) =>
      ValidationBuilder().maxLength(100, 'Location must be less than 100 characters').build()(value);
}