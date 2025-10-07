# iOS 실제 기기 테스트 실행 계획

## 📋 실행 단계:

### Phase 1: 사전 확인 (5분) ✅ 완료
- [x] Apple Developer 계정 및 Team ID 확인
- [x] 연결 가능한 iOS 기기 확인 (iPhone 7 & iPhone 12 mini)
- [x] Xcode 프로젝트 signing 설정 점검

### Phase 2: 기기 연결 및 빌드 (10분) ✅ 완료
- [x] iOS 기기들을 Mac에 연결
- [x] `flutter devices`로 인식 확인
- [x] 각 기기별로 `flutter run --release` 실행

### Phase 3: 핵심 기능 테스트 (15분) ✅ 완료
- [x] 앱 설치 및 실행 확인
- [x] 프로덕션 환경 Vercel 프록시 API 연동 테스트
- [x] 사진 업로드 → Vercel 프록시를 통한 OpenAI 분석 플로우 검증
- [x] 메모리/성능 기본 확인

### Phase 4: 결과 정리 (5분) ✅ 완료
- [x] 테스트 결과 정리
- [x] PROGRESS.md 업데이트 (2025-09-19 iPhone 디바이스 테스트 완료 기록)
- [x] 발견된 이슈 기록

**총 예상 시간: 35분** ✅ **완료**
**사용된 리소스: iPhone 7 & iPhone 12 mini, Apple Developer 계정 (Team ID: N3626WUCV2)**

## ✅ 테스트 완료 요약 (2025-09-19)
- **테스트 기기**: iPhone 7 (iOS 15.8.5) & iPhone 12 mini (iOS 18.6)
- **빌드 성능**: iPhone 7 (94.3s), iPhone 12 mini (60.5s)
- **핵심 기능**: 모든 Provider, 챌린지 시스템, 토끼굴 시스템, Vercel 프록시 API 연동 정상
- **성능 지표**: 메모리 사용량 정상, 앱 시작 시간 < 3초, API 응답 < 10초
- **결과**: 모든 필수 항목 통과, USB 케이블 없이 독립 실행 확인

---

# 🎯 Ultra Think: iOS 실제 기기 테스트 완전 가이드

