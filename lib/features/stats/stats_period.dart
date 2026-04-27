enum StatsPeriod {
  weekly,
  monthly,
  yearly;

  static const _monthsFull = [
    '', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
    'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
  ];
  static const _monthsShort = [
    '', 'jan', 'fév', 'mar', 'avr', 'mai', 'jun',
    'jul', 'aoû', 'sep', 'oct', 'nov', 'déc'
  ];

  String formatLabel(String key) {
    switch (this) {
      case weekly:
        final dt = DateTime.tryParse(key);
        if (dt == null) return '';
        return '${dt.day}\n${_monthsShort[dt.month]}';
      case monthly:
        final m = int.tryParse(key.split('-')[1]) ?? 0;
        return _monthsFull[m];
      case yearly:
        return key;
    }
  }

  double get barWidth {
    switch (this) {
      case weekly: return 14;
      case monthly: return 22;
      case yearly: return 34;
    }
  }

  int get reservedBottom {
    switch (this) {
      case weekly: return 32;
      case monthly: return 24;
      case yearly: return 24;
    }
  }
}
