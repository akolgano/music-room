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
import '../../utils/dialog_utils.dart';
import '../base_screen.dart';

class DeviceManagementScreen extends StatefulWidget {
  const DeviceManagementScreen({Key? key}) : super(key: key);

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends BaseScreen<DeviceManagementScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  List<Device> _allDevices = [];
  List<int> _friends = [];

  @override
  String get screenTitle => 'Device Management';

  @override
  List<Widget> get actions => [
    IconButton(
      icon: const Icon(Icons.refresh),
      onPressed: _loadData,
    ),
  ];

  @override
  Widget? get floatingActionButton => FloatingActionButton.extended(
    onPressed: _registerNewDevice,
    backgroundColor: AppTheme.primary,
    foregroundColor: Colors.black,
    icon: const Icon(Icons.add),
    label: const Text('Register Device'),
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  PreferredSizeWidget? buildAppBar() {
    return buildStandardAppBar(
      actions: actions,
    ) as PreferredSizeWidget;
  }

  @override
  Widget buildContent() {
    return buildTabScaffold(
      tabs: const [
        Tab(text: 'My Devices'),
        Tab(text: 'Control Delegation'),
      ],
      tabViews: [
        _buildMyDevicesTab(),
        _buildControlDelegationTab(),
      ],
      controller: _tabController,
    );
  }

  Future<void> _loadData() async {
    await runAsyncAction(
      () async {
        final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
        final friendProvider = Provider.of<FriendProvider>(context, listen: false);
        
        await Future.wait([
          deviceProvider.fetchUserDevices(auth.token!),
          friendProvider.fetchFriends(auth.token!),
          _loadAllDevices(),
        ]);
        
        _friends = friendProvider.friends;
      },
      errorMessage: 'Failed to load device data',
    );
  }

  Future<void> _loadAllDevices() async {
    await runAsync(() async {
      _allDevices = await _apiService.getAllUserDevices(auth.token!);
    });
  }

  Widget _buildMyDevicesTab() {
    return Consumer<DeviceProvider>(
      builder: (context, deviceProvider, _) {
        if (deviceProvider.userDevices.isEmpty) {
          return EmptyState(
            icon: Icons.devices,
            title: 'No devices registered',
            subtitle: 'Register your first device to start using Music Room',
            buttonText: 'Register Device',
            onButtonPressed: _registerNewDevice,
          );
        }

        return buildListWithRefresh<Device>(
          items: deviceProvider.userDevices,
          onRefresh: _loadData,
          itemBuilder: (device, index) {
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
                        StatusIndicator(
                          isConnected: device.isActive,
                          connectedText: 'Active',
                          disconnectedText: 'Inactive',
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
                  onSelected: (value) => _handleDeviceAction(value, device, deviceProvider),
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
        );
      },
    );
  }

  Widget _buildControlDelegationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoBanner(
            title: 'Control Delegation',
            message: 'Allow your friends to control music playback on your devices. This enables collaborative playlist management and remote control.',
            icon: Icons.info,
          ),
          const SizedBox(height: 16),
          const SectionTitle('Delegate to Friends'),
          const SizedBox(height: 8),
          if (_friends.isEmpty)
            EmptyState(
              icon: Icons.people_outline,
              title: 'No friends to delegate to',
              subtitle: 'Add friends first to delegate device control',
              buttonText: 'Add Friends',
              onButtonPressed: () => navigateTo(AppRoutes.friends),
            )
          else
            Column(
              children: _friends.map((friendId) => Card(
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
              )).toList(),
            ),
        ],
      ),
    );
  }

  void _handleDeviceAction(String action, Device device, DeviceProvider deviceProvider) {
    switch (action) {
      case 'set_current':
        deviceProvider.setCurrentDevice(device);
        showSuccess('Device set as current');
        break;
      case 'delegate':
        _showDelegateDialog(device);
        break;
      case 'check_permissions':
        _checkDevicePermissions(device);
        break;
    }
  }

  Future<void> _registerNewDevice() async {
    final deviceName = await DialogUtils.showTextInputDialog(
      context,
      title: 'Register New Device',
      hintText: 'Enter device name',
      validator: (value) => value?.isEmpty ?? true ? 'Please enter a device name' : null,
    );

    if (deviceName != null && deviceName.isNotEmpty) {
      await runAsyncAction(
        () async {
          final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
          
          final uuid = 'device-${DateTime.now().millisecondsSinceEpoch}';
          final licenseKey = _generateLicenseKey();

          final device = await deviceProvider.registerDevice(
            uuid,
            licenseKey,
            deviceName,
            auth.token!,
          );

          if (device != null) {
            _loadData();
          }
        },
        successMessage: 'Device registered successfully!',
        errorMessage: 'Failed to register device',
      );
    }
  }

  void _showDelegateDialog(Device device) {
    if (_friends.isEmpty) {
      showError('No friends to delegate to');
      return;
    }

    DialogUtils.showSelectionDialog<int>(
      context: context,
      title: 'Delegate Control: ${device.name}',
      items: _friends,
      itemTitle: (friendId) => 'Friend #$friendId',
      itemLeading: (friendId) => CircleAvatar(
        backgroundColor: Colors.primaries[friendId % Colors.primaries.length],
        child: const Icon(Icons.person, color: Colors.white),
      ),
    ).then((selectedIndex) {
      if (selectedIndex != null) {
        _delegateControl(device, _friends[selectedIndex]);
      }
    });
  }

  void _showDelegateToFriendDialog(int friendId) {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final devices = deviceProvider.userDevices;

    if (devices.isEmpty) {
      showError('No devices to delegate');
      return;
    }

    DialogUtils.showSelectionDialog<Device>(
      context: context,
      title: 'Delegate to Friend #$friendId',
      items: devices,
      itemTitle: (device) => device.name,
      itemSubtitle: (device) => 'UUID: ${device.uuid}',
      itemLeading: (device) => Icon(
        device.isActive ? Icons.smartphone : Icons.smartphone_outlined,
        color: Colors.white,
      ),
    ).then((selectedIndex) {
      if (selectedIndex != null) {
        _delegateControl(devices[selectedIndex], friendId);
      }
    });
  }

  Future<void> _delegateControl(Device device, int friendId) async {
    await runAsyncAction(
      () async {
        await _apiService.delegateDeviceControl(
          deviceUuid: device.uuid,
          delegateUserId: friendId,
          canControl: true,
          token: auth.token!,
        );
      },
      successMessage: 'Control delegated to Friend #$friendId for ${device.name}',
      errorMessage: 'Failed to delegate control',
    );
  }

  Future<void> _checkDevicePermissions(Device device) async {
    try {
      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
      final canControl = await deviceProvider.checkControlPermission(
        device.uuid,
        auth.token!,
      );
      
      DialogUtils.showInfoDialog(
        context: context,
        title: 'Device Permissions: ${device.name}',
        icon: canControl ? Icons.check_circle : Icons.cancel,
        message: canControl ? 'You can control this device' : 'No control permission',
        points: [
          'UUID: ${device.uuid}',
          'Status: ${device.isActive ? 'Active' : 'Inactive'}',
          'Permission: ${canControl ? 'Granted' : 'Denied'}',
        ],
      );
    } catch (e) {
      showError('Failed to check permissions');
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
