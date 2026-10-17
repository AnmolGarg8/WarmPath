/// Plans page displaying subscription plans, upgrade prompts, and webhook-verified checkout.
/// Owner: M4
library;

import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/w_card.dart';
import '../../../core/widgets/w_button.dart';
import '../../../core/widgets/error_state.dart';
import '../models/plan_model.dart';
import '../models/subscription_model.dart';
import '../services/plans_wallet_api_service.dart';
import '../services/razorpay_service.dart';
import '../controllers/subscription_polling_controller.dart';
import '../widgets/test_mode_banner.dart';
import '../widgets/plan_card.dart';
import '../widgets/cancel_subscription_dialog.dart';

class PlansPage extends StatefulWidget {
  final String? reason;
  final PlansWalletApiService? apiService;
  final WarmPathRazorpayService? razorpayService;
  final SubscriptionPollingController? pollingController;

  const PlansPage({
    super.key,
    this.reason,
    this.apiService,
    this.razorpayService,
    this.pollingController,
  });

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  late final PlansWalletApiService _api;
  late final WarmPathRazorpayService _razorpay;
  late final SubscriptionPollingController _polling;

  List<PlanModel> _plans = [];
  UserSubscriptionModel? _currentSubscription;
  bool _isLoading = true;
  String? _errorMessage;
  String? _subscribingPlanCode;

  @override
  void initState() {
    super.initState();
    _api = widget.apiService ?? PlansWalletApiService();
    _razorpay = widget.razorpayService ?? WarmPathRazorpayService();
    _polling = widget.pollingController ?? SubscriptionPollingController();

    _initRazorpay();
    _loadData();
  }

  void _initRazorpay() {
    _razorpay.initialize(
      onSuccess: (response) {
        // NOTE: Never trust client success alone!
        // Start polling the backend for webhook confirmation.
        if (_subscribingPlanCode != null) {
          _showVerificationModal(_subscribingPlanCode!);
        }
      },
      onFailure: (response) {
        if (mounted) {
          setState(() => _subscribingPlanCode = null);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment cancelled or failed: ${response.message ?? "Unknown error"}'),
              backgroundColor: AppColors.primaryAction,
            ),
          );
        }
      },
    );
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _api.getPlans(),
        _api.getSubscription(),
      ]);

      if (mounted) {
        setState(() {
          _plans = results[0] as List<PlanModel>;
          _currentSubscription = results[1] as UserSubscriptionModel;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _plans = PlanModel.defaultPlans();
          _currentSubscription = UserSubscriptionModel.defaultCampus();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onSubscribe(PlanModel plan) async {
    if (plan.isFree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are already eligible for unlimited free campus connects!'),
        ),
      );
      return;
    }

    setState(() => _subscribingPlanCode = plan.code);

    try {
      final checkout = await _api.createSubscription(plan.code);

      await _razorpay.openCheckout(
        subscriptionId: checkout.subscriptionId,
        keyId: checkout.razorpayKeyId,
        amountInr: checkout.amountInr,
        planName: plan.name,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _subscribingPlanCode = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initiate checkout: $e'),
            backgroundColor: AppColors.primaryAction,
          ),
        );
      }
    }
  }

  void _showVerificationModal(String targetPlanCode) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return ListenableBuilder(
          listenable: _polling,
          builder: (context, _) {
            final isPolling = _polling.status == PollingStatus.polling;
            final isSuccess = _polling.status == PollingStatus.active;
            final isTimeout = _polling.status == PollingStatus.timeout;

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.slate.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (isPolling) ...[
                    const SizedBox(
                      height: 48,
                      width: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppColors.primaryAction,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Verifying Payment Gateway...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _polling.statusMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: AppColors.slate),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'WarmPath waits for signed webhook verification to ensure safe credit issuance.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppColors.slate),
                    ),
                  ] else if (isSuccess) ...[
                    const Icon(
                      Icons.check_circle,
                      size: 54,
                      color: AppColors.teal,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Subscription Activated!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _polling.statusMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: AppColors.teal),
                    ),
                    const SizedBox(height: 20),
                    WButton(
                      label: 'Done',
                      onPressed: () {
                        Navigator.of(bottomSheetContext).pop();
                        setState(() => _subscribingPlanCode = null);
                        _loadData();
                      },
                    ),
                  ] else if (isTimeout) ...[
                    const Icon(
                      Icons.hourglass_bottom,
                      size: 50,
                      color: AppColors.amber,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Payment Pending',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _polling.statusMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: AppColors.slate),
                    ),
                    const SizedBox(height: 20),
                    WButton(
                      label: 'I Understand',
                      onPressed: () {
                        Navigator.of(bottomSheetContext).pop();
                        setState(() => _subscribingPlanCode = null);
                        _loadData();
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );

    // Start polling in background
    _polling.startPolling(
      fetchSubscription: () => _api.getSubscription(),
      targetPlanCode: targetPlanCode,
    );
  }

  void _showCancelDialog() {
    if (_currentSubscription == null) return;

    showDialog(
      context: context,
      builder: (context) => CancelSubscriptionDialog(
        planName: _currentSubscription!.planName,
        renewalDateText: _currentSubscription!.plainRenewal,
        onConfirm: () async {
          await _api.cancelSubscription(atPeriodEnd: true);
          _loadData();
        },
      ),
    );
  }

  @override
  void dispose() {
    _razorpay.dispose();
    _polling.dispose();
    super.dispose();
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

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test Mode Banner
            const TestModeBanner(
              message: 'Test mode: no real money moves. Payment gateway is simulated.',
            ),
            const SizedBox(height: 12),

            // Upgrade Reason prompt (if navigated from another feature)
            if (widget.reason != null && widget.reason!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryAction.withOpacity(0.1),
                  borderRadius: AppRadii.card,
                  border: Border.all(color: AppColors.primaryAction.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.primaryAction, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Upgrade Required',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryAction,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.reason!,
                            style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Active Subscription Card
            if (_currentSubscription != null) ...[
              WCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Active Subscription',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.slate,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _currentSubscription!.planName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _currentSubscription!.active
                                ? AppColors.teal.withOpacity(0.12)
                                : AppColors.amber.withOpacity(0.12),
                            borderRadius: AppRadii.badge,
                          ),
                          child: Text(
                            _currentSubscription!.plainStatus,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _currentSubscription!.active
                                  ? AppColors.teal
                                  : AppColors.amber,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _currentSubscription!.plainRenewal,
                          style: const TextStyle(fontSize: 13, color: AppColors.slate),
                        ),
                        Text(
                          '${_currentSubscription!.creditsLeft} Credits left',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    if (_currentSubscription!.isPaidPlan &&
                        !_currentSubscription!.cancelAtPeriodEnd) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showCancelDialog,
                          child: const Text(
                            'Cancel at period end',
                            style: TextStyle(
                              color: AppColors.slate,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Section Header
            const Text(
              'Available Plans',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose a plan based on the alumni mentors you want to connect with.',
              style: TextStyle(fontSize: 13, color: AppColors.slate),
            ),
            const SizedBox(height: 16),

            // Plan Cards
            ..._plans.map((p) {
              final isCurrent = _currentSubscription != null &&
                  _currentSubscription!.planCode.toLowerCase() == p.code.toLowerCase();

              return PlanCard(
                plan: p,
                isCurrentPlan: isCurrent,
                isSubscribing: _subscribingPlanCode == p.code,
                onSubscribe: () => _onSubscribe(p),
              );
            }),
          ],
        ),
      ),
    );
  }
}
