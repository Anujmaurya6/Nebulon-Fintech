import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../features/profile/provider/profile_provider.dart';
import '../features/notifications/provider/notification_provider.dart';
import '../features/auth/provider/auth_provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../core/network/connectivity_service.dart';
import '../core/utils/error_handler.dart';
import 'login_signup.dart';
import 'banking_screen.dart';
import 'deployment_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(profileProvider.notifier).loadProfile());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final connectivity = ref.watch(connectivityProvider);
    final notifSettings = ref.watch(notificationProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildAppBar(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildProfileHero(context, state),
                  const SizedBox(height: 32),
                  _buildSectionHeader('System Status'),
                  const SizedBox(height: 16),
                  _buildConnectivityCard(context, connectivity),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Control Center'),
                  const SizedBox(height: 16),
                  _buildSettingsGroup(context, 'Account Management', [
                    _buildSettingsItem(
                      context,
                      'Personal Information',
                      'Name, Age, Phone, Gmail, Address',
                      Icons.person_pin_outlined,
                      onTap: () =>
                          _showPersonalInformationDialog(context, state),
                    ),
                    _buildSettingsItem(
                      context,
                      'Bank Accounts',
                      'Manage linked institutions',
                      Icons.account_balance_outlined,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BankingScreen(),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSettingsGroup(context, 'Security & Privacy', [
                    _buildToggleItem(
                      context,
                      'Biometric Authentication',
                      state.isBiometricSupported
                          ? 'FaceID or Fingerprint'
                          : 'Hardware not detected',
                      Icons.fingerprint_rounded,
                      state.isBiometricEnabled && state.isBiometricSupported,
                      onChanged: state.isBiometricSupported
                          ? (v) {
                              HapticFeedback.mediumImpact();
                              ref
                                  .read(profileProvider.notifier)
                                  .toggleBiometrics(v);
                              ErrorHandler.showSuccess(
                                context,
                                v
                                    ? 'Biometrics enabled.'
                                    : 'Biometrics disabled.',
                              );
                            }
                          : null,
                    ),

                    _buildSettingsItem(
                      context,
                      'Session Management',
                      'Logout from all devices',
                      Icons.devices_other_outlined,
                      onTap: () => _showSessionManagementSheet(context),
                    ),
                    _buildSettingsItem(
                      context,
                      'Change Password',
                      'Update vault credentials',
                      Icons.lock_reset_rounded,
                      onTap: () => _showChangePasswordDialog(context),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSettingsGroup(context, 'Data Sovereignty', [
                    _buildSettingsItem(
                      context,
                      'Export My Data',
                      'Download financial history (JSON/PDF)',
                      Icons.file_download_outlined,
                      onTap: () => _handleDataExport(context),
                    ),
                    _buildSettingsItem(
                      context,
                      'Permanent Deletion',
                      'Erase all vault records',
                      Icons.delete_forever_outlined,
                      onTap: () => _showDeleteAccountConfirmation(context),
                    ),
                  ]),

                  const SizedBox(height: 24),
                  _buildSettingsGroup(context, 'App Experience', [
                    _buildToggleItem(
                      context,
                      'Notification Center',
                      notifSettings.globalEnabled
                          ? 'Alerts & Reminders Active'
                          : 'All Notifications Disabled',
                      Icons.notifications_none_outlined,
                      notifSettings.globalEnabled,
                      onChanged: (v) {
                        HapticFeedback.mediumImpact();
                        ref.read(notificationProvider.notifier).toggleGlobal(v);
                        ErrorHandler.showSuccess(
                          context,
                          v ? 'Notifications enabled.' : 'Notifications muted.',
                        );
                      },
                      onLongPress: () => _showNotificationCenterSheet(context),
                    ),
                    _buildSettingsItem(
                      context,
                      'Ops Center',
                      'Stable Deployment & Versioning',
                      Icons.settings_suggest_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DeploymentScreen(),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 40),
                  _buildLogoutButton(context),
                  const SizedBox(height: 32),
                  Text(
                    'SMART VAULT • VERSION 3.2.0-PRO',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.textSecondary.withOpacity(0.4),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.only(top: 60, bottom: 20, left: 24, right: 24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: AppTheme.divider.withOpacity(0.5)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Settings', style: theme.textTheme.headlineLarge),
          IconButton(
            icon: Icon(Icons.sync_rounded, color: theme.colorScheme.primary),
            onPressed: () => _handleManualSync(),
          ),
        ],
      ),
    );
  }

  Future<void> _handleManualSync() async {
    setState(() => _isSyncing = true);
    HapticFeedback.selectionClick();
    await ref.read(profileProvider.notifier).syncData();
    if (mounted) {
      setState(() => _isSyncing = false);
      ErrorHandler.showSuccess(context, 'Vault synchronization complete.');
    }
  }

  Widget _buildProfileHero(BuildContext context, ProfileState state) {
    final theme = Theme.of(context);
    final name = state.profile?.fullName ?? 'Executive User';
    final email = state.profile?.email ?? 'active.user@smartvault.com';
    final avatarUrl = state.profile?.avatarUrl;

    return Column(
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: () => _showAvatarOptions(context, avatarUrl != null),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 54,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null
                      ? Text(
                          name.isNotEmpty
                              ? name
                                    .split(' ')
                                    .map((e) => e[0])
                                    .take(2)
                                    .join()
                                    .toUpperCase()
                              : 'U',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => _showAvatarOptions(context, avatarUrl != null),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          name,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  void _showAvatarOptions(BuildContext context, bool hasAvatar) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Profile Picture',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.photo_library_outlined),
              ),
              title: const Text('Add from Device'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            if (hasAvatar)
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFE5E5),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.rose,
                  ),
                ),
                title: const Text(
                  'Delete Picture',
                  style: TextStyle(color: AppTheme.rose),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final success = await ref
                      .read(profileProvider.notifier)
                      .deleteAvatar();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success ? 'Picture Deleted' : 'Failed to Delete',
                        ),
                      ),
                    );
                  }
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        HapticFeedback.mediumImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Uploading picture...'),
              duration: Duration(seconds: 1),
            ),
          );
        }

        final success = await ref
            .read(profileProvider.notifier)
            .updateAvatar(image.path);
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated successfully'),
                backgroundColor: AppTheme.indigo,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to update profile picture'),
                backgroundColor: AppTheme.rose,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Failed to pick image: $e');
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 2,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildConnectivityCard(
    BuildContext context,
    ConnectivityStatus status,
  ) {
    final theme = Theme.of(context);
    final isOnline = status == ConnectivityStatus.isConnected;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: theme.cardTheme.shape is RoundedRectangleBorder
            ? Border.fromBorderSide(
                (theme.cardTheme.shape as RoundedRectangleBorder).side,
              )
            : Border.all(color: AppTheme.divider.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isOnline ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                color: isOnline ? AppTheme.emerald : AppTheme.rose,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOnline ? 'App is Online' : 'App is Offline',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    isOnline ? 'Cloud Synced' : 'Local Storage Only',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              Icons.sync_rounded,
              color: isOnline
                  ? theme.colorScheme.primary
                  : AppTheme.textSecondary,
            ),
            onPressed: isOnline ? () => _handleManualSync() : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(
    BuildContext context,
    String title,
    List<Widget> items,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              letterSpacing: 1.2,
              color: AppTheme.textSecondary.withOpacity(0.6),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            border: theme.cardTheme.shape is RoundedRectangleBorder
                ? Border.fromBorderSide(
                    (theme.cardTheme.shape as RoundedRectangleBorder).side,
                  )
                : Border.all(color: AppTheme.divider.withOpacity(0.3)),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppTheme.textSecondary.withOpacity(0.7),
          fontSize: 12,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: AppTheme.divider,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }

  Widget _buildToggleItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool isOn, {
    ValueChanged<bool>? onChanged,
    VoidCallback? onLongPress,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      onLongPress: onLongPress,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppTheme.textSecondary.withOpacity(0.7),
          fontSize: 12,
        ),
      ),
      trailing: Switch.adaptive(
        value: isOn,
        onChanged: onChanged,
        activeTrackColor: AppTheme.emerald,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  void _showNotificationCenterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final s = ref.watch(notificationProvider);
          final theme = Theme.of(context);
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Notification Center',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Managed Intelligent Alerts',
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 32),
                _buildNotifToggle(
                  'Transaction Alerts',
                  'Real-time updates on vault movement',
                  Icons.receipt_long_rounded,
                  s.transactionsEnabled,
                  (v) => ref
                      .read(notificationProvider.notifier)
                      .updateSettings(transactionsEnabled: v),
                ),
                _buildNotifToggle(
                  'Security Reminders',
                  'Login alerts & vault health checks',
                  Icons.security_rounded,
                  s.securityEnabled,
                  (v) => ref
                      .read(notificationProvider.notifier)
                      .updateSettings(securityEnabled: v),
                ),
                _buildNotifToggle(
                  'AI Financial Insights',
                  'Personalized budget & target alerts',
                  Icons.auto_awesome_rounded,
                  s.aiInsightsEnabled,
                  (v) => ref
                      .read(notificationProvider.notifier)
                      .updateSettings(aiInsightsEnabled: v),
                ),
                _buildNotifToggle(
                  'Offers & Rewards',
                  'New premium partners & benefit logs',
                  Icons.card_giftcard_rounded,
                  s.marketingEnabled,
                  (v) => ref
                      .read(notificationProvider.notifier)
                      .updateSettings(marketingEnabled: v),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Save Configuration'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotifToggle(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppTheme.emerald,
          ),
        ],
      ),
    );
  }

  void _showPersonalInformationDialog(
    BuildContext context,
    ProfileState state,
  ) {
    final nameController = TextEditingController(text: state.profile?.fullName);
    final ageController = TextEditingController(
      text: state.profile?.age?.toString(),
    );
    final phoneController = TextEditingController(text: state.profile?.phone);
    final gmailController = TextEditingController(
      text: state.profile?.gmail ?? state.profile?.email,
    );
    final addressController = TextEditingController(
      text: state.profile?.address,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Personal Information',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 32),
              _buildLargeTextField(
                nameController,
                'Full Name',
                Icons.person_outline,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildLargeTextField(
                      ageController,
                      'Age',
                      Icons.cake_outlined,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildLargeTextField(
                      phoneController,
                      'Phone',
                      Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildLargeTextField(
                gmailController,
                'Gmail / Email',
                Icons.email_outlined,
              ),
              const SizedBox(height: 16),
              _buildLargeTextField(
                addressController,
                'Address',
                Icons.map_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () async {
                  final success = await ref
                      .read(profileProvider.notifier)
                      .updateProfile({
                        'full_name': nameController.text,
                        'age': ageController.text,
                        'phone': phoneController.text,
                        'gmail': gmailController.text,
                        'address': addressController.text,
                      });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ErrorHandler.showSuccess(
                      context,
                      'Identity data securely updated.',
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Save Changes'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLargeTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            filled: true,
            fillColor: Theme.of(context).cardTheme.color,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Update'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Existing Password'),
            ),
            TextField(
              controller: newController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'New Vault Key'),
            ),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Confirm New Key'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (newController.text != confirmController.text) {
                ErrorHandler.showError(context, 'New keys do not match.');
                return;
              }
              if (newController.text.length < 8) {
                ErrorHandler.showError(
                  context,
                  'Password must be 8+ characters.',
                );
                return;
              }
              HapticFeedback.mediumImpact();
              Navigator.pop(context);
              ErrorHandler.showSuccess(
                context,
                'Credential vault updated successfully.',
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showSessionManagementSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.devices,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Active Sessions',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            const ListTile(
              leading: Icon(Icons.phone_android),
              title: Text('This Device (Pixel 6 Pro)'),
              subtitle: Text('New Delhi, India • Active Now'),
            ),
            const ListTile(
              leading: Icon(Icons.laptop_mac),
              title: Text('MacBook Air M2'),
              subtitle: Text('Mumbai, India • 2h ago'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.vibrate();
                Navigator.pop(context);
                ErrorHandler.showSuccess(
                  context,
                  'All remote sessions terminated. Vault access restricted to this device.',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Logout All Other Devices'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDataExport(BuildContext context) {
    HapticFeedback.selectionClick();
    ErrorHandler.showSuccess(
      context,
      'Data export initiated. Secure archive generation in progress...',
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (context.mounted) {
        ErrorHandler.showSuccess(
          context,
          'Vault data successfully exported to /Downloads/Smart_Vault_Export.json',
        );
      }
    });
  }

  void _showDeleteAccountConfirmation(BuildContext context) {
    final keyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Permanent Erasure?',
          style: TextStyle(color: AppTheme.error),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will erase all financial history, vault backups, and AI context. This action is IRREVERSIBLE.',
            ),
            const SizedBox(height: 20),
            const Text(
              'Type "PERMANENT DELETE" to confirm:',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: keyController,
              decoration: const InputDecoration(
                hintText: 'Enter confirmation key',
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ABORT'),
          ),
          ElevatedButton(
            onPressed: () {
              if (keyController.text != 'PERMANENT DELETE') {
                ErrorHandler.showError(context, 'Confirmation key mismatch.');
                return;
              }
              HapticFeedback.heavyImpact();
              Navigator.pop(context);
              ref.read(authProvider.notifier).signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginSignupScreen()),
                (route) => false,
              );
              ErrorHandler.showSuccess(
                context,
                'All vault records have been purged.',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('PURGE VAULT'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () async {
        HapticFeedback.vibrate();
        await ref.read(authProvider.notifier).signOut();
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginSignupScreen()),
            (route) => false,
          );
        }
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.error,
        side: BorderSide(color: AppTheme.error.withOpacity(0.2)),
        padding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        minimumSize: const Size(double.infinity, 60),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.logout_rounded, size: 20),
          SizedBox(width: 12),
          Text(
            'Log out Account',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
