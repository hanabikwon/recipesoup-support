# Recipesoup 아키텍처 문서

## 시스템 개요
**Recipesoup**는 감정 기반 레시피 아카이빙 앱으로, 개인의 요리 경험과 감정을 함께 기록하는 Flutter 기반 모바일 애플리케이션입니다. OpenAI API를 활용한 사진 기반 재료/조리법 추천과 개인 패턴 분석을 통해 단순한 레시피 저장을 넘어선 감성적 요리 일기 경험을 제공합니다.

## 앱 플로우 다이어그램
```
[앱 시작]
├── 스플래시 화면 (빈티지 로고)
└── Bottom Navigation (5탭 구조)
    ├── 🏠 홈 (개인 통계 + 최근 레시피 + "과거 오늘")
    ├── 🔍 검색 (요리이름 + 감정상태 우선)
    ├── 📊 통계 (개인 패턴 분석)
    ├── 📁 보관함 (폴더별 정리)
    ├── ⚙️ 설정 (개인화)
    └── ➕ FAB (빠른 작성 우선)
        ├── 📝 빠른 레시피 작성
        ├── 📷 사진으로 작성
        └── 📊 감정 체크
```

## 기술 스택 상세
### 프론트엔드 (심플 구현 우선)
- **Flutter**: 크로스 플랫폼 앱 개발 (iOS/Android)
- **상태 관리**: Provider + ChangeNotifier (가장 심플한 구현)
- **네비게이션**: Navigator 1.0 (기본 네비게이션)
- **HTTP 통신**: dio (OpenAI API 호출)
- **로컬 저장소**: Hive (심플한 NoSQL) + SharedPreferences
- **이미지**: image_picker + image (로컬 저장)
- **UI 컴포넌트**: Material Design 3 기반 커스텀

### 백엔드 연동 (최소 구성)
- **API 서비스**: OpenAI GPT-4o-mini (사진 분석 + 통계)
- **인증**: 불필요 (개인 아카이빙 서비스)
- **실시간 통신**: 불필요 (오프라인 우선 설계)
- **클라우드**: 불필요 (로컬 저장 완전 독립)

## 프로젝트 구조 (Bottom Navigation 기반)
```
lib/
├── main.dart                    # 앱 진입점
├── config/
│   ├── constants.dart           # 상수 정의 (감정 Enum 등)
│   ├── theme.dart               # 빈티지 아이보리 테마
│   └── api_config.dart          # OpenAI API 설정
├── models/
│   ├── recipe.dart              # 레시피 모델
│   ├── ingredient.dart          # 재료 모델 (구조화된 리스트)
│   └── mood.dart                # 감정 Enum 정의
├── services/
│   ├── openai_service.dart      # OpenAI API 통신
│   ├── hive_service.dart        # Hive 로컬 DB
│   ├── image_service.dart       # 이미지 로컬 저장
│   ├── burrow_unlock_service.dart    # 토끼굴 마일스톤 unlock 관리
│   ├── burrow_unlock_coordinator.dart # 토끼굴 unlock 조정
│   ├── challenge_service.dart   # 챌린지 시스템 관리
│   └── cooking_method_service.dart   # 요리 방법 분석
├── screens/
│   ├── splash_screen.dart       # 스플래시 (빈티지 로고)
│   ├── main_screen.dart         # Bottom Navigation 컨테이너
│   ├── home_screen.dart         # 홈 탭
│   ├── search_screen.dart       # 검색 탭
│   ├── stats_screen.dart        # 통계 탭
│   ├── archive_screen.dart      # 보관함 탭
│   ├── settings_screen.dart     # 설정 탭
│   ├── create_screen.dart       # 레시피 작성 (FAB)
│   └── detail_screen.dart       # 레시피 상세보기
├── widgets/
│   ├── common/                  # 공통 위젯 (FAB, Cards 등)
│   └── recipe/                  # 레시피 관련 위젯
├── providers/
│   ├── recipe_provider.dart     # 레시피 상태 관리
│   └── stats_provider.dart      # 통계 상태 관리
└── utils/
    ├── validators.dart          # 입력 검증
    ├── image_utils.dart         # 이미지 처리
    └── date_utils.dart          # 날짜 처리 ("과거 오늘" 등)
```

