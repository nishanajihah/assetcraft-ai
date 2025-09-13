import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'ai_generation_screen.dart';
import 'gallery_screen.dart';
import 'store_screen.dart';
import 'user_management_screen.dart';

/// Main Navigation Screen
///
/// Bottom tab navigation between the 4 core screens:
/// 1. AI Generation - Create new assets
/// 2. Gallery - Browse user and community assets
/// 3. Store - Purchase gemstones and subscriptions
/// 4. User Management - Profile and settings
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    AIGenerationScreen(),
    GalleryScreen(),
    StoreScreen(),
    UserManagementScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMedium,
              vertical: AppDimensions.paddingSmall,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.auto_awesome,
                  activeIcon: Icons.auto_awesome,
                  label: 'Create',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.photo_library_outlined,
                  activeIcon: Icons.photo_library,
                  label: 'Gallery',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.store_outlined,
                  activeIcon: Icons.store,
                  label: 'Store',
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: AppDimensions.paddingSmall,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryGold.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primaryGold : AppColors.textSecondary,
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isActive
                    ? AppColors.primaryGold
                    : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
