import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/tokens.dart';

class MainBottomNav extends StatelessWidget {
  final int currentIndex;

  const MainBottomNav({
    super.key,
    required this.currentIndex,
  });

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        context.go('/discover');
        break;
      case 1:
        context.go('/sessions');
        break;
      case 2:
        context.go('/plans-wallet');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) => _onItemTapped(context, index),
      backgroundColor: AppColors.white,
      indicatorColor: AppColors.primaryAction.withOpacity(0.15),
      elevation: 3,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.explore_outlined, color: AppColors.slate),
          selectedIcon: Icon(Icons.explore, color: AppColors.primaryAction),
          label: 'Discover',
        ),
        NavigationDestination(
          icon: Icon(Icons.forum_outlined, color: AppColors.slate),
          selectedIcon: Icon(Icons.forum, color: AppColors.primaryAction),
          label: 'Inbox',
        ),
        NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined, color: AppColors.slate),
          selectedIcon: Icon(Icons.account_balance_wallet, color: AppColors.primaryAction),
          label: 'Wallet',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline, color: AppColors.slate),
          selectedIcon: Icon(Icons.person, color: AppColors.primaryAction),
          label: 'Profile',
        ),
      ],
    );
  }
}
