const sessionTypeOptions = <String>[
  'Pareggio di mandria',
  'Pareggio su selezione',
  'Sessione urgenze',
  'Sessione ricontrolli',
];

const _sessionTypeLabelToCode = <String, String>{
  'Pareggio di mandria': 'herd_trim',
  'Pareggio su selezione': 'selected_trim',
  'Sessione urgenze': 'emergency',
  'Sessione ricontrolli': 'recheck',
};

const _sessionTypeCodeToLabel = <String, String>{
  'herd_trim': 'Pareggio di mandria',
  'selected_trim': 'Pareggio su selezione',
  'emergency': 'Sessione urgenze',
  'recheck': 'Sessione ricontrolli',
};

String sessionTypeLabelToCode(String label) {
  return _sessionTypeLabelToCode[label] ?? 'herd_trim';
}

String sessionTypeCodeToLabel(String code) {
  return _sessionTypeCodeToLabel[code] ?? 'Pareggio di mandria';
}

String sessionStatusCodeToLabel(String code) {
  switch (code) {
    case 'open':
      return 'Aperta';
    case 'closed':
      return 'Chiusa';
    case 'reopened':
      return 'Riaperta';
    case 'archived':
      return 'Archiviata';
    default:
      return code;
  }
}

String formatItalianDate(DateTime date) {
  const months = [
    'gennaio',
    'febbraio',
    'marzo',
    'aprile',
    'maggio',
    'giugno',
    'luglio',
    'agosto',
    'settembre',
    'ottobre',
    'novembre',
    'dicembre',
  ];

  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}
