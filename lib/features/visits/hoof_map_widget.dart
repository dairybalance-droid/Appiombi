import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'hoof_map_models.dart';

class HoofPairMap extends StatelessWidget {
  const HoofPairMap({
    super.key,
    required this.footLabel,
    required this.observations,
    required this.onZoneTap,
  });

  final String footLabel;
  final Map<String, HoofZoneObservation> observations;
  final ValueChanged<HoofMapZoneDefinition> onZoneTap;

  @override
  Widget build(BuildContext context) {
    final zones = HoofMapDefinitions.zonesForFoot(footLabel);

    return LayoutBuilder(
      builder: (context, constraints) {
        final pairBounds = pairBoundsForAvailableWidth(constraints.maxWidth);
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: pairBounds.width,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  footLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
              AspectRatio(
                aspectRatio: pairBounds.width / pairBounds.height,
                child: LayoutBuilder(
                  builder: (context, painterConstraints) {
                    final size = Size(
                      painterConstraints.maxWidth,
                      painterConstraints.maxHeight,
                    );
                    return GestureDetector(
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
                                (zone) => zone.buildHitPath(size).contains(localPosition),
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
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HoofPairPainter extends CustomPainter {
  const _HoofPairPainter({
    required this.zones,
    required this.observations,
  });

  final List<HoofMapZoneDefinition> zones;
  final Map<String, HoofZoneObservation> observations;

  @override
  void paint(Canvas canvas, Size size) {
    final inactiveFill = Paint()..color = Colors.white;
    final labelPainter = TextPainter(textDirection: TextDirection.ltr);

    for (final zone in zones) {
      final visiblePath = zone.buildVisiblePath(size);
      final observation = observations[zone.zoneCode];
      final isActive = observation?.isActive == true;

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = isActive
            ? activeFillForFamily(zone.zoneFamily)
            : inactiveFill.color;

      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = borderColorForFamily(zone.zoneFamily);

      canvas.drawPath(visiblePath, fillPaint);
      canvas.drawPath(visiblePath, strokePaint);

      final center = visiblePath.getBounds().center;
      final codeLabel = _shortCode(zone.zoneCode);
      labelPainter.text = TextSpan(
        text: codeLabel,
        style: TextStyle(
          color: zone.zoneFamily == HoofZoneFamily.skin
              ? borderColorForFamily(zone.zoneFamily)
              : AppColors.textPrimary,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      );
      labelPainter.layout(maxWidth: 72);
      labelPainter.paint(
        canvas,
        Offset(
          center.dx - (labelPainter.width / 2),
          center.dy - (labelPainter.height / 2),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HoofPairPainter oldDelegate) {
    return oldDelegate.observations != observations || oldDelegate.zones != zones;
  }
}

String _shortCode(String zoneCode) {
  if (zoneCode.startsWith('SKIN_')) {
    return zoneCode.replaceFirst('SKIN_', '');
  }
  return zoneCode;
}
