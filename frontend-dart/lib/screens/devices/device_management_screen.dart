// lib/screens/devices/device_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/friend_provider.dart';
import '../../core/app_core.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';
import '../../services/api_service.dart';
import '../../utils/snackbar_utils.dart';

class DeviceManagementScreen extends StatefulWidget {
  const DeviceManagementScreen({Key? key}) : super(key: key);

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  List<Device> _allDevices = [];
  List<int> _friends = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
      final friendProvider = Provider.of<FriendProvider>(context, listen: false);
      
      await Future.wait([
        deviceProvider.fetchUserDevices(authProvider.token!),
        friendProvider.fetchFriends(authProvider.token!),
        _loadAllDevices(),
      ]);
      
      if (mounted) {
        setState(() {
          _friends = friendProvider.friends;
        });
      }
    } catch (e) {
      SnackBarUtils.showError(context, 'Failed to load device data');
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadAllDevices() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _allDevices = await _apiService.getAllUserDevices(authProvider.token!);
    } catch (e) {
      print('Error loading all devices: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Device Management'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'My Devices'),
            Tab(text: 'Control Delegation'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? CommonWidgets.loadingWidget()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMyDevicesTab(),
                _buildControlDelegationTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _registerNewDevice,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Register Device'),
      ),
    );
  }

  Widget _buildMyDevicesTab() {
    return Consumer<DeviceProvider>(
      builder: (context, deviceProvider, _) {
        if (deviceProvider.userDevices.isEmpty) {
          return CommonWidgets.emptyState(
            icon: Icons.devices,
            title: 'No devices registered',
            subtitle: 'Register your first device to start using Music Room',
            buttonText: 'Register Device',
            onButtonPressed: _registerNewDevice,
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          color: AppTheme.primary,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: deviceProvider.userDevices.length,
            itemBuilder: (context, index) {
              final device = deviceProvider.userDevices[index];
              final isCurrentDevice = deviceProvider.currentDevice?.id == device.id;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: isCurrentDevice ? AppTheme.primary.withOpacity(0.1) : AppTheme.surface,
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCurrentDevice ? AppTheme.primary : AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      device.isActive ? Icons.smartphone : Icons.smartphone_outlined,
                      color: isCurrentDevice ? Colors.black : Colors.white,
                    ),
                  ),
                  title: Text(
                    device.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: isCurrentDevice ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UUID: ${device.uuid}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: device.isActive ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            device.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: device.isActive ? Colors.green : Colors.red,
                              fontSize: 12,
                            ),
                          ),
                          if (isCurrentDevice) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Current',
                                style: TextStyle(color: Colors.black, fontSize: 10),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'set_current':
                          deviceProvider.setCurrentDevice(device);
                          SnackBarUtils.showSuccess(context, 'Device set as current');
                          break;
                        case 'delegate':
                          _showDelegateDialog(device);
                          break;
                        case 'check_permissions':
                          _checkDevicePermissions(device);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (!isCurrentDevice)
                        const PopupMenuItem(
                          value: 'set_current',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, size: 16),
                              SizedBox(width: 8),
                              Text('Set as Current'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delegate',
                        child: Row(
                          children: [
                            Icon(Icons.share, size: 16),
                            SizedBox(width: 8),
                            Text('Delegate Control'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'check_permissions',
                        child: Row(
                          children: [
                            Icon(Icons.security, size: 16),
                            SizedBox(width: 8),
                            Text('Check Permissions'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildControlDelegationTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: AppTheme.primary.withOpacity(0.1),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: AppTheme.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Control Delegation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Allow your friends to control music playback on your devices. '
                    'This enables collaborative playlist management and remote control.',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Delegate to Friends',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          if (_friends.isEmpty)
            Card(
              color: AppTheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.people_outline, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No friends to delegate to', 
                                 style: TextStyle(color: Colors.white, fontSize: 16)),
                      const SizedBox(height: 8),
                      const Text('Add friends first to delegate device control', 
                                 style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.friends),
                        icon: const Icon(Icons.person_add),
                        label: const Text('Add Friends'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _friends.length,
                itemBuilder: (context, index) {
                  final friendId = _friends[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: AppTheme.surface,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.primaries[friendId % Colors.primaries.length],
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text('Friend #$friendId', 
                                 style: const TextStyle(color: Colors.white)),
                      subtitle: Text('User ID: $friendId', 
                                   style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      trailing: ElevatedButton.icon(
                        onPressed: () => _showDelegateToFriendDialog(friendId),
                        icon: const Icon(Icons.share, size: 16),
                        label: const Text('Delegate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _registerNewDevice() async {
    final deviceName = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Register New Device', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter device name',
              hintStyle: TextStyle(color: Colors.grey),
            ),
            style: const TextStyle(color: Colors.white),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Register'),
            ),
          ],
        );
      },
    );

    if (deviceName != null && deviceName.isNotEmpty) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
        
        final uuid = 'device-${DateTime.now().millisecondsSinceEpoch}';
        final licenseKey = _generateLicenseKey();

        final device = await deviceProvider.registerDevice(
          uuid,
          licenseKey,
          deviceName,
          authProvider.token!,
        );

        if (device != null) {
          SnackBarUtils.showSuccess(context, 'Device registered successfully!');
          _loadData();
        }
      } catch (e) {
        SnackBarUtils.showError(context, 'Failed to register device');
      }
    }
  }

  void _showDelegateDialog(Device device) {
    if (_friends.isEmpty) {
      SnackBarUtils.showError(context, 'No friends to delegate to');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Delegate Control: ${device.name}', 
                   style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _friends.length,
            itemBuilder: (context, index) {
              final friendId = _friends[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.primaries[friendId % Colors.primaries.length],
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: Text('Friend #$friendId', style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop();
                  _delegateControl(device, friendId);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDelegateToFriendDialog(int friendId) {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final devices = deviceProvider.userDevices;

    if (devices.isEmpty) {
      SnackBarUtils.showError(context, 'No devices to delegate');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Delegate to Friend #$friendId', 
                   style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return ListTile(
                leading: Icon(
                  device.isActive ? Icons.smartphone : Icons.smartphone_outlined,
                  color: Colors.white,
                ),
                title: Text(device.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text('UUID: ${device.uuid}', 
                             style: const TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.of(context).pop();
                  _delegateControl(device, friendId);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _delegateControl(Device device, int friendId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      await _apiService.delegateDeviceControl(
        deviceUuid: device.uuid,
        delegateUserId: friendId,
        canControl: true,
        token: authProvider.token!,
      );
      
      SnackBarUtils.showSuccess(context, 
        'Control delegated to Friend #$friendId for ${device.name}');
    } catch (e) {
      SnackBarUtils.showError(context, 'Failed to delegate control');
    }
  }

  Future<void> _checkDevicePermissions(Device device) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
      
      final canControl = await deviceProvider.checkControlPermission(
        device.uuid,
        authProvider.token!,
      );
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text('Device Permissions: ${device.name}', 
                     style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    canControl ? Icons.check_circle : Icons.cancel,
                    color: canControl ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    canControl ? 'You can control this device' : 'No control permission',
                    style: TextStyle(
                      color: canControl ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'UUID: ${device.uuid}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      SnackBarUtils.showError(context, 'Failed to check permissions');
    }
  }

  String _generateLicenseKey() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(16, (index) => 
      chars[(DateTime.now().millisecondsSinceEpoch + index) % chars.length]).join();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
