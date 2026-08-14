import 'package:flutter/material.dart';
import 'package:moonfin_design/moonfin_design.dart';

import '../../../data/services/seerr/seerr_discovery_browse_refinements.dart';

class SeerrDiscoveryRefinementDialog extends StatefulWidget {
  final String mediaType;
  final SeerrDiscoveryBrowseRefinements initial;

  const SeerrDiscoveryRefinementDialog({
    super.key,
    required this.mediaType,
    required this.initial,
  });

  @override
  State<SeerrDiscoveryRefinementDialog> createState() =>
      _SeerrDiscoveryRefinementDialogState();
}

class _SeerrDiscoveryRefinementDialogState
    extends State<SeerrDiscoveryRefinementDialog> {
  late Set<int> _genres;
  late RangeValues _years;
  late RangeValues _runtime;
  late double _rating;
  late int _votes;
  late String _language;

  int get _maxYear => DateTime.now().year + 2;

  @override
  void initState() {
    super.initState();
    _genres = Set<int>.from(widget.initial.genreIds);
    _years = RangeValues(
      (widget.initial.yearFrom ?? 1900).toDouble(),
      (widget.initial.yearTo ?? _maxYear).toDouble(),
    );
    _runtime = RangeValues(
      (widget.initial.runtimeMin ?? 0).toDouble(),
      (widget.initial.runtimeMax ?? 240).toDouble(),
    );
    _rating = widget.initial.minimumRating ?? 0;
    _votes = widget.initial.minimumVotes ?? 0;
    _language = widget.initial.originalLanguage ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final genres = SeerrDiscoveryBrowseTaxonomy.genresFor(widget.mediaType);
    return AlertDialog(
      backgroundColor: AppColorScheme.surface,
      title: const Text('Refine discovery'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 680),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'These filters only narrow this collection. The lane’s original '
                'filters stay locked.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColorScheme.onSurface.withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 20),
              _sectionTitle(context, 'Genres — all selected must match'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final genre in genres)
                    FilterChip(
                      label: Text(genre.label),
                      selected: _genres.contains(genre.id),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _genres.add(genre.id);
                          } else {
                            _genres.remove(genre.id);
                          }
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 22),
              _sectionTitle(
                context,
                'Release years: ${_years.start.round()}–${_years.end.round()}',
              ),
              RangeSlider(
                values: _years,
                min: 1900,
                max: _maxYear.toDouble(),
                divisions: _maxYear - 1900,
                labels: RangeLabels(
                  _years.start.round().toString(),
                  _years.end.round().toString(),
                ),
                onChanged: (value) => setState(() => _years = value),
              ),
              const SizedBox(height: 12),
              _sectionTitle(
                context,
                _rating <= 0
                    ? 'Minimum rating: Any'
                    : 'Minimum rating: ${_rating.toStringAsFixed(1)}',
              ),
              Slider(
                value: _rating,
                min: 0,
                max: 9,
                divisions: 18,
                label: _rating <= 0 ? 'Any' : _rating.toStringAsFixed(1),
                onChanged: (value) => setState(() => _rating = value),
              ),
              const SizedBox(height: 12),
              _sectionTitle(context, 'Minimum vote count'),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                initialValue: _votes,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Any')),
                  DropdownMenuItem(value: 50, child: Text('50+')),
                  DropdownMenuItem(value: 100, child: Text('100+')),
                  DropdownMenuItem(value: 250, child: Text('250+')),
                  DropdownMenuItem(value: 500, child: Text('500+')),
                  DropdownMenuItem(value: 1000, child: Text('1,000+')),
                  DropdownMenuItem(value: 5000, child: Text('5,000+')),
                  DropdownMenuItem(value: 10000, child: Text('10,000+')),
                ],
                onChanged: (value) => setState(() => _votes = value ?? 0),
              ),
              const SizedBox(height: 22),
              _sectionTitle(
                context,
                'Runtime: ${_runtime.start.round()}–${_runtime.end.round()} min',
              ),
              RangeSlider(
                values: _runtime,
                min: 0,
                max: 240,
                divisions: 48,
                labels: RangeLabels(
                  '${_runtime.start.round()} min',
                  _runtime.end >= 240
                      ? '240+ min'
                      : '${_runtime.end.round()} min',
                ),
                onChanged: (value) => setState(() => _runtime = value),
              ),
              const SizedBox(height: 12),
              _sectionTitle(context, 'Original language'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _language,
                isExpanded: true,
                items: [
                  for (final language in SeerrDiscoveryBrowseTaxonomy.languages)
                    DropdownMenuItem(
                      value: language.key,
                      child: Text(language.value),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _language = value ?? ''),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            const SeerrDiscoveryBrowseRefinements(),
          ),
          child: const Text('Reset'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_result()),
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String text) => Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      );

  SeerrDiscoveryBrowseRefinements _result() {
    final yearFrom = _years.start.round() <= 1900 ? null : _years.start.round();
    final yearTo = _years.end.round() >= _maxYear ? null : _years.end.round();
    final runtimeMin = _runtime.start.round() <= 0 ? null : _runtime.start.round();
    final runtimeMax = _runtime.end.round() >= 240 ? null : _runtime.end.round();
    return SeerrDiscoveryBrowseRefinements(
      genreIds: Set<int>.unmodifiable(_genres),
      yearFrom: yearFrom,
      yearTo: yearTo,
      minimumRating: _rating <= 0 ? null : _rating,
      minimumVotes: _votes <= 0 ? null : _votes,
      runtimeMin: runtimeMin,
      runtimeMax: runtimeMax,
      originalLanguage: _language.isEmpty ? null : _language,
    );
  }
}
