// allow-mock-file: guided demo, simulated and labelled
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/personas.dart';
import '../../engine/contracts.dart';
import '../../engine/demo_config.dart';
import '../../engine/safety_engine_impl.dart';
import '../../models/demo_event_log.dart';
import '../../models/demo_models.dart';
import '../../state/demo_state.dart';

DemoChapter buildP4TrustChapter() {
  return DemoChapter(
    id: 'p4_trust',
    pillarNumber: 4,
    title: 'Trust by Design & Moderation',
    summary:
        'Institutional domain verification, graduated request limits, real-time scam and off-platform push scanning, contact masking, and moderation audit trail.',
    steps: [
      // Step 1: Verification at Entry
      DemoStep(
        title: 'Institutional Verification',
        whatItIs:
            'Type an official college email address. It is checked against the approved campus roster, unlocking verified badges.',
        actor: DemoActor.student,
        presenterNote:
            'Demonstrate that only verified campus emails unlock alumni access. Try typing a personal or approved domain.',
        builder: (context, ref) => const _VerificationStepWidget(),
      ),

      // Step 2: Graduated Privileges & Daily Limits
      DemoStep(
        title: 'Graduated Daily Limits',
        whatItIs:
            'Daily request rate-limits tied to trust level (New: 1, Basic: 3, Verified: 5, Trusted: 10) to stop spam.',
        actor: DemoActor.student,
        presenterNote:
            'Show the jury: New profiles cannot spam 50 alumni. Limits enforce thoughtful, high-signal connection requests.',
        builder: (context, ref) => const _GraduatedLimitsStepWidget(),
      ),

      // Step 3: Scam & Payment Bypass Scanner
      DemoStep(
        title: 'Live Scam & Bypass Scan',
        whatItIs:
            'Interactive safety scanner. Detects fee requests, WhatsApp/Telegram off-platform pushes, shortlinks, and obfuscations.',
        actor: DemoActor.moderator,
        presenterNote:
            'Invite the jury to type any test message. Show how spaced letters (w h a t s a p p) or digit substitutions (ph0ne) are caught.',
        builder: (context, ref) => const _ScamScanStepWidget(),
      ),

      // Step 4: Contact Masking & Privacy
      DemoStep(
        title: 'Automatic Contact Masking',
        whatItIs:
            'Phone numbers and personal emails are redacted in conversation previews until a protected session is mutually accepted.',
        actor: DemoActor.moderator,
        presenterNote:
            'Contact masking protects junior students from unsolicited external contact and harassment.',
        builder: (context, ref) => const _ContactMaskingStepWidget(),
      ),

      // Step 5: Moderation Queue & Audit Log
      DemoStep(
        title: 'Moderator Resolution & Audit',
        whatItIs:
            'Flagged incidents escalate to the moderation queue where Campus Safety Lead Priya (sample) resolves them with tamper-evident audit logging.',
        actor: DemoActor.moderator,
        presenterNote:
            'Resolving a flag logs a tamper-evident audit event. Notice how the virtual clock records the 2.4-hour SLA.',
        builder: (context, ref) => const _ModerationStepWidget(),
      ),

      // Step 6: DPDP Consent & Data Deletion
      DemoStep(
        title: 'DPDP Data Rights & Purge',
        whatItIs:
            'Full compliance with India DPDP Act 2023: granular consent withdrawal, personal data export, and permanent account anonymization.',
        actor: DemoActor.student,
        presenterNote:
            'Demonstrate that students can download a JSON export or permanently purge their profile with one tap.',
        builder: (context, ref) => const _DataDeletionStepWidget(),
      ),
    ],
  );
}

// --- Step Widgets ---

class _VerificationStepWidget extends StatefulWidget {
  const _VerificationStepWidget();

  @override
  State<_VerificationStepWidget> createState() => _VerificationStepWidgetState();
}

