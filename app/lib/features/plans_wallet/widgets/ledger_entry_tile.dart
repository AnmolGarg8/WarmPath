/// Ledger entry tile rendering credit transactions in clear, plain language.
/// Owner: M4
library;

import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';
import '../models/wallet_model.dart';

class LedgerEntryTile extends StatelessWidget {
  final LedgerEntryModel entry;

  const LedgerEntryTile({super.key, required this.entry});

  IconData _iconForReason() {
    switch (entry.reason.toLowerCase()) {
      case 'reserve':
      case 'session_reservation':
        return Icons.lock_clock;
      case 'refund':
      case 'session_refund_no_reply_72h':
      case 'session_refund_giver_no_show':
      case 'session_refund_dispute_outcome':
        return Icons.replay_circle_filled;
      case 'purchase':
      case 'subscription':
      case 'grant':
      case 'plan_credit_grant':
        return Icons.add_card;
      case 'donate':
        return Icons.volunteer_activism;
      case 'payout':
      case 'cashout':
        return Icons.payments;
      case 'expire':
        return Icons.timer_off;
      default:
        return Icons.swap_horiz;
    }
  }

  Color _colorForEntry() {
    if (entry.isPositive) {
      return AppColors.teal;
    }
    if (entry.reason.toLowerCase() == 'reserve' || entry.reason.toLowerCase() == 'session_reservation') {
      return AppColors.amber;
    }
    return AppColors.primaryAction;
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForEntry();
    final icon = _iconForReason();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.slate.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.plainReason,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (entry.plainDate.isNotEmpty) ...[
                      Text(
                        entry.plainDate,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate,
                        ),
                      ),
                      const Text('•', style: TextStyle(color: AppColors.slate)),
                    ],
                    Text(
                      'Txn: ${entry.shortTxnId}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.slate,
                        fontFamily: 'monospace',
                      ),
                    ),
                    if (entry.runningBalance != null) ...[
                      const Text('•', style: TextStyle(color: AppColors.slate)),
                      Text(
                        'Bal: ${entry.runningBalance} cr',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: AppRadii.badge,
            ),
            child: Text(
              entry.displayCredits,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
