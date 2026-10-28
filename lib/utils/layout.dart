import 'dart:math' as math;

/// Shared page geometry for the storefront.
class Layout {
  const Layout._();

  static const double maxContentWidth = 1200;

  /// Side padding that grows on large screens so content stays readable.
  static double pagePadding(double width) {
    if (width >= maxContentWidth + 96) return (width - maxContentWidth) / 2;
    if (width >= 820) return math.max(32, (width - maxContentWidth) / 2);
    if (width >= 520) return 28;
    return 20;
  }
}
