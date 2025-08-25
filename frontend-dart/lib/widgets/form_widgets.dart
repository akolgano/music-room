import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/provider_core.dart';
import '../core/theme_core.dart';
import 'core_widgets.dart';

double _responsive(double value, {String type = 'sp'}) {
  if (kIsWeb) return value;
  switch (type) {
    case 'w':
      return value.w;
    case 'h':
      return value.h;
    case 'sp':
    default:
      return value.sp;
  }
}

class FormWidgets {
  
  static Widget passwordField({
    required BuildContext context,
    required TextEditingController controller,
    String labelText = 'Password',
    String? hintText,
    String? Function(String?)? validator,
    Function(String)? onFieldSubmitted,
    bool showVisibilityToggle = true,
  }) {
    bool obscureText = true;
    return StatefulBuilder(
      builder: (context, setState) {
        return AppWidgets.textField(
          context: context,
          controller: controller,
          labelText: labelText,
          hintText: hintText ?? 'Enter your password',
          prefixIcon: Icons.lock,
          obscureText: obscureText,
          validator: validator ?? (value) => AppValidators.password(value, 8),
          onFieldSubmitted: onFieldSubmitted,
          suffixIcon: showVisibilityToggle
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility : Icons.visibility_off,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  onPressed: () => setState(() => obscureText = !obscureText),
                )
              : null,
        );
      },
    );
  }
  
  static Widget emailField({
    required BuildContext context,
    required TextEditingController controller,
    String labelText = 'Email',
    String? hintText,
    Function(String)? onFieldSubmitted,
    bool enabled = true,
  }) {
    return AppWidgets.textField(
      context: context,
      controller: controller,
      labelText: labelText,
      hintText: hintText ?? 'user@example.com',
      prefixIcon: Icons.email,
      keyboardType: TextInputType.emailAddress,
      validator: AppValidators.email,
      onFieldSubmitted: onFieldSubmitted,
      enabled: enabled,
    );
  }
  
  static Widget usernameField({
    required BuildContext context,
    required TextEditingController controller,
    String labelText = 'Username',
    String? hintText,
    Function(String)? onFieldSubmitted,
  }) {
    return AppWidgets.textField(
      context: context,
      controller: controller,
      labelText: labelText,
      hintText: hintText ?? 'Choose a username',
      prefixIcon: Icons.person,
      validator: AppValidators.username,
      onFieldSubmitted: onFieldSubmitted,
    );
  }
  
  static Widget numericField({
    required BuildContext context,
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    int? maxLength,
    String? Function(String?)? validator,
    Function(String)? onFieldSubmitted,
  }) {
    return AppWidgets.textField(
      context: context,
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon ?? Icons.pin,
      keyboardType: TextInputType.number,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
    );
  }
  
  static Widget otpField({
    required BuildContext context,
    required TextEditingController controller,
    Function(String)? onFieldSubmitted,
    Function(String)? onChanged,
  }) {
    return numericField(
      context: context,
      controller: controller,
      labelText: 'OTP Code',
      hintText: 'Enter 6-digit code',
      prefixIcon: Icons.security,
      maxLength: 6,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter OTP';
        }
        if (value.trim() != value) {
          return 'OTP cannot have spaces';
        }
        if (!RegExp(r'^\d{6}$').hasMatch(value)) {
          return 'OTP must be exactly 6 digits';
        }
        return null;
      },
      onFieldSubmitted: onFieldSubmitted,
    );
  }
  
  static Widget searchField({
    required BuildContext context,
    required TextEditingController controller,
    String? hintText,
    Function(String)? onChanged,
    Function(String)? onSubmitted,
    VoidCallback? onClear,
  }) {
    return AppWidgets.textField(
      context: context,
      controller: controller,
      labelText: '',
      hintText: hintText ?? 'Search...',
      prefixIcon: Icons.search,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      suffixIcon: controller.text.isNotEmpty
          ? IconButton(
              icon: Icon(
                Icons.clear,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              onPressed: () {
                controller.clear();
                onClear?.call();
                onChanged?.call('');
              },
            )
          : null,
    );
  }
  
  static Widget multilineField({
    required BuildContext context,
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    int maxLines = 5,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppWidgets.textField(
          context: context,
          controller: controller,
          labelText: labelText,
          hintText: hintText,
          maxLines: maxLines,
          validator: validator,
        ),
        if (maxLength != null)
          Padding(
            padding: EdgeInsets.only(
              top: _responsive(4.0, type: 'h'),
              right: _responsive(8.0, type: 'w'),
            ),
            child: Align(
              alignment: Alignment.bottomRight,
              child: Text(
                '${controller.text.length}/$maxLength',
                style: ThemeUtils.getCaptionStyle(context),
              ),
            ),
          ),
      ],
    );
  }
  
  static Widget datePickerField({
    required BuildContext context,
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    Function(DateTime)? onDateSelected,
  }) {
    return AppWidgets.textField(
      context: context,
      controller: controller,
      labelText: labelText,
      hintText: hintText ?? 'Select date',
      prefixIcon: Icons.calendar_today,
      readOnly: true,
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: initialDate ?? DateTime.now(),
          firstDate: firstDate ?? DateTime(2000),
          lastDate: lastDate ?? DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primary,
                  onPrimary: Colors.white,
                  surface: AppTheme.surface,
                  onSurface: AppTheme.onSurface,
                ),
              ),
              child: child!,
            );
          },
        );
        
        if (picked != null) {
          controller.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
          onDateSelected?.call(picked);
        }
      },
    );
  }
  
  static Widget timePickerField({
    required BuildContext context,
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    TimeOfDay? initialTime,
    Function(TimeOfDay)? onTimeSelected,
  }) {
    return AppWidgets.textField(
      context: context,
      controller: controller,
      labelText: labelText,
      hintText: hintText ?? 'Select time',
      prefixIcon: Icons.access_time,
      readOnly: true,
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: initialTime ?? TimeOfDay.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primary,
                  onPrimary: Colors.white,
                  surface: AppTheme.surface,
                  onSurface: AppTheme.onSurface,
                ),
              ),
              child: child!,
            );
          },
        );
        
        if (picked != null) {
          final hour = picked.hourOfPeriod == 0 && picked.period == DayPeriod.pm ? 12 : picked.hourOfPeriod;
          final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
          controller.text = '${hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')} $period';
          onTimeSelected?.call(picked);
        }
      },
    );
  }
  
  static Widget dropdownField<T>({
    required BuildContext context,
    required String labelText,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    String? hintText,
    IconData? prefixIcon,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: _responsive(16.0, type: 'w'),
          vertical: _responsive(12.0, type: 'h'),
        ),
      ),
      dropdownColor: AppTheme.surface,
      style: ThemeUtils.getBodyStyle(context),
    );
  }
  
  static Widget sliderField({
    required BuildContext context,
    required String labelText,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
    int? divisions,
    String? Function(double)? labelBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: ThemeUtils.getSubheadingStyle(context),
        ),
        SizedBox(height: _responsive(8.0, type: 'h')),
        Row(
          children: [
            Text(
              min.toStringAsFixed(0),
              style: ThemeUtils.getCaptionStyle(context),
            ),
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                label: labelBuilder?.call(value) ?? value.toStringAsFixed(0),
                onChanged: onChanged,
                activeColor: AppTheme.primary,
                inactiveColor: AppTheme.primary.withValues(alpha: 0.3),
              ),
            ),
            Text(
              max.toStringAsFixed(0),
              style: ThemeUtils.getCaptionStyle(context),
            ),
          ],
        ),
        if (labelBuilder != null)
          Center(
            child: Text(
              labelBuilder(value) ?? value.toStringAsFixed(0),
              style: ThemeUtils.getBodyStyle(context).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
  
  static Widget switchField({
    required BuildContext context,
    required String labelText,
    required bool value,
    required Function(bool) onChanged,
    String? subtitle,
    IconData? leadingIcon,
  }) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: _responsive(4.0, type: 'h')),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: ListTile(
        leading: leadingIcon != null ? Icon(leadingIcon, color: AppTheme.primary) : null,
        title: Text(
          labelText,
          style: ThemeUtils.getBodyStyle(context),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: ThemeUtils.getCaptionStyle(context),
              )
            : null,
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppTheme.primary,
        ),
      ),
    );
  }
  
  static Widget checkboxField({
    required BuildContext context,
    required String labelText,
    required bool value,
    required Function(bool?) onChanged,
    String? subtitle,
    bool tristate = false,
  }) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: _responsive(4.0, type: 'h')),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: CheckboxListTile(
        title: Text(
          labelText,
          style: ThemeUtils.getBodyStyle(context),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: ThemeUtils.getCaptionStyle(context),
              )
            : null,
        value: value,
        onChanged: onChanged,
        tristate: tristate,
        activeColor: AppTheme.primary,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
  
  static Widget radioGroupField<T>({
    required BuildContext context,
    required String labelText,
    required T? groupValue,
    required List<RadioOption<T>> options,
    required Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: ThemeUtils.getSubheadingStyle(context).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: _responsive(8.0, type: 'h')),
        RadioGroup<T>(
          groupValue: groupValue,
          onChanged: onChanged,
          child: Column(
            children: options.map((option) => RadioListTile<T>(
                  title: Text(
                    option.label,
                    style: ThemeUtils.getBodyStyle(context),
                  ),
                  subtitle: option.subtitle != null
                      ? Text(
                          option.subtitle!,
                          style: ThemeUtils.getCaptionStyle(context),
                        )
                      : null,
                  value: option.value,
                  activeColor: AppTheme.primary,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: _responsive(4.0, type: 'w'),
                  ),
                )).toList(),
          ),
        ),
      ],
    );
  }
}

