import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_responsive.dart';
import 'hoof_map_models.dart';

const String _hoofCardAssetPath = 'assets/images/hoof_single_card_reference.png';
const double _hoofCardAspectRatio = 1061 / 1483;

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
        final cardWidth = math.min(
          constraints.maxWidth,
          AppResponsive.maxPhoneContentWidth,
        );
        final cardRadius = compact ? 18.0 : 20.0;

        Widget mapCanvas() {
          return AspectRatio(
            aspectRatio: _hoofCardAspectRatio,
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
                      final path = _displayPathForZone(zone, size);
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(cardRadius),
                          child: Image.asset(
                            _hoofCardAssetPath,
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _HoofPairOverlayPainter(
                            zones: zones,
                            observations: observations,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ],
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
          constraints: BoxConstraints(maxWidth: cardWidth),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              mapCanvas(),
              Positioned(
                left: compact ? 10 : 12,
                top: compact ? 10 : 12,
                child: _FootBadge(
                  label: footLabel,
                  subtitle: _footSubtitle(footLabel),
                  compact: compact,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HoofPairOverlayPainter extends CustomPainter {
  const _HoofPairOverlayPainter({
    required this.zones,
    required this.observations,
  });

  final List<HoofMapZoneDefinition> zones;
  final Map<String, HoofZoneObservation> observations;

  @override
  void paint(Canvas canvas, Size size) {
    for (final zone in zones) {
      final observation = observations[zone.zoneCode];
      if (observation?.isActive != true) {
        continue;
      }

      final visiblePath = _displayPathForZone(zone, size);
      final fillColor = activeFillForFamily(zone.zoneFamily);

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = fillColor;

      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidthForFamily(zone.zoneFamily)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = borderColorForFamily(zone.zoneFamily);

      canvas.drawPath(visiblePath, fillPaint);

      if (zone.zoneFamily == HoofZoneFamily.skin) {
        _drawDashedPath(canvas, visiblePath, strokePaint);
      } else {
        canvas.drawPath(visiblePath, strokePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HoofPairOverlayPainter oldDelegate) {
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
          color: Color(0xF7F8F9FB),
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
  final customPath = _customStyledZonePath(zone, size);
  if (customPath != null) {
    return customPath;
  }

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

Path? _customStyledZonePath(HoofMapZoneDefinition zone, Size size) {
  final zoneCode = zone.zoneCode;

  if (zoneCode.startsWith('C')) {
    final parts = zoneCode.split('_');
    if (parts.length < 2) {
      return null;
    }
    final clawNumber = int.tryParse(parts.first.substring(1));
    if (clawNumber == null) {
      return null;
    }
    final suffix = parts[1];
    final isLeft = _isLeftVisualClaw(zone.footLabel, clawNumber);
    final rect = _clawRect(size, isLeft: isLeft);

    if (suffix == 'UG') {
      return _accessoryDigitPath(size, isLeft: isLeft);
    }

    return _clawZonePath(suffix, rect, isLeft: isLeft);
  }

  if (zoneCode.startsWith('SKIN_')) {
    if (zoneCode.endsWith('_LAT')) {
      final clawNumber = int.tryParse(
        zoneCode.replaceAll('SKIN_C', '').replaceAll('_LAT', ''),
      );
      if (clawNumber == null) {
        return null;
      }
      final isLeft = _isLeftVisualClaw(zone.footLabel, clawNumber);
      return _lateralSkinPath(size, isLeft: isLeft);
    }

    if (zoneCode.endsWith('_Nod')) {
      return _centralSkinPath(size, _CentralSkinBand.top);
    }
    if (zoneCode.endsWith('_D')) {
      return _centralSkinPath(size, _CentralSkinBand.upperMid);
    }
    if (zoneCode.endsWith('_ID')) {
      return _centralSkinPath(size, _CentralSkinBand.mid);
    }
    if (zoneCode.endsWith('_Dors')) {
      return _centralSkinPath(size, _CentralSkinBand.bottom);
    }
  }

  return null;
}

bool _isLeftVisualClaw(String footLabel, int clawNumber) {
  return switch (footLabel) {
    'AS' => clawNumber == 1,
    'AD' => clawNumber == 3,
    'PS' => clawNumber == 5,
    'PD' => clawNumber == 7,
    _ => true,
  };
}

Rect _clawRect(Size size, {required bool isLeft}) {
  final width = size.width * 0.31;
  final height = size.height * 0.70;
  final left = isLeft ? size.width * 0.08 : size.width * 0.61;
  final top = size.height * 0.22;
  return Rect.fromLTWH(left, top, width, height);
}

Path _clawZonePath(String suffix, Rect rect, {required bool isLeft}) {
  switch (suffix) {
    case 'B':
      return _zonePath(rect, const [
        Offset(0.18, 0.16),
        Offset(0.32, 0.05),
        Offset(0.58, 0.04),
        Offset(0.74, 0.13),
        Offset(0.70, 0.31),
        Offset(0.32, 0.31),
      ], isLeft: isLeft);
    case 'S':
      return _zonePath(rect, const [
        Offset(0.16, 0.28),
        Offset(0.31, 0.22),
        Offset(0.57, 0.23),
        Offset(0.78, 0.35),
        Offset(0.73, 0.49),
        Offset(0.48, 0.57),
        Offset(0.24, 0.51),
        Offset(0.08, 0.40),
      ], isLeft: isLeft);
    case 'P':
      return _zonePath(rect, const [
        Offset(0.23, 0.51),
        Offset(0.48, 0.57),
        Offset(0.66, 0.69),
        Offset(0.61, 0.84),
        Offset(0.44, 0.93),
        Offset(0.25, 0.86),
        Offset(0.18, 0.66),
      ], isLeft: isLeft);
    case 'APX':
      return _zonePath(rect, const [
        Offset(0.34, 0.84),
        Offset(0.53, 0.89),
        Offset(0.48, 1.00),
        Offset(0.30, 0.96),
      ], isLeft: isLeft);
    case 'LBab':
      return _zonePath(rect, const [
        Offset(0.00, 0.39),
        Offset(0.06, 0.20),
        Offset(0.18, 0.10),
        Offset(0.18, 0.27),
        Offset(0.08, 0.40),
        Offset(0.18, 0.66),
        Offset(0.25, 0.86),
        Offset(0.18, 0.98),
        Offset(0.04, 0.88),
        Offset(0.00, 0.64),
      ], isLeft: isLeft);
    case 'LBax':
      return _zonePath(rect, const [
        Offset(0.76, 0.35),
        Offset(0.88, 0.40),
        Offset(0.90, 0.60),
        Offset(0.79, 0.88),
        Offset(0.65, 0.96),
        Offset(0.61, 0.84),
        Offset(0.66, 0.69),
        Offset(0.73, 0.49),
      ], isLeft: isLeft);
  }
  return Path();
}

Path _zonePath(Rect rect, List<Offset> localPoints, {required bool isLeft}) {
  final points = localPoints
      .map(
        (point) => Offset(
          rect.left + (isLeft ? point.dx : (1 - point.dx)) * rect.width,
          rect.top + point.dy * rect.height,
        ),
      )
      .toList();
  return _smoothedClosedPath(points);
}

Path _accessoryDigitPath(Size size, {required bool isLeft}) {
  final rect = Rect.fromLTWH(
    isLeft ? size.width * 0.19 : size.width * 0.67,
    size.height * 0.06,
    size.width * 0.17,
    size.height * 0.14,
  );

  final points = [
    Offset(rect.left + rect.width * 0.52, rect.top),
    Offset(rect.right, rect.bottom),
    Offset(rect.left, rect.bottom - rect.height * 0.06),
  ];
  return _roundedPolygonPath(points, 9);
}

enum _CentralSkinBand { top, upperMid, mid, bottom }

Path _centralSkinPath(Size size, _CentralSkinBand band) {
  Rect rect;
  switch (band) {
    case _CentralSkinBand.top:
      rect = Rect.fromLTWH(
        size.width * 0.40,
        size.height * 0.07,
        size.width * 0.20,
        size.height * 0.08,
      );
    case _CentralSkinBand.upperMid:
      rect = Rect.fromLTWH(
        size.width * 0.405,
        size.height * 0.18,
        size.width * 0.19,
        size.height * 0.085,
      );
    case _CentralSkinBand.mid:
      rect = Rect.fromLTWH(
        size.width * 0.43,
        size.height * 0.295,
        size.width * 0.14,
        size.height * 0.145,
      );
    case _CentralSkinBand.bottom:
      rect = Rect.fromLTWH(
        size.width * 0.415,
        size.height * 0.47,
        size.width * 0.17,
        size.height * 0.16,
      );
  }

  return Path()..addRRect(
    RRect.fromRectAndRadius(
      rect,
      Radius.circular(math.min(rect.width, rect.height) * 0.48),
    ),
  );
}

Path _lateralSkinPath(Size size, {required bool isLeft}) {
  final rect = Rect.fromLTWH(
    isLeft ? size.width * 0.01 : size.width * 0.86,
    size.height * 0.20,
    size.width * 0.10,
    size.height * 0.22,
  );

  final points = isLeft
      ? [
          Offset(rect.right, rect.top + rect.height * 0.12),
          Offset(rect.left + rect.width * 0.38, rect.top),
          Offset(rect.left, rect.top + rect.height * 0.28),
          Offset(
            rect.left + rect.width * 0.06,
            rect.bottom - rect.height * 0.16,
          ),
          Offset(rect.right - rect.width * 0.16, rect.bottom),
          Offset(rect.right, rect.bottom - rect.height * 0.22),
        ]
      : [
          Offset(rect.left, rect.top + rect.height * 0.12),
          Offset(rect.right - rect.width * 0.38, rect.top),
          Offset(rect.right, rect.top + rect.height * 0.28),
          Offset(
            rect.right - rect.width * 0.06,
            rect.bottom - rect.height * 0.16,
          ),
          Offset(rect.left + rect.width * 0.16, rect.bottom),
          Offset(rect.left, rect.bottom - rect.height * 0.22),
        ];
  return _smoothedClosedPath(points);
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

String _footSubtitle(String footLabel) {
  return switch (footLabel) {
    'AS' => 'Anteriore sinistro',
    'AD' => 'Anteriore destro',
    'PS' => 'Posteriore sinistro',
    'PD' => 'Posteriore destro',
    _ => footLabel,
  };
}
