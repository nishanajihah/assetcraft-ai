import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/user_provider.dart';
import '../core/theme/app_theme.dart';
import '../ui/components/app_components.dart';

/// User Management Screen
///
/// Handles user profile, settings, account management, and logout
/// Features: Profile editing, usage statistics, subscription status, account actions
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<UserProvider>(context, listen: false);
      _nameController.text = provider.user?.displayName ?? '';
      _emailController.text = provider.user?.email ?? '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppDimensions.paddingLarge),
          child: Consumer<UserProvider>(
            builder: (context, provider, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  SizedBox(height: AppDimensions.spacingLarge),
                  _buildProfileSection(provider),
                  SizedBox(height: AppDimensions.spacingLarge),
                  _buildSubscriptionSection(provider),
                  SizedBox(height: AppDimensions.spacingLarge),
                  _buildUsageStatsSection(provider),
                  SizedBox(height: AppDimensions.spacingLarge),
                  _buildSettingsSection(),
                  SizedBox(height: AppDimensions.spacingLarge),
                  _buildAccountActionsSection(provider),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.person, color: AppColors.primaryGold, size: 32),
        SizedBox(width: AppDimensions.spacingMedium),
        Expanded(
          child: Text(
            'Settings & Account',
            style: AppTextStyles.headingLarge.copyWith(
              color: AppColors.primaryGold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            return GemstoneCounter(count: userProvider.gemstoneCount);
          },
        ),
      ],
    );
  }

  Widget _buildProfileSection(UserProvider provider) {
    return NeomorphicContainer(
      padding: EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_circle,
                color: AppColors.primaryGold,
                size: 24,
              ),
              SizedBox(width: AppDimensions.spacingSmall),
              Text(
                'Profile Information',
                style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isEditing = !_isEditing;
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(AppDimensions.paddingSmall),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _isEditing ? Icons.check : Icons.edit,
                    color: AppColors.primaryGold,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: AppDimensions.spacingLarge),

          // Profile avatar
          Center(
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: AppColors.primaryGold, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: provider.user?.photoURL != null
                        ? Image.network(
                            provider.user!.photoURL!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultAvatar();
                            },
                          )
                        : _buildDefaultAvatar(),
                  ),
                ),

                if (_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _changeProfilePhoto,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          SizedBox(height: AppDimensions.spacingLarge),

          // Name field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Display Name',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppDimensions.spacingSmall),
              _isEditing
                  ? NeomorphicTextField(
                      controller: _nameController,
                      hintText: 'Enter your name',
                    )
                  : Text(
                      provider.user?.displayName ?? 'Anonymous User',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
            ],
          ),

          SizedBox(height: AppDimensions.spacingMedium),

          // Email field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Email Address',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppDimensions.spacingSmall),
              Text(
                provider.user?.email ?? 'No email provided',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          if (_isEditing) ...[
            SizedBox(height: AppDimensions.spacingLarge),
            Row(
              children: [
                Expanded(
                  child: GoldButton(
                    text: 'Save Changes',
                    onPressed: () => _saveProfile(provider),
                    variant: ButtonVariant.primary,
                  ),
                ),
                SizedBox(width: AppDimensions.spacingMedium),
                Expanded(
                  child: GoldButton(
                    text: 'Cancel',
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        _nameController.text = provider.user?.displayName ?? '';
                      });
                    },
                    variant: ButtonVariant.secondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Icon(Icons.person, size: 50, color: AppColors.primaryGold);
  }

  Widget _buildSubscriptionSection(UserProvider provider) {
    return NeomorphicContainer(
      padding: EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium,
                color: AppColors.primaryGold,
                size: 24,
              ),
              SizedBox(width: AppDimensions.spacingSmall),
              Text(
                'Subscription Status',
                style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          SizedBox(height: AppDimensions.spacingMedium),

          Container(
            padding: EdgeInsets.all(AppDimensions.paddingMedium),
            decoration: BoxDecoration(
              color: provider.isPremium
                  ? AppColors.primaryGold.withOpacity(0.1)
                  : AppColors.surfaceDim,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: provider.isPremium
                  ? Border.all(color: AppColors.primaryGold, width: 1)
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: provider.isPremium
                        ? AppColors.primaryGold
                        : AppColors.textSecondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    provider.isPremium ? Icons.star : Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),

                SizedBox(width: AppDimensions.spacingMedium),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.isPremium ? 'Premium Member' : 'Free Plan',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (provider.isPremium &&
                          provider.subscriptionEndDate != null)
                        Text(
                          'Expires on ${_formatDate(provider.subscriptionEndDate!)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),

                if (!provider.isPremium)
                  GoldButton(
                    text: 'Upgrade',
                    onPressed: () {
                      // Navigate to store screen
                      // Navigator.pushNamed(context, '/store');
                    },
                    variant: ButtonVariant.primary,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageStatsSection(UserProvider provider) {
    return NeomorphicContainer(
      padding: EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: AppColors.primaryGold, size: 24),
              SizedBox(width: AppDimensions.spacingSmall),
              Text(
                'Usage Statistics',
                style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          SizedBox(height: AppDimensions.spacingLarge),

          Row(
            children: [
              // Total generations
              Expanded(
                child: _buildStatRow(
                  icon: Icons.auto_awesome,
                  label: 'Total Assets',
                  value: '${provider.totalGenerations}',
                  color: AppColors.primaryGold,
                ),
              ),

              // This month generations
              Expanded(
                child: _buildStatRow(
                  icon: Icons.calendar_month,
                  label: 'This Month',
                  value: '${provider.monthlyGenerations}',
                  color: AppColors.accentTeal,
                ),
              ),
            ],
          ),

          SizedBox(height: AppDimensions.spacingMedium),

          Row(
            children: [
              // Weekly generations
              Expanded(
                child: _buildStatRow(
                  icon: Icons.date_range,
                  label: 'This Week',
                  value: '${provider.weeklyGenerations}',
                  color: AppColors.accentDeepOrange,
                ),
              ),

              // Favorite assets
              Expanded(
                child: _buildStatRow(
                  icon: Icons.favorite,
                  label: 'Favorites',
                  value: '${provider.favoriteCount}',
                  color: AppColors.accentPink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(icon, color: color, size: 24),
        ),

        SizedBox(height: AppDimensions.spacingSmall),

        Text(
          value,
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),

        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return NeomorphicContainer(
      padding: EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: AppColors.primaryGold, size: 24),
              SizedBox(width: AppDimensions.spacingSmall),
              Text(
                'App Settings',
                style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          SizedBox(height: AppDimensions.spacingMedium),

          _buildSettingTile(
            icon: Icons.notifications,
            title: 'Push Notifications',
            subtitle: 'Get notified about new features',
            trailing: Switch(
              value: true,
              onChanged: (value) {
                // Handle notification toggle
              },
              activeColor: AppColors.primaryGold,
            ),
          ),

          _buildSettingTile(
            icon: Icons.download,
            title: 'Auto-save to Gallery',
            subtitle: 'Automatically save generated assets',
            trailing: Switch(
              value: true,
              onChanged: (value) {
                // Handle auto-save toggle
              },
              activeColor: AppColors.primaryGold,
            ),
          ),

          _buildSettingTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: 'English',
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16,
            ),
            onTap: () {
              // Show language selector
            },
          ),

          _buildSettingTile(
            icon: Icons.help,
            title: 'Help & Support',
            subtitle: 'Get help or contact support',
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16,
            ),
            onTap: () {
              _showHelpDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primaryGold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: AppColors.primaryGold, size: 20),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildAccountActionsSection(UserProvider provider) {
    return Column(
      children: [
        // Export data
        SizedBox(
          width: double.infinity,
          child: GoldButton(
            text: '📊 Export My Data',
            onPressed: () => _exportUserData(provider),
            variant: ButtonVariant.secondary,
            icon: Icons.download,
          ),
        ),

        SizedBox(height: AppDimensions.spacingMedium),

        // Logout
        SizedBox(
          width: double.infinity,
          child: GoldButton(
            text: '🚪 Log Out',
            onPressed: () => _confirmLogout(provider),
            variant: ButtonVariant.outline,
            icon: Icons.logout,
          ),
        ),

        SizedBox(height: AppDimensions.spacingMedium),

        // Delete account
        SizedBox(
          width: double.infinity,
          child: GoldButton(
            text: '🗑️ Delete Account',
            onPressed: () => _confirmDeleteAccount(provider),
            variant: ButtonVariant.danger,
            icon: Icons.delete_forever,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _changeProfilePhoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLarge),
        ),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(AppDimensions.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Change Profile Photo',
                style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),

              SizedBox(height: AppDimensions.spacingLarge),

              ListTile(
                leading: Icon(Icons.camera_alt, color: AppColors.primaryGold),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement camera functionality
                },
              ),

              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: AppColors.primaryGold,
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement gallery functionality
                },
              ),

              ListTile(
                leading: Icon(Icons.delete, color: AppColors.accentDeepOrange),
                title: const Text('Remove Photo'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement remove photo functionality
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveProfile(UserProvider provider) async {
    try {
      await provider.updateProfile(displayName: _nameController.text);

      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppColors.accentTeal,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: AppColors.accentDeepOrange,
        ),
      );
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text(
          'Need help? Contact us at:\n\n'
          '📧 support@assetcraft.ai\n'
          '🌐 www.assetcraft.ai/help\n\n'
          'We usually respond within 24 hours!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Open email app or web browser
            },
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  void _exportUserData(UserProvider provider) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Exporting your data...'),
            ],
          ),
        ),
      );

      await provider.exportUserData();

      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data export completed! Check your downloads.'),
          backgroundColor: AppColors.accentTeal,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export data: $e'),
          backgroundColor: AppColors.accentDeepOrange,
        ),
      );
    }
  }

  void _confirmLogout(UserProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _logout(provider);
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(UserProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Delete Account'),
        content: const Text(
          'This will permanently delete your account and all associated data. '
          'This action cannot be undone.\n\n'
          'Are you absolutely sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount(provider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentDeepOrange,
            ),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(UserProvider provider) async {
    try {
      await provider.logout();

      // Navigate to login screen
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to log out: $e'),
          backgroundColor: AppColors.accentDeepOrange,
        ),
      );
    }
  }

  Future<void> _deleteAccount(UserProvider provider) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Deleting account...'),
            ],
          ),
        ),
      );

      await provider.deleteAccount();

      Navigator.pop(context); // Close loading dialog

      // Navigate to login screen
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete account: $e'),
          backgroundColor: AppColors.accentDeepOrange,
        ),
      );
    }
  }
}
