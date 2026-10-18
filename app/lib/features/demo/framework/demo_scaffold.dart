// allow-mock-file: guided demo, simulated and labelled
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../chapters/registry.dart';
import '../demo_banner.dart';
import '../models/demo_models.dart';
import '../state/demo_state.dart';

class DemoScaffold extends ConsumerWidget {
  const DemoScaffold({super.key});

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Guided Demo?'),
        content: const Text(
          'You will return to the real WarmPath application. No live data or accounts were touched during this simulation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Stay in Demo'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/auth/email');
            },
            child: const Text('Exit to App'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Demo Walkthrough?'),
        content: const Text(
          'This will clear the simulated event log, reset the virtual clock, and return you to Chapter 1 (Pillar 1).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(demoControllerProvider.notifier).reset();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(demoControllerProvider);
    final controller = ref.read(demoControllerProvider.notifier);

    final currentChapter = state.currentChapter;
    final currentStep = state.currentStep;

    // Calculate overall progress across all registered steps
    int totalSteps = 0;
    int currentGlobalStep = 0;
    for (int i = 0; i < demoChaptersRegistry.length; i++) {
      if (i < state.chapterIndex) {
        currentGlobalStep += demoChaptersRegistry[i].steps.length;
      } else if (i == state.chapterIndex) {
        currentGlobalStep += state.stepIndex;
      }
      totalSteps += demoChaptersRegistry[i].steps.length;
    }
    final progress = totalSteps > 0 ? (currentGlobalStep + 1) / totalSteps : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Permanent Mandatory Honest Demo Banner
            const DemoBanner(),

            // 2. Top App Bar with Chapter Selector, Clock, and Exit
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Chapter Menu Picker
                    PopupMenuButton<int>(
                      tooltip: 'Jump to Chapter',
                      onSelected: (idx) => controller.jumpToChapter(idx),
                      itemBuilder: (context) {
                        return List.generate(demoChaptersRegistry.length, (i) {
                          final ch = demoChaptersRegistry[i];
                          final isSelected = i == state.chapterIndex;
                          return PopupMenuItem<int>(
                            value: i,
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                  size: 16,
                                  color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Ch ${i + 1}: ${ch.title}',
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.menu_book_rounded, size: 16, color: Color(0xFF1E3A8A)),
                            const SizedBox(width: 6),
                            Text(
                              'Ch ${state.chapterIndex + 1}/${demoChaptersRegistry.length}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, size: 18, color: Color(0xFF1E3A8A)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Virtual Clock Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time_filled, size: 14, color: Color(0xFF475569)),
                          const SizedBox(width: 6),
                          Text(
                            state.virtualClock.format(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Fast-Forward 48 Hours Button (for Escrow & Dispute Window)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        side: const BorderSide(color: Color(0xFF0F766E)),
                        foregroundColor: const Color(0xFF0F766E),
                      ),
                      icon: const Icon(Icons.fast_forward_rounded, size: 14),
                      label: const Text(
                        '+48h Dispute',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        controller.fastForward48Hours();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Fast-forwarded 48 hours to: ${state.virtualClock.format()}. Escrow dispute window expired.',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 6),

                    // Reset Walkthrough Button
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF64748B)),
                      tooltip: 'Reset Demo',
                      onPressed: () => _showResetConfirmation(context, ref),
                    ),

                    // Exit to App Button
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF64748B)),
                      tooltip: 'Exit Demo',
                      onPressed: () => _showExitConfirmation(context),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Actor Switcher Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const Text(
                    'Perspective:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: DemoActor.values.map((actor) {
                          final isSelected = state.selectedActor == actor;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: FilterChip(
                              label: Text(actor.label),
                              avatar: Icon(actor.icon, size: 14, color: isSelected ? Colors.white : actor.color),
                              selected: isSelected,
                              selectedColor: actor.color,
                              labelStyle: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : const Color(0xFF334155),
                              ),
                              onSelected: (_) => controller.setActor(actor),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  // Presenter Notes Toggle
                  IconButton(
                    icon: Icon(
                      state.showPresenterNotes ? Icons.record_voice_over : Icons.voice_over_off,
                      size: 18,
                      color: state.showPresenterNotes ? const Color(0xFFB45309) : Colors.grey,
                    ),
                    tooltip: 'Toggle Presenter Notes',
                    onPressed: () => controller.togglePresenterNotes(),
                  ),
                ],
              ),
            ),

            // 4. Chapter & Step Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                border: Border(bottom: BorderSide(color: Color(0xFFCBD5E1))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PILLAR ${currentChapter.pillarNumber}: ${currentChapter.title.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Step ${state.stepIndex + 1}/${currentChapter.steps.length}: ${currentStep.title}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: currentStep.actor.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          currentStep.actor.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: currentStep.actor.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentStep.whatItIs,
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                  ),
                ],
              ),
            ),

            // 5. Presenter Notes Talking Points Bar (Collapsible)
            if (state.showPresenterNotes)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  border: Border(bottom: BorderSide(color: Color(0xFFFDE68A))),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.campaign_rounded, size: 18, color: Color(0xFF92400E)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'TALKING POINT: ${currentStep.presenterNote}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF78350F),
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 6. Interactive Step Content
            Expanded(
              child: Builder(
                builder: (ctx) => currentStep.builder(ctx, ref),
              ),
            ),

            // 7. Overall Walkthrough Progress Bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
              minHeight: 4,
            ),

            // 8. Bottom Navigation Controls (Next, Back, Step Indicator)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  // Back Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Back', style: TextStyle(fontWeight: FontWeight.w600)),
                    onPressed: (state.chapterIndex == 0 && state.stepIndex == 0)
                        ? null
                        : () => controller.previousStep(),
                  ),

                  const Spacer(),

                  // Global Step Counter
                  Text(
                    'Step ${currentGlobalStep + 1} of $totalSteps',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),

                  const Spacer(),

                  // Next Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    label: Text(
                      (state.chapterIndex == demoChaptersRegistry.length - 1 &&
                              state.stepIndex == currentChapter.steps.length - 1)
                          ? 'Finish'
                          : 'Next',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    onPressed: (state.chapterIndex == demoChaptersRegistry.length - 1 &&
                            state.stepIndex == currentChapter.steps.length - 1)
                        ? () => _showExitConfirmation(context)
                        : () => controller.nextStep(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
