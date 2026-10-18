// allow-mock-file: guided demo, simulated and labelled
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/personas.dart';
import '../../engine/contracts.dart';
import '../../models/demo_event_log.dart';
import '../../models/demo_models.dart';
import '../../state/demo_state.dart';

DemoChapter buildP5ConnectChapter() {
  return DemoChapter(
    id: 'p5_connect',
    pillarNumber: 5,
    title: 'Capacity-Aware Connect & Escrow',
    summary:
        'Weekly mentor capacity controls, online-now instant routing, simulated video call with 5-minute overlap rule, and 48-hour dispute escrow.',
    steps: [
      // Step 1: Giver Sets Capacity & Goes Online
      DemoStep(
        title: 'Giver Capacity & Online Window',
        whatItIs:
            'Alumnus Arjun (sample) sets his weekly capacity (3 slots) and toggles "Online Now" for an instant 30-minute availability window.',
        actor: DemoActor.giver,
        presenterNote:
            'Givers control their availability. Once weekly capacity hits 0, they disappear from routing to prevent flooding.',
        builder: (context, ref) => const _GiverAvailabilityStepWidget(),
      ),

      // Step 2: Student Sees Online Badge
      DemoStep(
        title: 'Instant Request & Escrow Lock',
        whatItIs:
            'Student sees Arjun\'s "Online Now" status and sends an instant connection request. 1 session credit is reserved in escrow.',
        actor: DemoActor.student,
        presenterNote:
            'Escrow is locked the moment the request is sent, guaranteeing giver payment while protecting student funds.',
        builder: (context, ref) => const _StudentConnectRequestStepWidget(),
      ),

      // Step 3: Simulated In-App Video Call
      DemoStep(
        title: 'Simulated In-App Video Call',
        whatItIs:
            'Clean simulation of the 20-minute connection room. Displays join timestamps and active call timer (no live camera in demo).',
        actor: DemoActor.student,
        presenterNote:
            'Clarify to the jury: This simulates our Jitsi meet integration. Note the join timestamps.',
        builder: (context, ref) => const _SimulatedCallStepWidget(),
      ),

      // Step 4: Completion Verification Checklist
      DemoStep(
        title: 'Completion Verification Checklist',
        whatItIs:
            'System checks: Did both join? Was mutual overlap >= 5 minutes? Verified completion transitions credit to dispute window.',
        actor: DemoActor.moderator,
        presenterNote:
            'The 5-minute mutual presence rule prevents accidental drop-ins or phantom meetings from counting as completed.',
        builder: (context, ref) => const _CompletionChecklistStepWidget(),
      ),

      // Step 5: Escrow Timeline & 48h Fast-Forward
      DemoStep(
        title: 'Payment Timeline & 48h Dispute',
        whatItIs:
            'Protected payment lifecycle: Reserved -> Completed -> 48h Dispute Window -> Settled. Tap Fast-Forward to trigger settlement.',
        actor: DemoActor.giver,
        presenterNote:
            'Demonstrate the 48-hour fast forward. Once the dispute window passes without reports, payout is automatically released.',
        builder: (context, ref) => const _PaymentTimelineStepWidget(),
      ),

      // Step 6: Alternate Branch: Giver No-Show Refund
      DemoStep(
        title: 'Alternate Branch: Giver No-Show',
        whatItIs:
            'Demonstrates automatic 100% refund when a giver fails to join. Student wallet is instantly credited back.',
        actor: DemoActor.student,
        presenterNote:
            'Emphasize student protection: If the mentor doesn\'t join, the credit returns immediately with zero paperwork.',
        builder: (context, ref) => const _NoShowRefundStepWidget(),
      ),
    ],
  );
}

// --- Step Widgets ---

class _GiverAvailabilityStepWidget extends StatefulWidget {
  const _GiverAvailabilityStepWidget();

  @override
  State<_GiverAvailabilityStepWidget> createState() => _GiverAvailabilityStepWidgetState();
}

