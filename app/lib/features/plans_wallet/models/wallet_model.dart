/// Wallet and credit ledger models with plain-language explanations.
/// Owner: M4
library;

class LedgerEntryModel {
  final String id;
  final String txnId;
  final int amountCredits;
  final int amountInr;
  final String direction; // 'in' (credit) or 'out' (debit)
  final String reason; // 'purchase', 'reserve', 'release', 'refund', 'payout', 'donate', 'grant', 'expire'
  final String? refType; // 'session', 'request', 'subscription', 'cashout', 'scholarship', 'dispute'
  final String? refId;
  final DateTime? createdAt;
  final String? notes;

  const LedgerEntryModel({
    required this.id,
    required this.txnId,
    required this.amountCredits,
    required this.amountInr,
    required this.direction,
    required this.reason,
    this.refType,
    this.refId,
    this.createdAt,
    this.notes,
  });

  bool get isPositive =>
      direction.toLowerCase() == 'in' ||
      direction.toLowerCase() == 'credit' ||
      amountCredits > 0;

  String get displayCredits {
    final prefix = isPositive ? '+' : '-';
    final absCredits = amountCredits.abs();
    return '$prefix$absCredits ${absCredits == 1 ? 'Credit' : 'Credits'}';
  }

  String get plainReason {
    final r = reason.toLowerCase();
    switch (r) {
      case 'reserve':
        return 'Reserved for mentorship session';
      case 'refund':
        if (notes != null && notes!.isNotEmpty) {
          return 'Refunded: $notes';
        }
        return 'Refunded: Giver did not reply in 72 hours / Session cancelled';
      case 'purchase':
      case 'subscription':
      case 'grant':
        return 'Monthly subscription credit allowance';
      case 'donate':
        return 'Donated to student scholarship pool';
      case 'payout':
      case 'cashout':
        return 'Cash-out payout to bank account';
      case 'release':
        return 'Reservation released';
      case 'expire':
        return 'Unused credit expired at billing cycle end';
      default:
        return notes ?? 'Credit ledger update ($reason)';
    }
  }

  String get plainDate {
    if (createdAt == null) return '';
    final dt = createdAt!;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  factory LedgerEntryModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is int) {
        return DateTime.fromMillisecondsSinceEpoch(val * 1000);
      }
      return DateTime.tryParse(val.toString());
    }

    final rawAmount = (json['amount_credits'] as num?)?.toInt() ??
        (json['credits'] as num?)?.toInt() ??
        0;
    final dir = json['direction']?.toString().toLowerCase() ??
        (rawAmount >= 0 ? 'in' : 'out');

    return LedgerEntryModel(
      id: json['id']?.toString() ?? '',
      txnId: json['txn_id']?.toString() ?? '',
      amountCredits: rawAmount.abs(),
      amountInr: (json['amount_inr'] as num?)?.toInt() ?? 0,
      direction: dir,
      reason: json['reason']?.toString() ?? 'ledger_entry',
      refType: json['ref_type']?.toString(),
      refId: json['ref_id']?.toString(),
      createdAt: parseDate(json['created_at']),
      notes: json['notes']?.toString(),
    );
  }
}

class WalletModel {
  final int paidCredits;
  final int affinityCredits;
  final int totalCredits;
  final List<LedgerEntryModel> ledger;
  final String? nextCursor;

  const WalletModel({
    required this.paidCredits,
    required this.affinityCredits,
    required this.totalCredits,
    required this.ledger,
    this.nextCursor,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    final paid = (json['paid_credits'] as num?)?.toInt() ?? 0;
    final affinity = (json['affinity_credits'] as num?)?.toInt() ?? 0;
    final total = (json['total_credits'] as num?)?.toInt() ?? (paid + affinity);

    final rawEntries = json['ledger'] as List<dynamic>? ??
        json['entries'] as List<dynamic>? ??
        [];
    final entries = rawEntries
        .map((e) => LedgerEntryModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return WalletModel(
      paidCredits: paid,
      affinityCredits: affinity,
      totalCredits: total,
      ledger: entries,
      nextCursor: json['next_cursor']?.toString(),
    );
  }

  static WalletModel empty() {
    return const WalletModel(
      paidCredits: 0,
      affinityCredits: 0,
      totalCredits: 0,
      ledger: [],
      nextCursor: null,
    );
  }
}
