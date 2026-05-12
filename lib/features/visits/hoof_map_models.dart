import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

enum HoofZoneFamily {
  horn,
  accessoryDigit,
  skin,
}

enum HoofPopupKind {
  horn,
  skin,
}

enum HoofShapeKind {
  polygon,
  oval,
}

class HoofZoneObservation {
  const HoofZoneObservation({
    required this.zoneCode,
    required this.zoneFamily,
    required this.anatomicalArea,
    required this.anatomicalPosition,
    required this.popupKind,
    required this.lesionTypeCode,
    required this.extensionCode,
    required this.isActive,
  });

  final String zoneCode;
  final HoofZoneFamily zoneFamily;
  final String anatomicalArea;
  final String anatomicalPosition;
  final HoofPopupKind popupKind;
  final String lesionTypeCode;
  final String extensionCode;
  final bool isActive;

  HoofZoneObservation copyWith({
    String? lesionTypeCode,
    String? extensionCode,
    bool? isActive,
  }) {
    return HoofZoneObservation(
      zoneCode: zoneCode,
      zoneFamily: zoneFamily,
      anatomicalArea: anatomicalArea,
      anatomicalPosition: anatomicalPosition,
      popupKind: popupKind,
      lesionTypeCode: lesionTypeCode ?? this.lesionTypeCode,
      extensionCode: extensionCode ?? this.extensionCode,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'zoneCode': zoneCode,
      'zoneFamily': zoneFamily.name,
      'anatomicalArea': anatomicalArea,
      'anatomicalPosition': anatomicalPosition,
      'popupKind': popupKind.name,
      'lesionTypeCode': lesionTypeCode,
      'extensionCode': extensionCode,
      'isActive': isActive,
    };
  }

  factory HoofZoneObservation.fromJson(Map<String, dynamic> json) {
    return HoofZoneObservation(
      zoneCode: json['zoneCode'] as String? ?? '',
      zoneFamily: HoofZoneFamily.values.byName(
        json['zoneFamily'] as String? ?? HoofZoneFamily.horn.name,
      ),
      anatomicalArea: json['anatomicalArea'] as String? ?? '',
      anatomicalPosition: json['anatomicalPosition'] as String? ?? '',
      popupKind: HoofPopupKind.values.byName(
        json['popupKind'] as String? ?? HoofPopupKind.horn.name,
      ),
      lesionTypeCode: json['lesionTypeCode'] as String? ?? '',
      extensionCode: json['extensionCode'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? false,
    );
  }
}

class HoofMapZoneDefinition {
  const HoofMapZoneDefinition({
    required this.zoneCode,
    required this.zoneFamily,
    required this.anatomicalArea,
    required this.anatomicalPosition,
    required this.footLabel,
    required this.popupKind,
    required this.shapeKind,
    required this.visiblePoints,
    required this.hitInflation,
  });

  final String zoneCode;
  final HoofZoneFamily zoneFamily;
  final String anatomicalArea;
  final String anatomicalPosition;
  final String footLabel;
  final HoofPopupKind popupKind;
  final HoofShapeKind shapeKind;
  final List<Offset> visiblePoints;
  final double hitInflation;

  Path buildVisiblePath(Size size) {
    final points = visiblePoints
        .map((point) => Offset(point.dx * size.width, point.dy * size.height))
        .toList();

    switch (shapeKind) {
      case HoofShapeKind.oval:
        return Path()..addOval(Rect.fromPoints(points.first, points.last));
      case HoofShapeKind.polygon:
        final path = Path()..moveTo(points.first.dx, points.first.dy);
        for (final point in points.skip(1)) {
          path.lineTo(point.dx, point.dy);
        }
        path.close();
        return path;
    }
  }

  Path buildHitPath(Size size) {
    final visiblePath = buildVisiblePath(size);
    final bounds = visiblePath.getBounds().inflate(hitInflation);
    return Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          bounds,
          const Radius.circular(12),
        ),
      );
  }
}

class HoofPairDefinition {
  const HoofPairDefinition({
    required this.footLabel,
    required this.pairCode,
    required this.leftClawNumber,
    required this.rightClawNumber,
    required this.leftClawPosition,
    required this.rightClawPosition,
    required this.leftSideLabel,
    required this.rightSideLabel,
    required this.centralSkinCodes,
  });

