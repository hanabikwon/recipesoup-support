# Recipesoup 개발 주의사항 및 팁
*감정 기반 레시피 아카이빙 앱 개발시 빈번한 실수와 해결 방법*

## 📱 프로젝트 현재 상태 (2025-09-25 기준)
- **✅ 구현 완료**: Phase 0-6 모든 단계 완료, 배포 준비 완료
- **🎯 검증 완료**: iPhone 7 & iPhone 12 mini 실기 테스트 통과
- **🏗️ 아키텍처**: 22개 화면 + 11개 서비스 + 5개 Provider + 완전한 기능 생태계
- **🔒 보안**: Unicode 안전성, API 키 보안, 에러 처리 완전 구현
- **💡 이 NOTE.md는 실제 개발 과정에서 발생한 문제들과 검증된 해결책을 기록**

## ⚠️ 치명적 실수 방지

### 1. Unicode Surrogate Pair 처리 (API 에러 방지!)
- **문제**: "no low surrogate in string" JSON 파싱 에러 (400 Bad Request)
- **원인**: 잘못된 Unicode 문자가 OpenAI API 요청에 포함
- **해결 방법**: UnicodeSanitizer 사용 필수
  ```dart
  // ❌ 위험한 코드 - 직접 API 호출
  final response = await dio.post(endpoint, data: requestData);

  // ✅ 안전한 코드 - Unicode 정리 후 API 호출
  final sanitizedRequest = UnicodeSanitizer.sanitizeApiRequest(requestData);
  final response = await dio.post(endpoint, data: sanitizedRequest);
  ```
- **적용 위치**: 모든 OpenAI API 호출 전
- **추가 검증**: Base64 이미지 데이터도 validateBase64() 사용
- **Fallback**: sanitization 실패 시 안전한 기본값 반환
- **디버깅**: debugUnicodeInfo() 메서드로 문자열 분석 가능

### 2. OpenAI API 키 보안 (절대 실수 금지!)
- **절대 금지**: API 키를 소스 코드에 하드코딩
- **API 키 관리**: recipesoup-openai-apikey.txt 파일에 별도 보관 (절대 소스코드 하드코딩 금지)
- **올바른 방법 (Vercel 프록시 아키텍처)**:
  ```dart
  // Vercel 서버리스 환경변수에서 API 키 관리
  // 클라이언트는 프록시 토큰만 사용

  // lib/config/api_config.dart
  class ApiConfig {
    static const String baseUrl = 'https://recipesoup-proxy-*.vercel.app';
    static String get proxyToken => '[REDACTED - See ARCHITECTURE.md]';

    static Map<String, String> get headers => {
      'Content-Type': 'application/json',
      'x-app-token': proxyToken, // 프록시 인증만 필요
    };
  }
  ```
- **프로덕션 환경변수 설정 (2025-10-02 추가)**:
  - **✅ `.env.production` 파일 필수**: release 모드에서 ApiConfig.initialize()가 로드 시도
  - **✅ OPENAI_API_KEY 의도적 생략**: Vercel 프록시 아키텍처로 불필요 (주석으로 설명)
  - **✅ 필수 설정 항목**: API_MODEL, DEBUG_MODE, REQUIRE_HTTPS, API_TIMEOUT_SECONDS
  - **✅ `.gitignore` 보호**: `.env.*` 패턴으로 모든 환경변수 파일 보호됨 검증 완료
- **체크포인트**: 커밋 전 반드시 `grep -r "sk-proj" . --exclude-dir=.git` 실행

### 3. UI 구조 변경 시 Side Effect (네비게이션 오류 방지!)
- **위험한 작업**: MainScreen AppBar 제거, 탭 개수 변경, 인덱스 매핑 수정
- **필수 체크 항목**:
  - 각 개별 화면이 독립적인 AppBar를 가지고 있는지 확인
  - _migrateCurrentIndex() 메서드에서 모든 케이스 매핑 확인
  - BottomNavigationBar items 배열과 _screens 배열 길이 일치
  - 인덱스 범위 체크 (_onTabTapped에서 0~N-1 확인)
