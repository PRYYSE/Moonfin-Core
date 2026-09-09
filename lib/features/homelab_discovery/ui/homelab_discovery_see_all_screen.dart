import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/services/seerr/seerr_api_models.dart';
import '../../../ui/navigation/destinations.dart';
import '../../../ui/widgets/navigation_layout.dart';
import '../../../util/platform_detection.dart';
import '../engine/discovery_see_all_controller.dart';
import 'discovery_adaptive_layout.dart';
import 'discovery_media_card.dart';
import 'discovery_tv_grid.dart';

class HomeLabDiscoverySeeAllScreen extends StatefulWidget {
  final HomeLabDiscoverySeeAllController controller;

  const HomeLabDiscoverySeeAllScreen({super.key, required this.controller});

  @override
  State<HomeLabDiscoverySeeAllScreen> createState() =>
      _HomeLabDiscoverySeeAllScreenState();
}

class _HomeLabDiscoverySeeAllScreenState
    extends State<HomeLabDiscoverySeeAllScreen> {
  late Future<HomeLabDiscoverySeeAllState> _initialFuture;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<HomeLabDiscoveryTvGridState> _tvGridKey =
      GlobalKey<HomeLabDiscoveryTvGridState>();
  final FocusNode _tvRefreshFocusNode = FocusNode(
    debugLabel: 'HomeLabDiscoveryDeepRefresh',
  );
  final FocusNode _tvRetryMoreFocusNode = FocusNode(
    debugLabel: 'HomeLabDiscoveryDeepRetryMore',
  );
  HomeLabDiscoverySeeAllState? _state;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _initialFuture = _loadInitial();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _tvRefreshFocusNode.dispose();
    _tvRetryMoreFocusNode.dispose();
    super.dispose();
  }

  Future<HomeLabDiscoverySeeAllState> _loadInitial() async {
    final state = await widget.controller.loadInitial();
    if (mounted) _state = state;
    return state;
  }

  void _retryInitial() {
    setState(() {
      _state = null;
      _initialFuture = _loadInitial();
    });
  }

  Future<void> _refresh() async {
    final state = await widget.controller.refresh();
    if (!mounted) return;
    setState(() => _state = state);
    _restoreTvGridFocus();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 900) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    final current = _state;
    if (_loadingMore || current == null || !current.hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final state = await widget.controller.loadMore();
      if (!mounted) return;
      setState(() => _state = state);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _retryMore() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final state = await widget.controller.retry();
      if (!mounted) return;
      setState(() => _state = state);
      _restoreTvGridFocus();
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _openTvItem(SeerrDiscoverItem item) async {
    await openHomeLabDiscoveryItem(context, item);
    _restoreTvGridFocus();
  }

  void _restoreTvGridFocus() {
    if (!mounted || !PlatformDetection.isTV) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _tvGridKey.currentState?.requestFocusFromMemory();
    });
  }

  void _focusTvRefresh() {
    if (_tvRefreshFocusNode.canRequestFocus) {
      _tvRefreshFocusNode.requestFocus();
    }
  }

  void _focusTvRetryMore() {
    if (_tvRetryMoreFocusNode.canRequestFocus) {
      _tvRetryMoreFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NavigationLayout(
        activeRoute: Destinations.seerrDiscover,
        showBackButton: true,
        child: SafeArea(
          child: FutureBuilder<HomeLabDiscoverySeeAllState>(
            future: _initialFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done &&
                  _state == null) {
                return const Center(child: CircularProgressIndicator());
              }
              final state = _state ?? snapshot.data;
              if (state == null) {
                return _DeepFailure(onRetry: _retryInitial);
              }
              if (state.items.isEmpty && state.hasError) {
                return _DeepFailure(onRetry: _retryInitial);
              }
              if (state.items.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.7,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'No results are available for ${state.title}.',
                                  textAlign: TextAlign.center,
                                ),
                                if (PlatformDetection.isWeb ||
                                    PlatformDetection.isTV) ...[
                                  const SizedBox(height: 12),
                                  FilledButton.icon(
                                    key: const ValueKey<String>(
                                      'homelab-discovery-deep-refresh-empty',
                                    ),
                                    autofocus: PlatformDetection.isTV,
                                    onPressed: _refresh,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Refresh'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return _buildGrid(state);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(HomeLabDiscoverySeeAllState state) {
    if (PlatformDetection.isTV) return _buildTvGrid(state);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${state.items.length} loaded',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (PlatformDetection.isWeb)
                    TextButton.icon(
                      key: const ValueKey<String>(
                        'homelab-discovery-deep-refresh',
                      ),
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                const spacing = 12.0;
                final columns = homeLabDiscoveryGridColumns(
                  constraints.crossAxisExtent,
                );
                final cardWidth =
                    (constraints.crossAxisExtent - (columns - 1) * spacing) /
                    columns;
                final childAspectRatio = cardWidth / (cardWidth / (2 / 3) + 58);

                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: spacing,
                    childAspectRatio: childAspectRatio,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = state.items[index];
                    return HomeLabDiscoveryMediaCard(
                      item: item,
                      width: cardWidth,
                      onFocus: index >= state.items.length - 8
                          ? _loadMore
                          : null,
                    );
                  }, childCount: state.items.length),
                );
              },
            ),
          ),
          if (_loadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (state.hasError)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Center(
                  child: FilledButton.icon(
                    onPressed: _retryMore,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry loading more'),
                  ),
                ),
              ),
            )
          else if (!state.hasMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Center(child: Text('End of list')),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTvGrid(HomeLabDiscoverySeeAllState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${state.items.length} loaded',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.arrowDown):
                      _restoreTvGridFocus,
                },
                child: TextButton.icon(
                  key: const ValueKey<String>('homelab-discovery-deep-refresh'),
                  focusNode: _tvRefreshFocusNode,
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: HomeLabDiscoveryTvGrid(
              key: _tvGridKey,
              hubKey: 'homelab-discovery:see-all:${state.section.id}',
              items: state.items,
              autofocus: true,
              onOpenItem: _openTvItem,
              onNearEnd: _loadMore,
              onBack: () => Navigator.of(context).maybePop(),
              onUpEdge: _focusTvRefresh,
              onDownEdge: !_loadingMore && state.hasError
                  ? _focusTvRetryMore
                  : null,
            ),
          ),
        ),
        if (_loadingMore)
          const Padding(
            padding: EdgeInsets.only(bottom: 18),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state.hasError)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
            child: Center(
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.arrowUp):
                      _restoreTvGridFocus,
                },
                child: FilledButton.icon(
                  key: const ValueKey<String>(
                    'homelab-discovery-deep-retry-more',
                  ),
                  focusNode: _tvRetryMoreFocusNode,
                  onPressed: _retryMore,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry loading more'),
                ),
              ),
            ),
          )
        else if (!state.hasMore)
          const Padding(
            padding: EdgeInsets.only(bottom: 18),
            child: Center(child: Text('End of list')),
          ),
      ],
    );
  }
}

class _DeepFailure extends StatelessWidget {
  final VoidCallback onRetry;

  const _DeepFailure({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This Discovery collection could not be loaded.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const ValueKey<String>('homelab-discovery-deep-retry'),
              autofocus: PlatformDetection.isTV,
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
