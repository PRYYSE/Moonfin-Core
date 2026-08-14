import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:moonfin_design/moonfin_design.dart';

import '../../../data/services/seerr/seerr_discovery_catalogue_index.dart';
import '../../../data/services/seerr/seerr_discovery_route_codec.dart';
import '../../../data/services/seerr/seerr_discovery_schema.dart';
import '../../../data/viewmodels/seerr_deep_discovery_view_model.dart';
import '../../../util/platform_detection.dart';
import '../../navigation/destinations.dart';
import '../../widgets/navigation_layout.dart';
import '../../widgets/quick_return_wrapper.dart';

class SeerrDiscoveryCatalogueScreen extends StatefulWidget {
  final String tabId;

  const SeerrDiscoveryCatalogueScreen({
    super.key,
    required this.tabId,
  });

  @override
  State<SeerrDiscoveryCatalogueScreen> createState() =>
      _SeerrDiscoveryCatalogueScreenState();
}

class _SeerrDiscoveryCatalogueScreenState
    extends State<SeerrDiscoveryCatalogueScreen> {
  late final SeerrDeepDiscoveryViewModel _viewModel;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _viewModel = GetIt.instance<SeerrDeepDiscoveryViewModel>();
    _viewModel.addListener(_onChanged);
    if (_viewModel.catalogue == null) {
      unawaited(_viewModel.load());
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  SeerrDiscoveryTab? get _tab {
    for (final tab in _viewModel.tabs) {
      if (tab.id == widget.tabId) return tab;
    }
    return null;
  }

  void _openSection(SeerrDiscoverySection section) {
    if (!section.expandable) return;
    final uri = Uri(
      path: Destinations.seerrBrowse,
      queryParameters: SeerrDiscoveryRouteCodec.encode(
        section.query,
        title: section.title,
        sectionId: section.id,
      ),
    );
    context.push(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final tab = _tab;
    return Scaffold(
      backgroundColor: AppColorScheme.background,
      body: NavigationLayout(
        showBackButton: true,
        child: SafeArea(
          child: tab == null
              ? _buildUnavailable()
              : QuickReturnWrapper(
                  scrollController: _scrollController,
                  child: _buildCatalogue(tab),
                ),
        ),
      ),
    );
  }

  Widget _buildUnavailable() {
    if (_viewModel.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColorScheme.accent),
      );
    }
    return Center(
      child: Text(
        'This Discovery category is unavailable.',
        style: TextStyle(
          color: AppColorScheme.onSurface.withValues(alpha: 0.72),
        ),
      ),
    );
  }

  Widget _buildCatalogue(SeerrDiscoveryTab tab) {
    final groups = SeerrDiscoveryCatalogueIndex.groups(tab);
    final count = SeerrDiscoveryCatalogueIndex.expandableCount(tab);
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = PlatformDetection.useMobileUi
        ? 16.0
        : width >= 1600
        ? 72.0
        : 48.0;

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            PlatformDetection.isTV ? 28 : 18,
            horizontalPadding,
            18,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All ${tab.title}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$count discovery paths — open any category for its full collection.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColorScheme.onSurface.withValues(alpha: 0.68),
                  ),
                ),
              ],
            ),
          ),
        ),
        for (final group in groups) ...[
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              14,
              horizontalPadding,
              10,
            ),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      group.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${group.sections.length}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColorScheme.onSurface.withValues(alpha: 0.52),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              0,
              horizontalPadding,
              16,
            ),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: PlatformDetection.isTV ? 380 : 320,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: PlatformDetection.useMobileUi ? 2.35 : 2.9,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final section = group.sections[index];
                  return _DiscoveryCatalogueTile(
                    section: section,
                    onTap: () => _openSection(section),
                  );
                },
                childCount: group.sections.length,
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 48)),
      ],
    );
  }
}

class _DiscoveryCatalogueTile extends StatefulWidget {
  final SeerrDiscoverySection section;
  final VoidCallback onTap;

  const _DiscoveryCatalogueTile({
    required this.section,
    required this.onTap,
  });

  @override
  State<_DiscoveryCatalogueTile> createState() =>
      _DiscoveryCatalogueTileState();
}

class _DiscoveryCatalogueTileState extends State<_DiscoveryCatalogueTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final accent = AppColorScheme.accent;
    final onSurface = AppColorScheme.onSurface;
    final surface = Theme.of(context).colorScheme.surface;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onFocusChange: (focused) {
          if (mounted) setState(() => _focused = focused);
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: _focused
                ? accent.withValues(alpha: 0.18)
                : surface.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _focused
                  ? accent.withValues(alpha: 0.95)
                  : onSurface.withValues(alpha: 0.12),
              width: _focused ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.section.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (widget.section.subtitle?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 3),
                      Text(
                        widget.section.subtitle!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: onSurface.withValues(alpha: 0.58),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: onSurface.withValues(alpha: _focused ? 0.95 : 0.52),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
