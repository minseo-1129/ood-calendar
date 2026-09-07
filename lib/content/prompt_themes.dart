// Theme-aware daily prompts. Replaces content/prompt_provider.dart.
//
// The user picks ONE axis during onboarding (changeable in Settings). The
// question for a given day is a pure function of (theme, date, swap), so a day
// always reopens with the same question. Saved entries persist their own
// prompt text, so switching themes later never rewrites past days.

const String kDefaultTheme = 'season';
const String kDefaultAgeBand = '30s';
const String kObjectThemePrefix = 'object:';

class PromptAxis {
  const PromptAxis(this.id, this.label, this.hint);

  final String id;
  final String label;
  final String hint;
}

class ObjectTheme {
  const ObjectTheme(this.id, this.label);

  final String id;
  final String label;
}

const List<PromptAxis> kPromptAxes = <PromptAxis>[
  PromptAxis('season', '계절과 날씨', '그 달과 그날 날씨에서 오는 질문'),
  PromptAxis('age', '나이대', '내 또래의 하루에서 오는 질문'),
  PromptAxis('mood', '기분과 감정', '오늘의 마음을 묻는 질문'),
  PromptAxis('object', '사물 하나 정하기', '매일 같은 것을 다르게 봅니다'),
  PromptAxis('random', '전부 섞기', '날마다 다른 축에서 하나'),
];

const List<ObjectTheme> kObjectThemes = <ObjectTheme>[
  ObjectTheme('cloud', '일일 구름'),
  ObjectTheme('flower', '일일 꽃'),
  ObjectTheme('cup', '일일 컵'),
  ObjectTheme('window', '일일 창'),
  ObjectTheme('walk', '일일 걸음'),
  ObjectTheme('light', '일일 빛'),
];

const List<String> kAgeBands = <String>['10s', '20s', '30s', '40s+'];

const Map<String, String> kAgeBandLabels = <String, String>{
  '10s': '10대',
  '20s': '20대',
  '30s': '30대',
  '40s+': '40대 이상',
};

const Map<int, List<String>> _monthPool = <int, List<String>>{
  1: <String>['올해 처음 산 것', '지금 가장 따뜻한 자리', '창문에 서린 김'],
  2: <String>['아직 안 녹은 것', '오래 신은 신발', '이번 주에 미룬 일 하나'],
  3: <String>['처음 본 초록', '가방에 새로 들어온 것', '아침에 열어둔 창'],
  4: <String>['오늘 바람의 모양', '길에서 주운 눈길', '벗어둔 겉옷'],
  5: <String>['가장 오래 앉아 있던 자리', '누가 준 것', '오늘의 초록 하나'],
  6: <String>['젖은 것', '오늘 마신 것', '우산 아래 보인 것'],
  7: <String>['가장 시원했던 순간', '오늘의 그늘', '얼음이 남긴 자국'],
  8: <String>['오늘 제일 밝았던 것', '땀을 식힌 것', '창밖 저녁 하늘'],
  9: <String>['손에 가장 오래 있던 것', '식탁 위에 남은 것', '조금 서늘해진 것'],
  10: <String>['떨어진 것 하나', '오늘 걸친 것', '해가 짧아진 자리'],
  11: <String>['식기 전에 먹은 것', '오늘의 회색', '주머니 속의 것'],
  12: <String>['올해 자주 쓴 물건', '오늘 켜둔 불빛', '남겨두고 싶은 장면'],
};

const Map<String, List<String>> _agePool = <String, List<String>>{
  '10s': <String>['오늘 책상 위', '가장 오래 들은 소리', '내일 챙길 것', '가방에서 나온 것'],
  '20s': <String>['오늘 가장 멀리 간 곳', '지갑에서 나온 것', '혼자 있던 시간', '오늘 미룬 것'],
  '30s': <String>['오늘 처리한 일 하나', '식탁 위 풍경', '잠깐 멈춘 자리', '오늘 챙긴 사람'],
  '40s+': <String>['오늘 돌본 것', '오래 쓰고 있는 물건', '조용했던 순간', '손에 익은 일'],
};

