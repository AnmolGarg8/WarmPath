// allow-mock-file: guided demo, simulated and labelled
import '../data/personas.dart';
import 'contracts.dart';
import 'demo_config.dart';

class SafetyEngineImpl implements SafetyEngine {
  // Regex patterns for detecting scam, off-platform bypass, and money requests
  static final RegExp _moneyPattern = RegExp(
    r'\b(pay\s*me|send\s*money|fees?|charges?|gpay|google\s*pay|phonepe|paytm|upi\s*(?:id)?|cash|crypto|bank\s*transfer|deposit|advance)\b',
    caseSensitive: false,
  );

  static final RegExp _offPlatformPattern = RegExp(
    r'\b(whatsapp|telegram|tele|call\s*me|my\s*number|phone\s*no|insta(?:gram)?|snapchat|dm\s*me|discord|talk\s*outside)\b',
    caseSensitive: false,
  );

  // Shortened and suspicious URLs
  static final RegExp _shortLinkPattern = RegExp(
    r'\b(bit\.ly|tinyurl\.com|t\.co|goo\.gl|t\.me|wa\.me|cutt\.ly|is\.gd|ow\.ly)\b',
    caseSensitive: false,
  );

  // Phone numbers (Indian 10-digit mobile or international formats)
  static final RegExp _phonePattern = RegExp(
    r'(?:\+?91[\-\s]?)?[6-9]\d{9}|\b\d{3}[-.\s]?\d{3}[-.\s]?\d{4}\b',
  );

  // Emails
  static final RegExp _emailPattern = RegExp(
    r'[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+',
  );

  /// Normalize common obfuscations:
  /// - spaced letters: "w h a t s a p p" -> "whatsapp"
  /// - digit substitutions: "@" -> "a", "0" -> "o", "1" -> "i", "3" -> "e", "5" -> "s", "ph0ne" -> "phone"
  /// - punctuation separators: "w.h.a.t.s.a.p.p" -> "whatsapp"
  String _normalizeObfuscations(String input) {
    String text = input.toLowerCase();

    // Common leetspeak substitutions
    text = text
        .replaceAll('@', 'a')
        .replaceAll('0', 'o')
        .replaceAll('1', 'i')
        .replaceAll('3', 'e')
        .replaceAll('5', 's')
        .replaceAll(r'$', 's')
        .replaceAll('+', 't');

    // Collapse spaced or punctuated single-letter sequences (e.g. "w h a t s a p p", "w.h.a.t.s.a.p.p")
    text = text.replaceAllMapped(
      RegExp(r'\b[a-z](?:[\s._-]+[a-z]){2,}\b'),
      (match) => match.group(0)!.replaceAll(RegExp(r'[\s._-]+'), ''),
    );

    return text;
  }

  @override
  SafetyScanResult scanMessage(String text) {
    if (text.trim().isEmpty) {
      return const SafetyScanResult(
        action: SafetyAction.allow,
        triggeredRules: [],
        maskedMessage: '',
        explanation: 'Empty message.',
      );
    }

    final normalized = _normalizeObfuscations(text);
    final List<String> rules = [];

    // Check money/fees
    if (_moneyPattern.hasMatch(text) || _moneyPattern.hasMatch(normalized)) {
      rules.add('Off-platform payment or fee solicitation detected');
    }

    // Check off-platform channels
    if (_offPlatformPattern.hasMatch(text) || _offPlatformPattern.hasMatch(normalized)) {
      rules.add('Attempt to redirect conversation off WarmPath (WhatsApp/Telegram)');
    }

    // Check suspicious links
    if (_shortLinkPattern.hasMatch(text) || _shortLinkPattern.hasMatch(normalized)) {
      rules.add('Suspicious link or URL shortener detected');
    }

    // Check contact sharing
    if (_phonePattern.hasMatch(text) || _emailPattern.hasMatch(text)) {
      rules.add('Unsolicited direct contact info (phone/email) shared');
    }

    // Determine safety action
    SafetyAction action;
    String explanation;

    if (rules.isEmpty) {
      action = SafetyAction.allow;
      explanation = 'Message passed all trust safeguards. Protected by in-app session escrow.';
    } else if (rules.any((r) => r.contains('payment') || r.contains('fee'))) {
      action = SafetyAction.block;
      explanation =
          'BLOCKED: Payments outside WarmPath are strictly prohibited. Mentors receive guaranteed credit payouts automatically through our double-entry escrow.';
    } else if (rules.any((r) => r.contains('redirect') || r.contains('link'))) {
      action = SafetyAction.review;
      explanation =
          'FLAGGED FOR MODERATION: Redirecting students to external platforms or sending shortlinks risks impersonation and removes session safety guarantees.';
    } else {
      action = SafetyAction.warn;
      explanation =
          'WARNING: Contact details detected. Contact information is masked until a session is confirmed to prevent unsolicited off-platform contact.';
    }

    final masked = maskContactInfo(text);

    return SafetyScanResult(
      action: action,
      triggeredRules: rules,
      maskedMessage: masked,
      explanation: explanation,
    );
  }

  @override
  String maskContactInfo(String text) {
    String result = text;
    result = result.replaceAllMapped(
      _phonePattern,
      (match) => '[PHONE MASKED FOR PRIVACY]',
    );
    result = result.replaceAllMapped(
      _emailPattern,
      (match) => '[EMAIL MASKED FOR PRIVACY]',
    );
    return result;
  }

  @override
  VerificationResult verifyEmail(String email) {
    final clean = email.trim().toLowerCase();
    if (!clean.contains('@')) {
      return const VerificationResult(
        isApproved: false,
        institutionName: 'Unknown',
        badge: 'Unverified',
        privileges: 'Limited: View only 1 mentor/day, no instant connects',
      );
    }

    final domain = clean.split('@').last;
    final isApproved = DemoPersonas.approvedInstitutionDomains.contains(domain);

    if (isApproved) {
      final institutionName = domain.contains('demo')
          ? 'Demo University'
          : 'Sample Institute of Technology';
      return VerificationResult(
        isApproved: true,
        institutionName: institutionName,
        badge: 'Verified Student Badge',
        privileges: 'Full access: Free own-college alumni connects + priority routing',
      );
    } else {
      return VerificationResult(
        isApproved: false,
        institutionName: 'External Domain ($domain)',
        badge: 'Basic / Guest Profile',
        privileges: 'Restricted: 1 request/day limit, cross-college reach gated',
      );
    }
  }

  @override
  PrivilegeResult checkDailyLimits(String trustLevel, int usedToday) {
    final limit = DemoConfig.dailyLimitsByTrustLevel[trustLevel.toLowerCase()] ?? 1;
    final remaining = (limit - usedToday).clamp(0, limit);
    final allowed = usedToday < limit;

    return PrivilegeResult(
      allowed: allowed,
      dailyLimit: limit,
      remainingToday: remaining,
      reason: allowed
          ? 'Allowed: $remaining of $limit daily connection requests remaining.'
          : 'Blocked: Daily connection limit reached ($limit/$limit) for trust level "$trustLevel". Limits reset every 24 hours to prevent spam.',
    );
  }
}
