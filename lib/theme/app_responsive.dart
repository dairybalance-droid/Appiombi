import 'package:flutter/material.dart';

class AppResponsive {
  const AppResponsive._();

  static const double minTouchTarget = 48.0;
  static const double normalButtonHeight = 48.0;
  static const double primaryActionHeight = 56.0;
  static const double largePrimaryButtonHeight = 64.0;
  static const double controlGap = 8.0;
  static const double screenPadding = 16.0;
  static const double compactHorizontalPadding = screenPadding;
  static const double compactVerticalPadding = 12.0;
  static const double dialogMaxWidthCompactFactor = 0.94;
  static const double dialogMaxHeightCompactFactor = 0.90;
  static const double buttonFontSize = 16.0;
  static const double secondaryFontSize = 14.0;
  static const double secondaryTextSize = secondaryFontSize;
  static const double smallPhoneWidth = 360.0;
  static const double maxPhoneContentWidth = 430.0;
  static const double compactBreakpoint = 600.0;
  static const double mediumBreakpoint = 900.0;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactBreakpoint;

  static bool isMedium(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= compactBreakpoint && width < mediumBreakpoint;
  }

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mediumBreakpoint;

  static EdgeInsets pagePadding(BuildContext context) {
    return const EdgeInsets.fromLTRB(screenPadding, 12, screenPadding, 20);
  }

  static EdgeInsets cardPadding(BuildContext context) {
    return const EdgeInsets.all(12);
  }

  static double contentMaxWidth(BuildContext context) => maxPhoneContentWidth;

  static double dialogMaxWidth(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return (screenWidth * dialogMaxWidthCompactFactor).clamp(
      smallPhoneWidth,
      maxPhoneContentWidth,
    );
  }

  static double dialogMaxHeight(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return screenHeight * dialogMaxHeightCompactFactor;
  }

  static double topBarHeight(BuildContext context) => normalButtonHeight;

  static double smallIconButtonSize(BuildContext context) => minTouchTarget;

  static double compactGap(BuildContext context) => controlGap;

  static TextStyle? buttonTextStyle(BuildContext context) => Theme.of(context)
      .textTheme
      .labelLarge
      ?.copyWith(fontSize: buttonFontSize, fontWeight: FontWeight.w800);

  static TextStyle? secondaryTextStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontSize: secondaryFontSize,
        fontWeight: FontWeight.w600,
      );

  static Widget phoneConstrained(
    BuildContext context, {
    required Widget child,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxPhoneContentWidth),
        child: child,
      ),
    );
  }
}
