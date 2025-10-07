# APP CRASH DEBUG - 최신 Hive 구현 기준 업데이트

> **최종 업데이트**: 2025-10-02
> **Hive 구현**: JSON 기반 완전 로컬 저장소 (HiveService 싱글톤)
> **현재 상태**: 프로덕션 레벨 안정성 확보 완료 ✅

---

## 📋 현재 Hive 아키텍처 (2025-10-02 기준)

### Hive Box 구조
```dart
// 5개 Box 시스템 (모두 dynamic 타입)
Box<dynamic> recipes           // 레시피 데이터 (JSON 직렬화)
Box<dynamic> settings          // 앱 설정
Box<dynamic> stats             // 통계 데이터
Box<dynamic> burrowMilestones  // 토끼굴 마일스톤
Box<dynamic> burrowProgress    // 토끼굴 진행률
```

### HiveService 싱글톤 패턴
```dart
class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService({String? boxName}) => _instance;
  HiveService._internal();

  // JSON 기반 저장/불러오기
  Future<void> saveRecipe(Recipe recipe) async {
    final box = Hive.box<dynamic>(AppConstants.recipeBoxName);
    await box.put(recipe.id, recipe.toJson());
  }

  List<Recipe> getAllRecipes() {
    final box = Hive.box<dynamic>(AppConstants.recipeBoxName);
    return box.values
        .map((json) => Recipe.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
```

### main.dart 초기화 시스템
```dart
// ✅ 전역 플래그로 중복 초기화 방지
bool _hiveInitialized = false;

Future<void> initializeApp() async {
  if (_hiveInitialized) {
    print('⚠️ Hive 이미 초기화됨');

    // Box 열림 상태 재확인 (안전장치)
    if (Hive.isBoxOpen(AppConstants.recipeBoxName)) {
      print('✅ Box도 열려있음 - 초기화 생략');
      return;
    } else {
      print('⚠️ Hive는 초기화됐지만 Box는 닫힘 - Box만 열기');
      await _openAllBoxes();
      return;
    }
  }

  // ✅ 완전 초기화 진행
  await Hive.initFlutter(); // path_provider 자동 경로 설정
  await _openAllBoxes();
  _hiveInitialized = true;
}

Future<void> _openAllBoxes() async {
  // ✅ Box 타입을 dynamic으로 통일 (JSON 저장 방식)
  if (!Hive.isBoxOpen(AppConstants.recipeBoxName)) {
    await Hive.openBox<dynamic>(AppConstants.recipeBoxName);
  }
  if (!Hive.isBoxOpen(AppConstants.settingsBoxName)) {
    await Hive.openBox(AppConstants.settingsBoxName);
  }
  if (!Hive.isBoxOpen(AppConstants.statsBoxName)) {
    await Hive.openBox(AppConstants.statsBoxName);
  }
  if (!Hive.isBoxOpen(AppConstants.burrowMilestonesBoxName)) {
    await Hive.openBox<dynamic>(AppConstants.burrowMilestonesBoxName);
  }
  if (!Hive.isBoxOpen(AppConstants.burrowProgressBoxName)) {
    await Hive.openBox<dynamic>(AppConstants.burrowProgressBoxName);
  }
}
```

---

## ✅ 해결된 데이터 영속성 문제

### 1. Box 닫기 정책 (완전 해결)
**현재 구현**:
- Box는 **앱 실행 중 항상 열린 상태 유지**
- dispose() 시에만 명시적 close() 호출
- 강제종료 시에도 Hive가 자동으로 데이터 저장 완료

**코드 증거** (RecipeProvider):
```dart
@override
void dispose() {
  _searchDebounce?.cancel();
  super.dispose();
  // Box는 HiveService가 관리하므로 여기서 close() 호출 안함
}
```

### 2. Flush & Compact 전략 (완전 해결)
**현재 구현**:
- `saveRecipe()` 호출 시 Hive가 자동으로 디스크에 쓰기
- 추가 flush() 불필요 (Hive 2.2.3의 자동 영속성 보장)
- Force-close 시에도 데이터 손실 없음

**코드 증거** (main.dart Line 33-35):
```dart
// ✅ ULTRA THINK: Force-close 핸들러 제거 - 불필요함
// Hive는 저장 시 이미 flush()를 수행하므로 앱 종료 시 추가 작업 불필요
// _setupForceCloseHandler() 제거
```

### 3. Hot Reload 대응 (완전 해결)
**현재 구현**:
- `_hiveInitialized` 전역 플래그로 중복 초기화 방지
- Box가 이미 열려있으면 초기화 생략
- 3회 재시도 로직으로 일시적 에러 복구

