## 🚀 iOS 앱스토어 배포 필수 최소 조건 (간단 버전)

### 💳 필수 준비
- [ ] Apple Developer Program 가입 ($99/년)
- [ ] Xcode 설치 및 Certificate 생성

### 📱 앱 설정
- [ ] Bundle Identifier 설정
- [ ] 앱 아이콘 1024x1024 제작
- [ ] iOS 권한 설명 추가 (카메라, 사진)

### 🧪 테스트
- [ ] iOS 릴리즈 빌드 성공 (`flutter build ios --release`)
- [ ] 베타 테스터 최소 3명 모집 (본인+내부1명+외부1명)
- [ ] TestFlight 업로드 및 테스트

### 📋 App Store Connect
- [ ] 앱 등록 및 메타데이터 입력
- [ ] 스크린샷 촬영 및 업로드
- [ ] GitHub Pages로 개인정보처리방침 페이지 생성
- [ ] 개인정보처리방침 URL 앱에 연결 (WebView)
- [ ] 개인정보처리방침 웹사이트 테스트

### ✅ 제출
- [ ] App Review Guidelines 점검
- [ ] 최종 빌드 제출

---

# 📱 Recipesoup iOS 앱스토어 배포 완전 초보자 가이드

## 🎯 전체 개요
- **목표**: Recipesoup Flutter 앱을 iOS App Store에 배포
- **예상 기간**: 4-6주
- **예상 비용**: $99 (Apple Developer Program)
- **전제조건**: macOS 시스템, Xcode, 기존 Flutter 프로젝트 완료

---

## 📋 Phase 1: 사전 준비 (1주차)

### 1️⃣ Apple Developer 계정 및 환경 설정
- [x] Apple Developer Program 가입 ($99/년)
- [x] Xcode 최신 버전 설치 (App Store에서)
- [x] Apple ID로 Xcode에 로그인
- [x] iOS Development Certificate 생성
- [x] App Store Distribution Certificate 생성

### 2️⃣ 앱 기본 설정
- [x] Bundle Identifier 결정 (예: com.yourname.recipesoup)
- [x] 앱 이름 최종 확정
- [x] 버전 번호 1.0.0으로 설정
- [x] iOS 최소 지원 버전 결정 (iOS 12.0 권장)

### 3️⃣ 앱 아이콘 및 스플래시 준비
- [x] 1024x1024 앱 아이콘 제작
- [x] iOS 모든 크기 아이콘 생성 (flutter_launcher_icons 사용)
- [ ] 스플래시 스크린 iOS 최적화

---

## 📋 Phase 2: 코드 및 설정 최적화 (20250919)

### 4️⃣ iOS 특화 권한 설정
- [x] Info.plist에 카메라 권한 설명 추가
- [x] Info.plist에 사진 라이브러리 권한 설명 추가
- [x] OpenAI API 네트워크 권한 설정

### 5️⃣ 프로덕션 환경 분리
- [x] 프로덕션용 .env 파일 생성
- [x] OpenAI API 키 프로덕션 환경 분리
- [x] 디버그 코드 제거 및 로그 레벨 조정

### 6️⃣ iOS 빌드 테스트
- [x] `flutter build ios --release` 성공 확인
- [ ] iOS 시뮬레이터에서 릴리즈 빌드 테스트
- [ ] 실제 iOS 기기에서 테스트 (최소 2대)

---

## 📋 Phase 3: App Store Connect 준비 (3주차)

### 7️⃣ App Store Connect 앱 등록
- [ ] App Store Connect에 앱 등록
- [ ] 카테고리 선택: Food & Drink
- [ ] 앱 설명 작성 (한국어)
- [ ] 키워드 최적화 (레시피, 감정, 요리, 아카이빙 등)

### 8️⃣ 개인정보 및 법적 준비
- [ ] 개인정보 처리방침 작성 및 웹사이트 업로드
- [ ] 데이터 사용 현황 신고서 작성
- [ ] OpenAI API 사용 관련 명시
- [ ] 연령 등급 설정 (4+ 권장)

