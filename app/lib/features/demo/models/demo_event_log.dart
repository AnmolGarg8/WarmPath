// allow-mock-file: guided demo, simulated and labelled

class VirtualClock {
  DateTime _currentTime;
  final DateTime _baseTime;

  VirtualClock({DateTime? initialTime})
      : _currentTime = initialTime ?? DateTime(2026, 10, 18, 10, 0),
        _baseTime = initialTime ?? DateTime(2026, 10, 18, 10, 0);

  DateTime get currentTime => _currentTime;

  void advanceMinutes(int minutes) {
    _currentTime = _currentTime.add(Duration(minutes: minutes));
  }

  void fastForwardHours(int hours) {
    _currentTime = _currentTime.add(Duration(hours: hours));
  }

  void reset() {
    _currentTime = _baseTime;
  }

  int get dayNumber {
    final diff = _currentTime.difference(_baseTime);
    return diff.inDays + 1;
  }

  String format() {
    final hour = _currentTime.hour;
    final minute = _currentTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour % 12 == 0 ? 12 : hour % 12;
    return 'Day $dayNumber, $formattedHour:$minute $period';
  }
}

class DemoEvent {
  final String id;
  final String type;
  final String actor;
  final String description;
  final String virtualTime;
  final Map<String, dynamic> payload;

  const DemoEvent({
    required this.id,
    required this.type,
    required this.actor,
    required this.description,
    required this.virtualTime,
    this.payload = const {},
  });
}

class DemoEventLog {
  final List<DemoEvent> _events = [];

  List<DemoEvent> get events => List.unmodifiable(_events);

  void append(DemoEvent event) {
    _events.add(event);
  }

  void log({
    required String type,
    required String actor,
    required String description,
    required String virtualTime,
    Map<String, dynamic> payload = const {},
  }) {
    _events.add(
      DemoEvent(
        id: 'evt_${_events.length + 1}_${DateTime.now().microsecondsSinceEpoch}',
        type: type,
        actor: actor,
        description: description,
        virtualTime: virtualTime,
        payload: payload,
      ),
    );
  }

  List<DemoEvent> eventsOfType(String type) {
    return _events.where((e) => e.type == type).toList();
  }

  List<DemoEvent> eventsForActor(String actor) {
    return _events.where((e) => e.actor == actor).toList();
  }

  int countOfType(String type) {
    return _events.where((e) => e.type == type).length;
  }

  void clear() {
    _events.clear();
  }
}
