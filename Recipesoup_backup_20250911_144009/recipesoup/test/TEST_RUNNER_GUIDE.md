# Recipesoup URL Recipe Import Tests - 실행 가이드

## 개요
URL 레시피 추출 기능에 대한 포괄적인 테스트 세트가 작성되었습니다. 이 가이드는 테스트를 실행하고 결과를 확인하는 방법을 설명합니다.

## 작성된 테스트 파일들

### 1. 단위 테스트 (Unit Tests)
```
test/unit/services/
├── url_scraper_service_test.dart      # URL 스크래핑 서비스 테스트
└── openai_service_test.dart           # OpenAI 텍스트 분석 기능 테스트 (기존에 추가)
```

### 2. 위젯 테스트 (Widget Tests)
```
test/widget/screens/
└── url_import_screen_test.dart        # UrlImportScreen 위젯 테스트
```

### 3. 통합 테스트 (Integration Tests)
```
test/integration/
└── url_import_integration_test.dart   # URL 가져오기 전체 플로우 테스트
```

## 테스트 실행 방법

### 전체 테스트 실행
```bash
# 프로젝트 루트에서 실행
cd /Users/hanabi/Downloads/practice/Recipesoup/recipesoup

# 모든 테스트 실행
flutter test
```

### 카테고리별 테스트 실행

#### 1. 단위 테스트만 실행
```bash
# URL 스크래핑 서비스 테스트
flutter test test/unit/services/url_scraper_service_test.dart

# OpenAI 서비스 텍스트 분석 테스트
flutter test test/unit/services/openai_service_test.dart

# 모든 단위 테스트
flutter test test/unit/
```

#### 2. 위젯 테스트만 실행
```bash
# UrlImportScreen 위젯 테스트
flutter test test/widget/screens/url_import_screen_test.dart

# 모든 위젯 테스트
flutter test test/widget/
```

#### 3. 통합 테스트만 실행
```bash
# URL 가져오기 통합 테스트
flutter test test/integration/url_import_integration_test.dart

# 모든 통합 테스트
flutter test test/integration/
```

### 테스트 실행 옵션

#### 상세한 출력으로 실행
```bash
flutter test --verbose
```

#### 특정 테스트만 실행
```bash
# 테스트 이름으로 필터링
flutter test --name "should scrape recipe content from blog URL successfully"

# 그룹으로 필터링  
flutter test --name "웹페이지 스크래핑 테스트"
```

#### 코드 커버리지 포함
```bash
flutter test --coverage
genhtml -o coverage_report coverage/lcov.info
open coverage_report/index.html
```

## 테스트 시나리오 요약

### 1. UrlScraperService 테스트
- ✅ 웹페이지 스크래핑 기본 기능
- ✅ 네이버 블로그, 티스토리, 일반 사이트 파싱
- ✅ 레시피 키워드 감지
- ✅ HTML 정리 및 텍스트 추출
- ✅ 에러 처리 (네트워크, HTTP 4xx/5xx)
- ✅ URL 유효성 검증
- ✅ 문자 인코딩 처리

### 2. OpenAI Service 텍스트 분석 테스트
- ✅ 블로그 텍스트에서 레시피 추출
- ✅ 네이버/티스토리 텍스트 패턴 처리
- ✅ 복잡한 구조의 레시피 분석
- ✅ 에러 처리 (API 키, Rate Limit, 타임아웃)
- ✅ 텍스트 전처리 및 정규화

### 3. UrlImportScreen 위젯 테스트
- ✅ 초기 화면 렌더링
- ✅ URL 입력 및 유효성 검증
- ✅ 로딩 상태 표시
- ✅ 스크래핑 결과 미리보기
- ✅ AI 분석 결과 표시
- ✅ 에러 상태 처리
- ✅ 네비게이션 테스트
- ✅ 접근성 및 테마 적용

### 4. 통합 테스트
- ✅ FAB → URL Import → Recipe Create 전체 플로우
- ✅ 다양한 블로그 플랫폼 처리
- ✅ 에러 시나리오 종합 처리
- ✅ 사용자 경험 테스트
- ✅ 데이터 무결성 보장

## 테스트 의존성 설정

### Mock 생성
테스트 실행 전 Mock 클래스를 생성해야 합니다:

```bash
# Mock 클래스 생성
flutter packages pub run build_runner build

# 변경사항이 있을 때마다 재생성
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### 필요한 패키지
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4
  build_runner: ^2.4.7
  integration_test:
    sdk: flutter
```

## 테스트 데이터 요구사항

### 환경 변수 설정
```bash
# .env 파일 생성 (테스트용)
OPENAI_API_KEY=test-api-key-for-testing
API_MODEL=gpt-4o-mini
DEBUG_MODE=true
```

### 테스트 이미지 (추후 필요시)
```
test/assets/
├── testimg1.jpg  # 김치찌개 사진
├── testimg2.jpg  # 파스타 사진
└── testimg3.jpg  # 한정식 상차림 사진
```

## 예상 테스트 결과

### 성공적인 실행 예시
```
00:00 +0: loading test/unit/services/url_scraper_service_test.dart
00:01 +15: All tests passed!

00:00 +0: loading test/unit/services/openai_service_test.dart  
00:02 +28: All tests passed!

00:00 +0: loading test/widget/screens/url_import_screen_test.dart
00:03 +22: All tests passed!

00:00 +0: loading test/integration/url_import_integration_test.dart
00:05 +12: All tests passed!

총 77개 테스트 통과 ✅
```

### 실패 시 확인사항
1. **Mock 클래스 생성 확인**: `build_runner build` 실행
2. **의존성 설치**: `flutter pub get`
3. **환경변수 설정**: `.env` 파일 존재 여부
4. **네트워크 연결**: HTTP 요청 테스트 시

## 지속적인 테스트 실행 (CI/CD 준비)

### GitHub Actions용 워크플로우 예시
```yaml
name: Flutter Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: flutter pub get
      - run: flutter pub run build_runner build
      - run: flutter test
      - run: flutter test test/integration/
```

## 테스트 실행 체크리스트

- [ ] Flutter SDK 버전 확인 (3.16.0+)
- [ ] 프로젝트 의존성 설치: `flutter pub get`
- [ ] Mock 클래스 생성: `build_runner build`
- [ ] 단위 테스트 실행 및 통과 확인
- [ ] 위젯 테스트 실행 및 통과 확인
- [ ] 통합 테스트 실행 및 통과 확인
- [ ] 코드 커버리지 85% 이상 달성 확인
- [ ] 모든 에러 시나리오 처리 확인

## 문제 해결

### 자주 발생하는 문제들

1. **MockHttpClient 에러**
   ```bash
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

2. **플러터 버전 호환성**
   ```bash
   flutter upgrade
   flutter pub get
   ```

3. **네트워크 테스트 실패**
   - Mock 서비스 설정 확인
   - 타임아웃 설정 증가

4. **위젯 테스트 렌더링 에러**
   - MaterialApp wrapper 확인
   - Provider 설정 검증

---

**참고**: 이 테스트들은 URL 레시피 추출 기능의 안정성과 품질을 보장하기 위해 TDD 원칙에 따라 작성되었습니다. 모든 테스트가 통과해야 배포 가능한 상태입니다.