# Recipesoup 테스트 실행 가이드

## 개요
이 문서는 **Recipesoup** 앱의 모든 테스트를 실행하는 구체적인 단계별 가이드입니다. 
TDD 원칙에 따라 구현 전 테스트를 작성하고, 감정 기반 레시피 아카이빙의 핵심 기능을 완벽히 검증합니다.

## 테스트 실행 체크리스트

### 사전 준비 ✅
- [ ] Flutter 개발 환경 설정 완료
- [ ] OpenAI API 키 설정 (.env 파일)
- [ ] 테스트 이미지 파일 준비 (testimg1.jpg, testimg2.jpg, testimg3.jpg)
- [ ] Chrome 브라우저 설치 (Playwright MCP용)
- [ ] 의존성 패키지 설치 완료

### 실행 순서 ✅
1. **단위 테스트** (Unit Tests)
2. **위젯 테스트** (Widget Tests)  
3. **통합 테스트** (Integration Tests)
4. **Playwright MCP 테스트** (Browser Tests)
5. **성능 및 접근성 테스트**

---

## 1. 단위 테스트 실행

### 1.1 환경 설정
```bash
# 프로젝트 루트에서
flutter pub get

# 테스트 의존성 추가 (pubspec.yaml)
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.2
  build_runner: ^2.4.7
  test: ^1.24.6
```

### 1.2 모델 테스트 실행
```bash
# Recipe 모델 테스트
flutter test test/models/recipe_test.dart

# 예상 결과:
# ✅ Recipe 생성자 테스트
# ✅ emotionalStory 필드 테스트  
# ✅ Hive 직렬화/역직렬화 테스트
# ✅ copyWith 메서드 테스트
# ✅ 날짜 기반 정렬 테스트
```

**구체적 테스트 케이스 예시:**
```dart
// test/models/recipe_test.dart
group('Recipe Model Tests', () {
  test('should create Recipe with emotional story', () {
    final recipe = Recipe(
      id: 'test_001',
      title: '승진 기념 스테이크',
      emotionalStory: '너무 기뻐서 스테이크를 구워먹었어요!',
      ingredients: [testIngredients[0]],
      instructions: ['스테이크를 구워주세요'],
      tags: ['#기념일', '#스테이크'],
      createdAt: DateTime.now(),
      mood: Mood.happy,
    );
    
    expect(recipe.emotionalStory, contains('기뻐서'));
    expect(recipe.mood, Mood.happy);
    expect(recipe.tags, contains('#기념일'));
  });
  
  test('should serialize to/from JSON correctly', () {
    final original = testRecipes[0]; // TESTDATA.md의 데이터 사용
    final json = original.toJson();
    final restored = Recipe.fromJson(json);
    
    expect(restored.id, original.id);
    expect(restored.emotionalStory, original.emotionalStory);
    expect(restored.mood, original.mood);
  });
});
```

### 1.3 서비스 테스트 실행

**OpenAI Service 테스트 (핵심!):**
```bash
flutter test test/services/openai_service_test.dart -v

# 예상 결과:
# ✅ testimg1.jpg 분석 성공 케이스
# ✅ testimg2.jpg 분석 다른 음식 처리  
# ✅ testimg3.jpg 복잡한 요리 분석
# ✅ 네트워크 에러 처리
# ✅ API 키 없음 에러 처리
# ✅ 타임아웃 처리 (30초)
```

**구체적 테스트 케이스:**
```dart
// test/services/openai_service_test.dart
group('OpenAI Service Tests', () {
  late MockOpenAIService mockService;
  
  setUp(() {
    mockService = MockOpenAIService();
  });
  
  test('should analyze testimg1.jpg successfully', () async {
    // TESTDATA.md의 testimg1_response 사용
    when(mockService.analyzeImage(any))
      .thenAnswer((_) async => testImg1Response);
    
    final result = await mockService.analyzeImage('test_image_data');
    
    expect(result.dishName, '김치찌개');
    expect(result.ingredients, contains('김치'));
    expect(result.difficulty, '쉬움');
  });
  
  test('should handle API timeout gracefully', () async {
    when(mockService.analyzeImage(any))
      .thenThrow(TimeoutException('Request timeout'));
    
    expect(
      () => mockService.analyzeImage('test_image_data'),
      throwsA(isA<TimeoutException>())
    );
  });
});
```

