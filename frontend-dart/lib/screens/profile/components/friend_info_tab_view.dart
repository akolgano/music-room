// lib/screens/profile/components/friend_info_tab_view.dart
import 'package:flutter/material.dart';
import '../../../core/app_core.dart';
import '../../../providers/profile_provider.dart';
import '../../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../../widgets/common_widgets.dart';
import './date_picker.dart';
import './utils.dart';


class FriendInfoTabView extends StatefulWidget {
  const FriendInfoTabView({Key? key}) : super(key: key);

  @override
  State<FriendInfoTabView> createState() => _FriendInfoTabViewState();
}

class _FriendInfoTabViewState extends State<FriendInfoTabView> {
  final _formKey = GlobalKey<FormState>();
  final _friendInfoController = TextEditingController();

  DateTime? _dob;
  bool _hobbyValidationError = false;
  
  final List<String> _hobbies = [
    'Sport',
    'Movie',
    'Music',
    'Travel',
  ];
  
  final Map<String, bool> _selectedHobbies = {};

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

      setState(() {
        for (var hobby in _hobbies) {
          _selectedHobbies[hobby] = profileProvider.hobbies?.contains(hobby) ?? false;
        }
      });

      if (profileProvider.friendInfo != null) {
        _friendInfoController.text = profileProvider.friendInfo!;
      }
      
    });
  }


  Future<void> _submit() async {
    try{

      setState((){
          _hobbyValidationError = false;
        });

      if (!_formKey.currentState!.validate()) return;
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

      if (authProvider.token == null) return;

      String dobToSave = "";
      if (_dob == null) {
        dobToSave = Utils.formatDate(profileProvider.dob);
      }
      dobToSave = Utils.formatDate(_dob);

      List<String> selected = [];
      for (var key in _selectedHobbies.keys) {
        if (_selectedHobbies[key] == true) {
          selected.add(key);
        }
      }

      if (selected.isEmpty){
        setState((){
          _hobbyValidationError = true;
        });
        return;
      }

      bool success = false;
      success = await profileProvider.updateFriendInfo(authProvider.token, dobToSave, selected, _friendInfoController.text);

      if (success) {
        await profileProvider.loadProfile(authProvider.token);
        CommonWidgets.showSnackBar(context, 'Update successful', backgroundColor: Colors.green);
      }

    } catch (e) {
        CommonWidgets.showSnackBar(context, 'Exception: $e', backgroundColor: Colors.red);
        return ;
      }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {

        return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppTheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(24),
                child: Form(
                key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

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

                    Text(
                      'Date of birth',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    DatePicker(
                      label: 'Date of Birth',
                      initDate: Utils.formatDate(profileProvider.dob),
                      onDateSelected: (date) {
                        setState(() => _dob = date);
                      },
                    ),
                    const SizedBox(height: 16),


                    Text(
                      'Hobby',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    if (_hobbyValidationError) ...[
                        Padding(
                          padding: EdgeInsets.only(left: 16.0),
                          child: Text(
                            'Please select at least one hobby.',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ],
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _hobbies.map((hobby) {
                        return CheckboxListTile(
                          title: Text(hobby),
                          value: _selectedHobbies[hobby] ?? false,
                          onChanged: (bool? value) {
                            setState(() {
                              _selectedHobbies[hobby] = value ?? false;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      controller: _friendInfoController,
                      labelText: 'Something for friend',
                      obscureText: false,
                      minLines: 5,
                      maxLines: 10,
                      validator: (v) => v?.isEmpty ?? true ? 'Please enter something for friend' :
                                v!.length > 500 ? 'Friend info maximum 500 characters' : null,
                    ),
                    const SizedBox(height: 24),

                    profileProvider.isLoading
                    ? const CircularProgressIndicator(color: AppTheme.primary)
                    : 
                      ElevatedButton(
                        onPressed: _submit,
                        child: Text('Save'),
                      ),
                    
                    ],

                  ),
                ),
            ),
          ),
        ]
        );
      }
    );
  }
}