## 핵심 모델

### Recipe 모델 (감정 기반 레시피)
```dart
class Recipe {
  final String id;
  final String title;
  final String emotionalStory;        // 감정 메모 (핵심 기능)
  final List<Ingredient> ingredients;  // 구조화된 재료 리스트
  final List<String> instructions;     // 단계별 조리법
  final String? localImagePath;       // 로컬 파일 경로
  final List<String> tags;            // 해시태그
  final DateTime createdAt;
  final Mood mood;                    // Enum 감정 상태
  final int? rating;                  // 만족도 점수 (1-5점)
  final DateTime? reminderDate;       // 리마인더 날짜
  final bool isFavorite;             // 즐겨찾기 여부
  
  // 생성자, fromJson, toJson, copyWith 등
  Recipe({
    required this.id,
    required this.title,
    required this.emotionalStory,
    required this.ingredients,
    required this.instructions,
    this.localImagePath,
    required this.tags,
    required this.createdAt,
    required this.mood,
    this.rating,
    this.reminderDate,
    this.isFavorite = false,
  });
}
```

### Ingredient 모델 (구조화된 재료)
```dart
class Ingredient {
  final String name;              // 재료명
  final String? amount;           // 용량 (선택사항)
  final String? unit;             // 단위 (선택사항)
  final IngredientCategory? category; // 카테고리
  
  Ingredient({
    required this.name,
    this.amount,
    this.unit,
    this.category,
  });
}

enum IngredientCategory {
  vegetable,    // 채소
  meat,         // 고기
  seafood,      // 해산물
  dairy,        // 유제품
  grain,        // 곡물
  seasoning,    // 조미료
  other,        // 기타
}
```

### Mood 모델 (Enum 감정 상태)
```dart
enum Mood {
  happy('😊', '기쁨', 'happy'),
  peaceful('😌', '평온', 'peaceful'),
  sad('😢', '슬픔', 'sad'),
  tired('😴', '피로', 'tired'),
  excited('🤩', '설렘', 'excited'),
  nostalgic('🥺', '그리움', 'nostalgic'),
  comfortable('☺️', '편안함', 'comfortable'),
  grateful('🙏', '감사', 'grateful');
  
  const Mood(this.emoji, this.korean, this.english);
  
  final String emoji;
  final String korean;
  final String english;
}
```

## API 구조

### OpenAI API 엔드포인트
```
BASE_URL: https://api.openai.com/v1
MODEL: gpt-4o-mini
API_KEY: [.env에서 관리]

[POST]   /chat/completions  # 사진 분석 및 재료/조리법 추천
```

### 사진 분석 요청/응답
```json
// 요청 예시 (사진 기반 추천)
{
  "model": "gpt-4o-mini",
  "messages": [
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "이 사진에 나오는 요리의 재료와 대략적인 조리법을 추천해주세요. JSON 형식으로 답해주세요."
        },
        {
          "type": "image_url",
          "image_url": {
            "url": "data:image/jpeg;base64,{base64_image}"
          }
        }
      ]
    }
  ],
  "max_tokens": 500
}

// 응답 예시
{
  "choices": [{
    "message": {
      "content": "{
        \"dish_name\": \"미역국\",
        \"ingredients\": [
          {\"name\": \"미역\", \"amount\": \"30g\"},
          {\"name\": \"쇠고기\", \"amount\": \"200g\"}
        ],
        \"instructions\": [
          \"미역을 물에 불린다\",
          \"쇠고기를 참기름에 볶는다\"
        ]
      }"
    }
  }]
}
```

