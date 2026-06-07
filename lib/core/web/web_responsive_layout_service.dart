import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Breakpoints responsive Web — mobile / tablette / desktop / grand écran.
class WebResponsiveLayoutService {
  WebResponsiveLayoutService._();

  static const mobileMax = 600.0;
  static const tabletMax = 1024.0;
  static const largeDesktopMin = 1440.0;

  static WebLayoutTier tierOf(double width) {
    if (width < mobileMax) return WebLayoutTier.mobile;
    if (width < tabletMax) return WebLayoutTier.tablet;
    if (width < largeDesktopMin) return WebLayoutTier.desktop;
    return WebLayoutTier.largeDesktop;
  }

  static WebLayoutTier tierOfContext(BuildContext context) =>
      tierOf(MediaQuery.sizeOf(context).width);

  static bool get isWeb => kIsWeb;

  static int gridColumns(double width) {
    final tier = tierOf(width);
    return switch (tier) {
      WebLayoutTier.mobile => 1,
      WebLayoutTier.tablet => 2,
      WebLayoutTier.desktop => 3,
      WebLayoutTier.largeDesktop => 4,
    };
  }

  static double contentMaxWidth(double width) {
    final tier = tierOf(width);
    return switch (tier) {
      WebLayoutTier.mobile => width,
      WebLayoutTier.tablet => 920,
      WebLayoutTier.desktop => 1200,
      WebLayoutTier.largeDesktop => 1400,
    };
  }
}

enum WebLayoutTier { mobile, tablet, desktop, largeDesktop }

typedef WebResponsiveLayoutServiceAlias = WebResponsiveLayoutService;