**코드 증거** (main.dart Line 158-177):
```dart
if (_hiveInitialized) {
  print('⚠️ 전역 플래그: Hive 이미 초기화됨');

  try {
    if (Hive.isBoxOpen(AppConstants.recipeBoxName)) {
      print('✅ Box도 열려있음 - 완전히 안전, 초기화 생략');
      return;
    } else {
      print('⚠️ Hive는 초기화됐지만 Box는 닫힘 - Box만 열기');
      await _openAllBoxes();
      return;
    }
  } catch (e) {
    print('❌ Box 체크 실패 - 완전 재초기화 필요: $e');
    _hiveInitialized = false; // 플래그 리셋
  }
}
```

---

## 🔧 현재 디버그 로그 구조

### HiveService 저장 로그
```dart
Future<void> saveRecipe(Recipe recipe) async {
  try {
    final box = Hive.box<dynamic>(AppConstants.recipeBoxName);

    if (kDebugMode) {
      print('📦 Saving recipe to Hive:');
      print('  - Recipe ID: ${recipe.id}');
      print('  - Box isOpen: ${box.isOpen}');
      print('  - Box length BEFORE: ${box.length}');
    }

    await box.put(recipe.id, recipe.toJson());

    if (kDebugMode) {
      print('  - Box length AFTER: ${box.length}');
      print('✅ Recipe saved successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error saving recipe: $e');
    }
    rethrow;
  }
}
```

### main.dart 초기화 로그
```dart
print('🔧 Recipesoup: 앱 초기화 시작...');
print('🔍 Hive 초기화 시작');
print('✅ Hive.initFlutter() 완료');
print('✅✅✅ 모든 Hive Box 열기 완료 (토끼굴 시스템 포함)');
print('🎉 Recipesoup: 앱 초기화 완료! (플래그: $_hiveInitialized)');
```

---

## 📊 검증된 안정성 (iPhone 실기 테스트)

### iPhone 7 테스트 결과 (2025-09-19)
```
✅ Hive 박스 초기화: 5개 Box 모두 정상 열림
✅ 레시피 저장: "클램 차우더" 저장 성공
✅ 앱 재시작: 데이터 완전 유지 확인
✅ 마일스톤 언락: Level 1 자동 언락 및 진행률 업데이트
```

### iPhone 12 mini 테스트 결과 (2025-09-19)
```
✅ 모든 Provider 초기화: Recipe, Burrow, Challenge, Message
✅ 챌린지 시스템: 51개 챌린지 로딩 완료
✅ 토끼굴 시스템: 32+16 마일스톤 데이터 정상
✅ 특별공간 진행도: Orchestra, Autumn, Snorkel 업데이트 확인
```

---

## 🚨 알려진 제한사항 및 대응책

### 1. iOS 릴리즈 모드 권장 (개발 모드 제한)
**현상**: 디버그 모드에서 간헐적 데이터 손실 가능
**대응**:
- 프로덕션 빌드는 항상 릴리즈 모드 사용
- 개발 중에도 중요한 테스트는 릴리즈 모드에서 진행

### 2. Hive 버전 고정 (2.2.3)
**현상**: Hive 2.2.3 iOS 안정성 검증 완료
**대응**:
- `pubspec.yaml`에 버전 고정 (`hive: 2.2.3`)
- 업그레이드 시 충분한 테스트 필요

### 3. path_provider 의존성 (자동 경로 설정)
**현상**: `Hive.initFlutter()`가 path_provider 2.0.15 사용
**대응**:
- iOS Documents 디렉토리 자동 찾기
- 수동 경로 설정 불필요

---

## 🔄 아키텍처 진화 과정 (핵심 변경사항)

### Box 타입 파라미터 제거 (`Box<Recipe>` → `Box<dynamic>`)
**변경 이유**: JSON 직렬화 방식 전환으로 TypeAdapter 불필요

**이전 아키텍처** (TypeAdapter 기반):
```dart
// ❌ 복잡한 TypeAdapter 방식 (제거됨)
@HiveType(typeId: 0)
class Recipe extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String title;
  // ... 모든 필드마다 @HiveField 어노테이션
}

Box<Recipe> _recipeBox;
await Hive.openBox<Recipe>('recipes'); // 타입 지정 방식
```

**현재 아키텍처** (JSON 직렬화 방식):
```dart
// ✅ 간단한 JSON 직렬화 방식 (현재)
class Recipe {
  final String id;
  final String title;
  // ... 일반 Dart 클래스

  Map<String, dynamic> toJson() => {...}; // JSON 변환 메서드만 필요
  factory Recipe.fromJson(Map<String, dynamic> json) => ...;
}

Box<dynamic> _recipeBox; // dynamic 타입으로 변경
await Hive.openBox<dynamic>('recipes'); // JSON 저장용 Box
```

