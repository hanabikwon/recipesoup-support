# TestFlight 빌드 가이드

## 🔐 보안 강화 완료

이제 Recipesoup 앱은 **하드코딩된 토큰 없이** 안전하게 TestFlight에 배포할 수 있습니다.

### 변경사항
- ✅ OpenAI API 키 완전 제거 (Vercel 프록시 사용)
- ✅ proxyToken을 환경변수로 전환
- ✅ 불필요한 보안 코드 정리

---

## 🚀 TestFlight 빌드 방법

### 방법 1: 빌드 스크립트 사용 (권장)

```bash
# 1. 환경변수 설정
export PROXY_APP_TOKEN=e4dbe63b81f2029720374d4b76144b6f17c566d19754793ce01b4f04951780ed

# 2. 빌드 스크립트 실행
./build-testflight.sh
```

### 방법 2: 직접 Flutter 명령어 사용

```bash
cd recipesoup

# iOS 빌드
flutter build ios \
    --dart-define=PROXY_APP_TOKEN=e4dbe63b81f2029720374d4b76144b6f17c566d19754793ce01b4f04951780ed \
    --release \
    --no-codesign
```

---

## 📱 Xcode Archive 및 업로드

1. **Xcode에서 프로젝트 열기**
   ```bash
   open recipesoup/ios/Runner.xcworkspace
   ```

2. **Archive 생성**
   - Product → Archive 선택
   - 빌드 완료까지 대기

3. **App Store Connect 업로드**
   - Distribute App 선택
   - App Store Connect 선택
   - Upload 실행

---

## 🧪 TestFlight 설정

1. **App Store Connect 접속**
   - https://appstoreconnect.apple.com

2. **TestFlight 탭 이동**
   - 업로드된 빌드 확인 (처리 시간: 10-30분)

3. **테스터 초대**
   - Internal Testing 또는 External Testing 선택
   - 이메일 주소로 테스터 초대
   - 테스터는 TestFlight 앱으로 다운로드 가능

---

## 🔍 개발 및 테스트

### 로컬 개발 실행
```bash
cd recipesoup

# 환경변수와 함께 실행
flutter run --dart-define=PROXY_APP_TOKEN=your_token_here
```

### 디버그 빌드
```bash
flutter build ios \
    --dart-define=PROXY_APP_TOKEN=your_token_here \
    --debug
```

---

## ⚠️ 주의사항

1. **토큰 보안**
   - `PROXY_APP_TOKEN`을 Git에 커밋하지 마세요
   - 환경변수나 빌드 시점에만 주입하세요

2. **빌드 실패 시**
   - `PROXY_APP_TOKEN` 환경변수가 설정되었는지 확인
   - 토큰 값이 정확한지 확인

3. **토큰 관리**
   - 정기적으로 토큰 교체 권장
   - Vercel 프록시 서버의 보안 설정 확인

---

## 🎯 완료된 보안 개선사항

### Before (보안 위험)
```dart
static String get proxyToken {
  return 'e4dbe63b81f2029720374d4b76144b6f17c566d19754793ce01b4f04951780ed';  // 하드코딩
}
```

### After (보안 강화)
```dart
static String get proxyToken {
  const token = String.fromEnvironment('PROXY_APP_TOKEN');  // 환경변수
  if (token.isEmpty) {
    throw ApiConfigException('PROXY_APP_TOKEN 환경변수가 필요합니다.');
  }
  return token;
}
```

이제 TestFlight 빌드 시 **토큰 노출 위험 없이** 안전하게 배포할 수 있습니다! 🎉