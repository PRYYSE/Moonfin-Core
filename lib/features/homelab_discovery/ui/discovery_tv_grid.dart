import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/services/seerr/seerr_api_models.dart';
import '../../../ui/widgets/focus/hub_focus_memory.dart';
import '../../../util/focus/dpad_keys.dart';
import '../../../util/focus/key_event_utils.dart';
import 'discovery_media_card.dart';

/// TV-only deep-browse grid with one deterministic focus owner.
///
/// Discovery cards are externally focused so Moonfin's normal card visuals are
/// retained without allowing every card to compete for framework focus. This
/// keeps remote traversal deterministic while leaving Web/mobile grids on the
/// stock focus/pointer path.
class HomeLabDiscoveryTvGrid extends StatefulWidget {
  final List<SeerrDiscoverItem> items;
  final String hubKey;
  final ValueChanged<SeerrDiscoverItem> onOpenItem;
  final VoidCallback? onNearEnd;
  final VoidCallback? onBack;
  final bool autofocus;
  final double targetCardWidth;

  const HomeLabDiscoveryTvGrid({
    super.key,
    required this.items,
    required this.hubKey,
    required this.onOpenItem,
    this.onNearEnd,
    this.onBack,
    this.autofocus = false,
    this.targetCardWidth = 168,
  });

  @override
  State<HomeLabDiscoveryTvGrid> createState() => HomeLabDiscoveryTvGridState();
}

class HomeLabDiscoveryTvGridState extends State<HomeLabDiscoveryTvGrid> {
  static const _horizontalPadding = 24.0;
  static const _crossAxisSpacing = 16.0;
  static const _mainAxisSpacing = 18.0;

  final FocusNode _focusNode = FocusNode(
    debugLabel: 'HomeLabDiscoveryTvGrid',
  );
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _itemKeys = <GlobalKey>[];

  int _focusedIndex = 0;
  int _columns = 1;
  bool _hasFocus = false;
  int? _lastNearEndItemCount;

  bool get hasFocus => _hasFocus;
  int get focusedIndex => _focusedIndex;
  int get columns => _columns;

