import 'package:flutter/material.dart';
import 'package:warmpath_app/core/widgets/empty_state.dart';

class SessionsPage extends StatelessWidget {
  const SessionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Sessions")),
      body: const EmptyState(
        title: "No active sessions",
        description: "Explore recommendations and request a structured mentorship connection.",
        icon: Icons.calendar_today_outlined,
      ),
    );
  }
}
