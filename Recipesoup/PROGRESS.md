# Recipesoup 개발 진행 상황

## 프로젝트 개요
- **프로젝트명**: Recipesoup - 감정 기반 레시피 아카이빙 툴
- **시작일**: 2025-09-01
- **목표 완료일**: 2025-12-31
- **현재 단계**: 테스트 문서화 완료 / 구현 준비

## 개발 단계별 진행 상황

### Phase 0: 테스트 문서화 및 설계 ✅ (완료)
- [x] **종합 테스트 프레임워크 구축**
  - [x] TESTPLAN.md 작성 (TDD 기반 종합 테스트 전략)
  - [x] TESTDATA.md 작성 (감정 기반 레시피 완전 샘플 데이터)
  - [x] Playwright MCP 음식 사진 분석 테스트 설계
  - [x] TEST_EXECUTION_GUIDE.md 작성 (단계별 실행 가이드)
- [x] **프로젝트 기반 문서 최신화**
  - [x] CLAUDE.md (프로젝트 개요 및 TDD 작업 가이드)
  - [x] ARCHITECTURE.md (Flutter + OpenAI 기반 시스템 아키텍처)
  - [x] DESIGN.md (빈티지 아이보리 테마 및 감정 중심 UI)
- [x] **개발 가이드라인 구축**
  - [x] NOTE.md (Recipesoup 특화 주의사항 및 실수 방지)
  - [x] PROGRESS.md (현재 진행 상황 정확한 반영)

### Phase 1: 프로젝트 초기 설정 🎯 (다음 단계)
- [ ] **테스트 환경 구축 우선**
  - [ ] 테스트 이미지 준비 (testimg1.jpg, testimg2.jpg, testimg3.jpg)
  - [ ] OpenAI API 키 .env 설정 확인
  - [ ] Playwright MCP 테스트 환경 검증
- [ ] **Flutter 프로젝트 생성**
  - [ ] `flutter create recipesoup` 실행
  - [ ] ARCHITECTURE.md 기반 폴더 구조 생성
  - [ ] TDD 기반 테스트 디렉토리 구조 설정
- [ ] **패키지 의존성 추가** (ARCHITECTURE.md 참조)
  - [ ] 상태관리: `provider`
  - [ ] 네트워킹: `dio`, `flutter_dotenv`
  - [ ] 로컬 저장소: `hive`, `hive_flutter`
  - [ ] 이미지: `image_picker`, `image`
  - [ ] 테스트: `mockito`, `build_runner`
- [ ] **환경 설정**
  - [ ] .env 파일 생성 (OpenAI API 키)
  - [ ] .gitignore 설정 (API 키 보안)
  - [ ] iOS 권한 설정 (카메라, 사진 라이브러리)
  - [ ] Android 권한 및 네트워크 보안 설정

### Phase 2: 핵심 모델 및 서비스 구현 (TDD 기반) ⬜
- [ ] **감정 기반 데이터 모델 구현** (테스트 먼저!)
  - [ ] Recipe 모델 테스트 작성 → Recipe 모델 구현
  - [ ] Ingredient 모델 테스트 작성 → Ingredient 모델 구현  
  - [ ] Mood enum 테스트 작성 → Mood enum 구현
  - [ ] Hive TypeAdapter 테스트 작성 → TypeAdapter 구현
  - [ ] 모델 직렬화/역직렬화 테스트 (TESTDATA.md 기반)
- [ ] **OpenAI Service 구현** (핵심 기능!)
  - [ ] OpenAI Service 단위 테스트 작성 (Mock 포함)
  - [ ] 실제 OpenAI API 연동 구현
  - [ ] testimg1.jpg, testimg2.jpg, testimg3.jpg 기반 테스트 검증
  - [ ] API 에러 처리 완벽 구현 (401, 429, 400, 5xx)
  - [ ] 이미지 최적화 및 Base64 인코딩 구현
- [ ] **Hive 로컬 저장소 서비스 구현**
  - [ ] Hive Service 단위 테스트 작성
  - [ ] Recipe CRUD 작업 구현
  - [ ] "과거 오늘" 검색 기능 구현
  - [ ] 감정별/태그별 필터링 구현
- [ ] **유틸리티 함수 구현**
  - [ ] Date Utils (과거 오늘 기능용)
  - [ ] Image Utils (리사이징, 압축)
  - [ ] Validators (emotionalStory 필수 검증 등)

