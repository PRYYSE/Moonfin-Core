import 'package:flutter/material.dart';

import '../../../ui/navigation/destinations.dart';
import '../../../ui/widgets/navigation_layout.dart';
import '../catalogue/discovery_catalogue.dart';

/// Safe v2 shell used while the legacy lane engine is ported behind the new
/// catalogue boundary. This branch is not promoted live until the full lane UI
/// and acceptance gates pass.
class HomeLabDiscoveryScreen extends StatelessWidget {
  final HomeLabDiscoveryCatalogue catalogue;

  const HomeLabDiscoveryScreen({
    super.key,
    required this.catalogue,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: catalogue.tabs.length,
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
                  tabs: [
                    for (final tab in catalogue.tabs) Tab(text: tab.title),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      for (final tab in catalogue.tabs)
                        _PortInProgressTab(tab: tab),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PortInProgressTab extends StatelessWidget {
  final HomeLabDiscoveryTab tab;

  const _PortInProgressTab({required this.tab});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: tab.sections.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final section = tab.sections[index];
        return Text(
          section.title,
          style: Theme.of(context).textTheme.titleMedium,
        );
      },
    );
  }
}
