import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../util/focus/dpad_keys.dart';
import '../../../util/focus/key_event_utils.dart';
import '../../../util/platform_detection.dart';
import '../catalogue/discovery_catalogue.dart';

class HomeLabDiscoveryTabStrip extends StatefulWidget {
  final List<HomeLabDiscoveryTab> tabs;
  final VoidCallback? onTvEnterContent;

  const HomeLabDiscoveryTabStrip({
    super.key,
    required this.tabs,
    this.onTvEnterContent,
  });

  @override
  State<HomeLabDiscoveryTabStrip> createState() =>
      HomeLabDiscoveryTabStripState();
}

class HomeLabDiscoveryTabStripState extends State<HomeLabDiscoveryTabStrip> {
  final FocusNode _tvFocusNode = FocusNode(
    debugLabel: 'HomeLabDiscoveryTabStrip',
  );

  bool get hasTvFocus => _tvFocusNode.hasFocus;

  bool requestTvFocus() {
    if (!PlatformDetection.isTV || !_tvFocusNode.canRequestFocus) return false;
    _tvFocusNode.requestFocus();
    return true;
  }

  bool _moveTvTab(int delta) {
    final controller = DefaultTabController.of(context);
    final target = (controller.index + delta)
        .clamp(0, widget.tabs.length - 1)
        .toInt();
    if (target == controller.index) return false;
    controller.index = target;
    return true;
  }

  KeyEventResult _handleTvKeyEvent(FocusNode node, KeyEvent event) {
    final onEnterContent = widget.onTvEnterContent;
    if (onEnterContent != null) {
      final select = handleOneShotSelect(event, onEnterContent);
      if (select != KeyEventResult.ignored) return select;
    }

    if (!event.isActionable) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (key.isLeftKey || key.isRightKey) {
      final isRtl = Directionality.of(context) == TextDirection.rtl;
      final movesForward = key.isRightKey != isRtl;
      if (_moveTvTab(movesForward ? 1 : -1)) {
        return KeyEventResult.handled;
      }
      node.focusInDirection(
        key.isLeftKey ? TraversalDirection.left : TraversalDirection.right,
      );
      return KeyEventResult.handled;
    }

    if (key.isDownKey) {
      onEnterContent?.call();
      return KeyEventResult.handled;
    }

    if (key.isUpKey) {
      node.focusInDirection(TraversalDirection.up);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _tvFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabBar = TabBar(
      isScrollable: true,
      tabs: [
        for (final tab in widget.tabs)
          Tab(
            key: ValueKey<String>('homelab-discovery-tab-${tab.id}'),
            height: PlatformDetection.isWeb ? null : kMinInteractiveDimension,
            text: tab.title,
          ),
      ],
    );

    if (PlatformDetection.isTV) {
      return Focus(
        focusNode: _tvFocusNode,
        descendantsAreFocusable: false,
        onKeyEvent: _handleTvKeyEvent,
        child: tabBar,
      );
    }

    if (!PlatformDetection.isWeb) return tabBar;

    final controller = DefaultTabController.of(context);
    void move(int delta) {
      final target = (controller.index + delta)
          .clamp(0, widget.tabs.length - 1)
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
            controller.animateTo(widget.tabs.length - 1),
      },
      child: tabBar,
    );
  }
}