### 9️⃣ 스크린샷 및 미디어 준비
- [ ] iPhone 스크린샷 촬영 (6.7", 6.5", 5.5")
- [ ] iPad 스크린샷 촬영 (12.9")
- [ ] 앱 미리보기 동영상 제작 (선택사항)
- [ ] 앱 아이콘 최종 검토

---

## 📋 Phase 4: 베타 테스트 (4주차)

### 🔟 TestFlight 내부 테스트
- [ ] Xcode Archive 및 TestFlight 업로드
- [ ] 내부 테스터 추가 (본인 + 1-2명)
- [ ] 기본 기능 테스트 완료
- [ ] 크리티컬 버그 수정

### 1️⃣1️⃣ TestFlight 외부 베타 테스트
- [ ] 외부 베타 테스터 5-10명 모집
- [ ] 베타 테스트 가이드 문서 작성
- [ ] 2주간 베타 테스트 진행
- [ ] 피드백 수집 및 버그 수정
- [ ] 최종 빌드 TestFlight 배포

---

## 📋 Phase 5: 최종 제출 및 배포 (5-6주차)

### 1️⃣2️⃣ App Store 제출 준비
- [ ] App Review Guidelines 최종 점검
- [ ] 메타데이터 최종 검토
- [ ] 스크린샷 품질 확인
- [ ] 개인정보 보호 설정 완료

### 1️⃣3️⃣ App Store 제출
- [ ] App Store Connect에서 최종 빌드 선택
- [ ] 모든 메타데이터 입력 완료
- [ ] 심사를 위해 제출
- [ ] Apple 리뷰 대기 (1-7일)

### 1️⃣4️⃣ 출시 후 관리
- [ ] 앱 승인 확인
- [ ] App Store 출시
- [ ] 초기 사용자 피드백 모니터링
- [ ] 필요시 핫픽스 준비

---

## 🚨 중요 체크포인트

### 거부 위험 요소 사전 점검
- [ ] UI가 iOS Human Interface Guidelines 준수
- [ ] 크래시 없음 보장
- [ ] OpenAI API 사용 사실 명시
- [ ] 사용자 생성 콘텐츠 관리 정책
- [ ] 외부 링크 최소화

### 성능 최적화 체크리스트
- [ ] 앱 크기 150MB 이하
- [ ] 시작 시간 3초 이하
- [ ] 메모리 사용량 최적화
- [ ] 배터리 소모 최적화

---

## 🛠️ 구체적인 실행 가이드

### Phase 1 상세 실행 단계

**1️⃣ Apple Developer 계정 설정 (첫 번째 할 일)**
```
1. developer.apple.com 접속
2. "Account" 클릭
3. Apple ID로 로그인
4. "Join the Apple Developer Program" 선택
5. Individual 선택 (개인 개발자)
6. $99 결제 후 승인 대기 (24-48시간)
```

**2️⃣ Xcode 설치 및 설정**
```
1. Mac App Store에서 Xcode 검색
2. "받기" 클릭 (약 10GB, 시간 소요)
3. 설치 완료 후 Xcode 실행
4. "Agree" 라이센스 동의
5. Additional components 설치 완료 대기
```

**3️⃣ Certificate 생성 (Xcode에서)**
```
1. Xcode > Preferences > Accounts
2. "+" 클릭 > Apple ID 추가
3. Apple Developer 계정으로 로그인
4. Team 선택
5. "Manage Certificates" 클릭
6. "+" > iOS Development, iOS Distribution 생성
```

### Phase 2 코드 설정 상세

**4️⃣ Bundle Identifier 설정**
```yaml
# ios/Runner/Info.plist에서
<key>CFBundleIdentifier</key>
<string>com.yourname.recipesoup</string>
```

**5️⃣ 권한 설정 추가**
```xml
<!-- ios/Runner/Info.plist에 추가 -->
<key>NSCameraUsageDescription</key>
<string>음식 사진을 촬영하여 레시피에 추가합니다</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>사진 라이브러리에서 음식 사진을 선택합니다</string>
```

**6️⃣ 앱 아이콘 설정**
```yaml
# pubspec.yaml에 추가
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_icons:
  android: false
  ios: true
  image_path: "assets/app_icon.png"  # 1024x1024 이미지
```

### 빌드 및 테스트 명령어
```bash
# iOS 릴리즈 빌드
flutter build ios --release

# TestFlight용 빌드 (Xcode에서)
1. Xcode에서 ios/Runner.xcworkspace 열기
2. Product > Archive
3. Distribute App > App Store Connect
4. Upload 완료 대기
```

### 개인정보처리방침 웹사이트 구축
**1️⃣ GitHub Pages 설정**
```
1. GitHub에서 새 리포지토리 생성: recipesoup-privacy
2. Settings > Pages > Source: Deploy from a branch
3. Branch: main 선택
4. URL 확인: https://[username].github.io/recipesoup-privacy
```

**2️⃣ 개인정보처리방침 작성 (privacy-policy.md)**
```markdown
# Recipesoup 개인정보 처리방침

## 1. 개인정보 수집 현황
- 수집하는 개인정보: 없음
- 모든 데이터는 사용자 기기에만 저장 (Hive 로컬 DB)

## 2. OpenAI API 사용 (선택사항)
- 음식 사진 분석 시에만 사용
- 이미지는 분석 후 즉시 삭제
- OpenAI에서 사용자 데이터 저장하지 않음

## 3. 데이터 보관 및 관리
- 모든 레시피 데이터는 사용자 기기 내부에만 저장
- 서버나 클라우드에 데이터 전송하지 않음
- 사용자가 직접 백업/복원 기능으로 데이터 관리

## 4. 연락처
- 이메일: flow.planet.io@gmail.com
- 앱 관련 문의나 개인정보 처리 관련 질문 연락 가능

효력 발생일: 2025년 [배포월]
```

**3️⃣ 앱에 WebView 연결**
```dart
// settings_screen.dart에서 수정
_buildSettingsTile(
  icon: Icons.privacy_tip,
  title: '개인정보처리방침',
  subtitle: '개인정보 보호 정책',
  onTap: () => _showPrivacyPolicy(),
),

void _showPrivacyPolicy() {
  // WebView로 GitHub Pages URL 연결
  launchUrl(Uri.parse('https://[username].github.io/recipesoup-privacy'));
}
```


---

백업(삭제 금지)

📱 Recipesoup iOS 앱스토어 배포 전용 계획

  🎯 배포 목표

  플랫폼: iOS 전용 (iPhone/iPad)
  배포처: Apple App Store만
  제외: Android, Web, 서버 배포 없음

  ---
  🔍 현재 상태 분석

  프로젝트: Flutter iOS 앱 (감정 기반 레시피 아카이빙)
  특징: 완전 오프라인, 로컬 Hive DB, OpenAI API 연동
  준비도: 코드 완성, Phase 4 품질 개선 완료

  ---
  📋 iOS 앱스토어 배포 전 필수 작업

  1️⃣ Apple Developer 환경 준비

  - Apple Developer Account 가입 ($99/년)
  - Xcode 최신 버전 설치 (macOS 필수)
  - iOS Development Certificate 생성
  - App Store Distribution Certificate 생성
  - Provisioning Profile 설정

  2️⃣ 앱 설정 및 메타데이터

  - Bundle Identifier 설정 (com.yourname.recipesoup)
  - 앱 아이콘 최적화 (1024x1024 포함 모든 iOS 크기)
  - 스플래시 스크린 iOS 가이드라인 준수
  - 앱 이름 최종 확정 (App Store에서 사용할 이름)
  - 버전 정보 1.0.0으로 설정

  3️⃣ iOS 특화 테스트 및 QA

  - iOS 시뮬레이터 테스트 (iPhone 14, iPhone 15 등)
  - 실제 iOS 기기 테스트 (최소 2-3대)
  - 다양한 iOS 버전 호환성 테스트
  - iPad 호환성 확인 (iPhone 앱이지만 iPad에서도 실행)
  - iOS 접근성 기능 테스트 (VoiceOver 등)

  4️⃣ 베타 테스트 (TestFlight)

  - Internal Testing 설정 (개발팀용)
  - External Testing 그룹 생성
  - 베타 테스터 5-10명 모집
  - 테스트 가이드 문서 작성
  - 피드백 수집 시스템 구축

  5️⃣ App Store Connect 준비

  - 앱 등록 (App Store Connect)
  - 앱 설명 작성 (한국어)
  - 키워드 최적화
  - 카테고리 선택 (Food & Drink)
  - 연령 등급 설정
  - 개인정보 처리방침 URL 등록

  6️⃣ 스크린샷 및 미디어

  - iPhone 스크린샷 (6.7인치, 6.5인치, 5.5인치)
  - iPad 스크린샷 (12.9인치, 6세대)
  - 앱 미리보기 동영상 (선택사항, 권장)
  - 앱 아이콘 최종 검수

  7️⃣ 보안 및 개인정보

  - OpenAI API 키 보안 점검
  - 로컬 데이터 암호화 확인
  - 개인정보 처리방침 작성
  - 데이터 사용 현황 신고서 작성
  - App Tracking Transparency 설정 (iOS 14.5+)

  8️⃣ 성능 최적화 (iOS 특화)

  - 앱 크기 최적화 (<150MB 권장)
  - 시작 시간 최적화 (<3초)
  - 메모리 사용량 점검 (iOS 메모리 제한)
  - 배터리 소모 최적화
  - 네트워크 사용 최적화 (OpenAI API 호출)

  ---
  🧪 iOS 베타 테스트 단계별 계획

  Phase 1: Internal Testing (1주)

  대상: 개발자 + 내부 1-2명
  목표: 기본 기능 동작 확인
  체크포인트:
  - 앱 설치/실행 정상 여부
  - 크리티컬 크래시 없음
  - 기본 레시피 작성/저장 기능

  Phase 2: External Beta Testing (2-3주)

  대상: 외부 베타 테스터 5-10명
  도구: TestFlight
  목표: 실사용자 피드백 수집
  체크포인트:
  - 사용성 테스트
  - 다양한 기기에서 호환성
  - OpenAI API 연동 안정성
  - 버그 수집 및 수정

  Phase 3: Pre-Submission (1주)

  대상: 최종 점검팀
  목표: 앱스토어 제출 준비
  체크포인트:
  - App Review Guidelines 준수 확인
  - 메타데이터 최종 검토
  - 스크린샷 품질 확인
  - 법적 요구사항 충족

  ---
  📱 iOS 빌드 및 제출 프로세스

  1단계: 프로덕션 빌드

  # iOS 프로덕션 빌드
  flutter build ios --release

  # 또는 Xcode Archive 사용
  flutter build ios --release --no-codesign
  # 이후 Xcode에서 Archive & Upload

  2단계: TestFlight 업로드

  # Xcode를 통한 업로드
  # Product > Archive > Distribute App > App Store Connect

  3단계: App Store 제출

  App Store Connect에서:
  1. 빌드 선택
  2. 메타데이터 입력
  3. 스크린샷 업로드
  4. 검토 제출

  ---
  📋 iOS 앱스토어 리뷰 가이드라인 체크리스트

  필수 준수 사항

  - UI/UX iOS Human Interface Guidelines 준수
  - 개인정보 수집/사용 명시
  - 외부 링크 최소화
  - 광고/프로모션 없음 (개인 앱인 경우)
  - 결제 시스템 없음 (무료 앱)
  - 콘텐츠 가이드라인 준수 (음식 관련 앱이므로 안전)

  거부 위험 요소 점검

  - API 사용 명시 (OpenAI 사용 사실)
  - 오프라인 기능 강조 (네트워크 의존성 최소화)
  - 사용자 생성 콘텐츠 관리 정책
  - 크래시 없음 보장

  ---
  🚀 배포 일정 계획 (4-6주)

  Week 1-2: 개발 환경 및 앱 준비

  - Apple Developer 계정 설정
  - 앱 메타데이터 완성
  - iOS 특화 테스트

  Week 3-4: 베타 테스트

  - TestFlight 베타 배포
  - 피드백 수집 및 버그 수정
  - 성능 최적화

  Week 5: 최종 준비

  - App Store Connect 설정 완료
  - 스크린샷/미디어 최종 업로드
  - 개인정보 처리방침 등록

  Week 6: 제출 및 리뷰

  - 앱스토어 제출
  - Apple 리뷰 대기 (보통 1-7일)
  - 승인 후 출시

  ---
  💰 예상 비용 및 필요 자원

  비용

  - Apple Developer Program: $99/년
  - macOS/Xcode: 기존 맥 사용 또는 구매 필요
  - iOS 테스트 기기: 최소 iPhone 1-2대

  인력

  - 개발자: iOS 빌드 및 제출 담당
  - 베타 테스터: 5-10명 (지인 또는 온라인 모집)
  - 디자이너: 앱 아이콘, 스크린샷 제작 (선택사항)

  ---
  ⚡ 즉시 시작할 우선순위 작업:
  1. Apple Developer 계정 생성
  2. macOS/Xcode 환경 준비
  3. 앱 아이콘 1024x1024 제작
  4. 베타 테스터 모집 시작
  5. 개인정보 처리방침 초안 작성



---

⏺ 아니요, 사이드 이펙트 전혀 없습니다!

  이 작업들은 모두 설정 파일 수정과 메타데이터 추가만 하는 것으로, 앱의 UI나 
  기능에는 전혀 영향을 주지 않습니다.

  🔍 각 작업별 영향도 분석

  1️⃣ iOS Info.plist 권한 설정 추가

  - 변경 내용: 권한 설명 텍스트만 추가
  - UI 영향: ❌ 없음
  - 기능 영향: ❌ 없음 (오히려 카메라/사진 접근이 더 안정적으로 작동)

  2️⃣ Bundle Identifier 설정

  - 변경 내용: 앱 고유 ID만 설정
  - UI 영향: ❌ 없음
  - 기능 영향: ❌ 없음 (앱 내부 동작은 동일)

  3️⃣ 앱 아이콘 파일 생성

  - 변경 내용: 이미지 파일만 추가
  - UI 영향: ✅ 있음 (홈 화면 아이콘만 변경, 앱 내부 UI는 동일)
  - 기능 영향: ❌ 없음

  4️⃣ 프로덕션 환경변수 분리

  - 변경 내용: .env 파일만 분리
  - UI 영향: ❌ 없음
  - 기능 영향: ❌ 없음 (같은 API 키 사용시)

  5️⃣-7️⃣ Xcode/App Store 설정들

  - 변경 내용: 배포 관련 설정만
  - UI 영향: ❌ 없음
  - 기능 영향: ❌ 없음

  ✅ 안전성 보장

  이 모든 작업들은:
  - 앱 소스코드 변경 없음
  - Flutter 위젯 변경 없음
  - 비즈니스 로직 변경 없음
  - 사용자 경험 변경 없음

  오직 앱 패키징과 배포를 위한 설정만 추가하는 것입니다.


  ---

  ⏺ Firebase Crashlytics는 iOS 앱 배포에 필수가 아닙니다.

  Firebase Crashlytics는 선택사항인 모니터링 도구입니다:

  Crashlytics가 하는 일

  - 앱 크래시 자동 보고 및 분석
  - 실시간 충돌 모니터링
  - 사용자 영향도 분석
  - 디버깅을 위한 상세한 스택 트레이스

  iOS 앱스토어 배포와의 관계

  - 앱스토어 심사: Crashlytics 없이도 통과 가능
  - 앱 작동: 핵심 기능에 전혀 영향 없음
  - 배포 과정: 추가 설정 불필요

  Recipesoup에 대한 권장사항

  Phase 1 배포: Crashlytics 없이 시작
  - 앱의 핵심 기능(감정 기반 레시피 아카이빙)에 집중
  - 배포 과정 단순화
  - 초기 사용자 피드백 우선 수집

  Phase 2 운영: 필요시 나중에 추가
  - 실제 사용자 증가 후 모니터링 필요성 판단
  - 크래시 리포트가 필요하다고 판단되면 그때 추가
  - 기존 앱 업데이트로 충분히 추가 가능

  결론: iOS 앱스토어 배포를 위해 구조적으로 바뀌어야 하는 부분은 거의 
  없으며, Firebase Crashlytics는 완전히 선택사항입니다.