### 통계 분석 요청/응답
```json
// 요청 예시 (개인 패턴 분석)
{
  "model": "gpt-4o-mini",
  "messages": [
    {
      "role": "user",
      "content": "다음 레시피 데이터를 분석해서 사용자의 요리 패턴과 감정 덕향을 분석해주세요: {recipe_data}"
    }
  ]
}

// 응답 예시
{
  "choices": [{
    "message": {
      "content": "당신의 요리 패턴을 분석한 결과:
      - 가장 자주 만드는 요리: 국물 요리 (40%)
      - 주로 요리하는 감정: 기쁨, 평온
      - 요리 빈도: 주 3-4회
      - 추천 사항: 더 다양한 감정 요리 도전"
    }
  }]
}
```

## 데이터베이스 스키마

### 로컬 데이터베이스 (Hive NoSQL)
```dart
// Hive Box 정의
@HiveType(typeId: 0)
class Recipe extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String title;
  
  @HiveField(2)
  String emotionalStory;
  
  @HiveField(3)
  List<Ingredient> ingredients;
  
  @HiveField(4)
  List<String> instructions;
  
  @HiveField(5)
  String? localImagePath;
  
  @HiveField(6)
  List<String> tags;
  
  @HiveField(7)
  DateTime createdAt;
  
  @HiveField(8)
  int moodIndex;  // Mood enum의 index
  
  @HiveField(9)
  int? rating;
  
  @HiveField(10)
  DateTime? reminderDate;
  
  @HiveField(11)
  bool isFavorite;
}

// Box 초기화
Box<Recipe> recipeBox = await Hive.openBox<Recipe>('recipes');
Box settingsBox = await Hive.openBox('settings');
Box statsBox = await Hive.openBox('user_stats');
```

### 데이터 저장 전략 (완전 로컬)
- **주 저장소**: Hive Box (빠른 NoSQL 접근)
- **이미지 저장**: 앱 내 documents 디렉토리
- **캐싱**: 불필요 (완전 로컬 방식)
- **동기화**: 불필요 (개인 아카이빙)
- **오프라인 지원**: 100% 오프라인 (일반 기능), API는 옵션

## 상태 관리 패턴 (Provider + ChangeNotifier)

### RecipeProvider (레시피 상태 관리)
```dart
class RecipeProvider extends ChangeNotifier {
  // 상태
  List<Recipe> _recipes = [];
  Recipe? _selectedRecipe;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<Recipe> get recipes => _recipes;
  List<Recipe> get todayMemories => _getTodayMemories();
  Recipe? get selectedRecipe => _selectedRecipe;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // 레시피 CRUD
  Future<void> loadRecipes() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _recipes = await HiveService.getAllRecipes();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> addRecipe(Recipe recipe) async {
    try {
      await HiveService.saveRecipe(recipe);
      _recipes.insert(0, recipe); // 최신 순
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // 검색 기능
  List<Recipe> searchRecipes(String query, {Mood? mood}) {
    return _recipes.where((recipe) {
      bool matchesTitle = recipe.title.toLowerCase().contains(query.toLowerCase());
      bool matchesMood = mood == null || recipe.mood == mood;
      return matchesTitle && matchesMood;
    }).toList();
  }
  
  // "과거 오늘" 기능
  List<Recipe> _getTodayMemories() {
    final today = DateTime.now();
    return _recipes.where((recipe) {
      final recipeDate = recipe.createdAt;
      return recipeDate.month == today.month && 
             recipeDate.day == today.day &&
             recipeDate.year != today.year;
    }).toList();
  }
}
```

### StatsProvider (개인 통계 상태 관리)
```dart
class StatsProvider extends ChangeNotifier {
  List<Recipe> _recipes = [];
  
  void setRecipes(List<Recipe> recipes) {
    _recipes = recipes;
    notifyListeners();
  }
  
  // 감정 분석
  Map<Mood, double> get emotionDistribution {
    if (_recipes.isEmpty) return {};
    
    Map<Mood, int> counts = {};
    for (var recipe in _recipes) {
      counts[recipe.mood] = (counts[recipe.mood] ?? 0) + 1;
    }
    
    return counts.map((mood, count) => 
      MapEntry(mood, count / _recipes.length));
  }
  
  // 요리 패턴 분석
  Map<String, int> get cookingPatterns {
    Map<String, int> patterns = {};
    for (var recipe in _recipes) {
      for (var tag in recipe.tags) {
        patterns[tag] = (patterns[tag] ?? 0) + 1;
      }
    }
    return patterns;
  }
  
  // 연속 기록 계산
  int get continuousStreak {
    // 로직 구현...
    return 5; // 예시
  }
}
```