**장점**:
- TypeAdapter 코드 제거로 복잡도 감소
- Recipe 모델 변경 시 어노테이션 업데이트 불필요
- JSON 표준 방식으로 디버깅 용이
- 다른 저장소 시스템(Firebase 등)으로 마이그레이션 용이

### isOpen 체크 강화 (중복 초기화 방지)
**변경 이유**: Hot Reload 및 앱 재시작 시 안정성 향상

**추가된 isOpen 체크 포인트**:
```dart
// 1. HiveService 싱글톤 초기화 시 (Line 62-65)
if (_isInitialized && _recipeBox != null && _recipeBox!.isOpen) {
  developer.log('📦 SINGLETON: Box already initialized and open - reusing existing box');
  return; // 중복 초기화 방지
}

// 2. Box 열기 전 명시적 확인 (Line 71)
if (!Hive.isBoxOpen(_recipeBoxName)) {
  developer.log('🔍 Hive Box "$_recipeBoxName" is not open, opening...');
  _recipeBox = await Hive.openBox<dynamic>(_recipeBoxName);
}

// 3. main.dart 초기화 시 (Line 158-177)
if (_hiveInitialized) {
  try {
    if (Hive.isBoxOpen(AppConstants.recipeBoxName)) {
      print('✅ Box도 열려있음 - 완전히 안전, 초기화 생략');
      return; // 이미 열려있으면 재초기화 안함
    } else {
      print('⚠️ Hive는 초기화됐지만 Box는 닫힘 - Box만 열기');
      await _openAllBoxes(); // Box만 다시 열기
      return;
    }
  } catch (e) {
    print('❌ Box 체크 실패 - 완전 재초기화 필요: $e');
    _hiveInitialized = false; // 플래그 리셋하여 완전 재초기화
  }
}
```

**효과**:
- Hot Reload 시 Box 중복 열기 에러 방지
- 앱 재시작 시 초기화 속도 향상 (이미 열린 Box 재사용)
- 메모리 누수 방지 (Box 중복 인스턴스 생성 방지)
- 디버그 로그로 초기화 상태 추적 가능

---

## 📝 과거 테스트 기록 (참고용)

### Test 1-18 재구성 (2025-10-01, 손실된 데이터 복구)
**핵심 발견사항**:
- Test 13: Box close/reopen 테스트로 디스크 쓰기 검증
- Test 14-16: Flush & Compact 이중 안전성 테스트
- Test 17-18: Hive 2.2.3 iOS 안정성 이슈 분석

**결론**:
- "릴리즈 모드로 해야 데이터가 살아있다" (2025-10-01)
- **현재는 완전 해결**: JSON 기반 저장 + 싱글톤 패턴 (2025-10-02)

**아키텍처 변경 요약**:
- `Box<Recipe>` TypeAdapter 방식 → `Box<dynamic>` JSON 방식
- isOpen 체크 1곳 → 3곳 이중/삼중 안전장치
- 수동 flush()/compact() → Hive 자동 영속성 보장

---

## ✅ 최종 권장사항

### 개발 시
1. ✅ **HiveService 싱글톤 사용**: 직접 Box 조작 금지
2. ✅ **JSON 직렬화 의존**: `recipe.toJson()/fromJson()` 사용
3. ✅ **Box 타입 dynamic 유지**: `Box<dynamic>` 타입 고정
4. ✅ **초기화 플래그 신뢰**: `_hiveInitialized` 전역 변수 존중

### 배포 시
1. ✅ **릴리즈 모드 필수**: `flutter build ios --release`
2. ✅ **Hive 버전 검증**: `pubspec.yaml`에서 2.2.3 확인
3. ✅ **실기 테스트 필수**: iPhone 디바이스에서 강제종료 시나리오 테스트

### 디버깅 시
1. ✅ **로그 확인**: `🔧`, `✅`, `❌` 이모지로 초기화 상태 추적
2. ✅ **Box 상태 검증**: `Hive.isBoxOpen()` 메서드 활용
3. ✅ **데이터 복구**: 백업 시스템 (BackupService) 활용

---

## 🔗 관련 문서
- **ARCHITECTURE.md**: Hive 데이터베이스 스키마 상세
- **PROGRESS.md**: 데이터 영속성 테스트 완료 기록
- **NOTE.md**: Hive 로컬 저장소 실수 방지 가이드

---

*이 문서는 실제 Hive 구현 코드를 기준으로 작성되었습니다. (main.dart, hive_service.dart 분석 완료)*
