import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../util/platform_detection.dart';
import '../catalogue/discovery_catalogue.dart';

class HomeLabDiscoveryTabStrip extends StatelessWidget {
  final List<HomeLabDiscoveryTab> tabs;

  const HomeLabDiscoveryTabStrip({super.key, required this.tabs});

  @override
  Widget build(BuildContext context) {
    final tabBar = TabBar(
      isScrollable: true,
      tabs: [
        for (final tab in tabs)
          Tab(
            key: ValueKey<String>('homelab-discovery-tab-${tab.id}'),
            text: tab.title,
          ),
      ],
    );

    if (!PlatformDetection.isWeb) return tabBar;

    final controller = DefaultTabController.of(context);
    void move(int delta) {
      final target = (controller.index + delta)
          .clamp(0, tabs.length - 1)
          .toInt();
      if (target != controller.index) controller.animateTo(target);
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => move(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => move(1),
        const SingleActivator(LogicalKeyboardKey.home): () =>
            controller.animateTo(0),
        const SingleActivator(LogicalKeyboardKey.end): () =>
            controller.animateTo(tabs.length - 1),
      },
      child: tabBar,
    );
  }
}