## 📋 Step 7 현황 분석

  현재 상태:

  - [x] iOS Release 빌드 완성 (248.9MB)
  - [x] 프로덕션 환경 설정 완료
  - [x] 시뮬레이터 테스트 완료 (iPhone 7 & iPhone 12 mini - 2025.09.19)
  - [x] 실제 기기 테스트 완료 ✅ (iPhone 7 & iPhone 12 mini - 2025.09.19)

  왜 실제 기기 테스트가 필요한가?

  1. Performance: 시뮬레이터 ≠ 실제 기기 성능
  2. Release Mode: 시뮬레이터에서 불가능
  3. API 연동: 실제 네트워크 환경 테스트
  4. 메모리/배터리: 하드웨어 제약 확인

  🔧 실제 기기 테스트 Ultra Think 계획

  Phase 1: 사전 준비 (Apple Developer 요구사항)

  1.1 Apple Developer 계정 확인

  # 현재 설정 확인
  flutter doctor -v
  xcodebuild -showBuildSettings -project
  ios/Runner.xcodeproj
  - [x] Apple Developer Program 가입 여부 확인
  - [x] Team ID 확인 (N3626WUCV2가 이미 설정됨)
  - [x] Automatic Signing 활성화 상태 점검

  1.2 iOS 기기 준비 (최소 2대)

  권장 기기 조합:
  - [x] iPhone (iPhone 7 & iPhone 12 mini): iOS 18.6 ✅
  - [ ] iPad (옵션): 다른 화면 크기 테스트
  - [x] 다른 iOS 버전: 호환성 확인 (두 기기 모두 테스트 완료)

  1.3 Xcode 설정 확인

  # Xcode 프로젝트 열기
  open ios/Runner.xcworkspace
  체크 항목:
  - [x] Bundle Identifier: com.recipesoup.app.recipesoup
  - [x] Team 설정: 자동 사이닝 활성화
  - [x] Deployment Target: iOS 12.0+

  Phase 2: 기기 연결 및 설정

  2.1 기기 연결 확인

  # 연결된 기기 확인
  flutter devices
  xcrun simctl list devices | grep "iPhone\|iPad"

  2.2 기기별 Provisioning Profile 생성

  # 각 기기별로 실행
  flutter run -d [DEVICE_ID] --release
  자동 처리 항목:
  - [x] Device Registration
  - [x] Provisioning Profile 자동 생성
  - [x] Code Signing Certificate

  Phase 3: 실제 기기 Release 빌드 테스트

  3.1 첫 번째 기기 테스트

  # iPhone 연결 후
  flutter run -d [iPhone_DEVICE_ID] --release
  검증 항목:
  - [x] 앱 설치 성공 여부
  - [x] 초기 실행 속도 (스플래시 → 홈)
  - [x] 프로덕션 환경 로드 확인

  3.2 두 번째 기기 테스트

  # iPad 또는 다른 iPhone 연결 후
  flutter run -d [SECOND_DEVICE_ID] --release
  추가 검증:
  - [x] 다른 기기에서 동일한 성능
  - [x] 화면 크기별 UI 적응성
  - [x] 기기별 특성 확인

  Phase 4: 기능별 심화 테스트

  4.1 Vercel 프록시 API 연동 테스트

  Vercel 서버리스 프록시를 통한 AI 분석 호출:
  - [x] 사진 업로드 → Vercel 프록시 → OpenAI 분석 요청
  - [x] x-app-token 헤더 인증 검증
  - [x] 네트워크 지연 시간 측정
  - [x] API 오류 처리 확인
  - [x] 타임아웃 동작 검증

  4.2 성능 측정

  Xcode Instruments 활용:
  # Performance 프로파일링
  flutter run --release --profile -d [DEVICE_ID]
  측정 항목:
  - [x] 메모리 사용량 (Heap, Stack)
  - [x] CPU 사용률
  - [x] 배터리 소모량
  - [x] 네트워크 트래픽

  4.3 사용자 시나리오 테스트

  핵심 플로우 검증:
  - [x] 1. 앱 시작 → 스플래시 → 홈
  - [x] 2. 레시피 작성 → 사진 업로드 → AI 분석
  - [x] 3. 감정 메모 작성 → 저장
  - [x] 4. 검색 → 필터링 → 상세보기
  - [x] 5. 통계 → 감정 분석 확인

  Phase 5: 문제 해결 및 최적화

  5.1 일반적인 실제 기기 이슈들

  예상 문제점:
  - 메모리 부족으로 인한 앱 종료
  - 네트워크 지연으로 인한 API 타임아웃
  - 실제 기기에서 느린 UI 반응성
  - 배터리 소모 과다

  5.2 해결 방안

  메모리 최적화:
  - 이미지 압축 강화
  - 불필요한 객체 해제
  - Provider 상태 관리 최적화

  네트워크 최적화:
  - API 타임아웃 조정
  - 재시도 로직 강화
  - 오프라인 모드 강화

  🚨 주의사항 및 Troubleshooting

  Apple Developer 관련

  - Signing 오류: Team ID 재확인 필요
  - Provisioning 만료: 자동 갱신 확인
  - 기기 등록 제한: 연간 100대 제한

  네트워크 관련

  - 실제 WiFi/Cellular: 시뮬레이터와 다른 환경
  - 프록시 토큰 검증: Vercel 서버 접근 권한 확인
  - 방화벽/VPN: 네트워크 차단 이슈

  성능 관련

  - 메모리 제약: 실제 기기는 시뮬레이터보다 제한적
  - CPU 스로틀링: 발열 시 성능 저하
  - 배터리 최적화: iOS 백그라운드 제한

  📊 성공 기준

  필수 통과 항목:

  - [x] 2대 이상 기기에서 정상 설치/실행 ✅
  - [x] Release 모드에서 안정적 동작 ✅
  - [x] Vercel 프록시 API 실제 연동 성공 ✅
  - [x] 메모리 사용량 < 150MB ✅
  - [x] 앱 시작 시간 < 3초 ✅
  - [x] API 응답 시간 < 10초 ✅

  권장 최적화 항목:

  - [x] 배터리 효율성 측정
  - [x] 다양한 iOS 버전 호환성
  - [x] 네트워크 불안정 환경 대응
  - [x] 메모리 부족 시 graceful 처리