- **올바른 수정 방법**:
  ```dart
  // ❌ 위험한 방법 - 갑작스런 구조 변경
  final List<Widget> _screens = [HomeScreen(), NewScreen()];
  
  // ✅ 안전한 방법 - Ultra Think로 모든 의존성 체크
  // 1. 각 화면의 Scaffold/AppBar 독립성 확인
  // 2. 인덱스 매핑 로직 업데이트  
  // 3. 탭 아이템과 화면 배열 길이 일치
  // 4. 컴파일 및 빌드 테스트
  final List<Widget> _screens = [
    const HomeScreen(),    // 0
    const BurrowScreen(),  // 1  
    const StatsScreen(),   // 2
    const ArchiveScreen(), // 3
    const SettingsScreen(), // 4 - 새로 추가
  ];
  ```
- **테스트 필수**: `flutter build web` 성공 여부 반드시 확인

### 4. SafeArea 처리 누락 (상단바 제거 후 발생!)
- **문제**: MainScreen AppBar 제거 후 개별 화면에서 상태바 충돌
- **증상**: 탭바나 콘텐츠가 상태바(status bar)와 겹쳐서 표시
- **원인**: SafeArea 처리 없이 바로 UI 요소를 상단에 배치
- **올바른 해결 방법**:
  ```dart
  // ❌ 위험한 코드 - 상태바 충돌 가능
  return Scaffold(
    body: Column(
      children: [
        TabBar(...), // 상태바와 겹칠 수 있음
        Expanded(child: TabBarView(...)),
      ],
    ),
  );
  
  // ✅ 안전한 코드 - SafeArea로 보호
  return Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Text('화면 제목', style: TextStyle(fontSize: 24, bold)),
          ),
          TabBar(...), // 상태바 아래에 안전하게 배치
          Expanded(child: TabBarView(...)),
        ],
      ),
    ),
  );
  ```
- **체크 포인트**: 
  - `flutter build web` 후 상단 영역 레이아웃 확인
  - 시뮬레이터에서 상태바 겹침 현상 점검
  - SafeArea 적용 후 충분한 상단 패딩 확보

### 5. TDD 원칙 위반 (개발 속도 저하 원인)
- **절대 규칙**: 모든 API 관련 코드는 테스트 먼저 작성
- **틀린 순서**: 구현 → 테스트 → 리팩토링
- **올바른 순서**: 테스트 → 구현 → 리팩토링
- **특히 중요**: OpenAI Service 테스트 (네트워크 의존성)
  ```dart
  // ❌ 틀린 예시 - 구현부터 시작
  class OpenAIService {
    Future<RecipeAnalysis> analyzeImage(String imageData) async {
      // 구현...
    }
  }
  
  // ✅ 올바른 예시 - 테스트부터 시작
  test('should analyze food image and return ingredients', () async {
    // Given
    when(mockService.analyzeImage(any))
      .thenAnswer((_) async => testImg1Response);
    
    // When
    final result = await service.analyzeImage(testImageData);
    
    // Then
    expect(result.ingredients, contains('김치'));
  });
  ```

## 🧠 Recipesoup 특화 주의사항

### 6. 감정 기반 데이터 모델 실수
- **흔한 실수**: Recipe에서 `emotionalStory` 필드를 Optional로 처리
- **올바른 방법**: `emotionalStory`는 필수 필드 (앱의 핵심 가치)
  ```dart
  // ❌ 틀린 모델
  class Recipe {
    final String? emotionalStory; // 선택사항으로 처리 (위험!)
  }
  
  // ✅ 올바른 모델
  class Recipe {
    final String emotionalStory; // 필수 필드 (감정 기반 앱의 핵심)
    
    Recipe({
      required this.emotionalStory, // required 키워드 필수
      // ...
    });
  }
  ```

