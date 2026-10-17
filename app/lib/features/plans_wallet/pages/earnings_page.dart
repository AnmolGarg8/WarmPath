/// Giver earnings page displaying dispute window pending balances,
/// rating band payout share, cash-out requests, and sponsored seats.
/// Owner: M4
library;

import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/w_card.dart';
import '../../../core/widgets/w_button.dart';
import '../../../core/widgets/band_badge.dart';
import '../../../core/widgets/error_state.dart';
import '../models/earnings_model.dart';
import '../models/sponsored_seat_model.dart';
import '../services/plans_wallet_api_service.dart';
import '../widgets/test_mode_banner.dart';
import '../widgets/cashout_dialog.dart';
import '../widgets/donate_dialog.dart';

class EarningsPage extends StatefulWidget {
  final PlansWalletApiService? apiService;

  const EarningsPage({super.key, this.apiService});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  late final PlansWalletApiService _api;

  EarningsModel? _earnings;
  List<SponsoredSeatModel> _sponsoredSeats = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _api = widget.apiService ?? PlansWalletApiService();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _api.getEarnings(),
        _api.getSponsoredSeats(),
      ]);

      if (mounted) {
        setState(() {
          _earnings = results[0] as EarningsModel;
          _sponsoredSeats = results[1] as List<SponsoredSeatModel>;
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

  void _openCashout() {
    if (_earnings == null || !_earnings!.canCashout) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available earnings for cash-out.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => CashoutDialog(
        availableInr: _earnings!.availableInr,
        onSubmit: (amount) async {
          await _api.requestCashout(amount);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Cash-out of ₹$amount requested (Test Mode). Balance updated.',
                ),
                backgroundColor: AppColors.teal,
              ),
            );
            _loadData();
          }
        },
      ),
    );
  }

  void _openDonate() {
    final available = _earnings?.availableCredits ?? 0;
    if (available <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have 0 available credits to donate right now.'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => DonateDialog(
        maxCredits: available,
        onDonate: (credits) async {
          await _api.donateCredits(credits);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Donated $credits credit(s) to the Scholarship Pool!',
                ),
                backgroundColor: AppColors.teal,
              ),
            );
            _loadData();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ErrorState(
        message: _errorMessage!,
        onRetry: _loadData,
      );
    }

    final earnings = _earnings ?? EarningsModel.empty();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const TestModeBanner(
            message: 'Test mode: Cash-out requests and transfers are simulated.',
          ),
          const SizedBox(height: 16),

          // Financial metrics grid
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  title: 'Available',
                  amount: '₹${earnings.availableInr}',
                  color: AppColors.teal,
                  subtitle: 'Ready to cash-out',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metricCard(
                  title: 'Pending (48h)',
                  amount: '₹${earnings.pendingInr}',
                  color: AppColors.amber,
                  subtitle: 'Dispute window',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _metricCard(
            title: 'Total Paid Out to Date',
            amount: '₹${earnings.paidOutInr}',
            color: AppColors.deepIndigo,
            subtitle: 'Successfully transferred to bank account',
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: WButton(
                  label: 'Request Cash-Out',
                  backgroundColor: earnings.canCashout
                      ? AppColors.teal
                      : AppColors.slate.withOpacity(0.5),
                  onPressed: earnings.canCashout ? _openCashout : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: WButton(
                  label: 'Donate Credits',
                  backgroundColor: AppColors.primaryAction,
                  onPressed: _openDonate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Rating Band and Payout Share Card
          WCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mentor Band Payout Share',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    BandBadge(band: earnings.ratingBand),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '${earnings.payoutSharePct}%',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryAction,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'of session fee earned by you',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  earnings.plainRatingBandShare,
                  style: const TextStyle(fontSize: 13, color: AppColors.slate),
                ),
                const Divider(height: 20),
                const Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 16, color: AppColors.slate),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '48-Hour Dispute Window Guarantee',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  earnings.plainDisputeNotice,
                  style: const TextStyle(fontSize: 12, color: AppColors.slate),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Sponsored Seats Section
          const Text(
            'Sponsored Seats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Institutional grants and community scholarship seats you qualify for.',
            style: TextStyle(fontSize: 12, color: AppColors.slate),
          ),
          const SizedBox(height: 12),

          if (_sponsoredSeats.isEmpty)
            const WCard(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No sponsored seats currently active. Sponsored seats are granted automatically by your college administration.',
                  style: TextStyle(fontSize: 13, color: AppColors.slate),
                ),
              ),
            )
          else
            ..._sponsoredSeats.map((seat) => _sponsoredSeatTile(seat)),
        ],
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String amount,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.slate.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.slate,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.slate),
          ),
        ],
      ),
    );
  }

  Widget _sponsoredSeatTile(SponsoredSeatModel seat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.teal.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school, color: AppColors.teal, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  seat.institutionName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  seat.plainFundingSource,
                  style: const TextStyle(fontSize: 12, color: AppColors.slate),
                ),
                const SizedBox(height: 6),
                Text(
                  '${seat.creditsRemaining} of ${seat.creditsGranted} credits remaining',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.teal,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.1),
              borderRadius: AppRadii.badge,
            ),
            child: Text(
              seat.status.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.teal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
