import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/w_card.dart';
import '../../core/widgets/w_button.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/skeleton_box.dart';
import 'availability_models.dart';
import 'availability_controller.dart';

class AvailabilityPage extends ConsumerStatefulWidget {
  const AvailabilityPage({super.key});

  @override
  ConsumerState<AvailabilityPage> createState() => _AvailabilityPageState();
}

class _AvailabilityPageState extends ConsumerState<AvailabilityPage> {
  int _selectedOnlineMinutes = 30;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(availabilityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giver Availability & Status'),
        backgroundColor: AppColors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: state.isLoading && state.data == null
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null && state.data == null
              ? ErrorState(
                  message: state.errorMessage!,
                  onRetry: () => ref.read(availabilityProvider.notifier).loadAvailability(),
                )
              : _buildContent(context, state),
    );
  }

  Widget _buildContent(BuildContext context, AvailabilityState state) {
    final data = state.data;
    if (data == null) return const SizedBox.shrink();

    final isOnline = state.onlineStatus?.onlineNow ?? false;
    final remainingSecs = state.onlineSecondsRemaining;
    final minsLeft = remainingSecs ~/ 60;
    final secsLeft = remainingSecs % 60;

    return RefreshIndicator(
      onRefresh: () => ref.read(availabilityProvider.notifier).loadAvailability(),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. Instant Online Control Card
          WCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline ? AppColors.teal : AppColors.slate.withOpacity(0.4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOnline ? 'Online Now (Instant Connect Open)' : 'Currently Offline',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isOnline ? AppColors.teal : AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isOnline
                      ? 'Closing in \${minsLeft.toString().padLeft(2, "0")}:\${secsLeft.toString().padLeft(2, "0")}. Students can connect instantly.'
                      : 'Open an instant connect window for incoming student requests without prior scheduling.',
                  style: const TextStyle(fontSize: 14, color: AppColors.slate),
                ),
                const SizedBox(height: 16),
                if (isOnline) ...[
                  WButton(
                    label: 'Stop & Go Offline',
                    backgroundColor: AppColors.slate,
                    onPressed: () => ref.read(availabilityProvider.notifier).goOffline(),
                  ),
                ] else ...[
                  Wrap(
                    spacing: 8,
                    children: [15, 30, 60].map((mins) {
                      final selected = _selectedOnlineMinutes == mins;
                      return ChoiceChip(
                        label: Text('\$mins mins'),
                        selected: selected,
                        selectedColor: AppColors.teal.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: selected ? AppColors.teal : AppColors.textDark,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedOnlineMinutes = mins);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  WButton(
                    label: 'Go Online for \$_selectedOnlineMinutes Minutes',
                    backgroundColor: AppColors.teal,
                    isLoading: state.isLoading,
                    onPressed: () => ref.read(availabilityProvider.notifier).goOnline(_selectedOnlineMinutes),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Weekly Capacity Card
          WCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly Session Capacity',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 4),
                Text(
                  'Used this week: \${data.usedThisWeek} of \${data.weeklyCapacity} sessions (\${data.capacityLeft} slots remaining)',
                  style: const TextStyle(fontSize: 14, color: AppColors.slate),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      color: data.weeklyCapacity > 1 ? AppColors.primaryAction : AppColors.slate,
                      onPressed: data.weeklyCapacity > 1
                          ? () => ref.read(availabilityProvider.notifier).updateCapacity(data.weeklyCapacity - 1)
                          : null,
                    ),
                    Text(
                      '\${data.weeklyCapacity} sessions / week',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppColors.primaryAction,
                      onPressed: () => ref.read(availabilityProvider.notifier).updateCapacity(data.weeklyCapacity + 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Timezone & Recurring Windows Card
          WCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recurring Availability Windows',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppColors.teal),
                      tooltip: 'Add Window',
                      onPressed: () => _showAddWindowDialog(context),
                    ),
                  ],
                ),
                Text(
                  'Timezone: \${data.timezone}',
                  style: const TextStyle(fontSize: 13, color: AppColors.slate, fontWeight: FontWeight.w500),
                ),
                const Divider(height: 24),
                if (data.windows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'No recurring windows set yet. Add available days & hours below.',
                      style: TextStyle(color: AppColors.slate, fontStyle: FontStyle.italic),
                    ),
                  )
                else
                  ...data.windows.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final w = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadii.badge,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.deepIndigo.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  w.weekdayShort,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: AppColors.deepIndigo,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '\${w.startTime} - \${w.endTime}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () => ref.read(availabilityProvider.notifier).removeWindow(idx),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddWindowDialog(BuildContext context) {
    int selectedWeekday = 0;
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final startStr = '\${startTime.hour.toString().padLeft(2, "0")}:\${startTime.minute.toString().padLeft(2, "0")}';
          final endStr = '\${endTime.hour.toString().padLeft(2, "0")}:\${endTime.minute.toString().padLeft(2, "0")}';

          return AlertDialog(
            title: const Text('Add Availability Window'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedWeekday,
                  decoration: const InputDecoration(labelText: 'Day of Week'),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Monday')),
                    DropdownMenuItem(value: 1, child: Text('Tuesday')),
                    DropdownMenuItem(value: 2, child: Text('Wednesday')),
                    DropdownMenuItem(value: 3, child: Text('Thursday')),
                    DropdownMenuItem(value: 4, child: Text('Friday')),
                    DropdownMenuItem(value: 5, child: Text('Saturday')),
                    DropdownMenuItem(value: 6, child: Text('Sunday')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedWeekday = val);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final picked = await showTimePicker(context: ctx, initialTime: startTime);
                          if (picked != null) setDialogState(() => startTime = picked);
                        },
                        child: Text('Start: \$startStr'),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final picked = await showTimePicker(context: ctx, initialTime: endTime);
                          if (picked != null) setDialogState(() => endTime = picked);
                        },
                        child: Text('End: \$endStr'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final window = TimeWindow(
                    weekday: selectedWeekday,
                    startTime: startStr,
                    endTime: endStr,
                  );
                  if (window.isValid()) {
                    ref.read(availabilityProvider.notifier).addWindow(window);
                    Navigator.of(ctx).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Start time must be before end time.')),
                    );
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }
}
