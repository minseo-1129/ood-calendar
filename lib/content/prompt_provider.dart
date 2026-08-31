const List<String> dailyPromptPool = <String>[
  '오늘 이상하게 기억나는 것 하나',
  '창문 밖에서 오늘 처음 본 것',
  '발밑에 있던 것',
  '오늘 손에 제일 오래 있던 물건',
  '지나가다 눈이 멈춘 곳',
  '오늘 들은 소리 중 하나',
  '어제와 달랐던 한 가지',
  '오늘 만난 사람의 뒷모습',
];

String promptForDate(DateTime date) {
  final index = (date.day * 7 + date.month * 3) % dailyPromptPool.length;
  return dailyPromptPool[index];
}
