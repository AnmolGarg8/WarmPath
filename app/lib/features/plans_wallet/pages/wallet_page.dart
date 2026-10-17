/// Wallet page rendering paid, affinity, and total credits alongside
/// double-entry ledger transactions with cursor pagination.
/// Owner: M4
library;

import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/w_card.dart';
import '../../../core/widgets/w_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../models/wallet_model.dart';
import '../services/plans_wallet_api_service.dart';
import '../widgets/ledger_entry_tile.dart';

class WalletPage extends StatefulWidget {
  final PlansWalletApiService? apiService;
  final VoidCallback? onGetMoreCredits;

  const WalletPage({
    super.key,
    this.apiService,
    this.onGetMoreCredits,
  });

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  late final PlansWalletApiService _api;

  WalletModel? _wallet;
  final List<LedgerEntryModel> _entries = [];
  String? _nextCursor;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _api = widget.apiService ?? PlansWalletApiService();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final wallet = await _api.getWallet();
      if (mounted) {
        setState(() {
          _wallet = wallet;
          _entries.clear();
          _entries.addAll(wallet.ledger);
          _nextCursor = wallet.nextCursor;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _nextCursor == null) return;

    setState(() => _isLoadingMore = true);

    try {
      final moreWallet = await _api.getWallet(cursor: _nextCursor);
      if (mounted) {
        setState(() {
          _entries.addAll(moreWallet.ledger);
          _nextCursor = moreWallet.nextCursor;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load older transactions: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ErrorState(
        message: _errorMessage!,
        onRetry: _loadWallet,
      );
    }

    final total = _wallet?.totalCredits ?? 0;
    final paid = _wallet?.paidCredits ?? 0;
    final affinity = _wallet?.affinityCredits ?? 0;

    return RefreshIndicator(
      onRefresh: _loadWallet,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Balance Overview Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.deepIndigo, Color(0xFF1F2150)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadii.card,
              boxShadow: [
                BoxShadow(
                  color: AppColors.deepIndigo.withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AVAILABLE CREDITS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Icon(Icons.shield_outlined, color: Colors.white70, size: 18),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$total',
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Credits Total',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Paid (Cross-College)',
                            style: TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$paid Credits',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 32, color: Colors.white24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Affinity (Campus)',
                            style: TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$affinity Credits',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (widget.onGetMoreCredits != null) ...[
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: WButton(
                      label: 'Get More Credits',
                      backgroundColor: AppColors.primaryAction,
                      onPressed: widget.onGetMoreCredits,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Ledger Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Credit Ledger History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '${_entries.length} records',
                style: const TextStyle(fontSize: 12, color: AppColors.slate),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Every credit reserved, refunded, or issued is recorded immutably.',
            style: TextStyle(fontSize: 12, color: AppColors.slate),
          ),
          const SizedBox(height: 16),

          // Ledger Entries List
          if (_entries.isEmpty)
            const EmptyState(
              title: 'No Ledger Entries Yet',
              message: 'Your credit usage, session reservations, and refunds will appear here.',
              icon: Icons.receipt_long_outlined,
            )
          else ...[
            ..._entries.map((entry) => LedgerEntryTile(entry: entry)),
            if (_nextCursor != null) ...[
              const SizedBox(height: 12),
              Center(
                child: _isLoadingMore
                    ? const CircularProgressIndicator()
                    : TextButton.icon(
                        icon: const Icon(Icons.arrow_downward, size: 16),
                        label: const Text('Load More Transactions'),
                        onPressed: _loadMore,
                      ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