  final String footLabel;
  final String pairCode;
  final int leftClawNumber;
  final int rightClawNumber;
  final String leftClawPosition;
  final String rightClawPosition;
  final String leftSideLabel;
  final String rightSideLabel;
  final List<String> centralSkinCodes;
}

const hoofMapZoneCount = 80;

const List<HoofPairDefinition> hoofPairDefinitions = [
  HoofPairDefinition(
    footLabel: 'AS',
    pairCode: '12',
    leftClawNumber: 1,
    rightClawNumber: 2,
    leftClawPosition: 'anteriore sinistro esterno',
    rightClawPosition: 'anteriore sinistro interno',
    leftSideLabel: 'esterno',
    rightSideLabel: 'interno',
    centralSkinCodes: ['SKIN_12_Nod', 'SKIN_12_D', 'SKIN_12_ID', 'SKIN_12_Dors'],
  ),
  HoofPairDefinition(
    footLabel: 'AD',
    pairCode: '34',
    leftClawNumber: 3,
    rightClawNumber: 4,
    leftClawPosition: 'anteriore destro interno',
    rightClawPosition: 'anteriore destro esterno',
    leftSideLabel: 'interno',
    rightSideLabel: 'esterno',
    centralSkinCodes: ['SKIN_34_Nod', 'SKIN_34_D', 'SKIN_34_ID', 'SKIN_34_Dors'],
  ),
  HoofPairDefinition(
    footLabel: 'PS',
    pairCode: '56',
    leftClawNumber: 5,
    rightClawNumber: 6,
    leftClawPosition: 'posteriore sinistro esterno',
    rightClawPosition: 'posteriore sinistro interno',
    leftSideLabel: 'esterno',
    rightSideLabel: 'interno',
    centralSkinCodes: ['SKIN_56_Nod', 'SKIN_56_D', 'SKIN_56_ID', 'SKIN_56_Dors'],
  ),
  HoofPairDefinition(
    footLabel: 'PD',
    pairCode: '78',
    leftClawNumber: 7,
    rightClawNumber: 8,
    leftClawPosition: 'posteriore destro interno',
    rightClawPosition: 'posteriore destro esterno',
    leftSideLabel: 'interno',
    rightSideLabel: 'esterno',
    centralSkinCodes: ['SKIN_78_Nod', 'SKIN_78_D', 'SKIN_78_ID', 'SKIN_78_Dors'],
  ),
];

class HoofMapDefinitions {
  const HoofMapDefinitions._();

  static final List<HoofMapZoneDefinition> allZones = _buildAllZones();

  static List<HoofMapZoneDefinition> zonesForFoot(String footLabel) {
    return allZones.where((zone) => zone.footLabel == footLabel).toList();
  }

  static void debugValidate() {
    assert(() {
      final codes = <String>{};
      if (allZones.length != hoofMapZoneCount) {
        throw FlutterError(
          'Hoof map zone count mismatch: expected $hoofMapZoneCount, found ${allZones.length}.',
        );
      }

      for (final zone in allZones) {
        if (zone.zoneCode.trim().isEmpty) {
          throw FlutterError('A hoof map zone has an empty zoneCode.');
        }
        if (!codes.add(zone.zoneCode)) {
          throw FlutterError('Duplicate hoof map zoneCode detected: ${zone.zoneCode}.');
        }
        if (zone.anatomicalArea.trim().isEmpty ||
            zone.anatomicalPosition.trim().isEmpty) {
          throw FlutterError('Zone ${zone.zoneCode} is missing anatomical metadata.');
        }
        if (zone.visiblePoints.isEmpty) {
          throw FlutterError('Zone ${zone.zoneCode} has no visible path definition.');
        }
      }
      return true;
    }());
  }
}

Map<String, HoofZoneObservation> decodeHoofMapObservations(String rawValue) {
  if (rawValue.trim().isEmpty) {
    return {};
  }

  final decoded = jsonDecode(rawValue);
  if (decoded is! Map<String, dynamic>) {
    return {};
  }

  return decoded.map(
    (key, value) => MapEntry(
      key,
      HoofZoneObservation.fromJson(value as Map<String, dynamic>),
    ),
  );
}

String encodeHoofMapObservations(Map<String, HoofZoneObservation> observations) {
  return jsonEncode(
    observations.map((key, value) => MapEntry(key, value.toJson())),
  );
}

