# Recipesoup 개발 명령어

## 기본 Flutter 명령어

### 프로젝트 설정
```bash
# 의존성 설치
flutter pub get

# 프로젝트 실행 (개발 모드)
flutter run

# 핫 리로드: r
# 핫 리스타트: R
# 종료: q
```

### 빌드 명령어
```bash
# 웹 빌드
flutter build web

# Android APK 빌드
flutter build apk

# iOS 빌드 (macOS에서만)
flutter build ios

# macOS 앱 빌드
flutter build macos

# Windows 앱 빌드
flutter build windows
```

### 테스트 명령어
```bash
# 모든 테스트 실행
flutter test

# 단위 테스트만 실행
flutter test test/unit/

# 위젯 테스트만 실행
flutter test test/widget/

# 통합 테스트만 실행
flutter test test/integration/

# 상세한 출력으로 테스트
flutter test --verbose

# 코드 커버리지 포함
flutter test --coverage
```

### 코드 품질 명령어
```bash
# 정적 분석 실행
flutter analyze

# 포맷팅 확인
flutter format --dry-run .

# 포맷팅 적용
flutter format .
```

### Mock 생성 명령어
```bash
# Mock 클래스 생성
flutter packages pub run build_runner build

# 변경사항 있을 때 재생성
flutter packages pub run build_runner build --delete-conflicting-outputs

# Watch 모드로 자동 생성
flutter packages pub run build_runner watch
```

### 환경 설정
```bash
# .env 파일 생성 필요
OPENAI_API_KEY=your_api_key_here
API_MODEL=gpt-4o-mini
```

### 디바이스 관리
```bash
# 연결된 디바이스 확인
flutter devices

# 에뮬레이터 실행
flutter emulators
flutter emulators --launch <emulator_id>
```

## 작업 완료 후 실행할 명령어
1. `flutter analyze` - 정적 분석
2. `flutter test` - 전체 테스트
3. `flutter format .` - 코드 포맷팅

## Darwin (macOS) 시스템 관련
- 시스템: Darwin 24.6.0
- iOS 시뮬레이터 사용 가능
- macOS 네이티브 빌드 지원