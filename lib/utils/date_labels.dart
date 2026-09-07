String dateKey(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year$month$day';
}

String monthKey(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$year$month';
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
  const weekdays = <String>['월', '화', '수', '목', '금', '토', '일'];
  final weekday = weekdays[date.weekday - DateTime.monday];
  return '${date.month}월 ${date.day}일 ${weekday}요일';
}

String monthLabel(DateTime date) {
  return '${date.year}년 ${date.month}월';
}
