// lib/screens/music/device_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../core/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/dialog_helper.dart';
import 'dart:math';

class DeviceManagementScreen extends StatefulWidget {
  const DeviceManagementScreen({Key? key}) : super(key: key);

  @override
  _DeviceManagementScreenState createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  bool _isLoading = false;
  List<Device> _devices = [];
  List<MusicControlDelegate> _delegates = [];

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      
      await musicProvider.fetchDevices(authProvider.token!);
      setState(() {
        _devices = List.from(musicProvider.devices);
        _delegates = List.from(musicProvider.delegates);
      });
    } catch (e) {
      _showSnackBar('Error loading devices: $e', isError: true);
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _registerDevice() async {
    final deviceName = await DialogHelper.showTextInput(
      context,
      title: 'Register New Device',
      hintText: 'Enter device name',
    );

    if (deviceName == null || deviceName.isEmpty) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);

      final uuid = _generateUUID();
      final licenseKey = _generateLicenseKey();

      final device = await musicProvider.registerDevice(
        uuid,
        licenseKey,
        deviceName,
        authProvider.token!,
      );

      if (device != null) {
        setState(() {
          _devices.add(device);
        });
        _showSnackBar('Device registered successfully');
      }
    } catch (e) {
      _showSnackBar('Error registering device: $e', isError: true);
    }
  }

  Future<void> _delegateControl(Device device) async {
    final userId = await DialogHelper.showTextInput(
      context,
      title: 'Delegate Control',
      hintText: 'Enter user ID to delegate control to',
    );

    if (userId == null || userId.isEmpty) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);

      final delegate = await musicProvider.delegateControl(
        device.uuid,
        userId,
        true, 
        authProvider.token!,
      );

      if (delegate != null) {
        setState(() {
          _delegates.add(delegate);
        });
        _showSnackBar('Control delegated successfully');
      }
    } catch (e) {
      _showSnackBar('Error delegating control: $e', isError: true);
    }
  }

  Future<void> _checkControlPermission(Device device) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);

      final canControl = await musicProvider.checkControlPermission(
        device.uuid,
        authProvider.token!,
      );

      _showSnackBar(
        canControl 
          ? 'You have control permission for this device'
          : 'You do not have control permission for this device',
        isError: !canControl,
      );
    } catch (e) {
      _showSnackBar('Error checking permission: $e', isError: true);
    }
  }

  String _generateUUID() {
    final random = Random();
    return 'device-${random.nextInt(999999).toString().padLeft(6, '0')}';
  }

  String _generateLicenseKey() {
    final random = Random();
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(16, (index) => chars[random.nextInt(chars.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Device Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDevices,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDevicesSection(),
                  const SizedBox(height: 32),
                  _buildDelegatesSection(),
                  const SizedBox(height: 32),
                  _buildInfoSection(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _registerDevice,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.black),
        tooltip: 'Register New Device',
      ),
    );
  }

  Widget _buildDevicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Devices',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        if (_devices.isEmpty)
          const EmptyState(
            icon: Icons.devices,
            title: 'No devices registered',
            subtitle: 'Register your first device to start controlling music playback',
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _devices.length,
            itemBuilder: (context, index) {
              final device = _devices[index];
              return Card(
                color: AppTheme.surface,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: device.isActive ? Colors.green : Colors.grey,
                    child: Icon(
                      Icons.devices,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    'Device ${device.uuid}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status: ${device.isActive ? 'Active' : 'Inactive'}',
                        style: TextStyle(
                          color: device.isActive ? Colors.green : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'License: ${device.licenseKey}',
                        style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 10),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'delegate':
                          _delegateControl(device);
                          break;
                        case 'check':
                          _checkControlPermission(device);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'delegate',
                        child: Text('Delegate Control'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'check',
                        child: Text('Check Permission'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildDelegatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delegated Controls',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        if (_delegates.isEmpty)
          const EmptyState(
            icon: Icons.admin_panel_settings,
            title: 'No delegated controls',
            subtitle: 'Delegate control to other users to let them control your devices',
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _delegates.length,
            itemBuilder: (context, index) {
              final delegate = _delegates[index];
              return Card(
                color: AppTheme.surface,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: delegate.canControl ? AppTheme.primary : Colors.grey,
                    child: Icon(
                      delegate.canControl ? Icons.check : Icons.block,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    'User: ${delegate.delegate}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Can Control: ${delegate.canControl ? 'Yes' : 'No'}',
                        style: TextStyle(
                          color: delegate.canControl ? Colors.green : Colors.red,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Created: ${delegate.createdAt.toLocal().toString().split(' ')[0]}',
                        style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About Device Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text(
              'Device management allows you to:',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Register your devices for music control',
              style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14),
            ),
            const Text(
              '• Delegate control to other users',
              style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14),
            ),
            const Text(
              '• Check control permissions',
              style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14),
            ),
            const Text(
              '• Manage collaborative music experiences',
              style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'Note: This is a demo implementation. In a production app, device registration would be handled automatically when the app is installed.',
              style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
