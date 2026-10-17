import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/w_card.dart';
import '../../core/widgets/w_button.dart';
import '../../core/widgets/error_state.dart';
import '../../core/api/dio_client.dart';
import 'sessions_api_service.dart';
import 'session_models.dart';
import 'sessions_error_helper.dart';

class ConnectPage extends ConsumerStatefulWidget {
  final String giverId;
  final String giverName;
  final bool isOnlineNow;
  final bool isOwnCollege;
  final String studentPlan; // Campus, Standard, High, Premium
  final String? prefilledIntent;

  const ConnectPage({
    super.key,
    required this.giverId,
    required this.giverName,
    this.isOnlineNow = false,
    this.isOwnCollege = true,
    this.studentPlan = 'Standard',
    this.prefilledIntent,
  });

  @override
  ConsumerState<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends ConsumerState<ConnectPage> {
  late TextEditingController _intentController;
  late bool _isInstant;
  DateTime? _selectedSlot;
  List<SlotItem> _slots = [];
  bool _isLoadingSlots = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isInstant = widget.isOnlineNow;
    _intentController = TextEditingController(
      text: widget.prefilledIntent ?? 'Hi, I would love to connect for guidance on career transitions and resume feedback.',
    );
    if (!_isInstant) {
      _loadSlots();
    }
  }

  @override
  void dispose() {
    _intentController.dispose();
    super.dispose();
  }

  Future<void> _loadSlots() async {
    setState(() {
      _isLoadingSlots = true;
      _errorMessage = null;
    });
    try {
      final api = ref.read(sessionsApiServiceProvider);
      final slots = await api.getGiverSlots(widget.giverId);
      setState(() {
        _slots = slots;
        _isLoadingSlots = false;
        if (slots.isNotEmpty) {
          _selectedSlot = slots.first.slotStart;
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingSlots = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _submitRequest() async {
    final intent = _intentController.text.trim();
    if (intent.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a clear intent statement (at least 5 characters).')),
      );
      return;
    }

    if (!_isInstant && _selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an available booking slot.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(sessionsApiServiceProvider);
      final req = await api.createRequest(
        giverId: widget.giverId,
        kind: _isInstant ? 'instant' : 'booked',
        intentText: intent,
        slotStart: _isInstant ? null : _selectedSlot,
        idempotencyKey: 'req_\${DateTime.now().millisecondsSinceEpoch}',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection request sent successfully!')),
      );
      context.pop(req);
    } catch (e) {
      String displayError = 'Failed to submit request.';
      if (e is AppException) {
        displayError = translateSessionError(e.code, e.message);
      } else {
        displayError = e.toString();
      }
      setState(() {
        _isSubmitting = false;
        _errorMessage = displayError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final disclosure = getCreditDisclosureText(
      isOwnCollege: widget.isOwnCollege,
      planName: widget.studentPlan,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Connect with \${widget.giverName}'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Mode Toggle
          if (widget.isOnlineNow)
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Instant Connect (Online Now)')),
                    selected: _isInstant,
                    selectedColor: AppColors.teal.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: _isInstant ? AppColors.teal : AppColors.textDark,
                      fontWeight: _isInstant ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (val) {
                      setState(() => _isInstant = true);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Book Future Slot')),
                    selected: !_isInstant,
                    selectedColor: AppColors.deepIndigo.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: !_isInstant ? AppColors.deepIndigo : AppColors.textDark,
                      fontWeight: !_isInstant ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (val) {
                      setState(() => _isInstant = false);
                      if (_slots.isEmpty) _loadSlots();
                    },
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),

          // Credit Disclosure Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isOwnCollege ? AppColors.teal.withOpacity(0.12) : AppColors.amber.withOpacity(0.12),
              borderRadius: AppRadii.badge,
              border: Border.all(
                color: widget.isOwnCollege ? AppColors.teal.withOpacity(0.4) : AppColors.amber.withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  widget.isOwnCollege ? Icons.verified_user : Icons.monetization_on_outlined,
                  color: widget.isOwnCollege ? AppColors.teal : AppColors.amber,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    disclosure,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: widget.isOwnCollege ? AppColors.teal : AppColors.amber,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Intent Text Box
          WCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What do you want to accomplish?',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Be specific about your current background and questions. Contact info will be auto-masked.',
                  style: TextStyle(fontSize: 13, color: AppColors.slate),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _intentController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'e.g. Seeking advice on transitioning from backend to ML engineering...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Slot Picker (if booked)
          if (!_isInstant)
            WCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select a 20-Minute Slot',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Booking horizon: \${widget.studentPlan == "Premium" ? "30 days" : widget.studentPlan == "High" ? "14 days" : "3 days"}',
                    style: const TextStyle(fontSize: 12, color: AppColors.slate),
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingSlots)
                    const Center(child: CircularProgressIndicator())
                  else if (_slots.isEmpty)
                    const Text('No slots currently open within your booking window.')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _slots.map((s) {
                        final selected = _selectedSlot == s.slotStart;
                        final format = DateFormat('EEE, MMM d • h:mm a');
                        return ChoiceChip(
                          label: Text(format.format(s.slotStart.toLocal())),
                          selected: selected,
                          selectedColor: AppColors.primaryAction.withOpacity(0.15),
                          labelStyle: TextStyle(
                            color: selected ? AppColors.primaryAction : AppColors.textDark,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _selectedSlot = s.slotStart);
                          },
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: AppRadii.badge,
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          WButton(
            label: _isInstant ? 'Send Instant Request' : 'Confirm Slot Booking',
            isLoading: _isSubmitting,
            onPressed: _submitRequest,
          ),
        ],
      ),
    );
  }
}
