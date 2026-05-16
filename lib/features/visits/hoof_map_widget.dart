import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_responsive.dart';
import 'hoof_map_models.dart';

class HoofPairMap extends StatelessWidget {
  const HoofPairMap({
    super.key,
    required this.footLabel,
    required this.compact,
    required this.observations,
    required this.onZoneTap,
  });

  final String footLabel;
  final bool compact;
  final Map<String, HoofZoneObservation> observations;
  final ValueChanged<HoofMapZoneDefinition> onZoneTap;

  @override
  Widget build(BuildContext context) {
    final zones = HoofMapDefinitions.zonesForFoot(footLabel);

    return LayoutBuilder(
      builder: (context, constraints) {
        final pairBounds = pairBoundsForAvailableWidth(constraints.maxWidth);
        final cardRadius = compact ? 18.0 : 20.0;

        Widget mapCanvas() {
          return AspectRatio(
            aspectRatio: pairBounds.width / pairBounds.height,
            child: LayoutBuilder(
              builder: (context, painterConstraints) {
                final size = Size(
                  painterConstraints.maxWidth,
                  painterConstraints.maxHeight,
                );
                final mapSurface = GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) {
                    final localPosition = details.localPosition;
                    final exactHit = zones.reversed.where((zone) {
                      final path = zone.buildVisiblePath(size);
                      return path.contains(localPosition);
                    });

                    final hitZone = exactHit.isNotEmpty
                        ? exactHit.first
                        : zones.reversed.firstWhere(
                            (zone) =>
                                zone.buildHitPath(size).contains(localPosition),
                            orElse: () => const HoofMapZoneDefinition(
                              zoneCode: '',
                              zoneFamily: HoofZoneFamily.horn,
                              anatomicalArea: '',
                              anatomicalPosition: '',
                              footLabel: '',
                              popupKind: HoofPopupKind.horn,
                              shapeKind: HoofShapeKind.polygon,
                              visiblePoints: [],
                              hitInflation: 0,
                            ),
                          );

                    if (hitZone.zoneCode.isEmpty) {
                      return;
                    }

                    onZoneTap(hitZone);
                  },
                  child: CustomPaint(
                    painter: _HoofPairPainter(
                      zones: zones,
                      observations: observations,
                    ),
                    child: const SizedBox.expand(),
                  ),
                );

                if (!AppResponsive.isCompact(context)) {
                  return mapSurface;
                }

                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 1.35,
                  scaleEnabled: true,
                  panEnabled: true,
                  constrained: true,
                  child: mapSurface,
                );
              },
            ),
          );
        }

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: pairBounds.width),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              compact ? 10 : 12,
              compact ? 52 : 56,
              compact ? 10 : 12,
              compact ? 10 : 12,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFDFDFD),
              border: Border.all(color: const Color(0xFFD7DADF), width: 1),
              borderRadius: BorderRadius.circular(cardRadius),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                mapCanvas(),
                Positioned(
                  left: -1,
                  top: -(compact ? 42.0 : 46.0),
                  child: _FootBadge(
                    label: footLabel,
                    subtitle: _footSubtitle(footLabel),
                    compact: compact,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HoofPairPainter extends CustomPainter {
  const _HoofPairPainter({required this.zones, required this.observations});

  final List<HoofMapZoneDefinition> zones;
  final Map<String, HoofZoneObservation> observations;

  @override
  void paint(Canvas canvas, Size size) {
    final shadowPaint = Paint()
      ..color = const Color(0x06000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    for (final zone in zones) {
      final visiblePath = _displayPathForZone(zone, size);
      final observation = observations[zone.zoneCode];
      final isActive = observation?.isActive == true;

      final fillColor = isActive
          ? activeFillForFamily(zone.zoneFamily)
          : _inactiveFillForFamily(zone.zoneFamily);

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = fillColor;

      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidthForFamily(zone.zoneFamily)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = borderColorForFamily(zone.zoneFamily);

      if (zone.zoneFamily != HoofZoneFamily.skin) {
        canvas.drawPath(visiblePath.shift(const Offset(0, 1.5)), shadowPaint);
      }

      canvas.drawPath(visiblePath, fillPaint);

      if (zone.zoneFamily == HoofZoneFamily.skin) {
        _drawDashedPath(canvas, visiblePath, strokePaint);
      } else {
        canvas.drawPath(visiblePath, strokePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HoofPairPainter oldDelegate) {
    return oldDelegate.observations != observations ||
        oldDelegate.zones != zones;
  }
}

class _FootBadge extends StatelessWidget {
  const _FootBadge({
    required this.label,
    required this.subtitle,
    required this.compact,
  });

  final String label;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _BadgeClipper(),
      child: Container(
        constraints: BoxConstraints(
          minWidth: compact ? 86 : 96,
          minHeight: compact ? 42 : 46,
        ),
        padding: EdgeInsets.fromLTRB(
          compact ? 12 : 14,
          compact ? 6 : 7,
          compact ? 18 : 20,
          compact ? 7 : 8,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FB),
          border: Border(
            top: BorderSide(color: Color(0xFFD7DADF)),
            left: BorderSide(color: Color(0xFFD7DADF)),
            right: BorderSide(color: Color(0xFFD7DADF)),
            bottom: BorderSide(color: Color(0xFFD7DADF)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: AppColors.textPrimary,
              ),
            ),
            if (!compact)
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BadgeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const cut = 16.0;
    return Path()
      ..moveTo(0, cut)
      ..lineTo(cut, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - cut)
      ..lineTo(size.width - cut, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

Path _displayPathForZone(HoofMapZoneDefinition zone, Size size) {
  switch (zone.shapeKind) {
    case HoofShapeKind.oval:
      final points = zone.visiblePoints
          .map((point) => Offset(point.dx * size.width, point.dy * size.height))
          .toList();
      final rect = Rect.fromPoints(points.first, points.last);
      return Path()..addRRect(
        RRect.fromRectAndRadius(
          rect,
          Radius.circular(math.min(rect.width, rect.height) * 0.48),
        ),
      );
    case HoofShapeKind.polygon:
      final points = zone.visiblePoints
          .map((point) => Offset(point.dx * size.width, point.dy * size.height))
          .toList();
      if (points.length == 3) {
        return _roundedPolygonPath(points, 10);
      }
      return _smoothedClosedPath(points);
  }
}

Path _smoothedClosedPath(List<Offset> points) {
  if (points.length < 3) {
    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      path.close();
    }
    return path;
  }

  final path = Path();
  for (var i = 0; i < points.length; i++) {
    final current = points[i];
    final next = points[(i + 1) % points.length];
    final mid = Offset((current.dx + next.dx) / 2, (current.dy + next.dy) / 2);
    if (i == 0) {
      path.moveTo(mid.dx, mid.dy);
    } else {
      path.quadraticBezierTo(current.dx, current.dy, mid.dx, mid.dy);
    }
  }
  final first = points.first;
  final last = points.last;
  final closingMid = Offset((last.dx + first.dx) / 2, (last.dy + first.dy) / 2);
  path.quadraticBezierTo(last.dx, last.dy, closingMid.dx, closingMid.dy);
  path.close();
  return path;
}

Path _roundedPolygonPath(List<Offset> points, double radius) {
  final path = Path();
  for (var i = 0; i < points.length; i++) {
    final previous = points[(i - 1 + points.length) % points.length];
    final current = points[i];
    final next = points[(i + 1) % points.length];

    final toPrev = (previous - current);
    final toNext = (next - current);
    final prevLength = toPrev.distance;
    final nextLength = toNext.distance;
    final effectiveRadius = math.min(
      radius,
      math.min(prevLength, nextLength) / 3,
    );

    final start = current + (toPrev / prevLength) * effectiveRadius;
    final end = current + (toNext / nextLength) * effectiveRadius;

    if (i == 0) {
      path.moveTo(start.dx, start.dy);
    } else {
      path.lineTo(start.dx, start.dy);
    }
    path.quadraticBezierTo(current.dx, current.dy, end.dx, end.dy);
  }
  path.close();
  return path;
}

void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
  for (final metric in path.computeMetrics()) {
    var distance = 0.0;
    const dash = 8.0;
    const gap = 5.0;
    while (distance < metric.length) {
      final next = math.min(distance + dash, metric.length);
      canvas.drawPath(metric.extractPath(distance, next), paint);
      distance += dash + gap;
    }
  }
}

double _strokeWidthForFamily(HoofZoneFamily family) {
  switch (family) {
    case HoofZoneFamily.skin:
      return 1.8;
    case HoofZoneFamily.horn:
    case HoofZoneFamily.accessoryDigit:
      return 2.2;
  }
}

Color _inactiveFillForFamily(HoofZoneFamily family) {
  switch (family) {
    case HoofZoneFamily.skin:
      return const Color(0xFFFFFCFC);
    case HoofZoneFamily.horn:
    case HoofZoneFamily.accessoryDigit:
      return Colors.white;
  }
}

String _footSubtitle(String footLabel) {
  return switch (footLabel) {
    'AS' => 'Anteriore sinistro',
    'AD' => 'Anteriore destro',
    'PS' => 'Posteriore sinistro',
    'PD' => 'Posteriore destro',
    _ => footLabel,
  };
}
