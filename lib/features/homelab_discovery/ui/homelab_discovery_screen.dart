import 'package:flutter/material.dart';

import '../../../ui/navigation/destinations.dart';
import '../../../ui/widgets/navigation_layout.dart';
import '../../../util/platform_detection.dart';
import '../catalogue/discovery_catalogue.dart';
import '../data/discovery_lane_loader.dart';
import '../engine/discovery_runtime.dart';
import '../engine/discovery_tab_controller.dart';
import 'discovery_media_card.dart';
import 'homelab_discovery_see_all_screen.dart';

class HomeLabDiscoveryScreen extends StatefulWidget {
  final HomeLabDiscoveryCatalogue catalogue;
  final HomeLabDiscoveryRuntimeLoad? runtimeLoad;

  const HomeLabDiscoveryScreen({
    super.key,
    required this.catalogue,
    this.runtimeLoad,
  });

  @override
  State<HomeLabDiscoveryScreen> createState() => _HomeLabDiscoveryScreenState();
}

class _HomeLabDiscoveryScreenState extends State<HomeLabDiscoveryScreen> {
  late Future<HomeLabDiscoveryRuntime> _runtimeFuture;
  HomeLabDiscoveryRuntime? _runtime;

  @override
  void initState() {
    super.initState();
    _runtimeFuture = _createRuntime();
  }

  Future<HomeLabDiscoveryRuntime> _createRuntime() async {
    final runtime =
        await (widget.runtimeLoad ?? HomeLabDiscoveryRuntime.create)(
          widget.catalogue,
        );
    if (!mounted) {
      runtime.dispose();
      return runtime;
    }
    _runtime = runtime;
    return runtime;
  }

  void _retryRuntime() {
    _runtime?.dispose();
    _runtime = null;
    setState(() => _runtimeFuture = _createRuntime());
  }

  @override
  void dispose() {
    _runtime?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HomeLabDiscoveryRuntime>(
      future: _runtimeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _shell(const Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || snapshot.data == null) {
          return _shell(
            _DiscoveryFailure(
              message: 'Discovery could not connect to its data services.',
              onRetry: _retryRuntime,
            ),
          );
        }

        final runtime = snapshot.data!;
        final tabs = widget.catalogue.tabs;
        if (tabs.isEmpty) {
          return _shell(
            const Center(child: Text('No Discovery sections are configured.')),
          );
        }

        return DefaultTabController(
          length: tabs.length,
          child: Scaffold(
            body: NavigationLayout(
              activeRoute: Destinations.seerrDiscover,
              showBackButton: true,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                      child: Text(
                        'Discovery',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    TabBar(
                      isScrollable: true,
                      tabs: [for (final tab in tabs) Tab(text: tab.title)],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          for (final tab in tabs)
                            _HomeLabDiscoveryTabView(
                              key: PageStorageKey<String>(
                                'homelab-discovery-${tab.id}',
                              ),
                              controller: runtime.controllerFor(tab.id),
                              runtime: runtime,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _shell(Widget child) {
    return Scaffold(
      body: NavigationLayout(
        activeRoute: Destinations.seerrDiscover,
        showBackButton: true,
        child: SafeArea(child: child),
      ),
    );
  }
}

class _HomeLabDiscoveryTabView extends StatefulWidget {
  final HomeLabDiscoveryTabController controller;
  final HomeLabDiscoveryRuntime runtime;

  const _HomeLabDiscoveryTabView({
    super.key,
    required this.controller,
    required this.runtime,
  });

  @override
  State<_HomeLabDiscoveryTabView> createState() =>
      _HomeLabDiscoveryTabViewState();
}

class _HomeLabDiscoveryTabViewState extends State<_HomeLabDiscoveryTabView> {
  late Future<HomeLabDiscoveryTabLoadResult> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = widget.controller.load();
  }

  @override
  void didUpdateWidget(covariant _HomeLabDiscoveryTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _loadFuture = widget.controller.load();
    }
  }

  void _retry() {
    setState(() => _loadFuture = widget.controller.load());
  }

  Future<void> _refresh() async {
    final next = widget.controller.refresh();
    setState(() => _loadFuture = next);
    await next;
  }

  void _openSeeAll(HomeLabDiscoveryLaneLoadResult lane) {
    final controller = widget.runtime.seeAllControllerFor(lane.section);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HomeLabDiscoverySeeAllScreen(controller: controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HomeLabDiscoveryTabLoadResult>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return _DiscoveryFailure(
            message: 'This Discovery tab could not be loaded.',
            onRetry: _retry,
          );
        }

        final result = snapshot.data!;
        final lanes = result.usableLanes;
        final failedCount = result.failedLanes.length;
        if (lanes.isEmpty) {
          return _DiscoveryFailure(
            message: failedCount > 0
                ? 'Discovery is temporarily unavailable for this tab.'
                : 'Nothing is available in this Discovery tab right now.',
            onRetry: _retry,
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            key: PageStorageKey<String>(
              'homelab-discovery-list-${widget.controller.tab.id}',
            ),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 36),
            itemCount: lanes.length + (failedCount > 0 ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= lanes.length) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        failedCount == 1
                            ? 'Retry unavailable row'
                            : 'Retry $failedCount unavailable rows',
                      ),
                    ),
                  ),
                );
              }
              final lane = lanes[index];
              return _DiscoveryLane(
                lane: lane,
                onSeeAll: lane.section.expandable
                    ? () => _openSeeAll(lane)
                    : null,
              );
            },
          ),
        );
      },
    );
  }
}

class _DiscoveryLane extends StatelessWidget {
  final HomeLabDiscoveryLaneLoadResult lane;
  final VoidCallback? onSeeAll;

  const _DiscoveryLane({required this.lane, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = PlatformDetection.isTV
        ? 168.0
        : width < 600
        ? 124.0
        : 148.0;
    final cardHeight = cardWidth / (2 / 3) + 58;
    final subtitle = lane.section.subtitle?.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lane.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                if (onSeeAll != null)
                  TextButton.icon(
                    onPressed: onSeeAll,
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.chevron_right),
                    label: const Text('See all'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: lane.items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => SizedBox(
                width: cardWidth,
                child: HomeLabDiscoveryMediaCard(
                  item: lane.items[index],
                  width: cardWidth,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoveryFailure extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DiscoveryFailure({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
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
