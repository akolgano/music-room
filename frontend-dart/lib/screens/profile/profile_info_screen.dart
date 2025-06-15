// lib/screens/profile/profile_info_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:mime/mime.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/consolidated_core.dart';
import '../../providers/profile_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/unified_components.dart';

class ProfileInfoScreen extends StatefulWidget {
  const ProfileInfoScreen({Key? key}) : super(key: key);

  @override
  State<ProfileInfoScreen> createState() => _ProfileInfoScreenState();
}

class _ProfileInfoScreenState extends State<ProfileInfoScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? AppConstants.defaultApiBaseUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Profile Information'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Public'),
            Tab(text: 'Private'),
            Tab(text: 'Friends'),
            Tab(text: 'Music'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PublicInfoTab(baseUrl: _baseUrl),
          const _PrivateInfoTab(),
          const _FriendInfoTab(),
          const _MusicPreferenceTab(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _PublicInfoTab extends StatefulWidget {
  final String baseUrl;
  const _PublicInfoTab({required this.baseUrl});

  @override
  State<_PublicInfoTab> createState() => _PublicInfoTabState();
}

class _PublicInfoTabState extends State<_PublicInfoTab> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();
  
  String? _gender;
  XFile? _imageFile;
  String? _imageBase64;
  Uint8List? _imageBytes;
  String? _mimeType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfileData());
  }

  void _loadProfileData() {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    setState(() {
      _gender = profileProvider.gender;
      if (profileProvider.location != null) _locationController.text = profileProvider.location!;
      if (profileProvider.bio != null) _bioController.text = profileProvider.bio!;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null && await _isValidImageFile(picked)) {
      final mimeType = await _getMimeType(picked);
      final bytes = await picked.readAsBytes();

      setState(() {
        _imageBytes = bytes;
        _imageFile = picked;
        _imageBase64 = base64Encode(bytes);
        _mimeType = mimeType;
      });
    }
  }

  Future<bool> _isValidImageFile(XFile file) async {
    final ext = file.name.split('.').last.toLowerCase();
    if (!(ext == 'jpg' || ext == 'jpeg' || ext == 'png')) return false;

    final bytes = await file.readAsBytes();
    final mimeType = lookupMimeType(file.name, headerBytes: bytes);
    return mimeType == 'image/jpeg' || mimeType == 'image/png';
  }

  Future<String?> _getMimeType(XFile file) async {
    final bytes = await file.readAsBytes();
    return lookupMimeType(file.name, headerBytes: bytes);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    if (authProvider.token == null) return;

    try {
      if (_imageFile != null) {
        await profileProvider.updateAvatar(authProvider.token, _imageBase64, _mimeType);
        setState(() {
          _imageFile = null;
          _imageBytes = null;
          _imageBase64 = null;
          _mimeType = null;
        });
      }

      await profileProvider.updatePublicBasic(authProvider.token, _gender, _locationController.text);
      
      await profileProvider.updatePublicBio(authProvider.token, _bioController.text);

      await profileProvider.loadProfile(authProvider.token);
      UnifiedComponents.showSnackBar(context, 'Profile updated successfully', backgroundColor: Colors.green);
    } catch (e) {
      UnifiedComponents.showSnackBar(context, 'Error: $e', backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Card(
                  color: AppTheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text('Avatar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 16),
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: _imageBytes != null
                              ? MemoryImage(_imageBytes!)
                              : (profileProvider.avatar != null
                                  ? NetworkImage('${widget.baseUrl}${profileProvider.avatar!}')
                                  : null),
                          child: _imageBytes == null && profileProvider.avatar == null
                              ? const Icon(Icons.person, size: 50)
                              : null,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _pickImage,
                          child: const Text('Change Avatar'),
                        ),
                      ],
                    ),
                  ),
                ),
                
                Card(
                  color: AppTheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Basic Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 16),
                        
                        const Text('Gender', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

                        UnifiedComponents.textField(
                          controller: _locationController,
                          labelText: 'Current Location',
                          validator: (value) => ValidationUtils.required(value, 'location'),
                        ),
                      ],
                    ),
                  ),
                ),

                Card(
                  color: AppTheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 16),
                        UnifiedComponents.textField(
                          controller: _bioController,
                          labelText: 'About yourself',
                          minLines: 5,
                          maxLines: 10,
                          validator: (value) => ValidationUtils.lengthRange(value, 1, 500, 'Bio'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                profileProvider.isLoading
                    ? const CircularProgressIndicator(color: AppTheme.primary)
                    : UnifiedComponents.primaryButton(
                        text: 'Save Changes',
                        onPressed: _submit,
                        icon: Icons.save,
                      ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PrivateInfoTab extends StatefulWidget {
  const _PrivateInfoTab();

  @override
  State<_PrivateInfoTab> createState() => _PrivateInfoTabState();
}

class _PrivateInfoTabState extends State<_PrivateInfoTab> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _postalCodeController = TextEditingController();
  
  String? _selectedCountry;
  final List<String> _countries = ['Singapore', 'Malaysia', 'Indonesia', 'Thailand', 'United States', 'Canada', 'United Kingdom', 'Australia'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfileData());
  }

  void _loadProfileData() {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    setState(() {
      if (profileProvider.firstName != null) _firstNameController.text = profileProvider.firstName!;
      if (profileProvider.lastName != null) _lastNameController.text = profileProvider.lastName!;
      if (profileProvider.phone != null) _phoneController.text = profileProvider.phone!;
      if (profileProvider.street != null) _streetController.text = profileProvider.street!;
      if (profileProvider.postalCode != null) _postalCodeController.text = profileProvider.postalCode!;
      _selectedCountry = profileProvider.country;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    if (authProvider.token == null) return;

    try {
      await profileProvider.updatePrivateInfo(
        authProvider.token,
        _firstNameController.text,
        _lastNameController.text,
        _phoneController.text,
        _streetController.text,
        _selectedCountry,
        _postalCodeController.text,
      );

      await profileProvider.loadProfile(authProvider.token);
      UnifiedComponents.showSnackBar(context, 'Private info updated successfully', backgroundColor: Colors.green);
    } catch (e) {
      UnifiedComponents.showSnackBar(context, 'Error: $e', backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Card(
              color: AppTheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('Private Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 24),
                    
                    UnifiedComponents.textField(
                      controller: _firstNameController,
                      labelText: 'First Name',
                      validator: (value) => ValidationUtils.lengthRange(value, 1, 50, 'First name'),
                    ),
                    const SizedBox(height: 16),
                    
                    UnifiedComponents.textField(
                      controller: _lastNameController,
                      labelText: 'Last Name',
                      validator: (value) => ValidationUtils.lengthRange(value, 1, 50, 'Last name'),
                    ),
                    const SizedBox(height: 16),
                    
                    UnifiedComponents.textField(
                      controller: _phoneController,
                      labelText: 'Phone Number',
                      validator: ValidationUtils.phoneNumber,
                    ),
                    const SizedBox(height: 16),
                    
                    UnifiedComponents.textField(
                      controller: _streetController,
                      labelText: 'Address',
                      minLines: 3,
                      maxLines: 5,
                      validator: (value) => ValidationUtils.lengthRange(value, 1, 100, 'Address'),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _selectedCountry,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        border: OutlineInputBorder(),
                      ),
                      items: _countries.map((country) => DropdownMenuItem(value: country, child: Text(country))).toList(),
                      onChanged: (value) => setState(() => _selectedCountry = value),
                      validator: (value) => value == null ? 'Please select a country' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    UnifiedComponents.textField(
                      controller: _postalCodeController,
                      labelText: 'Postal Code',
                      validator: (value) => ValidationUtils.lengthRange(value, 1, 10, 'Postal code'),
                    ),
                    const SizedBox(height: 24),

                    profileProvider.isLoading
                        ? const CircularProgressIndicator(color: AppTheme.primary)
                        : UnifiedComponents.primaryButton(
                            text: 'Save Changes',
                            onPressed: _submit,
                            icon: Icons.save,
                          ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FriendInfoTab extends StatefulWidget {
  const _FriendInfoTab();

  @override
  State<_FriendInfoTab> createState() => _FriendInfoTabState();
}

class _FriendInfoTabState extends State<_FriendInfoTab> {
  final _formKey = GlobalKey<FormState>();
  final _friendInfoController = TextEditingController();
  final _dobController = TextEditingController();
  
  DateTime? _selectedDate;
  final List<String> _hobbies = ['Sport', 'Movie', 'Music', 'Travel'];
  final Map<String, bool> _selectedHobbies = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfileData());
  }

  void _loadProfileData() {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    setState(() {
      if (profileProvider.friendInfo != null) _friendInfoController.text = profileProvider.friendInfo!;
      if (profileProvider.dob != null) {
        _selectedDate = profileProvider.dob;
        _dobController.text = _formatDate(profileProvider.dob);
      }
      for (var hobby in _hobbies) {
        _selectedHobbies[hobby] = profileProvider.hobbies?.contains(hobby) ?? false;
      }
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _dobController.text = _formatDate(pickedDate);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final selected = _selectedHobbies.entries.where((entry) => entry.value).map((entry) => entry.key).toList();
    if (selected.isEmpty) {
      UnifiedComponents.showSnackBar(context, 'Please select at least one hobby', backgroundColor: Colors.red);
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    if (authProvider.token == null) return;

    try {
      await profileProvider.updateFriendInfo(
        authProvider.token,
        _selectedDate != null ? _formatDate(_selectedDate) : null,
        selected,
        _friendInfoController.text,
      );

      await profileProvider.loadProfile(authProvider.token);
      UnifiedComponents.showSnackBar(context, 'Friend info updated successfully', backgroundColor: Colors.green);
    } catch (e) {
      UnifiedComponents.showSnackBar(context, 'Error: $e', backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Card(
              color: AppTheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Friends Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 24),
                    
                    const Text('Date of Birth', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _dobController,
                      readOnly: true,
                      onTap: _selectDate,
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth',
                        suffixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text('Hobbies', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Column(
                      children: _hobbies.map((hobby) => CheckboxListTile(
                        title: Text(hobby),
                        value: _selectedHobbies[hobby] ?? false,
                        onChanged: (bool? value) => setState(() => _selectedHobbies[hobby] = value ?? false),
                      )).toList(),
                    ),
                    const SizedBox(height: 16),

                    UnifiedComponents.textField(
                      controller: _friendInfoController,
                      labelText: 'About you (for friends)',
                      minLines: 5,
                      maxLines: 10,
                      validator: (value) => ValidationUtils.lengthRange(value, 1, 500, 'Friend info'),
                    ),
                    const SizedBox(height: 24),

                    profileProvider.isLoading
                        ? const CircularProgressIndicator(color: AppTheme.primary)
                        : UnifiedComponents.primaryButton(
                            text: 'Save Changes',
                            onPressed: _submit,
                            icon: Icons.save,
                          ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MusicPreferenceTab extends StatefulWidget {
  const _MusicPreferenceTab();

  @override
  State<_MusicPreferenceTab> createState() => _MusicPreferenceTabState();
}

class _MusicPreferenceTabState extends State<_MusicPreferenceTab> {
  final List<String> _preferences = ['Classical', 'Jazz', 'Pop', 'Rock', 'Rap', 'R&B', 'Techno'];
  final Map<String, bool> _selectedPreferences = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfileData());
  }

  void _loadProfileData() {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    setState(() {
      for (var pref in _preferences) {
        _selectedPreferences[pref] = profileProvider.musicPreferences?.contains(pref) ?? false;
      }
    });
  }

  Future<void> _submit() async {
    final selected = _selectedPreferences.entries.where((entry) => entry.value).map((entry) => entry.key).toList();
    if (selected.isEmpty) {
      UnifiedComponents.showSnackBar(context, 'Please select at least one music preference', backgroundColor: Colors.red);
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    if (authProvider.token == null) return;

    try {
      await profileProvider.updateMusicPreferences(authProvider.token, selected);
      await profileProvider.loadProfile(authProvider.token);
      UnifiedComponents.showSnackBar(context, 'Music preferences updated successfully', backgroundColor: Colors.green);
    } catch (e) {
      UnifiedComponents.showSnackBar(context, 'Error: $e', backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            color: AppTheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Music Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 24),
                  
                  Column(
                    children: _preferences.map((pref) => CheckboxListTile(
                      title: Text(pref),
                      value: _selectedPreferences[pref] ?? false,
                      onChanged: (bool? value) => setState(() => _selectedPreferences[pref] = value ?? false),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),

                  profileProvider.isLoading
                      ? const CircularProgressIndicator(color: AppTheme.primary)
                      : UnifiedComponents.primaryButton(
                          text: 'Save Changes',
                          onPressed: _submit,
                          icon: Icons.save,
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
