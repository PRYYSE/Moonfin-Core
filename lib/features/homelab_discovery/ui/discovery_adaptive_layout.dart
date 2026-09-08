double homeLabDiscoveryLaneCardWidth(double viewportWidth) {
  return viewportWidth < 600 ? 124.0 : 148.0;
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