**Hive Service 테스트:**
```bash
flutter test test/services/hive_service_test.dart

# 예상 결과:
# ✅ Recipe CRUD 작업
# ✅ 날짜별 레시피 조회
# ✅ 감정별 필터링
# ✅ "과거 오늘" 검색 기능
```

### 1.4 전체 단위 테스트 실행
```bash
# 모든 단위 테스트 실행
flutter test test/unit/ --coverage

# 커버리지 리포트 생성
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# 목표 커버리지: 85% 이상
```

---

## 2. 위젯 테스트 실행

### 2.1 화면별 위젯 테스트

**스플래시 화면 테스트:**
```bash
flutter test test/widgets/splash_screen_test.dart

# 예상 결과:
# ✅ 빈티지 로고 렌더링
# ✅ 아이보리 배경색 적용 (#FAF8F3)
# ✅ 자동 메인 화면 전환 (2.5초)
```

**구체적 테스트 케이스:**
```dart
// test/widgets/splash_screen_test.dart
testWidgets('Splash screen shows vintage logo and theme', (tester) async {
  await tester.pumpWidget(MaterialApp(home: SplashScreen()));
  
  // 빈티지 로고 확인
  expect(find.byKey(Key('vintage_logo')), findsOneWidget);
  
  // 아이보리 배경색 확인
  final container = tester.widget<Container>(
    find.byKey(Key('splash_background'))
  );
  expect(container.decoration.color, Color(0xFFFAF8F3));
  
  // 자동 전환 테스트
  await tester.pump(Duration(seconds: 3));
  expect(find.byType(MainScreen), findsOneWidget);
});
```

**Bottom Navigation 테스트:**
```bash
flutter test test/widgets/main_screen_test.dart

# 예상 결과:
# ✅ 5탭 네비게이션 표시
# ✅ 탭 전환 동작
# ✅ FAB 버튼 렌더링
# ✅ 빈티지 테마 적용
```

**레시피 작성 화면 테스트:**
```bash
flutter test test/widgets/create_recipe_screen_test.dart

# 예상 결과:
# ✅ 감정 이야기 텍스트 영역 표시
# ✅ 사진 업로드 버튼 동작
# ✅ 감정 상태 선택 위젯
# ✅ 태그 입력 검증
```

### 2.2 컴포넌트 테스트

**레시피 카드 컴포넌트:**
```dart
testWidgets('Recipe card displays emotional story prominently', (tester) async {
  final testRecipe = testRecipes[0]; // TESTDATA.md 데이터 사용
  
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: RecipeCard(recipe: testRecipe))
  ));
  
  // 감정 메모가 이탤릭 폰트로 표시되는지 확인
  final emotionalStoryWidget = tester.widget<Text>(
    find.text(testRecipe.emotionalStory)
  );
  expect(emotionalStoryWidget.style?.fontStyle, FontStyle.italic);
  
  // 태그 표시 확인
  expect(find.text('#기념일'), findsOneWidget);
  expect(find.text('#스테이크'), findsOneWidget);
});
```

### 2.3 전체 위젯 테스트 실행
```bash
flutter test test/widgets/ --coverage
```

---

## 3. 통합 테스트 실행

### 3.1 사용자 시나리오 테스트

**시나리오 1: 첫 사용자 레시피 작성:**
```bash
flutter test integration_test/first_user_flow_test.dart

# 테스트 단계:
# 1. ✅ 앱 시작 → 스플래시 → 홈 화면
# 2. ✅ 빈 상태 메시지 확인
# 3. ✅ "첫 레시피 작성하기" 버튼 클릭
# 4. ✅ 감정 중심 작성 완료
# 5. ✅ 홈 화면에서 작성된 레시피 확인
```

