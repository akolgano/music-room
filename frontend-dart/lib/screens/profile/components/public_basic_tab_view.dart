// lib/screens/profile/components/public_basic_tab_view.dart
import 'package:flutter/material.dart';
import '../../../core/app_core.dart';
import '../../../providers/profile_provider.dart';
import '../../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../../widgets/common_widgets.dart';
import '../../../widgets/base_form_widget.dart';
import '../../../core/common_utils.dart';

class PublicBasicTabView extends StatefulWidget {
  const PublicBasicTabView({Key? key}) : super(key: key);

  @override
  State<PublicBasicTabView> createState() => _PublicBasicTabViewState();
}

class _PublicBasicTabViewState extends State<PublicBasicTabView> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  String? _gender;
  bool _genderValidationError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      if (profileProvider.gender != null) {
        setState(() => _gender = profileProvider.gender);
      }
      if (profileProvider.location != null) {
        _locationController.text = profileProvider.location!;
      }
    });
  }

  Future<void> _submit() async {
    try {
      setState(() => _genderValidationError = false);

      if (!_formKey.currentState!.validate()) return;
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

      if (authProvider.token == null) return;

      if (_gender == null) {
        setState(() => _genderValidationError = true);
        return;
      }

      bool success = await profileProvider.updatePublicBasic(
        authProvider.token, 
        _gender, 
        _locationController.text
      );

      if (success) {
        await profileProvider.loadProfile(authProvider.token);
        CommonUtils.showSnackBar(context, 'Update successful', backgroundColor: Colors.green);
      }
    } catch (e) {
      CommonUtils.showSnackBar(context, 'Exception: $e', backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        return Form(
          key: _formKey,
          child: BaseFormWidget(
            title: 'Basic Information',
            isLoading: profileProvider.isLoading,
            errorMessage: profileProvider.errorMessage,
            onSubmit: _submit,
            children: [
              const Text('Gender', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              if (_genderValidationError) ...[
                const Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: Text(
                    'Please select gender',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],

              RadioListTile<String>(
                title: const Text('Male'),
                value: 'male',
                groupValue: _gender,
                onChanged: (value) => setState(() => _gender = value),
              ),
              RadioListTile<String>(
                title: const Text('Female'),
                value: 'female',
                groupValue: _gender,
                onChanged: (value) => setState(() => _gender = value),
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _locationController,
                labelText: 'Current Location',
                validator: (v) => CommonUtils.validateRequired(v, 'location') ?? 
                         CommonUtils.validateMaxLength(v, 50, 'Location'),
              ),
            ],
          ),
        );
      },
    );
  }
}
