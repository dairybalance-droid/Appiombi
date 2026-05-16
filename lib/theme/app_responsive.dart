import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppResponsive {
  const AppResponsive._();

  static const double minTouchTarget = 48.0;
  static const double primaryActionHeight = 56.0;
  static const double controlGap = 8.0;
  static const double compactHorizontalPadding = 16.0;
  static const double compactVerticalPadding = 12.0;
  static const double compactBreakpoint = 600.0;
  static const double mediumBreakpoint = 900.0;
  static const double dialogMaxWidthCompactFactor = 0.94;
  static const double dialogMaxHeightCompactFactor = 0.90;
  static const double buttonFontSize = 16.0;
  static const double secondaryTextSize = 14.0;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactBreakpoint;

  static bool isMedium(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= compactBreakpoint && width < mediumBreakpoint;
  }

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mediumBreakpoint;

  static EdgeInsets pagePadding(BuildContext context) {
    if (isCompact(context)) {
      return const EdgeInsets.fromLTRB(
        compactHorizontalPadding,
        compactVerticalPadding,
        compactHorizontalPadding,
        compactVerticalPadding + 8,
      );
    }
    if (isMedium(context)) {
      return const EdgeInsets.fromLTRB(20, 16, 20, 24);
    }
    return const EdgeInsets.fromLTRB(24, 20, 24, 28);
  }

  static EdgeInsets cardPadding(BuildContext context) {
    if (isCompact(context)) {
      return const EdgeInsets.all(compactVerticalPadding);
    }
    if (isMedium(context)) {
      return const EdgeInsets.all(16);
    }
    return const EdgeInsets.all(18);
  }

  static double contentMaxWidth(BuildContext context) {
    if (isCompact(context)) {
      return double.infinity;
    }
    if (isMedium(context)) {
      return 820;
    }
    return 980;
  }

  static double dialogMaxWidth(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    if (isCompact(context)) {
      return screenWidth * dialogMaxWidthCompactFactor;
    }
    return math.min(screenWidth - 48, 560.0);
  }

  static double dialogMaxHeight(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    if (isCompact(context)) {
      return screenHeight * dialogMaxHeightCompactFactor;
    }
    return screenHeight * 0.86;
  }

  static double topBarHeight(BuildContext context) =>
      isCompact(context) ? minTouchTarget : 52.0;

  static double smallIconButtonSize(BuildContext context) =>
      isCompact(context) ? minTouchTarget : 52.0;

  static double compactGap(BuildContext context) =>
      isCompact(context) ? controlGap : 12.0;

  static TextStyle? buttonTextStyle(BuildContext context) => Theme.of(context)
      .textTheme
      .labelLarge
      ?.copyWith(fontSize: buttonFontSize, fontWeight: FontWeight.w800);

  static TextStyle? secondaryTextStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontSize: secondaryTextSize,
        fontWeight: FontWeight.w600,
      );
}