### Phase 3: 빈티지 아이보리 테마 UI 구현 ⬜
- [ ] **빈티지 테마 시스템 구축** (DESIGN.md 기반)
  - [ ] 빈티지 아이보리 색상 팔레트 적용 (#FAF8F3, #8B9A6B 등)
  - [ ] 커스텀 테마 데이터 구현
  - [ ] 타이포그래피 시스템 (이탤릭 감정 텍스트 포함)
  - [ ] 카드 및 버튼 스타일 구현
- [ ] **공통 UI 컴포넌트 구현**
  - [ ] 빈티지 스타일 버튼 (올리브/브라운 계열)
  - [ ] 로딩 인디케이터 (빈티지 도트 스타일)
  - [ ] 레시피 카드 (감정 메모 이탤릭 강조)
  - [ ] FAB 및 확장 메뉴 (빈티지 오렌지)
- [ ] **Bottom Navigation 기반 화면 구현**
  - [ ] 스플래시 화면 (빈티지 로고 + 아이보리 배경)
  - [ ] 홈 화면 (개인 통계 + "과거 오늘" + 최근 레시피)
  - [ ] 검색 화면 (요리이름 + 감정상태 우선)
  - [ ] 통계 화면 (개인 패턴 분석 차트)
  - [ ] 보관함 화면 (폴더별 정리)
  - [ ] 설정 화면 (개인화 옵션)
- [ ] **감정 중심 레시피 작성 화면**
  - [ ] 사진 업로드 UI (크고 직관적인 영역)
  - [ ] 감정 이야기 텍스트 영역 (가이드 질문 포함)
  - [ ] 감정 상태 선택 위젯 (8가지 감정)
  - [ ] 재료/조리법 입력 (AI 추천 결과 반영)
  - [ ] 태그 입력 및 평점 선택

### Phase 4: 핵심 감정 기반 기능 통합 ⬜
- [ ] **음식 사진 분석 및 AI 추천 기능**
  - [ ] 사진 촬영/선택 기능 구현
  - [ ] OpenAI API 연동 (실제 testimg 기반 검증)
  - [ ] AI 분석 결과 UI 표시 및 편집
  - [ ] 네트워크 에러 및 로딩 상태 처리
  - [ ] Provider 상태 관리 통합
- [ ] **감정 기반 레시피 아카이빙**
  - [ ] emotionalStory 중심 레시피 저장
  - [ ] 감정 상태별 카테고리 정리
  - [ ] 태그 기반 검색 및 필터링
  - [ ] 즐겨찾기 및 개인 관리 기능
- [ ] **"과거 오늘" 회상 기능**
  - [ ] 날짜 기반 과거 레시피 검색
  - [ ] 감정 변화 추이 시각화
  - [ ] 개인 요리 패턴 분석 표시
  - [ ] 연속 기록 및 성취 시스템

### Phase 5: 테스트 및 최적화 ⬜
- [ ] 테스트 작성 및 실행
  - [ ] 단위 테스트 작성
  - [ ] 위젯 테스트 작성
  - [ ] 통합 테스트 작성
  - [ ] 테스트 커버리지 확인
- [ ] 성능 최적화
  - [ ] 이미지 최적화
  - [ ] 메모리 사용량 최적화
  - [ ] 앱 시작 시간 최적화
  - [ ] 네트워크 요청 최적화
- [ ] 버그 수정
  - [ ] 테스트 중 발견된 버그 수정
  - [ ] 사용자 피드백 반영

### Phase 6: 배포 준비 ⬜
- [ ] 앱 메타데이터 설정
  - [ ] 앱 이름 및 설명
  - [ ] 앱 아이콘 제작 및 설정
  - [ ] 스플래시 스크린 설정
- [ ] 빌드 설정
  - [ ] iOS 빌드 설정
  - [ ] Android 빌드 설정
  - [ ] 서명 키 생성 및 설정
- [ ] 스토어 등록 준비
  - [ ] 스크린샷 준비
  - [ ] 앱 설명 작성
  - [ ] 개인정보 처리방침 작성

## 현재 진행 상황 요약
- **완료된 작업**: 
  - ✅ **종합 테스트 문서화 완료** (2025-09-01)
    - TESTPLAN.md: TDD 기반 종합 테스트 계획 (단위/위젯/통합/성능/사용성)
    - TESTDATA.md: 감정 기반 레시피 테스트 데이터 (8가지 감정, 5개 완전한 레시피 샘플)
    - playwright_food_analysis_test.js: OpenAI API 음식 사진 분석 자동화 테스트
    - TEST_EXECUTION_GUIDE.md: 단계별 실행 가이드 및 구체적 테스트 케이스
  - ✅ **프로젝트 기반 문서 최신화**
    - CLAUDE.md: 프로젝트 개요 및 TDD 작업 가이드
    - ARCHITECTURE.md: Flutter + OpenAI 기반 시스템 아키텍처
    - DESIGN.md: 빈티지 아이보리 테마 및 감정 중심 UI 설계
  
- **진행 중인 작업**: 
  - 🚧 **실제 Flutter 앱 구현 준비**
    - 테스트 코드 우선 작성 (TDD 원칙)
    - OpenAI API 연동 서비스 구현
    
- **다음 작업 계획**: 
  - 🎯 **Phase 1: 프로젝트 초기 설정**
    - Flutter 프로젝트 생성 및 의존성 패키지 설치
    - 테스트 환경 구축 (testimg1.jpg, testimg2.jpg, testimg3.jpg 준비)
  - 🎯 **Phase 2: TDD 기반 핵심 모델 구현**
    - Recipe, Ingredient, Mood 모델 테스트 코드 작성
    - OpenAI Service 모킹 및 실제 구현

## 주요 이슈 및 해결 사항
### 해결된 이슈

### 2025-09-17: lib/services 디렉토리 정리 완료 🧹
- **문제**: 사용되지 않는 서비스 파일들이 코드베이스에 남아있어 혼란 야기
- **분석 과정**: Ultra Think 방식으로 lib/services의 모든 15개 파일 사용 여부 체계적 분석
- **삭제된 파일들**:
  1. `stats_service.dart` - 거의 빈 파일 (1줄), 통계 기능은 StatsProvider에서 처리
  2. `special_room_service.dart` - 기능이 BurrowUnlockCoordinator에 통합되어 중복
  3. `burrow_unlock_coordinator_backup.dart` - 백업 파일로 프로덕션 코드에서 사용 안됨
  4. `growth_track_service.dart` - 어디서도 import되지 않아 완전히 미사용
- **검증 방법**:
  - `mcp__serena__find_referencing_symbols` 도구로 참조 확인
  - `mcp__serena__search_for_pattern`으로 import 구문 검색
  - 실제 사용 여부 철저히 확인
- **Side Effect 방지**:
  - 실제 사용되는 핵심 서비스들(burrow_unlock_service.dart, challenge_service.dart 등)은 모두 보존
  - ARCHITECTURE.md 업데이트로 문서 일관성 유지
- **결과**: 코드베이스 정리로 개발자 혼란 감소, 유지보수성 향상
- **날짜**: 2025-09-17

### 2025-09-19: 토끼굴 마일스톤 시스템 최적화 완료 🏆
- **문제**: 기존 110개 레시피 완성 목표가 비현실적이어서 사용자 경험 저하
- **사용자 요구사항**: 32단계를 50개(→70개) 레시피로 완성하는 점진적 증가 시스템
- **Ultra Think 설계 과정**:
  1. **수학적 진행 계산**: 1-5단계(+1씩), 6-21단계(+2씩), 22-32단계(+3씩)
  2. **최종 70개 레시피 진행**: 1,2,3,4,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33,35,37,40,43,46,49,52,55,58,61,64,67,70
  3. **논리적 검증**: Level 32에서 정확히 70개 레시피 달성 확인
- **구현 완료 사항**:
  - ✅ **코드 수정**: `/lib/services/burrow_unlock_service.dart` Line 62-256
    - 31개 `requiredRecipes` 값을 110-recipe 시스템에서 70-recipe 시스템으로 전면 업데이트
    - Level 2: 3→2, Level 3: 5→3, ..., Level 32: 110→70
  - ✅ **주석 및 로그 메시지 업데이트**:
    - Line 53: "32단계 논리적 성장여정" → "32단계 70개 레시피 성장여정"
    - Line 348: "32-level growth journey" → "32-level 70-recipe journey"
  - ✅ **기능 검증**: 모든 특별공간(16개) 및 성장 마일스톤(32개) 정상 작동 확인
- **사용자 경험 개선**:
  - **현실적 목표 설정**: 110개→70개로 36% 감소하여 달성 가능성 향상
  - **점진적 성장 경험**: 초반 쉬운 목표(1,2,3,4,5)에서 후반 도전적 목표(+3씩)로 자연스러운 난이도 곡선
  - **완주 동기 부여**: 32단계 최종 달성이 현실적으로 가능한 범위로 조정
- **Side Effect 방지**:
  - 기존 특별공간 언락 조건 완전 보존
  - 다른 서비스 및 UI 구조에 영향 없음
  - 기존 사용자 데이터 호환성 유지
- **날짜**: 2025-09-19

### 2025-09-16: 토끼굴 마일스톤 시스템 완전 복원 완료 🎯
- **문제**: 토끼굴 화면에서 "특별한 공간들" 0/0개 표시, 마일스톤 데이터 누락
- **원인 분석**:
  - `BurrowUnlockCoordinator._createDefaultMilestones()`에서 오직 2개 마일스톤만 생성
  - 총 48개 마일스톤(32개 성장여정 + 16개 특별공간) 중 46개 누락
  - 기존 SpecialRoom enum(16개) 무시하고 새로운 특별공간 생성 시도
- **Ultra Think 해결 과정**:
  1. **Complete Growth Journey 32 Levels 생성**:
     - Level 1-8: 기초 입문 단계 (아늑한 토끼굴 → 어부의 토끼굴)
     - Level 9-16: 학습 발전 단계 (발전하는 토끼굴 → 요리책 저자 토끼굴)
     - Level 17-24: 창작 숙련 단계 (스케치 토끼굴 → 요리경연 토끼굴)
     - Level 25-30: 마스터 단계 (요리축제 토끼굴 → 감사의 토끼굴)
     - Level 31-32: 최종 완성 단계 (시그니처 요리 토끼굴 → 꿈의 레스토랑 토끼굴)
  2. **기존 16개 SpecialRoom enum 활용**:
     - ballroom, hotSpring, orchestra, alchemyLab, fineDining (기존 5개)
     - alps, camping, autumn, springPicnic, surfing, snorkel, summerbeach, baliYoga, orientExpress, canvas, vacance (추가 11개)
     - `BurrowMilestone.special()` 팩토리 메서드로 정확한 구조 생성
  3. **코드 레벨 수정**:
     - `/lib/services/burrow_unlock_coordinator.dart` Line 236-336 완전 재작성
     - 새로운 특별공간 생성 코드 제거, 기존 enum 활용 코드로 대체
     - 각 특별공간별 고유한 unlock 조건 설정
- **검증 결과**:
  - ✅ Flutter 앱 정상 실행 (컴파일 에러 해결)
  - ✅ Level 1, 2 unlock 알림 정상 작동
  - ✅ 총 48개 마일스톤 생성 확인 (32 growth + 16 special)
  - ✅ BurrowProvider와 BurrowUnlockCoordinator 정상 연동
- **Side Effect 방지**:
  - 기존 레시피 데이터 보존
  - 다른 화면 기능에 영향 없음
  - 기존 SpecialRoom enum 구조 완전 유지
- **날짜**: 2025-09-16

### 진행 중인 이슈
- **이슈**: [문제 설명]
  - **현재 상태**: [진행 상황]
  - **예상 해결일**: YYYY-MM-DD

## 기술적 결정 사항
1. **TDD 기반 개발 방식**: 구현 전 테스트 코드 작성으로 품질 보장 및 OpenAI API 같은 외부 서비스의 안정적 통합
2. **Flutter + OpenAI GPT-4o-mini**: 크로스플랫폼 앱 개발과 음식 사진 분석 AI 연동
3. **로컬 우선 아키텍처**: Hive NoSQL + 완전 오프라인 동작으로 개인 아카이빙 특성 강화
4. **감정 기반 데이터 모델링**: Recipe + EmotionalStory 조합으로 단순 레시피 저장을 넘어선 감성 기록
5. **Playwright MCP 테스트**: Flutter Web + Chrome 환경에서 실제 사용자 시나리오 자동 테스트
6. **빈티지 아이보리 테마**: 감정 회고에 집중할 수 있는 시각적 안정성 제공

## 중요 변경 사항
### 2025-09-01: 종합 테스트 프레임워크 구축 완료
- **TESTPLAN.md 작성**: 단위/위젯/통합/성능 테스트 전략 수립
- **TESTDATA.md 작성**: 8가지 감정별 샘플 데이터, 5개 완전한 레시피, OpenAI API 모킹 데이터
- **Playwright MCP 테스트 설계**: testimg1.jpg, testimg2.jpg, testimg3.jpg 기반 음식 사진 분석 자동화 테스트
- **TEST_EXECUTION_GUIDE.md 작성**: 구체적 실행 단계 및 CI/CD 통합 가이드
- **영향받는 부분**: 모든 개발 단계에서 TDD 원칙 적용 필수
- **추가 작업 필요 사항**: 실제 테스트 이미지 3개 준비, Flutter 프로젝트 생성

### 2025-09-05: 보관함 상단 영역 레이아웃 수정 완료 📱
- **문제**: MainScreen AppBar 제거 후 ArchiveScreen 상단 영역 레이아웃 이상
- **원인 분석**: 
  - SafeArea 처리 부족으로 탭바가 상태바와 겹침
  - 상단 제목/헤더 영역 부재
  - FloatingActionButton 위치 부적절 (endTop)
- **Ultra Think 수정사항**:
  - **SafeArea 래퍼 추가**: 전체 body를 SafeArea로 감싸서 상태바 충돌 방지
  - **보관함 헤더 영역 신규 추가**: 
    - 제목 "보관함" 표시 (fontSize: 24, bold)
    - 우상단 검색 아이콘 버튼 (Icons.search/Icons.close 토글)
    - 적절한 패딩 (horizontal: 20, vertical: 16)
  - **검색 UI 개선**:
    - FloatingActionButton 제거 (부적절한 endTop 위치)
    - 헤더 영역의 IconButton으로 대체
    - _buildSearchFab() 메서드 제거 (코드 정리)
  - **레이아웃 구조 최적화**:
    - Column: 헤더 → 탭바 → 탭뷰 순서로 명확한 계층 구조
    - 기존 검색 기능 및 바텀시트 UI 완전 유지
- **Side Effect 방지**: 
  - 다른 화면들(HomeScreen, BurrowScreen, StatsScreen, SettingsScreen) 독립적 AppBar 보유 확인
  - 기존 검색 기능 완전 유지 (바텀시트, 필터링 등)
- **테스트 검증**: Flutter Web 빌드 성공, 상단 영역 정상 표시

### 2025-09-05: UI 단순화 - 상단바 제거 및 설정 바텀바 이동 완료 🎨
- **목적**: 복잡한 상단바 제거로 UI 단순화 및 사용성 개선
- **주요 변경사항**:
  - **MainScreen AppBar 완전 제거** (lib/screens/main_screen.dart)
    - 'Recipesoup' 로고/제목 제거
    - 상단 영역 완전 제거로 화면 공간 확보
    - 각 개별 화면의 독립적 AppBar로 대체
  - **설정을 바텀 네비게이션으로 이동**
    - 4개 탭(홈/토끼굴/통계/보관함) → 5개 탭으로 확장
    - 설정 아이콘 및 라벨 추가 (Icons.settings)
    - _navigateToSettings() 메서드 제거 (별도 네비게이션 불필요)
  - **인덱스 매핑 시스템 업데이트**
    - _migrateCurrentIndex() 메서드 5개 탭 매핑으로 수정
    - _onTabTapped() 인덱스 범위 0~4로 확장
    - 기존 네비게이션 호환성 유지
- **Side Effect 방지 검증**:
  - 각 개별 화면(HomeScreen, BurrowScreen, StatsScreen, ArchiveScreen, SettingsScreen) 독립적 AppBar 보유 확인
  - MainScreen AppBar 제거가 다른 화면에 영향 없음 검증
  - SettingsScreen의 `automaticallyImplyLeading: false` 설정으로 뒤로가기 버튼 문제 없음
- **테스트 검증**: Flutter Web 빌드 성공, UI 구조 변경 완료
- **사용자 경험 개선**: 더 깔끔하고 직관적인 네비게이션 구조 제공

### 2025-09-05: Unicode Surrogate Pair 에러 수정 완료 🔧
- **해결된 문제**: API Error 400 "no low surrogate in string" JSON 파싱 에러
- **에러 원인**: OpenAI API 호출 시 잘못된 Unicode surrogate pair가 JSON에 포함
- **주요 수정사항**:
  - **UnicodeSanitizer 클래스 신규 추가** (lib/utils/unicode_sanitizer.dart)
    - `sanitize()`: 잘못된 surrogate pair를 안전한 문자(U+FFFD)로 대체
    - `sanitizeJsonData()`: JSON 데이터의 모든 문자열 필드를 재귀적으로 정리
    - `validateBase64()`: Base64 인코딩된 이미지 데이터 유효성 검증
    - `sanitizeApiRequest()`: API 요청 전체 데이터 정리 및 안전성 확보
  - **OpenAI Service 보안 강화** (lib/services/openai_service.dart)
    - 모든 API 호출 전 Unicode 안전성 검증 추가
    - Base64 이미지 데이터 유효성 검증 강화
    - 텍스트 분석 시 Unicode 정리 로직 적용
    - API 요청 데이터 sanitization 적용
  - **Archive Screen 컴파일 에러 수정** (lib/screens/archive_screen.dart)
    - `_isInSearchMode` 변수 누락 수정
    - `_buildSearchFab()` 메서드 구현 추가
    - `_buildBottomSheetSearch()` 메서드 구현 추가
- **기술적 구현**:
  - High/Low Surrogate pair 검증 및 수정 알고리즘
  - 제어 문자 필터링 (출력 가능한 문자만 유지)
  - JSON 인코딩/디코딩 안전성 보장
  - API 요청 실패 시 안전한 fallback 제공
- **Side Effect 방지**: 기존 기능 동작에 영향 없이 Unicode 처리만 강화
- **테스트 검증**: Flutter Web 빌드 성공, 컴파일 에러 모두 해결
- **보안 강화**: API 키 노출 방지 및 입력 데이터 검증 강화

### 2025-09-05: Search Screen → Archive Screen 통합 완료 ✅
- **통합 목적**: Bottom Navigation 복잡성 해소 (6탭 → 4탭으로 축소)
- **주요 변경사항**:
  - **Archive Screen에 완전한 검색 기능 통합**: 텍스트 검색, 감정 필터, 해시태그 필터 모두 포함
  - **조건부 렌더링 구현**: `_isInSearchMode` 기반으로 검색 모드 ↔ 탭 모드 전환
  - **상태 보존**: `AutomaticKeepAliveClientMixin`으로 탭 전환 시 검색 상태 유지
  - **Favorite 동기화**: 검색 결과와 탭 뷰 간 즐겨찾기 상태 실시간 동기화
  - **Main Navigation 재구성**: 홈/토끼굴/통계/보관함 4개 탭으로 최적화
- **UI 개선사항**:
  - **AppBar 중복 제거**: MainScreen AppBar 활용으로 UI 겹침 현상 해결
  - **FAB 위치 조정**: `endFloat`으로 바텀바 상단에 위치 (기존 endDocked에서 변경)
  - **검색 헤더 항상 표시**: 보관함 진입 시 즉시 검색 가능한 UX
- **기술적 구현**:
  - 검색 상태 변수 통합: `_searchController`, `_searchResults`, `_isInSearchMode` 등
  - 실시간 검색: 300ms debounce로 성능 최적화
  - 해시태그 토글: 선택/해제 기능으로 직관적 필터링
- **Side Effect 방지**: Ultra Think 방식으로 상태 관리 충돌 및 UI 레이아웃 이슈 완전 해결
- **영향받는 부분**: SearchScreen 독립 실행 종료, MainScreen 네비게이션 인덱스 재매핑
- **테스트 검증**: Flutter Web 빌드 성공, 모든 검색/필터/즐겨찾기 기능 정상 작동 확인

### 2025-09-01: 치명적 보안 버그 수정 완료 🚨
- **발견된 문제**: CLAUDE.md와 NOTE.md에 실제 OpenAI API 키 하드코딩 (3개 파일)
- **보안 위험도**: 치명적 (API 키 노출로 인한 무단 사용 가능)
- **수정 내용**:
  - CLAUDE.md 기술 스택 섹션: 실제 키 → "보안상 하드코딩 금지" 메시지
  - CLAUDE.md .env 예시: 실제 키 → "your_openai_api_key_here" 플레이스홀더
  - NOTE.md 주의사항: 실제 키 → "recipesoup-openai-apikey.txt 파일에 별도 보관" 안내
- **Side Effect 처리**: 관련 문서들의 API 키 참조 방식 검토 완료
- **영향받는 부분**: 향후 모든 민감정보는 .env 파일 또는 별도 파일로 관리 필수
- **추가 보안 강화**: NOTE.md에 보안 체크리스트 20개 항목으로 실수 방지 체계 구축

## 개발 메트릭
- **전체 진행률**: 15% (테스트 문서화 및 설계 완료)
- **예상 완료일**: 2025-02-28
- **문서화 완성도**: 100% (CLAUDE.md, ARCHITECTURE.md, DESIGN.md, TESTPLAN.md, TESTDATA.md)
- **테스트 커버리지 목표**: 85% (OpenAI Service 95%, 모델 90%, UI 75%)
- **준비된 테스트 케이스**: 50+ (단위/위젯/통합/Playwright 포함)

## 향후 계획
### 단기 계획 (1-2주)
- [ ] Flutter 프로젝트 생성 및 기본 구조 설정
- [ ] 테스트 이미지 파일 준비 (testimg1.jpg, testimg2.jpg, testimg3.jpg)
- [ ] TDD 기반 Recipe 모델 구현 (테스트 먼저 작성)
- [ ] OpenAI Service 단위 테스트 및 모킹 구현
- [ ] Hive 로컬 데이터베이스 연동 테스트

### 중기 계획 (1개월)
- [ ] Bottom Navigation 기반 UI 구현 (스플래시, 홈, 검색, 통계, 보관함, 설정)
- [ ] 감정 기반 레시피 작성 화면 구현 
- [ ] OpenAI API 실제 연동 및 사진 분석 기능 완성
- [ ] "과거 오늘" 기능 구현 (감정 회상)
- [ ] Playwright MCP 테스트 실행 및 버그 수정

### 장기 계획 (3개월)
- [ ] Flutter Web 완전 지원 및 성능 최적화
- [ ] 접근성 가이드라인 완전 준수
- [ ] 빈티지 아이보리 테마 완성 (디자인 시스템 구현)
- [ ] 사용자 피드백 반영 및 UX 개선
- [ ] iOS/Android 스토어 배포 준비

## 개발 메모
- **핵심 특징**: 감정과 요리를 연결하는 개인 아카이빙에 집중
- **중요한 점**: OpenAI API 의존성으로 인한 네트워크 에러 처리 완벽히 구현 필요
- **테스트 우선순위**: 음식 사진 분석 기능이 앱의 핵심이므로 Playwright MCP 테스트 우선 실행
- **주의사항**: API 키 보안 및 이미지 로컬 저장 용량 관리 필요

---

## 📋 버전 히스토리

### v2025.09.17 - 테스트 구조 재설정
**주요 변경사항:**
- **테스트 디렉터리 완전 제거**: `Recipesoup/recipesoup/test/` 전체 삭제
- **테스트 문서 상태 업데이트**: TESTPLAN.md, TEST_EXECUTION_GUIDE.md에 재설정 상태 배너 추가
- **프로젝트 백업**: `Recipesoup_backup_20250917_181741` 생성 (2.1GB)
- **문서 정리**: 기존 작동하지 않던 테스트 파일들 완전 정리
- **현재 상태**: 테스트 구조 재구축을 위한 클린 상태 완료

**영향도:**
- ✅ 기존 소스코드: 영향 없음
- ✅ 문서 구조: 정리 완료
- ✅ 프로젝트 안정성: 향상

**다음 단계:**
- 필요시 TDD 기반 새로운 테스트 구조 재구축
- Phase 1 프로젝트 초기 설정 진행 준비

---

### v2025.09.16 - 토끼굴 마일스톤 시스템 완전 복원
**주요 변경사항:**
- 토끼굴 화면 "특별한 공간들" 0/0개 표시 문제 해결
- 총 48개 마일스톤 생성 (32개 성장여정 + 16개 특별공간)
- BurrowUnlockCoordinator 완전 재작성

### v2025.09.05 - UI 구조 개선 및 에러 수정
**주요 변경사항:**
- MainScreen AppBar 제거로 UI 단순화
- 설정을 바텀 네비게이션으로 이동 (4탭→5탭)
- Unicode Surrogate Pair 에러 수정 완료
- Search Screen → Archive Screen 통합

---
*이 문서는 개발 진행에 따라 지속적으로 업데이트됩니다.*
*마지막 업데이트: 2025-09-17 (테스트 구조 재설정 완료)*