  @override
  void initState() {
    super.initState();
    _focusedIndex = HubFocusMemory.getForHub(
      widget.hubKey,
      widget.items.length,
    );
    _syncItemKeys();
    _focusNode.addListener(_handleFocusChange);
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) requestFocusFromMemory();
      });
    }
  }

  @override
  void didUpdateWidget(covariant HomeLabDiscoveryTvGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hubKey != widget.hubKey) {
      _focusedIndex = HubFocusMemory.getForHub(
        widget.hubKey,
        widget.items.length,
      );
      _lastNearEndItemCount = null;
    } else if (widget.items.isEmpty) {
      _focusedIndex = 0;
    } else {
      _focusedIndex = _focusedIndex.clamp(0, widget.items.length - 1);
      if (!identical(oldWidget.items, widget.items)) {
        _lastNearEndItemCount = null;
      }
    }
    _syncItemKeys();
    if (_hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollToFocused();
        _maybeNotifyNearEnd();
      });
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void requestFocusFromMemory() {
    if (widget.items.isEmpty || !_focusNode.canRequestFocus) return;
    final index = HubFocusMemory.getForHub(widget.hubKey, widget.items.length);
    _setFocusedIndex(index, notifyNearEnd: false);
    _focusNode.requestFocus();
    _scrollToFocused();
  }

  void _handleFocusChange() {
    if (!mounted) return;
    final next = _focusNode.hasFocus;
    if (next == _hasFocus) return;
    setState(() => _hasFocus = next);
    if (next) {
      _scrollToFocused();
      _maybeNotifyNearEnd();
    }
  }

  void _syncItemKeys() {
    while (_itemKeys.length < widget.items.length) {
      _itemKeys.add(GlobalKey());
    }
    if (_itemKeys.length > widget.items.length) {
      _itemKeys.removeRange(widget.items.length, _itemKeys.length);
    }
  }

  void _setFocusedIndex(int index, {bool notifyNearEnd = true}) {
    if (widget.items.isEmpty) return;
    final next = index.clamp(0, widget.items.length - 1);
    if (next != _focusedIndex) {
      setState(() => _focusedIndex = next);
    }
    HubFocusMemory.set(widget.hubKey, next);
    _scrollToFocused();
    if (notifyNearEnd) _maybeNotifyNearEnd();
  }

  void _scrollToFocused() {
    if (!mounted || _focusedIndex < 0 || _focusedIndex >= _itemKeys.length) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _focusedIndex >= _itemKeys.length) return;
      final itemContext = _itemKeys[_focusedIndex].currentContext;
      if (itemContext == null) return;
      Scrollable.ensureVisible(
        itemContext,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignment: 0.5,
      );
    });
  }

  void _maybeNotifyNearEnd() {
    if (widget.onNearEnd == null || widget.items.isEmpty) return;
    final threshold = (widget.items.length - (_columns * 2)).clamp(
      0,
      widget.items.length - 1,
    );
    if (_focusedIndex < threshold) return;
    if (_lastNearEndItemCount == widget.items.length) return;
    _lastNearEndItemCount = widget.items.length;
    widget.onNearEnd!();
  }

  int? _verticalTarget(bool isUp) {
    if (widget.items.isEmpty) return null;
    if (isUp) {
      final target = _focusedIndex - _columns;
      return target >= 0 ? target : null;
    }

    final target = _focusedIndex + _columns;
    if (target < widget.items.length) return target;

    final currentRow = _focusedIndex ~/ _columns;
    final lastRow = (widget.items.length - 1) ~/ _columns;
    if (currentRow >= lastRow) return null;

    final nextRowStart = (currentRow + 1) * _columns;
    final currentColumn = _focusedIndex % _columns;
    return (nextRowStart + currentColumn).clamp(
      nextRowStart,
      widget.items.length - 1,
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (widget.items.isEmpty) return KeyEventResult.ignored;

    final select = handleOneShotSelect(event, () {
      final index = _focusedIndex;
      if (index >= 0 && index < widget.items.length) {
        widget.onOpenItem(widget.items[index]);
      }
    });
    if (select != KeyEventResult.ignored) return select;

    if (widget.onBack != null) {
      final back = handleBackKeyAction(event, widget.onBack!);
      if (back != KeyEventResult.ignored) return back;
    }

    if (!event.isActionable) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (key.isLeftKey || key.isRightKey) {
      final isRtl = Directionality.of(context) == TextDirection.rtl;
      final movesForward = key.isRightKey != isRtl;
      final column = _focusedIndex % _columns;
      if (movesForward) {
        if (column >= _columns - 1 || _focusedIndex >= widget.items.length - 1) {
          return KeyEventResult.ignored;
        }
        _setFocusedIndex(_focusedIndex + 1);
        return KeyEventResult.handled;
      }
      if (column == 0) return KeyEventResult.ignored;
      _setFocusedIndex(_focusedIndex - 1);
      return KeyEventResult.handled;
    }

    if (key.isUpKey || key.isDownKey) {
      final target = _verticalTarget(key.isUpKey);
      if (target == null) return KeyEventResult.ignored;
      _setFocusedIndex(target);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: _handleKeyEvent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final usableWidth = (constraints.maxWidth - _horizontalPadding * 2)
              .clamp(1.0, double.infinity);
          final calculatedColumns =
              ((usableWidth + _crossAxisSpacing) /
                      (widget.targetCardWidth + _crossAxisSpacing))
                  .floor()
                  .clamp(1, 12);
          _columns = calculatedColumns;
          final cardWidth =
              (usableWidth - (_columns - 1) * _crossAxisSpacing) / _columns;
          final cardHeight = cardWidth / (2 / 3) + 58;

          return GridView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            clipBehavior: Clip.none,
            padding: const EdgeInsets.fromLTRB(
              _horizontalPadding,
              12,
              _horizontalPadding,
              28,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _columns,
              mainAxisSpacing: _mainAxisSpacing,
              crossAxisSpacing: _crossAxisSpacing,
              childAspectRatio: cardWidth / cardHeight,
            ),
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return KeyedSubtree(
                key: _itemKeys[index],
                child: HomeLabDiscoveryMediaCard(
                  item: item,
                  width: cardWidth,
                  externalIsFocused: _hasFocus && index == _focusedIndex,
                  onTap: () {
                    _setFocusedIndex(index);
                    widget.onOpenItem(item);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
