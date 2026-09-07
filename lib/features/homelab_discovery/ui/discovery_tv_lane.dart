import 'package:flutter/material.dart';

import '../../../data/services/seerr/seerr_api_models.dart';
import '../../../ui/widgets/focus/locked_focus_row.dart';
import '../data/discovery_lane_loader.dart';
import 'discovery_media_card.dart';

/// TV-only Discovery row that delegates D-pad semantics to Moonfin's current
/// locked-focus primitive while leaving Web/mobile on ordinary pointer/touch
/// scrolling widgets.
class HomeLabDiscoveryTvLane extends StatefulWidget {
  final String tabId;
  final HomeLabDiscoveryLaneLoadResult lane;
  final ValueChanged<SeerrDiscoverItem> onOpenItem;
  final VoidCallback? onSeeAll;
  final LockedFocusVerticalNav? onVerticalNavigation;
  final bool autofocus;

  const HomeLabDiscoveryTvLane({
    super.key,
    required this.tabId,
    required this.lane,
    required this.onOpenItem,
    this.onSeeAll,
    this.onVerticalNavigation,
    this.autofocus = false,
  });

  @override
  State<HomeLabDiscoveryTvLane> createState() => HomeLabDiscoveryTvLaneState();
}

class HomeLabDiscoveryTvLaneState extends State<HomeLabDiscoveryTvLane> {
  static const cardWidth = 168.0;
  static const itemSpacing = 16.0;
  static const horizontalPadding = 24.0;
  static const cardHeight = cardWidth / (2 / 3) + 58;

  final GlobalKey<LockedFocusRowState<SeerrDiscoverItem>> _rowKey =
      GlobalKey<LockedFocusRowState<SeerrDiscoverItem>>();

  void requestFocusFromMemory() {
    _rowKey.currentState?.requestFocusFromMemory();
    final rowContext = context;
    Scrollable.ensureVisible(
      rowContext,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      alignment: 0.5,
    );
  }

  void _moveToHost(TraversalDirection direction) {
    FocusManager.instance.primaryFocus?.focusInDirection(direction);
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = widget.lane.section.subtitle?.trim();
    final canSeeAll = widget.onSeeAll != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.lane.displayTitle,
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
                if (canSeeAll)
                  const Padding(
                    padding: EdgeInsets.only(left: 16, bottom: 2),
                    child: Text('See all  ›'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          LockedFocusRow<SeerrDiscoverItem>(
            key: _rowKey,
            items: widget.lane.items,
            hubKey:
                'homelab-discovery:${widget.tabId}:${widget.lane.section.id}',
            itemExtent: cardWidth,
            leadingPadding: horizontalPadding,
            itemSpacing: itemSpacing,
            height: cardHeight,
            padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
            autofocus: widget.autofocus,
            clipBehavior: Clip.none,
            onTap: (_, item) => widget.onOpenItem(item),
            onVerticalNavigation: widget.onVerticalNavigation,
            onLeftEdge: () => _moveToHost(TraversalDirection.left),
            onRightEdge: canSeeAll
                ? widget.onSeeAll
                : () => _moveToHost(TraversalDirection.right),
            itemBuilder: (context, item, _, isFocused) =>
                HomeLabDiscoveryMediaCard(
                  item: item,
                  width: cardWidth,
                  externalIsFocused: isFocused,
                  onTap: () => widget.onOpenItem(item),
                ),
          ),
        ],
      ),
    );
  }
}
