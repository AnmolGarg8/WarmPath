/// Unified Plans & Wallet page with tabbed navigation for Plans, Wallet Ledger, and Earnings.
/// Owner: M4
library;

import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import 'pages/plans_page.dart';
import 'pages/wallet_page.dart';
import 'pages/earnings_page.dart';

class PlansWalletPage extends StatefulWidget {
  final String? initialTab;
  final String? reason;

  const PlansWalletPage({
    super.key,
    this.initialTab,
    this.reason,
  });

  @override
  State<PlansWalletPage> createState() => _PlansWalletPageState();
}

class _PlansWalletPageState extends State<PlansWalletPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.initialTab != null) {
      switch (widget.initialTab!.toLowerCase()) {
        case 'wallet':
          initialIndex = 1;
          break;
        case 'earnings':
          initialIndex = 2;
          break;
        case 'plans':
        default:
          initialIndex = 0;
          break;
      }
    } else if (widget.reason != null && widget.reason!.isNotEmpty) {
      initialIndex = 0; // If upgrade reason specified, show plans tab
    }

    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _switchToPlansTab() {
    _tabController.animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Plans & Wallet',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryAction,
          unselectedLabelColor: AppColors.slate,
          indicatorColor: AppColors.primaryAction,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.card_membership, size: 20), text: 'Plans'),
            Tab(icon: Icon(Icons.account_balance_wallet, size: 20), text: 'Wallet'),
            Tab(icon: Icon(Icons.trending_up, size: 20), text: 'Earnings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          PlansPage(reason: widget.reason),
          WalletPage(onGetMoreCredits: _switchToPlansTab),
          const EarningsPage(),
        ],
      ),
    );
  }
}