class RadioOption<T> {
  final String label;
  final T value;
  final String? subtitle;
  
  const RadioOption({
    required this.label,
    required this.value,
    this.subtitle,
  });
}

class FormValidationUtils {

  static String? validateCreditCard(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a credit card number';
    }
    
    final cleanNumber = value.replaceAll(RegExp(r'\D'), '');
    
    if (cleanNumber.length < 13 || cleanNumber.length > 19) {
      return 'Invalid credit card number length';
    }
    
    int sum = 0;
    bool alternate = false;
    
    for (int i = cleanNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cleanNumber[i]);
      
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }
      
      sum += digit;
      alternate = !alternate;
    }
    
    if (sum % 10 != 0) {
      return 'Invalid credit card number';
    }
    
    return null;
  }
  
  static String? validatePhoneNumber(String? value, {String? countryCode}) {
    if (value == null || value.isEmpty) {
      return 'Please enter a phone number';
    }
    
    final cleanNumber = value.replaceAll(RegExp(r'\D'), '');
    
    if (countryCode == 'US' || countryCode == null) {
      if (cleanNumber.length != 10 && cleanNumber.length != 11) {
        return 'Invalid phone number format';
      }
      if (cleanNumber.length == 11 && !cleanNumber.startsWith('1')) {
        return 'Invalid country code';
      }
    }
    
    return null;
  }
  
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a URL';
    }
    
    final urlPattern = RegExp(
      r'^(https?:\/\/)?'
      r'((([a-z\d]([a-z\d-]*[a-z\d])*)\.)+[a-z]{2,}|'
      r'((\d{1,3}\.){3}\d{1,3}))'
      r'(\:\d+)?(\/[-a-z\d%_.~+]*)*'
      r'(\?[;&a-z\d%_.~+=-]*)?'
      r'(\#[-a-z\d_]*)?$',
      caseSensitive: false,
    );
    
    if (!urlPattern.hasMatch(value)) {
      return 'Please enter a valid URL';
    }
    
    return null;
  }
  
  static String? Function(String?) matchValidator(
    String? otherValue,
    String fieldName,
  ) {
    return (String? value) {
      if (value != otherValue) {
        return '$fieldName does not match';
      }
      return null;
    };
  }
}

class FormDecorationPresets {

  static InputDecoration outlined({
    required BuildContext context,
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(
          color: AppTheme.primary,
          width: 2.0,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: _responsive(16.0, type: 'w'),
        vertical: _responsive(12.0, type: 'h'),
      ),
    );
  }
  
  static InputDecoration filled({
    required BuildContext context,
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      border: UnderlineInputBorder(
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: AppTheme.primary,
          width: 2.0,
        ),
      ),
      errorBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: _responsive(16.0, type: 'w'),
        vertical: _responsive(12.0, type: 'h'),
      ),
    );
  }
}
