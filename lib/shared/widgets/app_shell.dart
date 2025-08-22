import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../features/ai_generation/presentation/ai_generation_screen.dart';
import '../../features/asset_library/presentation/asset_library_screen.dart';
import '../../features/monetization/presentation/credits_screen.dart';

/// Main app shell with bottom navigation
class AppShell extends ConsumerStatefulWidget {
  final int initialIndex;
  
  const AppShell({super.key, this.initialIndex = 0});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late int _currentIndex;
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _screens = [
    const AIGenerationScreen(),
    const AssetLibraryScreen(),
    const CreditsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.backgroundPrimary,
              AppColors.backgroundSecondary,
            ],
          ),
        ),
        child: SafeArea(child: _screens[_currentIndex]),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.neuShadowDark.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: AppColors.backgroundCard,
            selectedItemColor: AppColors.primaryGold,
            unselectedItemColor: AppColors.textSecondary,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: _currentIndex == 0
                      ? NeuStyles.neuPressed(borderRadius: 12)
                      : null,
                  child: const Icon(Icons.auto_awesome),
                ),
                label: 'Generate',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: _currentIndex == 1
                      ? NeuStyles.neuPressed(borderRadius: 12)
                      : null,
                  child: const Icon(Icons.photo_library),
                ),
                label: 'Library',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: _currentIndex == 2
                      ? NeuStyles.neuPressed(borderRadius: 12)
                      : null,
                  child: const Icon(Icons.account_balance_wallet),
                ),
                label: 'Credits',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
