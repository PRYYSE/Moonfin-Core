enum HomeLabDiscoveryWindowClass { compact, medium, expanded }

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
