class SessionRowData {
  const SessionRowData({
    required this.id,
    required this.dateLabel,
    required this.sessionType,
    required this.cowsVisited,
    required this.soleCount,
    required this.bandageCount,
  });

  final String id;
  final String dateLabel;
  final String sessionType;
  final int cowsVisited;
  final int soleCount;
  final int bandageCount;
}

class SessionCowEntry {
  const SessionCowEntry({
    required this.cowNumber,
    required this.worstLesion,
    required this.medications,
    required this.hasSole,
    required this.hasBandage,
  });

  final String cowNumber;
  final String worstLesion;
  final String medications;
  final bool hasSole;
  final bool hasBandage;
}

const sessionTypeOptions = <String>[
  'Pareggio di mandria',
  'Pareggio su selezione',
  'Sessione urgenze',
  'Sessione ricontrolli',
];

const previousSessionRows = <SessionRowData>[
  SessionRowData(
    id: 'session-2026-05-06',
    dateLabel: '06 maggio 2026',
    sessionType: 'Pareggio di mandria',
    cowsVisited: 18,
    soleCount: 7,
    bandageCount: 3,
  ),
  SessionRowData(
    id: 'session-2026-05-02',
    dateLabel: '02 maggio 2026',
    sessionType: 'Pareggio su selezione',
    cowsVisited: 9,
    soleCount: 4,
    bandageCount: 2,
  ),
  SessionRowData(
    id: 'session-2026-04-25',
    dateLabel: '25 aprile 2026',
    sessionType: 'Sessione urgenze',
    cowsVisited: 5,
    soleCount: 2,
    bandageCount: 1,
  ),
];

const sessionCowEntries = <SessionCowEntry>[
  SessionCowEntry(
    cowNumber: '789',
    worstLesion: 'Ulcera suola',
    medications: 'AB + AI',
    hasSole: true,
    hasBandage: true,
  ),
  SessionCowEntry(
    cowNumber: '234',
    worstLesion: 'Emorragia suola',
    medications: 'AI',
    hasSole: true,
    hasBandage: false,
  ),
  SessionCowEntry(
    cowNumber: '101',
    worstLesion: 'Necrosi localizzata',
    medications: 'AB',
    hasSole: false,
    hasBandage: true,
  ),
];
