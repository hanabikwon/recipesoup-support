# Recipesoup 코드 스타일 및 컨벤션

## 코딩 스타일
- **언어**: Dart (Flutter 3.x)
- **Linting**: flutter_lints 패키지 사용
- **분석 규칙**: analysis_options.yaml 기반

## 파일 및 폴더 구조
```
lib/
├── main.dart                    # 앱 진입점
├── config/                      # 설정 (constants, theme, api_config)
├── models/                      # 데이터 모델 (recipe, ingredient, mood)
├── services/                    # 비즈니스 로직 (openai, hive, image, stats)
├── screens/                     # 화면 컴포넌트
├── widgets/                     # 재사용 가능한 위젯
├── providers/                   # 상태 관리 (Provider 패턴)
└── utils/                       # 유틸리티 함수
```

## 네이밍 컨벤션
- **파일명**: snake_case.dart
- **클래스명**: PascalCase
- **변수/함수명**: camelCase
- **상수**: SCREAMING_SNAKE_CASE
- **Private**: _underscore 접두사

## 상태 관리 패턴
- **Provider + ChangeNotifier** 사용
- **RecipeProvider**: 레시피 CRUD 및 검색
- **StatsProvider**: 통계 및 개인 패턴 분석
- **BurrowProvider**: 게임화 요소 관리

## 데이터 모델 패턴
- Hive NoSQL을 위한 @HiveType 어노테이션
- toJson/fromJson 메서드 구현
- copyWith 메서드로 불변성 보장
- Enum 활용 (Mood, IngredientCategory 등)

## 에러 처리
- try-catch 블록 활용
- 타입별 에러 분류 (NetworkException, ApiException 등)
- Provider에서 에러 상태 관리

## 테스트 구조
- **Unit Tests**: test/unit/ (서비스, 모델, 유틸리티)
- **Widget Tests**: test/widget/ (화면, 위젯)
- **Integration Tests**: test/integration/ (전체 플로우)
- **Mock**: mockito 사용

## 의존성 관리
- pubspec.yaml에서 중앙 관리
- dev_dependencies 분리
- 버전 고정 방식