### 7. Mood Enum 처리 실수
- **흔한 실수**: Mood enum을 단순 String으로 저장
- **올바른 방법**: enum index와 함께 한국어/영어/이모지 매핑 유지
  ```dart
  // ❌ 틀린 방법
  enum Mood { happy, sad } // 정보 부족
  
  // ✅ 올바른 방법  
  enum Mood {
    happy('😊', '기쁨', 'happy'),
    sad('😢', '슬픔', 'sad');
    
    const Mood(this.emoji, this.korean, this.english);
    final String emoji, korean, english;
  }
  ```

### 8. 테스트 이미지 관리 실수
- **절대 실수 금지**: testimg1.jpg, testimg2.jpg, testimg3.jpg 누락
- **파일 위치**: `/tests/` 디렉토리에 정확히 배치
- **이미지 요구사항**:
  - testimg1.jpg: **김치찌개** 또는 한식 찌개 (예상: 김치, 돼지고기, 두부)
  - testimg2.jpg: **파스타** 또는 서양식 면요리 (예상: 파스타면, 토마토소스, 마늘)
  - testimg3.jpg: **한정식** 또는 복잡한 상차림 (예상: 밥, 국, 여러 반찬)
- **체크 명령**: `ls -la tests/*.jpg` (3개 파일 있어야 함)

### 9. Playwright MCP 테스트 무시 (치명적!)
- **흔한 실수**: Flutter 단위 테스트만 실행하고 브라우저 테스트 생략
- **절대 필수**: 
  1. `flutter build web` 
  2. Chrome에서 실행 
  3. Playwright MCP로 음식 사진 분석 자동화 테스트
- **실행 순서**:
  ```bash
  # 1. 웹 빌드
  flutter build web --web-renderer html
  
  # 2. 로컬 서버 실행
  cd build/web && python -m http.server 8080 &
  
  # 3. MCP 도구에서 테스트 실행
  await mcp_Playwright_browser_install({ random_string: "setup" });
  // 브라우저가 자동으로 http://localhost:8080으로 이동
  await mcp_Playwright_browser_evaluate({ function: playwrightTestScript });
  ```

## 🔧 기술적 실수 및 해결책

### 10. Hive 로컬 저장소 실수
- **흔한 실수**: Recipe 객체를 그대로 저장 시도
- **원인**: Hive TypeAdapter 등록 누락
- **해결**:
  ```dart
  // main.dart에서 반드시 등록
  void main() async {
    await Hive.initFlutter();
    
    // TypeAdapter 등록 필수 (자주 까먹음!)
    Hive.registerAdapter(RecipeAdapter());
    Hive.registerAdapter(IngredientAdapter());
    Hive.registerAdapter(MoodAdapter());
    
    runApp(MyApp());
  }
  ```

### 11. Provider 상태 관리 실수
- **흔한 실수**: notifyListeners() 과도한 호출
- **성능 문제**: 레시피 리스트 변경할 때마다 전체 화면 리빌드
- **해결**: Selector 사용으로 부분 업데이트
  ```dart
  // ❌ 성능 문제 발생
  Consumer<RecipeProvider>(
    builder: (context, provider, child) => 
      ListView.builder(...) // 전체 리빌드
  )
  
  // ✅ 최적화된 방법
  Selector<RecipeProvider, List<Recipe>>(
    selector: (context, provider) => provider.recipes,
    builder: (context, recipes, child) => 
      ListView.builder(...) // 레시피 리스트만 리빌드
  )
  ```

### 12. OpenAI API 에러 처리 미흡
- **흔한 실수**: 네트워크 에러만 처리하고 API 특화 에러 무시
- **처리해야 할 에러들**:
  - API 키 잘못됨 (401)
  - 요청 한도 초과 (429)  
  - 이미지 형식 오류 (400)
  - 서버 에러 (5xx)
- **올바른 에러 처리**:
  ```dart
  try {
    final result = await _openAIService.analyzeImage(imageData);
    return result;
  } on OpenAIException catch (e) {
    if (e.code == 'invalid_api_key') {
      throw ApiKeyException('OpenAI API 키가 올바르지 않습니다');
    } else if (e.code == 'rate_limit_exceeded') {
      throw RateLimitException('API 사용 한도를 초과했습니다');
    }
    rethrow;
  } on NetworkException catch (e) {
    throw NetworkException('네트워크 연결을 확인해주세요');
  } catch (e) {
    throw UnknownException('알 수 없는 오류가 발생했습니다: $e');
  }
  ```

