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
  final int? runningBalance;

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
    this.runningBalance,
  });

  bool get isPositive {
    final d = direction.toLowerCase();
    if (d == 'out' || d == 'debit') return false;
    if (d == 'in' || d == 'credit') return true;
    final r = reason.toLowerCase();
    if (r == 'reserve' || r == 'session_reservation') return false;
    return amountCredits > 0;
  }

  String get shortTxnId {
    if (txnId.isEmpty) return '';
    final clean = txnId.replaceAll('-', '');
    if (clean.length >= 8) {
      return clean.substring(clean.length - 8);
    }
    return txnId;
  }

  String get displayCredits {
    final prefix = isPositive ? '+' : '-';
    final absCredits = amountCredits.abs();
    return '$prefix$absCredits ${absCredits == 1 ? 'Credit' : 'Credits'}';
  }

  String get plainReason {
    if (notes != null && notes!.isNotEmpty) {
      return notes!;
    }
    final r = reason.toLowerCase();
    switch (r) {
      case 'reserve':
      case 'session_reservation':
        return 'Reserved for a session: -${amountCredits.abs()} ${amountCredits.abs() == 1 ? 'credit' : 'credits'}';
      case 'refund':
      case 'session_refund_no_reply_72h':
      case 'session_refund_giver_no_show':
      case 'session_refund_dispute_outcome':
        return 'Refunded: +${amountCredits.abs()} ${amountCredits.abs() == 1 ? 'credit' : 'credits'}';
      case 'purchase':
      case 'subscription':
      case 'grant':
      case 'plan_credit_grant':
        return 'Monthly subscription credit allowance: +${amountCredits.abs()} ${amountCredits.abs() == 1 ? 'credit' : 'credits'}';
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
        return 'Credit ledger update ($reason)';
    }
  }

  String get plainDate {
    if (createdAt == null) return '';
    final dt = createdAt!;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  LedgerEntryModel copyWith({
    String? id,
    String? txnId,
    int? amountCredits,
    int? amountInr,
    String? direction,
    String? reason,
    String? refType,
    String? refId,
    DateTime? createdAt,
    String? notes,
    int? runningBalance,
  }) {
    return LedgerEntryModel(
      id: id ?? this.id,
      txnId: txnId ?? this.txnId,
      amountCredits: amountCredits ?? this.amountCredits,
      amountInr: amountInr ?? this.amountInr,
      direction: direction ?? this.direction,
      reason: reason ?? this.reason,
      refType: refType ?? this.refType,
      refId: refId ?? this.refId,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      runningBalance: runningBalance ?? this.runningBalance,
    );
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
    final r = json['reason']?.toString().toLowerCase() ?? 'ledger_entry';
    String dir = json['direction']?.toString().toLowerCase() ??
        ((rawAmount >= 0 && r != 'reserve' && r != 'session_reservation') ? 'in' : 'out');
    if (r == 'reserve' || r == 'session_reservation') {
      dir = 'out';
    }

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
      notes: json['plain_reason']?.toString() ?? json['notes']?.toString(),
      runningBalance: (json['running_balance'] as num?)?.toInt(),
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
    final paid = (json['available_credits'] as num?)?.toInt() ??
        (json['paid_credits'] as num?)?.toInt() ??
        0;
    final affinity = (json['affinity_credits'] as num?)?.toInt() ?? 0;
    final total = (json['total_credits'] as num?)?.toInt() ?? (paid + affinity);

    final rawEntries = json['items'] as List<dynamic>? ??
        json['ledger'] as List<dynamic>? ??
        json['entries'] as List<dynamic>? ??
        [];

    int currentBal = total;
    final entries = <LedgerEntryModel>[];
    for (final raw in rawEntries) {
      final entry = LedgerEntryModel.fromJson(raw as Map<String, dynamic>);
      if (entry.runningBalance != null) {
        entries.add(entry);
      } else {
        entries.add(entry.copyWith(runningBalance: currentBal));
        currentBal -= (entry.isPositive ? entry.amountCredits : -entry.amountCredits);
      }
    }

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