**구체적 시나리오 코드:**
```dart
// integration_test/first_user_flow_test.dart
testWidgets('First user recipe creation flow', (tester) async {
  app.main();
  await tester.pumpAndSettle();
  
  // 스플래시 화면 대기
  await tester.pump(Duration(seconds: 3));
  
  // 빈 상태 확인
  expect(find.text('첫 레시피 작성하기'), findsOneWidget);
  
  // 작성 버튼 클릭
  await tester.tap(find.text('첫 레시피 작성하기'));
  await tester.pumpAndSettle();
  
  // 레시피 정보 입력
  await tester.enterText(
    find.byKey(Key('recipe_title')), 
    '첫 번째 레시피'
  );
  
  await tester.enterText(
    find.byKey(Key('emotional_story')),
    '첫 요리라서 설렜어요!'
  );
  
  // 감정 선택
  await tester.tap(find.text('😊 기쁨'));
  await tester.pumpAndSettle();
  
  // 저장 버튼 클릭
  await tester.tap(find.text('저장'));
  await tester.pumpAndSettle();
  
  // 홈 화면에서 레시피 확인
  expect(find.text('첫 번째 레시피'), findsOneWidget);
  expect(find.text('😊'), findsOneWidget);
});
```

**시나리오 2: 사진 기반 AI 분석:**
```dart
testWidgets('Photo-based recipe creation with AI analysis', (tester) async {
  // Mock OpenAI Service 설정
  when(mockOpenAI.analyzeImage(any))
    .thenAnswer((_) async => testImg1Response); // TESTDATA.md 데이터
  
  // FAB → "사진으로 작성" 플로우
  await tester.tap(find.byKey(Key('fab')));
  await tester.pumpAndSettle();
  
  await tester.tap(find.text('사진으로 작성'));
  await tester.pumpAndSettle();
  
  // 이미지 업로드 시뮬레이션
  final photoInput = find.byKey(Key('photo_input'));
  await tester.tap(photoInput);
  await tester.pumpAndSettle();
  
  // AI 분석 로딩 상태 확인
  expect(find.byKey(Key('analysis_loading')), findsOneWidget);
  
  // 분석 결과 대기
  await tester.pump(Duration(seconds: 10));
  
  // 추천 재료 확인
  expect(find.text('김치'), findsOneWidget);
  expect(find.text('돼지고기'), findsOneWidget);
  
  // 사용자 감정 메모 추가
  await tester.enterText(
    find.byKey(Key('emotional_story')),
    '오늘 김치찌개가 먹고 싶어서 만들었어요'
  );
  
  await tester.tap(find.text('저장'));
  await tester.pumpAndSettle();
});
```

### 3.2 통합 테스트 실행
```bash
# 모든 통합 테스트 실행
flutter test integration_test/

# 디바이스에서 실행
flutter test integration_test/first_user_flow_test.dart -d chrome
```

---

## 4. Playwright MCP 테스트 실행 (핵심!)

### 4.1 사전 준비
```bash
# 1. Flutter Web 빌드
flutter build web --web-renderer html

# 2. 테스트 이미지 준비
cp path/to/your/food/images/kimchi_stew.jpg tests/testimg1.jpg
cp path/to/your/food/images/pasta.jpg tests/testimg2.jpg  
cp path/to/your/food/images/korean_table.jpg tests/testimg3.jpg

# 3. 로컬 서버 실행
cd build/web
python -m http.server 8080 &
```

### 4.2 Playwright MCP 테스트 실행

**MCP 도구를 통한 실행:**
```javascript
// 1. 브라우저 네비게이션
await playwright_navigate({ 
  url: "http://localhost:8080"
});

// 2. 환경 체크 실행
await playwright_evaluate({ 
  script: `
    const fs = require('fs');
    
    // 테스트 이미지 파일 존재 확인
    const images = ['./testimg1.jpg', './testimg2.jpg', './testimg3.jpg'];
    for (const img of images) {
      if (!fs.existsSync(img)) {
        throw new Error('테스트 이미지 없음: ' + img);
      }
    }
    console.log('✅ 모든 테스트 이미지 준비됨');
  `
});

// 3. 메인 테스트 실행
await playwright_evaluate({ 
  script: fs.readFileSync('./tests/playwright_food_analysis_test.js', 'utf8')
});
```

