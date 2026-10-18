// allow-mock-file: guided demo, simulated and labelled
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'demo_event_log.dart';

enum DemoActor {
  student('Student', Icons.school_rounded, Color(0xFF1E3A8A)),
  giver('Giver (Alumnus)', Icons.person_rounded, Color(0xFF0F766E)),
  moderator('Moderator', Icons.shield_rounded, Color(0xFFB45309)),
  institution('Institution Admin', Icons.account_balance_rounded, Color(0xFF4338CA));

  final String label;
  final IconData icon;
  final Color color;

  const DemoActor(this.label, this.icon, this.color);
}

class DemoStep {
  final String title;
  final String whatItIs;
  final DemoActor actor;
  final String presenterNote;
  final Widget Function(BuildContext context, WidgetRef ref) builder;
  final void Function(DemoEventLog log, VirtualClock clock)? onEnter;

  const DemoStep({
    required this.title,
    required this.whatItIs,
    required this.actor,
    required this.presenterNote,
    required this.builder,
    this.onEnter,
  });
}

class DemoChapter {
  final String id;
  final int pillarNumber;
  final String title;
  final String summary;
  final List<DemoStep> steps;

  const DemoChapter({
    required this.id,
    required this.pillarNumber,
    required this.title,
    required this.summary,
    required this.steps,
  });
}