## 에러 처리

### 에러 타입
- **네트워크 에러**: 연결 실패, 타임아웃
- **API 에러**: 4xx, 5xx 응답
- **검증 에러**: 입력값 검증 실패
- **시스템 에러**: 앱 내부 오류

### 에러 처리 전략
```dart
try {
  // 작업 수행
} on NetworkException {
  // 네트워크 에러 처리
} on ApiException {
  // API 에러 처리
} catch (e) {
  // 일반 에러 처리
}
```

## 보안 고려사항

### 데이터 보안
- API 키 관리: 환경변수 사용
- 민감정보 암호화
- HTTPS 통신 강제

### 인증/인가
- [인증 방식 설명]
- 토큰 관리 전략
- 세션 관리

## 성능 최적화

### 이미지 최적화
- 압축 및 리사이징
- 캐싱 전략
- Lazy loading

### 데이터 최적화
- 페이지네이션
- 필요한 데이터만 요청
- 로컬 캐싱 활용

### UI 최적화
- const 위젯 사용
- 불필요한 rebuild 방지
- 리스트 가상화

## 테스트 전략

### 테스트 레벨
1. **단위 테스트**: 모델, 서비스, 유틸리티
2. **위젯 테스트**: UI 컴포넌트
3. **통합 테스트**: 전체 플로우

### 테스트 커버리지 목표
- 비즈니스 로직: 90% 이상
- UI 컴포넌트: 70% 이상
- 전체: 80% 이상

## 배포 아키텍처

### 빌드 설정
- **개발**: Debug 빌드
- **스테이징**: Release 빌드 + 테스트 서버
- **프로덕션**: Release 빌드 + 프로덕션 서버

### 환경별 설정
```dart
class Environment {
  static const String dev = 'development';
  static const String staging = 'staging';
  static const String prod = 'production';

  static String get current =>
    const String.fromEnvironment('ENV', defaultValue: dev);
}
```

## 확장성 고려사항

### 모듈화
- 기능별 모듈 분리
- 의존성 주입 패턴
- 인터페이스 정의

### 국제화 (i18n)
- 다국어 지원 구조
- 날짜/시간 포맷
- 통화 표시

### 플랫폼별 대응
- iOS/Android 차이점
- 태블릿 대응
- 웹 지원 (필요시)

---

## 📋 아키텍처 버전 히스토리

### v2025.09.17 - 테스트 아키텍처 재설계
**아키텍처 변경사항:**
- **테스트 레이어 재설정**: 기존 test/ 디렉터리 구조 완전 제거
- **TDD 준비 상태**: 향후 체계적 테스트 구축을 위한 클린 상태
- **문서 구조 최적화**: 형상 관리 시스템 도입으로 변경사항 추적 체계 구축

**현재 아키텍처 상태:**
```
lib/
├── main.dart                    # 앱 진입점
├── config/                      # 설정 관리 (API, 테마 등)
├── models/                      # 데이터 모델 (Recipe, Mood 등)
├── services/                    # 비즈니스 로직 (OpenAI, Hive, Challenge 등)
├── screens/                     # UI 화면 (Bottom Navigation 기반)
├── widgets/                     # 재사용 가능한 UI 컴포넌트
├── providers/                   # 상태 관리 (Provider 패턴)
└── utils/                       # 유틸리티 함수

test/                           # [제거됨] 향후 TDD 기반 재구축 예정
assets/                         # 이미지, 폰트 등 정적 자원
```

**다음 버전 계획:**
- Phase 1: 프로젝트 초기 설정 및 의존성 관리
- Phase 2: TDD 기반 핵심 모델 구현
- Phase 3: 체계적 테스트 구조 재구축

---