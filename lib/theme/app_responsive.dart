import 'package:flutter/material.dart';

class AppResponsive {
  const AppResponsive._();

  static const double compactBreakpoint = 520;
  static const double tabletBreakpoint = 900;
  static const double minTouchTarget = 48;
  static const double compactDialogMaxWidth = 420;
  static const double regularDialogMaxWidth = 560;
  static const double compactDialogHeightFactor = 0.9;
  static const double regularDialogHeightFactor = 0.86;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= compactBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  static EdgeInsets pagePadding(BuildContext context) {
    if (isCompact(context)) {
      return const EdgeInsets.fromLTRB(12, 12, 12, 20);
    }
    if (isTablet(context)) {
      return const EdgeInsets.fromLTRB(18, 16, 18, 24);
    }
    return const EdgeInsets.fromLTRB(24, 20, 24, 28);
  }

  static EdgeInsets cardPadding(BuildContext context) {
    if (isCompact(context)) {
      return const EdgeInsets.all(14);
    }
    if (isTablet(context)) {
      return const EdgeInsets.all(16);
    }
    return const EdgeInsets.all(18);
  }

  static double dialogMaxWidth(BuildContext context) {
    return isCompact(context)
        ? compactDialogMaxWidth
        : regularDialogMaxWidth;
  }

  static double dialogMaxHeight(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return height *
        (isCompact(context)
            ? compactDialogHeightFactor
            : regularDialogHeightFactor);
  }

  static double topBarHeight(BuildContext context) =>
      isCompact(context) ? 34 : 40;

  static double compactGap(BuildContext context) =>
      isCompact(context) ? 10 : 14;
}
