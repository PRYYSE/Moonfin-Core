/// Safe allow-list and normalisation for Moonfin deep-discovery filters.
///
/// These names mirror Seerr's current discover route schema. The clients may
/// receive discovery definitions from Moonbase/server configuration, but they
/// must never forward arbitrary query parameters to Seerr. Keeping this policy
/// in one place protects auth/session parameters and makes schema upgrades
/// explicit.
class SeerrDiscoveryFilterPolicy {
  const SeerrDiscoveryFilterPolicy._();

  static const allowed = <String>{
    'primaryReleaseDateGte',
    'primaryReleaseDateLte',
    'firstAirDateGte',
    'firstAirDateLte',
    'studio',
    'genre',
    'keywords',
    'excludeKeywords',
    'language',
    'withRuntimeGte',
    'withRuntimeLte',
    'voteAverageGte',
    'voteAverageLte',
    'voteCountGte',
    'voteCountLte',
    'network',
    'watchProviders',
    'watchRegion',
    'status',
    'certification',
    'certificationGte',
    'certificationLte',
    'certificationCountry',
  };

  /// Keys whose values can safely be token-expanded from server configuration.
  static const _dateKeys = <String>{
    'primaryReleaseDateGte',
    'primaryReleaseDateLte',
    'firstAirDateGte',
    'firstAirDateLte',
  };

  /// Extracts the `q.*` namespace used by the full-screen route and drops all
  /// unsupported keys. Values are trimmed and empty values are omitted.
  static Map<String, String> fromRouteParameters(
    Map<String, String> routeParameters, {
    DateTime? now,
  }) {
    final raw = <String, String>{};
    for (final entry in routeParameters.entries) {
      if (!entry.key.startsWith('q.')) continue;
      raw[entry.key.substring(2)] = entry.value;
    }
    return sanitise(raw, now: now);
  }

  static Map<String, String> sanitise(
    Map<String, String> filters, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final output = <String, String>{};
    for (final entry in filters.entries) {
      if (!allowed.contains(entry.key)) continue;
      var value = entry.value.trim();
      if (value.isEmpty) continue;
      if (_dateKeys.contains(entry.key)) {
        value = _resolveDateToken(value, clock);
      }
      if (value.isNotEmpty) output[entry.key] = value;
    }
    return output;
  }

  /// Allows long-lived server configuration to describe moving windows without
  /// hard-coding a year. Literal ISO dates pass through unchanged.
  ///
  /// Supported tokens:
  /// - `$today`
  /// - `$yearStart`
  /// - `$yearEnd`
  /// - `$monthsAgo:N`
  /// - `$monthsFromNow:N`
  /// - `$yearsAgo:N`
  /// - `$yearsFromNow:N`
  static String _resolveDateToken(String value, DateTime now) {
    if (!value.startsWith(r'$')) return value;

    final date = DateTime(now.year, now.month, now.day);
    if (value == r'$today') return _isoDate(date);
    if (value == r'$yearStart') return _isoDate(DateTime(date.year, 1, 1));
    if (value == r'$yearEnd') return _isoDate(DateTime(date.year, 12, 31));

    final parts = value.substring(1).split(':');
    if (parts.length != 2) return '';
    final amount = int.tryParse(parts[1]);
    if (amount == null || amount < 0 || amount > 120) return '';

    return switch (parts[0]) {
      'monthsAgo' => _isoDate(_shiftMonths(date, -amount)),
      'monthsFromNow' => _isoDate(_shiftMonths(date, amount)),
      'yearsAgo' => _isoDate(
        _safeDate(date.year - amount, date.month, date.day),
      ),
      'yearsFromNow' => _isoDate(
        _safeDate(date.year + amount, date.month, date.day),
      ),
      _ => '',
    };
  }

  static DateTime _shiftMonths(DateTime date, int delta) {
    final zeroBased = (date.year * 12 + date.month - 1) + delta;
    final year = zeroBased ~/ 12;
    final month = zeroBased % 12 + 1;
    return _safeDate(year, month, date.day);
  }

  static DateTime _safeDate(int year, int month, int day) {
    final firstNextMonth = month == 12
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
    final lastDay = firstNextMonth.subtract(const Duration(days: 1)).day;
    return DateTime(year, month, day.clamp(1, lastDay));
  }

  static String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