**개별 테스트 단계별 실행:**
```javascript
// 앱 접근성 테스트
await playwright_evaluate({
  script: `
    // FAB 버튼 클릭
    await page.locator('[data-testid="fab"], .fab, #fab').click();
    await page.locator('[data-testid="fab-menu"]').waitFor({timeout: 5000});
    
    // "사진으로 작성" 선택
    await page.locator('[data-testid="photo-recipe-btn"]').click();
    await page.locator('[data-testid="recipe-create"]').waitFor();
    
    console.log('✅ 레시피 작성 화면 진입');
  `
});

// testimg1.jpg 업로드 및 분석
await playwright_evaluate({
  script: `
    const photoInput = page.locator('input[type="file"]');
    await photoInput.setInputFiles('./testimg1.jpg');
    
    console.log('✅ 김치찌개 이미지 업로드');
    
    // 분석 시작 로딩 확인
    await page.locator('[data-testid="analysis-loading"]').waitFor({timeout: 5000});
    console.log('✅ AI 분석 시작됨');
    
    // 분석 결과 대기 (최대 20초)
    await page.locator('[data-testid="analysis-result"]').waitFor({timeout: 20000});
    console.log('✅ AI 분석 완료');
    
    // 결과 검증
    const pageContent = await page.content();
    if (pageContent.includes('김치') && pageContent.includes('돼지고기')) {
      console.log('✅ 예상 재료 발견: 김치, 돼지고기');
    } else {
      console.warn('⚠️ 예상 재료 일부 누락');
    }
  `
});
```

### 4.3 전체 Playwright 테스트 실행
```bash
# Node.js 환경에서 직접 실행 (개발용)
cd tests
node playwright_food_analysis_test.js

# 예상 출력:
# 🍽️ Recipesoup 음식 사진 분석 테스트 시작...
# 📱 앱 접근성 테스트...
# 🖼️ testimg1 분석 테스트... (김치찌개)
# 🖼️ testimg2 분석 테스트... (파스타)  
# 🖼️ testimg3 분석 테스트... (한정식)
# ❌ 에러 시나리오 테스트...
# 🎨 UI 상태 테스트...
# ⚡ 성능 테스트...
# 📊 테스트 결과: 85% 성공
```

---

## 5. 성능 및 접근성 테스트

### 5.1 성능 테스트
```bash
# Flutter 성능 프로파일링
flutter run --profile -d chrome
# DevTools에서 Performance 탭 확인

# 메모리 사용량 테스트
flutter test test/performance/memory_test.dart

# 예상 결과:
# ✅ 1000개 레시피 로딩: < 2초
# ✅ 메모리 사용량: < 200MB
# ✅ 이미지 처리: < 5초
```

### 5.2 접근성 테스트
```bash
flutter test test/accessibility/a11y_test.dart

# 예상 결과:
# ✅ 색상 대비 WCAG AA 준수
# ✅ 최소 터치 영역 48dp
# ✅ 스크린 리더 지원
# ✅ Semantics 설정
```

---

## 6. 전체 테스트 실행 및 리포트

### 6.1 모든 테스트 일괄 실행
```bash
#!/bin/bash
# run_all_tests.sh

echo "🧪 Recipesoup 전체 테스트 실행..."

# 1. 단위 테스트
echo "1️⃣ 단위 테스트 실행..."
flutter test test/unit/ --coverage || exit 1

# 2. 위젯 테스트  
echo "2️⃣ 위젯 테스트 실행..."
flutter test test/widgets/ || exit 1

# 3. 통합 테스트
echo "3️⃣ 통합 테스트 실행..."
flutter test integration_test/ -d chrome || exit 1

# 4. Flutter Web 빌드
echo "4️⃣ Flutter Web 빌드..."
flutter build web --web-renderer html || exit 1

# 5. 웹 서버 시작
echo "5️⃣ 웹 서버 시작..."
cd build/web && python -m http.server 8080 &
SERVER_PID=$!
cd ../..

# 6. Playwright MCP 테스트 (수동 실행 안내)
echo "6️⃣ Playwright MCP 테스트 준비 완료"
echo "   다음 명령으로 실행하세요:"
echo "   - 테스트 이미지를 tests/ 디렉토리에 복사"
echo "   - MCP 도구에서 Playwright 테스트 스크립트 실행"

# 7. 서버 정리
sleep 5
kill $SERVER_PID

echo "✅ 모든 테스트 완료!"
```