## 🎨 UI/UX 특화 실수

### 13. 빈티지 아이보리 테마 일관성 실수
- **흔한 실수**: 일부 위젯에서 기본 Material 색상 사용
- **필수 색상 코드**:
  ```dart
  // 반드시 사용해야 할 색상들
  const backgroundColor = Color(0xFFFAF8F3);     // 아이보리 백그라운드
  const primaryColor = Color(0xFF8B9A6B);        // 연한 올리브 그린
  const textPrimary = Color(0xFF2E3D1F);         // 다크 올리브 텍스트
  const fabColor = Color(0xFFD2A45B);            // FAB 빈티지 오렌지
  ```
- **체크 방법**: 모든 위젯에서 `Theme.of(context).primaryColor` 사용

### 14. 감정 메모 UI 강조 실수
- **흔한 실수**: 감정 메모를 일반 텍스트와 동일하게 표시
- **올바른 방법**: 이탤릭 폰트로 감정적 특성 강조
  ```dart
  // ❌ 틀린 표시
  Text(recipe.emotionalStory)
  
  // ✅ 올바른 표시
  Text(
    recipe.emotionalStory,
    style: TextStyle(
      fontStyle: FontStyle.italic, // 이탤릭으로 감정 강조
      fontSize: 16,
      color: Theme.of(context).textTheme.bodyLarge?.color,
    ),
  )
  ```

### 15. "과거 오늘" 기능 날짜 계산 실수 (기술 참조용)
- **흔한 실수**: DateTime 비교에서 년도까지 같이 비교
- **올바른 로직**: 월과 일만 비교해서 다른 년도 레시피 찾기
- **현재 상태**: 비즈니스 로직만 구현됨, UI 연동 미완성
  ```dart
  // ❌ 틀린 비교 (년도까지 비교)
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  
  // ✅ 올바른 "과거 오늘" 비교 (년도 제외, 기술 참조용)
  bool isPastToday(DateTime recipeDate, DateTime today) {
    return recipeDate.month == today.month && 
           recipeDate.day == today.day &&
           recipeDate.year != today.year; // 다른 년도여야 함
  }
  ```

## 🧪 테스트 관련 실수

### 16. MockOpenAIService 설정 실수
- **흔한 실수**: Mock 응답을 TESTDATA.md와 다르게 설정
- **올바른 방법**: TESTDATA.md의 정확한 응답 구조 사용
  ```dart
  // ✅ TESTDATA.md와 일치하는 Mock 설정
  when(mockOpenAI.analyzeImage(any))
    .thenAnswer((_) async => RecipeAnalysis(
      dishName: '김치찌개',
      ingredients: ['김치', '돼지고기', '두부', '양파', '대파'],
      instructions: ['김치를 기름에 볶는다', '돼지고기를 넣고 함께 볶는다'],
      difficulty: '쉬움',
      servings: '2-3인분'
    ));
  ```

### 17. 테스트 격리 실패
- **흔한 실수**: 이전 테스트의 Hive 데이터가 다음 테스트에 영향
- **해결**: setUp/tearDown에서 완전한 정리
  ```dart
  group('Recipe Tests', () {
    late Box<Recipe> recipeBox;
    
    setUp(() async {
      await Hive.initFlutter();
      recipeBox = await Hive.openBox<Recipe>('test_recipes');
    });
    
    tearDown(() async {
      await recipeBox.clear(); // 반드시 정리
      await recipeBox.close();
      await Hive.deleteFromDisk(); // 완전 삭제
    });
  });
  ```

## 🚀 성능 최적화 실수