List<HoofMapZoneDefinition> _buildAllZones() {
  final zones = <HoofMapZoneDefinition>[];
  for (final pair in hoofPairDefinitions) {
    zones.addAll(_buildClawZones(pair, pair.leftClawNumber, isLeft: true));
    zones.addAll(_buildClawZones(pair, pair.rightClawNumber, isLeft: false));
    zones.addAll(_buildCentralSkinZones(pair));
    zones.addAll(_buildLateralSkinZones(pair, pair.leftClawNumber, isLeft: true));
    zones.addAll(_buildLateralSkinZones(pair, pair.rightClawNumber, isLeft: false));
  }
  return zones;
}

List<HoofMapZoneDefinition> _buildClawZones(
  HoofPairDefinition pair,
  int clawNumber, {
  required bool isLeft,
}) {
  final x0 = isLeft ? 0.08 : 0.56;
  const y0 = 0.26;
  const width = 0.28;
  const height = 0.52;

  final axialLeft = isLeft ? x0 + width - 0.08 : x0;
  final axialRight = isLeft ? x0 + width : x0 + 0.08;
  final abassialLeft = isLeft ? x0 : x0 + width - 0.08;
  final abassialRight = isLeft ? x0 + 0.08 : x0 + width;
  final centerLeft = x0 + 0.08;
  final centerRight = x0 + width - 0.08;
  final centerX = x0 + (width / 2);

  final position = isLeft ? pair.leftClawPosition : pair.rightClawPosition;

  return [
    HoofMapZoneDefinition(
      zoneCode: 'C${clawNumber}_B',
      zoneFamily: HoofZoneFamily.horn,
      anatomicalArea: 'Bulbo',
      anatomicalPosition: position,
      footLabel: pair.footLabel,
      popupKind: HoofPopupKind.horn,
      shapeKind: HoofShapeKind.polygon,
      visiblePoints: [
        Offset(centerLeft, y0 + 0.02),
        Offset(centerRight, y0 + 0.02),
        Offset(centerRight - 0.02, y0 + 0.14),
        Offset(centerLeft + 0.02, y0 + 0.14),
      ],
      hitInflation: 5,
    ),
    HoofMapZoneDefinition(
      zoneCode: 'C${clawNumber}_S',
      zoneFamily: HoofZoneFamily.horn,
      anatomicalArea: 'Suola',
      anatomicalPosition: position,
      footLabel: pair.footLabel,
      popupKind: HoofPopupKind.horn,
      shapeKind: HoofShapeKind.polygon,
      visiblePoints: [
        Offset(centerLeft + 0.02, y0 + 0.14),
        Offset(centerRight - 0.02, y0 + 0.14),
        Offset(centerRight - 0.03, y0 + 0.31),
        Offset(centerLeft + 0.03, y0 + 0.31),
      ],
      hitInflation: 5,
    ),
    HoofMapZoneDefinition(
      zoneCode: 'C${clawNumber}_P',
      zoneFamily: HoofZoneFamily.horn,
      anatomicalArea: 'Punta',
      anatomicalPosition: position,
      footLabel: pair.footLabel,
      popupKind: HoofPopupKind.horn,
      shapeKind: HoofShapeKind.polygon,
      visiblePoints: [
        Offset(centerLeft + 0.05, y0 + 0.31),
        Offset(centerRight - 0.05, y0 + 0.31),
        Offset(centerRight - 0.07, y0 + 0.42),
        Offset(centerLeft + 0.07, y0 + 0.42),
      ],
      hitInflation: 5,
    ),
    HoofMapZoneDefinition(
      zoneCode: 'C${clawNumber}_APX',
      zoneFamily: HoofZoneFamily.horn,
      anatomicalArea: 'Apice',
      anatomicalPosition: position,
      footLabel: pair.footLabel,
      popupKind: HoofPopupKind.horn,
      shapeKind: HoofShapeKind.polygon,
      visiblePoints: [
        Offset(centerX - 0.04, y0 + 0.42),
        Offset(centerX + 0.04, y0 + 0.42),
        Offset(centerX, y0 + height),
      ],
      hitInflation: 6,
    ),
    HoofMapZoneDefinition(
      zoneCode: 'C${clawNumber}_LBab',
      zoneFamily: HoofZoneFamily.horn,
      anatomicalArea: 'Linea bianca abassiale',
      anatomicalPosition: position,
      footLabel: pair.footLabel,
      popupKind: HoofPopupKind.horn,
      shapeKind: HoofShapeKind.polygon,
      visiblePoints: [
        Offset(abassialLeft, y0 + 0.09),
        Offset(abassialRight, y0 + 0.12),
        Offset(abassialRight - 0.01, y0 + 0.44),
        Offset(abassialLeft + 0.01, y0 + 0.38),
      ],
      hitInflation: 5,
    ),
    HoofMapZoneDefinition(
      zoneCode: 'C${clawNumber}_LBax',
      zoneFamily: HoofZoneFamily.horn,
      anatomicalArea: 'Linea bianca assiale',
      anatomicalPosition: position,
      footLabel: pair.footLabel,
      popupKind: HoofPopupKind.horn,
      shapeKind: HoofShapeKind.polygon,
      visiblePoints: [
        Offset(axialLeft, y0 + 0.09),
        Offset(axialRight, y0 + 0.12),
        Offset(axialRight - 0.01, y0 + 0.38),
        Offset(axialLeft + 0.01, y0 + 0.44),
      ],
      hitInflation: 5,
    ),
    HoofMapZoneDefinition(
      zoneCode: 'C${clawNumber}_UG',
      zoneFamily: HoofZoneFamily.accessoryDigit,
      anatomicalArea: 'Unghiello',
      anatomicalPosition: position,
      footLabel: pair.footLabel,
      popupKind: HoofPopupKind.horn,
      shapeKind: HoofShapeKind.polygon,
      visiblePoints: [
        Offset(x0 + (width / 2), 0.06),
        Offset(x0 + width - 0.03, 0.20),
        Offset(x0 + 0.03, 0.20),
      ],
      hitInflation: 7,
    ),
  ];
}

