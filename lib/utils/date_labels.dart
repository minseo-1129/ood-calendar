String dateKey(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return year + month + day;
}

String monthKey(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  return year + month;
}

DateTime dateFromKey(String key) {
  return DateTime(
    int.parse(key.substring(0, 4)),
    int.parse(key.substring(4, 6)),
    int.parse(key.substring(6, 8)),
  );
}

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String drawingDateLabel(DateTime date) {
  const months = <String>[
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  return months[date.month - 1] + ' ' + date.day.toString();
}

String monthLabel(DateTime date) {
  const months = <String>[
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  return months[date.month - 1] + ' ' + date.year.toString();
}