### 18. 이미지 메모리 관리 실수  
- **흔한 실수**: 고해상도 이미지를 그대로 메모리에 로드
- **해결**: 이미지 리사이징 및 압축
  ```dart
  // ✅ 이미지 최적화
  Future<Uint8List> optimizeImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    
    // 최대 크기 제한
    final resized = img.copyResize(image, width: 800);
    
    // JPEG 압축
    return img.encodeJpg(resized, quality: 85);
  }
  ```

### 19. API 호출 과다 실수
- **흔한 실수**: 같은 이미지를 여러 번 분석 API 호출
- **해결**: 로컬 캐싱 구현
  ```dart
  class OpenAIService {
    final Map<String, RecipeAnalysis> _cache = {};
    
    Future<RecipeAnalysis> analyzeImage(String imageHash) async {
      // 캐시 확인 먼저
      if (_cache.containsKey(imageHash)) {
        return _cache[imageHash]!;
      }
      
      // API 호출 및 캐싱
      final result = await _callAPI(imageHash);
      _cache[imageHash] = result;
      return result;
    }
  }
  ```

## 📱 플랫폼별 주의사항

### 20. iOS 권한 설정 누락
- **필수 권한**: Info.plist에 카메라, 사진 라이브러리 접근
  ```xml
  <key>NSCameraUsageDescription</key>
  <string>음식 사진을 촬영하여 레시피를 기록하기 위해 카메라 접근이 필요합니다</string>
  
  <key>NSPhotoLibraryUsageDescription</key>
  <string>음식 사진을 선택하여 레시피를 기록하기 위해 사진 라이브러리 접근이 필요합니다</string>
  ```

### 21. Android 네트워크 보안 설정
- **문제**: HTTP 요청 차단 (Android 9+)
- **해결**: network_security_config.xml 설정
  ```xml
  <!-- android/app/src/main/res/xml/network_security_config.xml -->
  <network-security-config>
    <domain-config cleartextTrafficPermitted="true">
      <domain includeSubdomains="true">api.openai.com</domain>
    </domain-config>
  </network-security-config>
  ```

## 🔍 디버깅 팁

### 22. OpenAI API 응답 디버깅
- **로깅 추가**: API 요청/응답 상세 로그
  ```dart
  if (kDebugMode) {
    print('📤 OpenAI Request: $requestData');
    print('📥 OpenAI Response: $responseData');
  }
  ```

### 23. Hive 데이터 검사
- **디버깅 명령**: Box 내용 확인
  ```dart
  void debugHiveData() async {
    final box = await Hive.openBox<Recipe>('recipes');
    print('💾 Total recipes: ${box.length}');
    for (var recipe in box.values) {
      print('📝 Recipe: ${recipe.title} - ${recipe.emotionalStory}');
    }
  }
  ```

## ✅ 커밋 전 체크리스트

### 필수 확인 항목
- [ ] OpenAI API 키 하드코딩 체크: `grep -r "sk-proj" . --exclude-dir=.git`
- [ ] 테스트 이미지 존재 확인: `ls -la tests/*.jpg`
- [ ] TDD 원칙 준수: 모든 새 기능에 테스트 코드 존재
- [ ] Flutter Web 빌드 성공: `flutter build web`
- [ ] Playwright MCP 테스트 실행: Chrome에서 직접 확인
- [ ] 빈티지 테마 일관성: 모든 화면에서 아이보리 색상 사용
- [ ] 감정 메모 이탤릭 처리: 모든 emotionalStory 표시
- [ ] Hive TypeAdapter 등록: 모든 커스텀 모델 등록됨

## 🆘 비상시 해결책

### OpenAI API 장애시
1. Mock 응답으로 임시 대체
2. "네트워크 연결 확인" 사용자 안내
3. 로컬 캐시 데이터 우선 표시

### Hive 데이터 손상시
1. 백업 Box에서 복구 시도
2. 신규 Box 생성 후 재시작
3. 사용자에게 데이터 손실 안내 및 재입력 요청

### 테스트 실패시
1. TESTPLAN.md 체크리스트 재확인
2. testimg1.jpg, testimg2.jpg, testimg3.jpg 다시 준비
3. API 키 유효성 재확인

