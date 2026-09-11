enum HomeLabDiscoveryWindowClass { compact, medium, expanded }

const homeLabDiscoveryDefaultHeaderTopPadding = 20.0;
const homeLabDiscoveryMobileToolbarGap = 8.0;

HomeLabDiscoveryWindowClass homeLabDiscoveryWindowClass(double viewportWidth) {
  if (!viewportWidth.isFinite || viewportWidth <= 0) {
    return HomeLabDiscoveryWindowClass.compact;
  }
  if (viewportWidth < 600) return HomeLabDiscoveryWindowClass.compact;
  if (viewportWidth < 840) return HomeLabDiscoveryWindowClass.medium;
  return HomeLabDiscoveryWindowClass.expanded;
}

double homeLabDiscoveryLaneCardWidth(double viewportWidth) {
  return switch (homeLabDiscoveryWindowClass(viewportWidth)) {
    HomeLabDiscoveryWindowClass.compact => 124.0,
    HomeLabDiscoveryWindowClass.medium => 140.0,
    HomeLabDiscoveryWindowClass.expanded => 148.0,
  };
}

double homeLabDiscoveryHeaderTopPadding({
  required bool isMobile,
  required bool hasTopToolbar,
  required double toolbarHeight,
}) {
  if (!isMobile || !hasTopToolbar || !toolbarHeight.isFinite) {
    return homeLabDiscoveryDefaultHeaderTopPadding;
  }
  return toolbarHeight.clamp(0.0, double.infinity).toDouble() +
      homeLabDiscoveryMobileToolbarGap;
}

String homeLabDiscoveryLaneScrollStorageKey({
  required String tabId,
  required String sectionId,
  required int refreshNonce,
}) {
  return 'homelab-discovery-lane-scroll-$tabId-$sectionId-r$refreshNonce';
}

int homeLabDiscoveryGridColumns(double crossAxisExtent) {
  const spacing = 12.0;
  const targetCardWidth = 142.0;
  const minimumColumns = 2;
  const maximumColumns = 20;

  if (!crossAxisExtent.isFinite || crossAxisExtent <= 0) {
    return minimumColumns;
  }

  final calculated = ((crossAxisExtent + spacing) / (targetCardWidth + spacing))
      .floor();
  return calculated.clamp(minimumColumns, maximumColumns).toInt();
}