List<HoofMapZoneDefinition> _buildCentralSkinZones(HoofPairDefinition pair) {
  return [
    HoofMapZoneDefinition(
      zoneCode: pair.centralSkinCodes[0],
      zoneFamily: HoofZoneFamily.skin,
      anatomicalArea: 'Nodello',
      anatomicalPosition: '${pair.footLabel} centrale tra C${pair.leftClawNumber}-C${pair.rightClawNumber}',
      footLabel: pair.footLabel,
      popupKind: HoofPopupKind.skin,
      shapeKind: HoofShapeKind.oval,
      visiblePoints: const [Offset(0.34, 0.01), Offset(0.66, 0.09)],
      hitInflation: 6,
    ),
    HoofMapZoneDefinition(
      zoneCode: pair.centralSkinCodes[1],
      zoneFamily: HoofZoneFamily.skin,
      anatomicalArea: 'Digitale',
      anatomicalPosition: '${pair.footLabel} centrale tra C${pair.leftClawNumber}-C${pair.rightClawNumber}',
      footLabel: pair.footLabel,
      popupKind: HoofPopupKind.skin,
      shapeKind: HoofShapeKind.oval,
      visiblePoints: const [Offset(0.37, 0.12), Offset(0.63, 0.20)],
      hitInflation: 6,
    ),
    HoofMapZoneDefinition(
      zoneCode: pair.centralSkinCodes[2],
      zoneFamily: HoofZoneFamily.skin,
      anatomicalArea: 'Interdigitale',
      anatomicalPosition: '${pair.footLabel} centrale tra C${pair.leftClawNumber}-C${pair.rightClawNumber}',
      footLabel: pair.footLabel,
      popupKind: HoofPopupKind.skin,
      shapeKind: HoofShapeKind.oval,
      visiblePoints: const [Offset(0.44, 0.22), Offset(0.56, 0.44)],
      hitInflation: 8,
    ),
    HoofMapZoneDefinition(
      zoneCode: pair.centralSkinCodes[3],
      zoneFamily: HoofZoneFamily.skin,
      anatomicalArea: 'Dorsale',
      anatomicalPosition: '${pair.footLabel} centrale tra C${pair.leftClawNumber}-C${pair.rightClawNumber}',
      footLabel: pair.footLabel,
      popupKind: HoofPopupKind.skin,
      shapeKind: HoofShapeKind.oval,
      visiblePoints: const [Offset(0.40, 0.46), Offset(0.60, 0.58)],
      hitInflation: 6,
    ),
  ];
}