class _VerificationStepWidgetState extends State<_VerificationStepWidget> {
  String inputEmail = 'riya@demouniversity.edu';

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(demoControllerProvider);
        final result = state.safetyEngine.verifyEmail(inputEmail);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter Campus Email Address:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: inputEmail,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                  hintText: 'e.g. student@demouniversity.edu',
                ),
                onChanged: (v) => setState(() => inputEmail = v),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('riya@demouniversity.edu (Approved)'),
                    onPressed: () => setState(() => inputEmail = 'riya@demouniversity.edu'),
                  ),
                  ActionChip(
                    label: const Text('external.user@gmail.com (Unapproved)'),
                    onPressed: () => setState(() => inputEmail = 'external.user@gmail.com'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: result.isApproved ? const Color(0xFFDCFCE7) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: result.isApproved ? const Color(0xFF86EFAC) : const Color(0xFFFECACA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(result.isApproved ? Icons.verified : Icons.lock_outline, color: result.isApproved ? const Color(0xFF15803D) : Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          result.isApproved ? 'Institutional Identity Verified' : 'Unapproved Domain Warning',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: result.isApproved ? const Color(0xFF15803D) : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('• Institution: ${result.institutionName}', style: const TextStyle(fontSize: 12.5)),
                    Text('• Assigned Badge: ${result.badge}', style: const TextStyle(fontSize: 12.5)),
                    Text('• Access Level: ${result.privileges}', style: const TextStyle(fontSize: 12.5)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GraduatedLimitsStepWidget extends StatefulWidget {
  const _GraduatedLimitsStepWidget();

  @override
  State<_GraduatedLimitsStepWidget> createState() => _GraduatedLimitsStepWidgetState();
}

class _GraduatedLimitsStepWidgetState extends State<_GraduatedLimitsStepWidget> {
  String selectedTrust = 'verified';
  int requestsSentToday = 3;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(demoControllerProvider);
        final check = state.safetyEngine.checkDailyLimits(selectedTrust, requestsSentToday);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Student Trust Level:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['new', 'basic', 'verified', 'trusted'].map((lvl) {
                  final isSel = selectedTrust == lvl;
                  return ChoiceChip(
                    label: Text(lvl.toUpperCase()),
                    selected: isSel,
                    selectedColor: const Color(0xFF1E3A8A),
                    labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                    onSelected: (_) => setState(() {
                      selectedTrust = lvl;
                      requestsSentToday = 0; // reset for test
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trust Tier: ${selectedTrust.toUpperCase()}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Requests sent today: $requestsSentToday of ${check.dailyLimit}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: (requestsSentToday / check.dailyLimit).clamp(0.0, 1.0),
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation(check.allowed ? const Color(0xFF1E3A8A) : Colors.red),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        check.reason,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: check.allowed ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: check.allowed ? const Color(0xFF1E3A8A) : Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: const Text('Try Sending Connection Request'),
                        onPressed: check.allowed
                            ? () => setState(() => requestsSentToday += 1)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScamScanStepWidget extends StatefulWidget {
  const _ScamScanStepWidget();

  @override
  State<_ScamScanStepWidget> createState() => _ScamScanStepWidgetState();
}

class _ScamScanStepWidgetState extends State<_ScamScanStepWidget> {
  final TextEditingController _msgController = TextEditingController(
    text: 'Can you review my resume? Also pay me 500 advance via GPay on w h a t s a p p.',
  );

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(demoControllerProvider);
        final result = state.safetyEngine.scanMessage(_msgController.text);

        Color badgeColor;
        IconData badgeIcon;
        switch (result.action) {
          case SafetyAction.allow:
            badgeColor = const Color(0xFF15803D);
            badgeIcon = Icons.check_circle_rounded;
            break;
          case SafetyAction.warn:
            badgeColor = const Color(0xFFB45309);
            badgeIcon = Icons.warning_amber_rounded;
            break;
          case SafetyAction.review:
            badgeColor = const Color(0xFF4338CA);
            badgeIcon = Icons.visibility_rounded;
            break;
          case SafetyAction.block:
            badgeColor = const Color(0xFFDC2626);
            badgeIcon = Icons.block_rounded;
            break;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Interactive Message Safety Scanner:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _msgController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Type any message or test phrase...',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              const Text('Try Sample Phrases:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ActionChip(
                    label: const Text('Benign: "Can you review my resume?"'),
                    onPressed: () => setState(() => _msgController.text = 'Could you please review my software engineering resume?'),
                  ),
                  ActionChip(
                    label: const Text('Bypass: "w h a t s a p p me"'),
                    onPressed: () => setState(() => _msgController.text = 'Hey connect on w h a t s a p p for fast reply'),
                  ),
                  ActionChip(
                    label: const Text('Fee: "Send 500 via GPay"'),
                    onPressed: () => setState(() => _msgController.text = 'Registration fee 500 send via GPay or UPI'),
                  ),
                  ActionChip(
                    label: const Text('Link: "bit.ly/free-job"'),
                    onPressed: () => setState(() => _msgController.text = 'Check my openings here: bit.ly/free-job'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: badgeColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(badgeIcon, color: badgeColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'ACTION: ${result.action.name.toUpperCase()}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: badgeColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(result.explanation, style: TextStyle(fontSize: 12.5, color: badgeColor, height: 1.3)),
                    if (result.triggeredRules.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text('Triggered Safeguards:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ...result.triggeredRules.map((r) => Text('• $r', style: const TextStyle(fontSize: 11.5))),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ContactMaskingStepWidget extends StatelessWidget {
  const _ContactMaskingStepWidget();

  @override
  Widget build(BuildContext context) {
    const rawMessage = 'Call my mobile +91 9876543210 or email me at mentor@externalcorp.com';
    final masked = SafetyEngineImpl().maskContactInfo(rawMessage);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Privacy Protection: Contact Masking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          const Text(
            'Direct phone numbers and emails are masked in conversation cards to prevent unsolicited off-platform contact before a session is officially scheduled.',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFFFEF2F2),
            child: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Unmasked Original String:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF991B1B))),
                  SizedBox(height: 4),
                  Text(rawMessage, style: TextStyle(fontSize: 13, fontFamily: 'monospace')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFFDCFCE7),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sanitized & Masked Output:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF15803D))),
                  const SizedBox(height: 4),
                  Text(masked, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModerationStepWidget extends StatefulWidget {
  const _ModerationStepWidget();

  @override
  State<_ModerationStepWidget> createState() => _ModerationStepWidgetState();
}

class _ModerationStepWidgetState extends State<_ModerationStepWidget> {
  bool isResolved = false;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(demoControllerProvider);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.report_problem_rounded, color: Color(0xFFDC2626)),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Flagged Incident #MOD-8821',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isResolved ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isResolved ? 'Resolved' : 'Pending Review',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isResolved ? const Color(0xFF15803D) : const Color(0xFF991B1B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Reason: Off-platform fee request detected in chat.\n'
                        'Reviewer: Priya (sample) - Campus Safety Lead\n'
                        'SLA: Target < 24 hours (Current resolution time: 2.4 hours)',
                        style: TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 14),
                      if (!isResolved)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Resolve Incident & Log Tamper-Evident Audit'),
                          onPressed: () {
                            setState(() => isResolved = true);
                            state.eventLog.log(
                              type: 'ModerationResolved',
                              actor: 'Moderator Priya',
                              description: 'Incident #MOD-8821 resolved: Warned user and logged audit entry.',
                              virtualTime: state.virtualClock.format(),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Incident resolved. Audit entry committed to DemoEventLog.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        )
                      else
                        const Text(
                          'Audit Entry: Action committed with SHA-256 hash. Immutable log visible in Institution View.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DataDeletionStepWidget extends StatelessWidget {
  const _DataDeletionStepWidget();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DPDP Right to Data Deletion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          const Text(
            'Under Section 12 of the Digital Personal Data Protection Act, students retain full sovereignty over their identity.',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Permanent Data Purge Actions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  const Text(
                    '• Resume PDF and extracted skill vectors permanently purged from vector store\n'
                    '• Personal name and email anonymized to random UUID\n'
                    '• Financial ledger retained with pseudonym for double-entry tax audit compliance',
                    style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.delete_forever_rounded, size: 18),
                    label: const Text('Simulate DPDP Account Anonymization'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Simulated DPDP account deletion complete: PII anonymized, vectors wiped.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
