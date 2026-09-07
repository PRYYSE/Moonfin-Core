/// Small serialisable selection history used by the Discovery composer.
///
/// This stores section IDs and session counters only. It deliberately contains
/// no credentials, media metadata, watch history, favourites or ratings.
class HomeLabDiscoveryRotationHistory {
  int _sessionNumber;
  final Map<String, int> _lastSeenSession;
  final int maxEntries;

  HomeLabDiscoveryRotationHistory({
    int sessionNumber = 0,
    Map<String, int>? lastSeenSession,
    this.maxEntries = 512,
  }) : _sessionNumber = sessionNumber < 0 ? 0 : sessionNumber,
       _lastSeenSession = Map<String, int>.from(lastSeenSession ?? const {});

  factory HomeLabDiscoveryRotationHistory.fromJson(
    Map<String, dynamic> json, {
    int maxEntries = 512,
  }) {
    final raw = json['lastSeenSession'] as Map? ?? const {};
    return HomeLabDiscoveryRotationHistory(
      sessionNumber: (json['sessionNumber'] as num?)?.toInt() ?? 0,
      lastSeenSession: raw.map(
        (key, value) => MapEntry(key.toString(), (value as num).toInt()),
      ),
      maxEntries: maxEntries,
    );
  }

  int get sessionNumber => _sessionNumber;

  /// Age map expected by [HomeLabDiscoveryComposer.compose].
  ///
  /// `0` means shown in the latest committed session, `1` means one session
  /// ago, and so on.
  Map<String, int> get sessionsSinceSeen => {
    for (final entry in _lastSeenSession.entries)
      entry.key: (_sessionNumber - 1 - entry.value).clamp(0, 1 << 30).toInt(),
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