class _GiverAvailabilityStepWidgetState extends State<_GiverAvailabilityStepWidget> {
  int weeklySlots = 3;
  bool isOnline = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFF0F766E),
                        child: Text('AS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Arjun (sample)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Alumni Giver Dashboard • Demo University', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      Switch(
                        value: isOnline,
                        activeColor: const Color(0xFF15803D),
                        onChanged: (v) => setState(() => isOnline = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(
                        isOnline ? Icons.bolt_rounded : Icons.pause_circle_outline,
                        color: isOnline ? const Color(0xFF15803D) : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isOnline ? 'Online Now: Instant 30-min window active' : 'Offline: Bookings only',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isOnline ? const Color(0xFF15803D) : Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text('Weekly Capacity Limit:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  const SizedBox(height: 6),
                  Text(
                    'Arjun committed $weeklySlots slots this week (2 slots remaining). Once filled, he is automatically hidden from search results.',
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: weeklySlots.toDouble(),
                    min: 1,
                    max: 8,
                    divisions: 7,
                    activeColor: const Color(0xFF0F766E),
                    label: '$weeklySlots slots/week',
                    onChanged: (v) => setState(() => weeklySlots = v.round()),
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

class _StudentConnectRequestStepWidget extends StatelessWidget {
  const _StudentConnectRequestStepWidget();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(demoControllerProvider);
        final controller = ref.read(demoControllerProvider.notifier);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.bolt, color: Color(0xFF15803D)),
                          SizedBox(width: 8),
                          Text('Alumnus Arjun is Online Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Capacity remaining: 2 slots this week • 20-minute session duration',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Escrow Guarantee: 1 session credit is held safely in escrow. If Arjun fails to join within 5 minutes, 100% of your credit is refunded instantly.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.video_call_rounded, size: 20),
                          label: const Text('Send Instant Connect Request & Lock Escrow', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            controller.startInstantSession(DemoPersonas.giverArjun);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Session request accepted! Room created and escrow locked.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            controller.nextStep();
                          },
                        ),
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

class _SimulatedCallStepWidget extends StatelessWidget {
  const _SimulatedCallStepWidget();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Row(
              children: [
                Icon(Icons.videocam_outlined, color: Color(0xFFB45309)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'SIMULATED VIDEO ROOM: In production, connects via Jitsi Meet WebRTC. Visual timer below simulates mutual call presence.',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Color(0xFF1E3A8A),
                      child: Text('RS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    SizedBox(width: 24),
                    Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 28),
                    SizedBox(width: 24),
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Color(0xFF0F766E),
                      child: Text('AS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'Connected: Riya (Student) & Arjun (Alumnus)',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                SizedBox(height: 6),
                Text(
                  'Elapsed: 18:42 / 20:00  •  Mutual Presence: 18m',
                  style: TextStyle(color: Color(0xFF38BDF8), fontFamily: 'monospace', fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionChecklistStepWidget extends StatelessWidget {
  const _CompletionChecklistStepWidget();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(demoControllerProvider);
        final controller = ref.read(demoControllerProvider.notifier);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Session Completion Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              _buildCheckItem('Student joined room', 'Riya connected at 10:01 AM (19 mins present)', true),
              _buildCheckItem('Giver joined room', 'Arjun connected at 10:02 AM (18 mins present)', true),
              _buildCheckItem('Mutual overlap >= 5 minutes', 'Measured overlap: 18 minutes (Threshold: 5 mins)', true),
              _buildCheckItem('No safety report filed during call', 'Zero violations or payment bypass attempts detected', true),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15803D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Verify Completion & Open 48h Dispute Window', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    controller.completeActiveSession(studentJoinedMin: 19, giverJoinedMin: 18);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Session completed! 48-hour dispute window is now active.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    controller.nextStep();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCheckItem(String title, String subtitle, bool passed) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(passed ? Icons.check_circle : Icons.cancel, color: passed ? const Color(0xFF15803D) : Colors.red),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
      ),
    );
  }
}

class _PaymentTimelineStepWidget extends StatelessWidget {
  const _PaymentTimelineStepWidget();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(demoControllerProvider);
        final controller = ref.read(demoControllerProvider.notifier);

        final isSettled = state.activeSession?.state == SessionState.settled || state.fastForwarded;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Protected Escrow Timeline:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              _buildTimelineNode('1. Credit Reserved', 'Escrow locked upon request creation', true),
              _buildTimelineNode('2. Session Verified', '5+ minutes mutual presence verified', true),
              _buildTimelineNode(
                '3. 48-Hour Dispute Window',
                isSettled ? '48 hours elapsed with zero disputes' : 'Active countdown: Dispute window open for 48 hours',
                true,
                isCurrent: !isSettled,
              ),
              _buildTimelineNode(
                '4. Payout Settled to Giver',
                isSettled ? 'Settled! Payout released to Arjun based on band share' : 'Pending 48h dispute timer completion',
                isSettled,
              ),
              const SizedBox(height: 20),
              if (!isSettled)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.fast_forward_rounded),
                    label: const Text('Simulate Fast-Forward 48 Hours', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      controller.fastForward48Hours();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Dispute window elapsed. Payout settled to Arjun!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified, color: Color(0xFF15803D)),
                      SizedBox(width: 8),
                      Text(
                        'Payout Settled! In-memory ledger reflects release.',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineNode(String title, String subtitle, bool isCompleted, {bool isCurrent = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: isCompleted ? const Color(0xFF15803D) : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isCurrent ? const Color(0xFF1E3A8A) : Colors.black,
                  ),
                ),
                Text(subtitle, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoShowRefundStepWidget extends StatelessWidget {
  const _NoShowRefundStepWidget();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.replay_rounded, color: Color(0xFF1E3A8A)),
                    SizedBox(width: 8),
                    Text(
                      'Automated Refund Guarantee (No Paperwork)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF1E3A8A)),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '1. Giver No-Show: If mentor fails to connect within 5 minutes of scheduled time, the room closes and 100% of the reserved credit is refunded to student wallet immediately.\n\n'
                  '2. 72-Hour No-Reply: If a mentor does not accept or decline a booking within 72 hours, the request automatically expires and the credit returns.\n\n'
                  '3. Dispute Guarantee: If call dropped due to technical issues, student can flag dispute during 48h window for instant credit restoration.',
                  style: TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF334155)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