---

## 📋 문서 버전 히스토리

### v2025.09.18 - 최신 백업 동기화 완료
**문서 동기화 작업:**
- **MD 문서 일관성 확보**: 구버전 파일 내용 정리 및 최신 백업 버전으로 동기화
- **NOTE.md 동기화**: 모든 개발 주의사항 및 실수 방지 가이드 최신화
- **번호 체계 정리**: 모든 섹션 번호 재정렬로 가독성 향상
- **버전 히스토리**: 날짜별 변경사항 추적 체계 구축

### v2025.09.17 - 테스트 구조 재설정 주의사항 추가
**새로 추가된 주의사항:**
- **테스트 디렉터리 정리 완료**: 기존 작동하지 않던 테스트 파일들 완전 제거
- **형상 관리 Best Practice**: 버전 히스토리 시스템 도입 및 문서 추적 체계
- **백업 정책**: 주요 변경 전 반드시 전체 백업 생성 (Recipesoup_backup_YYYYMMDD_HHMMSS)
- **Side Effect 방지**: 모든 문서 업데이트는 Ultra Think 방식으로 영향도 분석 후 진행

### v2025.09.22 - 프로젝트 완료 및 배포 준비 주의사항 🚀
**완료된 프로젝트 운영 주의사항:**
- **✅ 프로덕션 검증 완료**: iPhone 7 (94.3s) + iPhone 12 mini (60.5s) 빌드 성공
- **🔒 보안 체크리스트 필수**:
  - Vercel 프록시 아키텍처로 OpenAI API 키 서버리스 관리 (클라이언트 노출 방지)
  - Unicode Sanitizer 모든 API 호출에 적용
  - Base64 이미지 검증 및 크기 제한
- **🎯 핵심 기능 안정성 보장**:
  - 토끼굴 마일스톤 시스템 (32+16) 완전 검증
  - 챌린지 시스템 (51개) 진행률 추적 정상
  - 감정 기반 레시피 아카이빙 완전 동작
  - "과거 오늘" 기능 비즈니스 로직만 구현 (UI 연동 미완성)
- **📱 디바이스 호환성 검증**:
  - UI 렌더링 오류 해결 (15px 오버플로우 → 23px 여유)
  - 메모리 사용량 정상 범위 유지
  - 핫 리로드 < 1s 성능 확보

**운영 및 유지보수 가이드:**
- **의존성 관리**: pubspec.yaml 50+ 패키지 정기 업데이트
- **API 모니터링**: OpenAI GPT-4o-mini 응답 시간 < 10초 유지
- **데이터 무결성**: Hive JSON 직렬화 안전성 지속 확인
- **사용자 경험**: 빈티지 아이보리 테마 일관성 유지

**배포 후 점검 사항:**
- **크래시 모니터링**: 초기화 실패, Provider 에러, API 호출 실패
- **성능 지표**: 앱 시작 시간, 이미지 로딩 속도, 검색 응답성
- **사용자 패턴**: 토끼굴 참여율, 챌린지 완료율, 레시피 작성 빈도

**프로젝트 상태 최종 업데이트:**
- ✅ **Phase 0-6 모든 단계 완료**: 테스트 문서화 → 배포 준비 완료
- ✅ **22개 화면 + 11개 서비스 + 5개 Provider**: 완전한 기능 생태계 구축
- ✅ **iPhone 실기 테스트**: 모든 핵심 시나리오 검증 완료
- 🚀 **배포 준비 완료**: 프로덕션 레벨 안정성 확보

---
*이 문서는 실제 개발 과정에서 발생한 실수들을 바탕으로 지속적으로 업데이트됩니다.*
*Recipesoup의 감정 기반 레시피 아카이빙 특성에 맞춘 특화된 주의사항들입니다.*

**💡 핵심 기억사항: 완료된 프로젝트 → 안정성 유지, 보안 철저, 사용자 경험 최우선!**
**🔄 최종 업데이트: v2025.09.25 - 문서 구조 통합 및 현행화 완료**