/// Lightweight serialisable history used by the lane composer.
///
/// This is deliberately section-ID-only state. It contains no credentials or
/// media history and can live locally first; a future Moonbase implementation
/// may persist it per user for cross-device consistency.
class SeerrDiscoveryRotationHistory {
  int _sessionNumber;
  final Map<String, int> _lastSeenSession;
  final int maxEntries;

  SeerrDiscoveryRotationHistory({
    int sessionNumber = 0,
    Map<String, int>? lastSeenSession,
    this.maxEntries = 512,
  })  : _sessionNumber = sessionNumber < 0 ? 0 : sessionNumber,
        _lastSeenSession = Map<String, int>.from(lastSeenSession ?? const {});

  factory SeerrDiscoveryRotationHistory.fromJson(
    Map<String, dynamic> json, {
    int maxEntries = 512,
  }) {
    final raw = json['lastSeenSession'] as Map? ?? const {};
    return SeerrDiscoveryRotationHistory(
      sessionNumber: (json['sessionNumber'] as num?)?.toInt() ?? 0,
      lastSeenSession: raw.map(
        (key, value) => MapEntry(key.toString(), (value as num).toInt()),
      ),
      maxEntries: maxEntries,
    );
  }

  int get sessionNumber => _sessionNumber;

  /// Age map expected by [SeerrDiscoveryComposer.compose].
  ///
  /// `0` means shown in the latest committed session, `1` means one session
  /// ago, and so on.
  Map<String, int> get sessionsSinceSeen => {
        for (final entry in _lastSeenSession.entries)
          entry.key: (_sessionNumber - 1 - entry.value).clamp(0, 1 << 30),
      };

  void commitSession(Iterable<String> selectedSectionIds) {
    final current = _sessionNumber;
    for (final id in selectedSectionIds) {
      final trimmed = id.trim();
      if (trimmed.isNotEmpty) _lastSeenSession[trimmed] = current;
    }
    _sessionNumber++;
    _trim();
  }

  void clear() {
    _sessionNumber = 0;
    _lastSeenSession.clear();
  }

  Map<String, dynamic> toJson() => {
        'sessionNumber': _sessionNumber,
        'lastSeenSession': _lastSeenSession,
      };

  void _trim() {
    if (_lastSeenSession.length <= maxEntries) return;
    final entries = _lastSeenSession.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    _lastSeenSession
      ..clear()
      ..addEntries(entries.take(maxEntries));
  }
}