List<HoofMapZoneDefinition> _buildLateralSkinZones(
  HoofPairDefinition pair,
  int clawNumber, {
  required bool isLeft,
}) {
  final x0 = isLeft ? 0.01 : 0.83;
  final x1 = isLeft ? 0.16 : 0.98;
  final top = 0.25;
  final bottom = 0.42;
  final position = isLeft ? pair.leftClawPosition : pair.rightClawPosition;

  return [
    HoofMapZoneDefinition(
      zoneCode: 'SKIN_C${clawNumber}_LAT',
      zoneFamily: HoofZoneFamily.skin,
      anatomicalArea: 'Cute laterale',
      anatomicalPosition: position,
      footLabel: pair.footLabel,
      popupKind: HoofPopupKind.skin,
      shapeKind: HoofShapeKind.oval,
      visiblePoints: [Offset(x0, top), Offset(x1, bottom)],
      hitInflation: 7,
    ),
  ];
}

Color activeFillForFamily(HoofZoneFamily family) {
  switch (family) {
    case HoofZoneFamily.horn:
      return const Color(0x40D8831F);
    case HoofZoneFamily.accessoryDigit:
      return const Color(0x40D8831F);
    case HoofZoneFamily.skin:
      return const Color(0x40E07C8E);
  }
}

Color borderColorForFamily(HoofZoneFamily family) {
  switch (family) {
    case HoofZoneFamily.horn:
    case HoofZoneFamily.accessoryDigit:
      return const Color(0xFF111111);
    case HoofZoneFamily.skin:
      return const Color(0xFFE08B9D);
  }
}

String hoofPopupTitle(HoofPopupKind kind) {
  switch (kind) {
    case HoofPopupKind.horn:
      return 'Lesione corno';
    case HoofPopupKind.skin:
      return 'Lesione cutanea';
  }
}

List<DropdownMenuItem<String>> hornLesionTypeItems() {
  return const [
    DropdownMenuItem(value: '', child: Text('')),
    DropdownMenuItem(value: 'hemorrhage', child: Text('Emorragia')),
    DropdownMenuItem(value: 'ulcer', child: Text('Ulcera')),
    DropdownMenuItem(value: 'protrusion', child: Text('Protrusione')),
    DropdownMenuItem(value: 'pus', child: Text('Pus')),
    DropdownMenuItem(value: 'necrosis', child: Text('Necrosi')),
    DropdownMenuItem(value: 'deep_planes', child: Text('Piani profondi')),
  ];
}

List<DropdownMenuItem<String>> skinLesionTypeItems() {
  return const [
    DropdownMenuItem(value: '', child: Text('')),
    DropdownMenuItem(value: 'stage_1_early', child: Text('1 - Precoce')),
    DropdownMenuItem(value: 'stage_2_acute', child: Text('2 - Acuta')),
    DropdownMenuItem(value: 'stage_3_healing', child: Text('3 - Guarigione')),
    DropdownMenuItem(value: 'stage_4_chronic', child: Text('4 - Cronica')),
    DropdownMenuItem(
      value: 'stage_4_1_reactivated',
      child: Text('4.1 - Riacutizzata'),
    ),
  ];
}

List<DropdownMenuItem<String>> extensionItems() {
  return const [
    DropdownMenuItem(value: '', child: Text('')),
    DropdownMenuItem(value: 'focal', child: Text('Focale')),
    DropdownMenuItem(value: 'wide', child: Text('Ampio')),
    DropdownMenuItem(value: 'multi_zone', child: Text('Multi-zona')),
  ];
}

int? extensionCodeToGrade(String code) {
  switch (code) {
    case 'focal':
      return 1;
    case 'wide':
      return 2;
    case 'multi_zone':
      return 3;
  }
  return null;
}

String? normalizeStructuredHornCode(String code) {
  switch (code) {
    case 'hemorrhage':
    case 'ulcer':
    case 'necrosis':
    case 'deep_planes':
      return code;
    case 'pus':
      return 'abscess_pus';
    default:
      return null;
  }
}

Rect pairBoundsForAvailableWidth(double maxWidth) {
  final width = math.min(maxWidth, 360.0);
  return Rect.fromLTWH(0, 0, width, width * 0.78);
}