const List<String> _moodPool = <String>[
  '오늘의 기분을 색이나 선으로',
  '마음이 가장 조용했던 순간',
  '오늘 나를 웃게 한 것',
  '조금 무거웠던 것',
  '지금 어깨의 상태',
  '오늘 마음이 머문 자리',
];

const Map<String, List<String>> _objectPool = <String, List<String>>{
  'cloud': <String>['오늘의 구름 한 조각', '창밖 하늘의 모양', '해가 가려진 순간', '저녁 하늘의 색', '오늘 본 가장 큰 구름'],
  'flower': <String>['오늘 지나친 꽃', '화분 속 오늘', '가장 오래 본 초록', '시들어가는 것', '길가에 핀 것'],
  'cup': <String>['오늘 마신 것', '손에 오래 있던 컵', '남아 있던 한 모금', '오늘의 첫 잔', '식어버린 것'],
  'window': <String>['오늘 열어둔 창', '창에 비친 것', '창밖 가장 멀리 있는 것', '오늘의 커튼', '창틀에 놓인 것'],
  'walk': <String>['오늘 신은 신발', '가장 오래 걸은 길', '발밑에 있던 것', '오늘 멈춰 선 자리', '돌아온 길'],
  'light': <String>['오늘 켜둔 불빛', '가장 밝았던 순간', '그늘의 모양', '저녁에 남은 빛', '오늘의 그림자'],
};

const List<String> _easyPool = <String>[
  '컵 하나',
  '오늘 신은 신발',
  '창문',
  '오늘 먹은 것',
  '손에 든 것',
];

const List<String> _weekendPool = <String>[
  '늦게 일어난 자리',
  '집 안에서 가장 좋아한 구석',
  '아무것도 안 한 시간',
];

/// Human label for a stored theme id, including `object:<id>` values.
String promptThemeLabel(String theme) {
  if (theme.startsWith(kObjectThemePrefix)) {
    final id = theme.substring(kObjectThemePrefix.length);
    for (final ObjectTheme option in kObjectThemes) {
      if (option.id == id) {
        return option.label;
      }
    }
    return '사물 하나';
  }

  for (final PromptAxis axis in kPromptAxes) {
    if (axis.id == theme) {
      return axis.label;
    }
  }
  return promptThemeLabel(kDefaultTheme);
}

bool isObjectTheme(String theme) => theme.startsWith(kObjectThemePrefix);

int _hash(String value) {
  var hash = 2166136261;
  for (var i = 0; i < value.length; i++) {
    hash ^= value.codeUnitAt(i);
    hash = (hash * 16777619) & 0xFFFFFFFF;
  }
  return hash;
}

List<String> _poolFor(String theme, DateTime date, String ageBand, int tenure) {
  if (isObjectTheme(theme)) {
    return _objectPool[theme.substring(kObjectThemePrefix.length)] ?? _easyPool;
  }
  if (theme == 'age') {
    return _agePool[ageBand] ?? _easyPool;
  }
  if (theme == 'mood') {
    return _moodPool;
  }
  if (theme == 'random') {
    return <String>[
      ..._monthPool.values.expand((List<String> pool) => pool),
      ..._agePool.values.expand((List<String> pool) => pool),
      ..._moodPool,
      ..._objectPool.values.expand((List<String> pool) => pool),
    ];
  }

  final pool = <String>[
    if (tenure < 3) ..._easyPool,
    ...?_monthPool[date.month],
    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday)
      ..._weekendPool,
  ];
  return pool.isEmpty ? _easyPool : pool;
}

/// [tenure] = how many days have been saved so far; the first few days get
/// easier prompts. [swap] lets a future "다른 질문 보기" affordance rotate.
String promptForDate(
  DateTime date, {
  String theme = kDefaultTheme,
  String ageBand = kDefaultAgeBand,
  int tenure = 0,
  int swap = 0,
}) {
  final pool = _poolFor(theme, date, ageBand, tenure);
  final key = '$theme|${date.year}-${date.month}-${date.day}';
  return pool[(_hash(key) + swap * 7) % pool.length];
}
