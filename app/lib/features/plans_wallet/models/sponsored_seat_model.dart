/// Sponsored seat model for students supported by institutional or scholarship funds.
/// Owner: M4
library;

class SponsoredSeatModel {
  final String id;
  final String institutionId;
  final String institutionName;
  final String status; // 'available', 'granted', 'active', 'used', 'expired'
  final String fundingSource; // 'alumni_donation', 'institution_grant', 'scholarship_pool'
  final int creditsGranted;
  final int creditsRemaining;
  final bool canClaim;
  final DateTime? grantedAt;
  final DateTime? expiresAt;

  const SponsoredSeatModel({
    required this.id,
    required this.institutionId,
    required this.institutionName,
    required this.status,
    required this.fundingSource,
    required this.creditsGranted,
    required this.creditsRemaining,
    this.canClaim = false,
    this.grantedAt,
    this.expiresAt,
  });

  bool get isActive =>
      status.toLowerCase() == 'active' ||
      status.toLowerCase() == 'granted' ||
      status.toLowerCase() == 'available';

  String get plainFundingSource {
    switch (fundingSource.toLowerCase()) {
      case 'alumni_donation':
        return 'Sponsored by WarmPath Alumni Giving';
      case 'institution_grant':
        return 'Funded by $institutionName Student Opportunity Fund';
      case 'scholarship_pool':
      default:
        return 'WarmPath Community Scholarship Pool';
    }
  }

  factory SponsoredSeatModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is int) {
        return DateTime.fromMillisecondsSinceEpoch(val * 1000);
      }
      return DateTime.tryParse(val.toString());
    }

    final canClaim = json['can_claim'] as bool? ?? (json['status'] == 'available');
    final instName = json['sponsor_name']?.toString() ??
        json['institution_name']?.toString() ??
        (json['funded_by']?.toString() == 'scholarship_pool' ? 'Scholarship Pool' : 'Institution Sponsor');
    final funding = json['funded_by']?.toString() ?? json['funding_source']?.toString() ?? 'scholarship_pool';

    return SponsoredSeatModel(
      id: json['id']?.toString() ?? '',
      institutionId: json['institution_id']?.toString() ?? '',
      institutionName: instName,
      status: json['status']?.toString() ?? (canClaim ? 'available' : 'granted'),
      fundingSource: funding,
      creditsGranted: (json['credits_granted'] as num?)?.toInt() ?? 1,
      creditsRemaining: (json['credits_remaining'] as num?)?.toInt() ?? 1,
      canClaim: canClaim,
      grantedAt: parseDate(json['granted_at'] ?? json['created_at']),
      expiresAt: parseDate(json['expires_at']),
    );
  }
}