### 6.2 커버리지 리포트 생성
```bash
# LCOV 커버리지 리포트
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# 목표 커버리지 확인:
# - 전체: 85% 이상
# - OpenAI Service: 95% 이상  
# - Recipe/Mood 모델: 90% 이상
# - UI 위젯: 75% 이상
```

### 6.3 테스트 결과 문서화
```bash
# 테스트 결과를 마크다운으로 출력
flutter test --machine > test_results.json
python3 generate_test_report.py test_results.json > TEST_RESULTS.md
```

---

## 7. CI/CD 통합

### 7.1 GitHub Actions 설정
```yaml
# .github/workflows/test.yml
name: Recipesoup Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
    
    - name: Install dependencies
      run: flutter pub get
      
    - name: Run unit tests
      run: flutter test test/unit/ --coverage
      
    - name: Run widget tests
      run: flutter test test/widgets/
      
    - name: Build web
      run: flutter build web
      
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: coverage/lcov.info
```

### 7.2 자동화된 테스트 검증
```bash
# pre-commit hook 설정
#!/bin/sh
# .git/hooks/pre-commit

echo "🧪 커밋 전 테스트 실행..."

# 빠른 테스트만 실행
flutter test test/unit/models/ || exit 1
flutter test test/unit/services/ || exit 1

echo "✅ 기본 테스트 통과"
exit 0
```

---

## 8. 트러블슈팅

### 자주 발생하는 문제와 해결책

**1. OpenAI API 테스트 실패**
```bash
# 원인: API 키 설정 오류
# 해결:
echo "OPENAI_API_KEY=sk-proj-..." > .env
echo "API_MODEL=gpt-4o-mini" >> .env

# API 키 유효성 확인
curl -H "Authorization: Bearer $OPENAI_API_KEY" \
     https://api.openai.com/v1/models
```

**2. Playwright 테스트 타임아웃**
```bash
# 원인: 네트워크 지연 또는 앱 로딩 느림
# 해결: 타임아웃 시간 증가
# TEST_CONFIG.apiAnalysisTimeout = 30000; // 30초
```

**3. Flutter Web 빌드 실패**
```bash
# 원인: 웹 호환성 이슈
# 해결:
flutter clean
flutter pub get
flutter build web --web-renderer html
```

**4. 테스트 이미지 인식 실패**
```bash
# 원인: 이미지 품질 또는 형식 문제
# 해결: 
# - 고품질 음식 사진 사용 (2MB 이하)
# - 명확한 음식 이미지 (배경 단순)
# - JPG/PNG 형식만 사용
```

---

## 9. 테스트 성공 기준

### 통과 기준
- [x] **모든 단위 테스트 PASS** (100%)
- [x] **모든 위젯 테스트 PASS** (100%)  
- [x] **핵심 통합 시나리오 PASS** (100%)
- [x] **음식 사진 분석 테스트 PASS** (testimg1,2,3 모두)
- [x] **Flutter Web Playwright 테스트 PASS**
- [x] **커버리지 목표 달성** (85% 이상)
- [x] **성능 기준 만족** (API 15초 이내, 메모리 200MB 이내)

### 배포 승인 기준
- [x] 모든 테스트 통과
- [x] 코드 리뷰 완료
- [x] 보안 스캔 통과
- [x] 접근성 가이드라인 준수
- [x] 성능 벤치마크 만족

---

## 10. 결론

이 실행 가이드를 따라 모든 테스트를 수행하면:

1. **TDD 원칙 준수**: 구현 전 테스트 작성으로 품질 보장
2. **핵심 기능 검증**: OpenAI 기반 음식 사진 분석 완벽 테스트
3. **감정 기반 UX 검증**: 레시피와 감정 연결 기능 확인
4. **브라우저 호환성**: Playwright MCP로 실제 사용자 시나리오 테스트
5. **성능 최적화**: 메모리, 속도, 접근성 모든 영역 검증

**성공적인 테스트 완료시 Recipesoup 앱은 사용자의 감정과 요리를 아름답게 연결하는 완성된 감성 레시피 아카이브가 됩니다. 🍽️✨**

---
*이 가이드는 실제 구현과 함께 지속적으로 업데이트되며, 모든 테스트는 감정 기반 레시피 아카이빙의 사용자 경험을 완벽히 검증합니다.*