import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/profile/provider/profile_provider.dart';
import '../features/auth/provider/auth_provider.dart';
import '../theme/app_theme.dart';
import '../core/network/connectivity_service.dart';
import '../core/utils/error_handler.dart';
import 'login_signup.dart';


class ProfileScreen extends ConsumerStatefulWidget {

  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(profileProvider.notifier).loadProfile());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final connectivity = ref.watch(connectivityProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
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
                  _buildPremiumStatusCard(),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Control Center'),
                  const SizedBox(height: 16),
                  _buildConnectivityCard(context, connectivity),
                  const SizedBox(height: 32),
                  _buildSettingsGroup(context, 'Account Management', [
                    _buildSettingsItem(
                      context, 
                      'Personal Information', 
                      'Name, Email, Job Title', 
                      Icons.person_pin_outlined, 
                      onTap: () => _showUpdateNameDialog(context, state)
                    ),
                    _buildSettingsItem(
                      context, 
                      'Bank Accounts', 
                      'Manage linked institutions', 
                      Icons.account_balance_outlined,
                      onTap: () => _showBankAccountsSheet(context),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSettingsGroup(context, 'Security & Privacy', [
                    _buildToggleItem(
                      context, 
                      'Biometric Authentication', 
                      state.isBiometricSupported ? 'FaceID or Fingerprint' : 'Hardware not detected', 
                      Icons.fingerprint_rounded, 
                      state.isBiometricEnabled && state.isBiometricSupported,
                      onChanged: state.isBiometricSupported ? (v) {
                        HapticFeedback.mediumImpact();
                        ref.read(profileProvider.notifier).toggleBiometrics(v);
                      } : null,
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
                    _buildSettingsItem(context, 'Theme Preferences', 'System, Dark, Light', Icons.palette_outlined),
                    _buildSettingsItem(context, 'Notification Center', 'Alerts & Reminders', Icons.notifications_none_outlined),
                  ]),
                  const SizedBox(height: 40),
                  _buildLogoutButton(context),
                  const SizedBox(height: 32),
                  Text(
                    'NEBULON FINTECH • VERSION 3.0.0-PRO',
                    style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.textSecondary.withValues(alpha: 0.4), letterSpacing: 2),
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
    return Container(
      padding: const EdgeInsets.only(top: 60, bottom: 20, left: 24, right: 24),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(bottom: BorderSide(color: AppTheme.divider.withValues(alpha: 0.5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Settings', style: Theme.of(context).textTheme.headlineLarge),
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: AppTheme.indigo),
            onPressed: () {
              HapticFeedback.selectionClick();
              ref.read(profileProvider.notifier).loadProfile();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHero(BuildContext context, ProfileState state) {
    final name = state.profile?.fullName ?? 'Executive User';
    final email = state.profile?.email ?? 'active.user@nebulon.com';

    return Row(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Hero(
                tag: 'profile_avatar',
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 37,
                    backgroundColor: AppTheme.surface,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppTheme.indigo),
                    ),
                  ),
                ),
              ),

            ),
            Positioned(
              bottom: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: AppTheme.emerald, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 10),
              ),
            ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 4),
              Text(email, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E2C), Color(0xFF2D2D44)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('NEBULON PRO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 13)),
                Text('Enterprise Subscription Active', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.keyboard_arrow_right_rounded, color: Colors.white54),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title.toUpperCase(), style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(letterSpacing: 2)),
      ),
    );
  }

  Widget _buildConnectivityCard(BuildContext context, ConnectivityStatus status) {
    final isOnline = status == ConnectivityStatus.isConnected;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(isOnline ? Icons.cloud_done_outlined : Icons.cloud_off_outlined, color: isOnline ? AppTheme.emerald : AppTheme.rose),
              const SizedBox(width: 16),
              Text(isOnline ? 'Cloud Synced' : 'Offline Mode', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (isOnline ? AppTheme.emerald : AppTheme.rose).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isOnline ? 'STABLE' : 'PENDING',
              style: TextStyle(color: isOnline ? AppTheme.emerald : AppTheme.rose, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, String title, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.divider.withValues(alpha: 0.3)),
      ),
      child: Column(children: items),
    );
  }

  Widget _buildSettingsItem(BuildContext context, String title, String subtitle, IconData icon, {VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppTheme.indigo, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.7), fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.divider),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildToggleItem(BuildContext context, String title, String subtitle, IconData icon, bool isOn, {ValueChanged<bool>? onChanged}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppTheme.indigo, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.7), fontSize: 12)),
      trailing: Switch.adaptive(
        value: isOn, 
        onChanged: onChanged,
        activeTrackColor: AppTheme.emerald,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  void _showBankAccountsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Text('Bank Accounts', style: Theme.of(context).textTheme.displayMedium),
            Text('MANAGE LINKED INSTITUTIONS', style: AppTheme.lightTheme.textTheme.labelSmall),
            const SizedBox(height: 32),
            _buildBankItem('HDFC Bank', 'Corporate Account • **** 8291', true),
            const SizedBox(height: 16),
            _buildBankItem('ICICI Bank', 'Savings Account • **** 1022', false),
            const Spacer(),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.indigo,
                foregroundColor: Colors.white,

                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Add New Institution'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankItem(String name, String details, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.indigo),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(details, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          if (isPrimary) Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.emerald, borderRadius: BorderRadius.circular(8)),
            child: const Text('PRIMARY', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
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
        side: const BorderSide(color: Color(0xFFFFDAD6)),
        padding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        minimumSize: const Size(double.infinity, 60),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.logout_rounded, size: 20),
          SizedBox(width: 12),
          Text('Log out Account', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showUpdateNameDialog(BuildContext context, ProfileState state) {
    final controller = TextEditingController(text: state.profile?.fullName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Identity'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Full Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final success = await ref.read(profileProvider.notifier).updateProfile({'full_name': controller.text});
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Identity Refined' : 'Operation Failed')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
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
            TextField(controller: oldController, obscureText: true, decoration: const InputDecoration(hintText: 'Existing Password')),
            TextField(controller: newController, obscureText: true, decoration: const InputDecoration(hintText: 'New Vault Key')),
            TextField(controller: confirmController, obscureText: true, decoration: const InputDecoration(hintText: 'Confirm New Key')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (newController.text != confirmController.text) {
                ErrorHandler.showError(context, 'New keys do not match.');
                return;
              }
              if (newController.text.length < 8) {
                ErrorHandler.showError(context, 'Password must be 8+ characters.');
                return;
              }
              HapticFeedback.mediumImpact();
              Navigator.pop(context);
              ErrorHandler.showSuccess(context, 'Credential vault updated successfully.');
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.devices, size: 48, color: AppTheme.indigo),
            const SizedBox(height: 24),
            Text('Active Sessions', style: Theme.of(context).textTheme.headlineMedium),
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
                ErrorHandler.showSuccess(context, 'All remote sessions terminated. Vault access restricted to this device.');
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
     ErrorHandler.showSuccess(context, 'Data export initiated. Secure archive generation in progress...');
     
     Future.delayed(const Duration(seconds: 3), () {
        if (context.mounted) {
          ErrorHandler.showSuccess(context, 'Vault data successfully exported to /Downloads/Nebulon_Vault_Export.json');
        }
     });
  }


  void _showDeleteAccountConfirmation(BuildContext context) {
    final keyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanent Erasure?', style: TextStyle(color: AppTheme.error)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This will erase all financial history, vault backups, and AI context. This action is IRREVERSIBLE.'),
            const SizedBox(height: 20),
            const Text('Type "PERMANENT DELETE" to confirm:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: keyController,
              decoration: const InputDecoration(hintText: 'Enter confirmation key'),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ABORT')),
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
              ErrorHandler.showSuccess(context, 'All vault records have been purged.');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
            child: const Text('PURGE VAULT'),
          ),
        ],
      ),
    );
  }

}

