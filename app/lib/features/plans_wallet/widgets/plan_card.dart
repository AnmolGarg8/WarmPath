/// Subscription plan card widget with plain-language features, reach bands,
/// priority explanation, and honest own-college free guarantee.
/// Owner: M4
library;

import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/w_card.dart';
import '../../../core/widgets/w_button.dart';
import '../models/plan_model.dart';

class PlanCard extends StatelessWidget {
  final PlanModel plan;
  final bool isCurrentPlan;
  final bool isSubscribing;
  final VoidCallback? onSubscribe;

  const PlanCard({
    super.key,
    required this.plan,
    this.isCurrentPlan = false,
    this.isSubscribing = false,
    this.onSubscribe,
  });

  Color _accentColor() {
    switch (plan.code.toLowerCase()) {
      case 'premium':
        return AppColors.amber;
      case 'high':
        return AppColors.primaryAction;
      case 'standard':
        return AppColors.teal;
      case 'campus':
      default:
        return AppColors.deepIndigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadii.card,
        border: Border.all(
          color: isCurrentPlan ? accent : AppColors.slate.withOpacity(0.18),
          width: isCurrentPlan ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrentPlan
                ? accent.withOpacity(0.15)
                : AppColors.textDark.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name and Current badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      plan.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                if (isCurrentPlan)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.15),
                      borderRadius: AppRadii.badge,
                      border: Border.all(color: accent),
                    ),
                    child: Text(
                      'CURRENT PLAN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Price section
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  plan.isFree ? '₹0' : '₹${plan.priceInr}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: plan.isFree ? AppColors.textDark : accent,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  plan.isFree ? 'forever' : '/month',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.slate,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Key Highlights: Credits, Reach, Booking Horizon, Priority
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.badge,
              ),
              child: Column(
                children: [
                  _infoRow(
                    icon: Icons.confirmation_number_outlined,
                    title: 'Monthly Allowance',
                    value: plan.creditsPerMonth > 0
                        ? '${plan.creditsPerMonth} Cross-College Credit${plan.creditsPerMonth > 1 ? 's' : ''}'
                        : 'Unlimited Campus Connects',
                  ),
                  const Divider(height: 14, thickness: 0.5),
                  _infoRow(
                    icon: Icons.hub_outlined,
                    title: 'Mentor Reach',
                    value: plan.plainReach,
                  ),
                  const Divider(height: 14, thickness: 0.5),
                  _infoRow(
                    icon: Icons.calendar_today_outlined,
                    title: 'Booking Horizon',
                    value: plan.plainBookingHorizon,
                  ),
                  const Divider(height: 14, thickness: 0.5),
                  _infoRow(
                    icon: Icons.speed_outlined,
                    title: 'Queue Priority',
                    value: plan.plainPriority,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Honest line about own college
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.teal.withOpacity(0.08),
                borderRadius: AppRadii.badge,
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 16, color: AppColors.teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Honest guarantee: Own-college alumni access is 100% free on every plan.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.teal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Plain-language features list
            ...plan.features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check, size: 16, color: accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textDark,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action button
            SizedBox(
              width: double.infinity,
              child: WButton(
                label: isCurrentPlan
                    ? 'Active Plan'
                    : plan.isFree
                        ? 'Select Campus'
                        : 'Subscribe for ₹${plan.priceInr}/mo',
                backgroundColor: isCurrentPlan
                    ? AppColors.slate.withOpacity(0.4)
                    : accent,
                isLoading: isSubscribing,
                onPressed: (isCurrentPlan || isSubscribing) ? null : onSubscribe,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.slate),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.slate,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}
