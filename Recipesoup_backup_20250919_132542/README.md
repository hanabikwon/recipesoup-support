# Recipesoup 🍲

**감정 기반 레시피 아카이빙 툴**

단순히 요리 방법을 저장하는 것이 아니라, **이 요리를 왜 만들었는지, 누구를 위해 만들었는지** 그 순간의 감정과 기억까지 함께 기록하는 감성 레시피 다이어리입니다.

## ✨ 주요 기능

- 📝 **감정 메모와 함께하는 레시피 작성**: 요리에 담긴 이야기와 감정을 함께 기록
- 📷 **AI 기반 음식 사진 분석**: OpenAI API를 활용한 재료와 조리법 자동 추천
- 🏠 **완전한 오프라인 지원**: 모든 데이터를 로컬에 저장하는 개인 아카이빙
- 🎭 **8가지 감정 상태 분류**: 기쁨, 평온, 슬픔, 피로, 설렘, 그리움, 편안함, 감사
- 📅 **"과거 오늘" 기능**: 같은 날짜에 만든 과거의 레시피 회상
- 📊 **개인 요리 패턴 분석**: 감정별, 시간대별 요리 성향 분석

## 🎨 디자인 특징

- **빈티지 아이보리 테마**: 따뜻한 색감으로 감정 회고에 집중할 수 있는 UI
- **Bottom Navigation**: 홈/토끼굴/통계/보관함/설정 5탭 구조
- **감정 중심 인터페이스**: 감정 메모를 이탤릭으로 강조 표시
- **개인 아카이빙 최적화**: 회원 로그인 없이 완전 로컬 서비스

## 🛠️ 기술 스택

- **프레임워크**: Flutter (iOS/Android)
- **상태 관리**: Provider + ChangeNotifier
- **로컬 저장소**: Hive NoSQL + SharedPreferences
- **AI 연동**: OpenAI GPT-4o-mini (사진 분석)
- **이미지 처리**: image_picker + image
- **네트워킹**: dio (OpenAI API 호출)
- **테마**: 빈티지 아이보리 컬러 팔레트

## 📁 프로젝트 구조

### 핵심 문서
1. **CLAUDE.md** - 프로젝트 개요 및 TDD 작업 가이드
2. **ARCHITECTURE.md** - Flutter + OpenAI 기반 시스템 아키텍처
3. **PROGRESS.md** - 개발 진행 상황 및 버전 히스토리
4. **DESIGN.md** - 빈티지 아이보리 테마 및 감정 중심 UI
5. **TESTPLAN.md** - TDD 기반 종합 테스트 전략
6. **TESTDATA.md** - 감정 기반 레시피 테스트 데이터
7. **NOTE.md** - Recipesoup 특화 개발 주의사항

### 앱 디렉터리 구조
```
recipesoup/
├── lib/
│   ├── main.dart                    # 앱 진입점
│   ├── config/                      # API, 테마 설정
│   ├── models/                      # Recipe, Mood, Challenge 등
│   ├── services/                    # OpenAI, Hive, 챌린지 등
│   ├── screens/                     # Bottom Navigation 기반 화면들
│   ├── widgets/                     # 재사용 가능한 UI 컴포넌트
│   ├── providers/                   # 상태 관리 (Recipe, Burrow 등)
│   └── utils/                       # 유틸리티 함수
├── assets/                          # 이미지, 폰트 등 정적 자원
└── test/                           # [재설정 중] TDD 기반 테스트 구조
```

## 🚀 시작하기

### 사전 준비
1. **Flutter 환경 설정** (3.x 버전)
2. **OpenAI API 키** 준비
3. **개발 환경** (VS Code + Flutter 확장 권장)

### 환경 설정
1. `.env` 파일 생성 및 API 키 설정:
   ```env
   OPENAI_API_KEY=sk-proj-your_key_here
   API_MODEL=gpt-4o-mini
   ```

2. **의존성 설치**:
   ```bash
   flutter pub get
   ```

3. **권한 설정**:
   - iOS: `Info.plist`에 카메라/사진 라이브러리 권한 추가
   - Android: `AndroidManifest.xml`에 네트워크 권한 추가

### 실행 방법
```bash
# 개발 모드 실행
flutter run

# 웹 빌드 (테스트용)
flutter build web
```

## 📋 개발 가이드

### TDD 기반 개발 프로세스
1. **@CLAUDE.md** 확인 → 프로젝트 개요 이해
2. **@ARCHITECTURE.md** 참조 → 시스템 구조 파악
3. **@TESTPLAN.md** → 테스트 계획 수립
4. **테스트 코드 작성** → 실제 구현
5. **@PROGRESS.md** 업데이트 → 진행 상황 추적

### 주의사항
- **API 키 보안**: 절대 소스코드에 하드코딩 금지
- **감정 중심 설계**: emotionalStory는 필수 필드로 처리
- **빈티지 테마 일관성**: 모든 UI에서 아이보리 색상 사용
- **Ultra Think 원칙**: 모든 주요 변경사항은 영향도 분석 후 진행

## 🎯 프로젝트 현황

### 현재 상태 (v2025.09.17)
- ✅ **소스코드**: 안정적 운영 상태 (5개 메인 화면 + 챌린지 시스템)
- ✅ **문서체계**: 형상 관리 시스템 구축 완료
- ✅ **UI/UX**: 빈티지 아이보리 테마 완성
- 🔄 **테스트**: 구조 재설정 완료, TDD 기반 재구축 준비

### 주요 기능 현황
- 🏠 **홈 화면**: 개인 통계 + 최근 레시피 + "과거 오늘" 기능
- 🐰 **토끼굴 시스템**: 48개 마일스톤 (성장 32개 + 특별공간 16개)
- 📊 **통계 화면**: 감정별 요리 패턴 분석
- 📁 **보관함**: 폴더별 정리 + 검색 통합
- ⚙️ **설정**: 개인화 옵션
- 🏆 **챌린지 시스템**: 감정 기반 요리 챌린지

## 🤝 기여 가이드

### 개발 참여시
1. **문서 우선 확인**: @CLAUDE.md → @PROGRESS.md → @NOTE.md 순서
2. **Ultra Think 원칙**: 모든 변경사항은 영향도 분석 후 진행
3. **TDD 준수**: 테스트 코드 우선 작성
4. **형상 관리**: 주요 변경사항은 문서 버전 히스토리에 기록

### 이슈 보고
- 버그: NOTE.md 트러블슈팅 섹션 확인 후 보고
- 기능 요청: 감정 기반 아카이빙 컨셉에 부합하는지 검토

## 📚 추가 리소스

- [OpenAI API 문서](https://platform.openai.com/docs)
- [Hive NoSQL 가이드](https://docs.hivedb.dev/)
- [Provider 상태관리](https://pub.dev/packages/provider)
- [Flutter 성능 최적화](https://flutter.dev/docs/perf)

## 🔒 보안 주의사항

- ⚠️ **API 키 관리**: .env 파일 사용, 절대 하드코딩 금지
- ⚠️ **이미지 처리**: 로컬 저장 시 용량 제한 (10MB 이하)
- ⚠️ **데이터 백업**: 중요 변경 전 전체 백업 필수

---

## 📋 프로젝트 버전 히스토리

### v2025.09.17 - 형상 관리 시스템 구축
**주요 업데이트:**
- ✅ **문서 체계 개편**: 모든 핵심 문서에 버전 히스토리 시스템 도입
- ✅ **테스트 구조 재설정**: 기존 비정상 테스트 파일 완전 정리
- ✅ **README.md 대규모 개선**: Recipesoup 프로젝트에 최적화된 문서로 전면 재작성
- ✅ **불필요한 파일 식별**: recipesoup_PRD_0901.md, tests/README.md 등 구버전 파일 정리
- ✅ **백업 시스템**: Recipesoup_backup_20250917_181741 (2.1GB) 생성

**문서 개선사항:**
- CLAUDE.md: 테스트 구조 재설정 대응
- PROGRESS.md: 상세한 버전 히스토리 추가
- NOTE.md: 형상 관리 주의사항 보강
- ARCHITECTURE.md: 현재 구조 상태 명시
- README.md: 완전한 Recipesoup 프로젝트 문서로 재작성

**다음 단계:**
- Phase 1: 프로젝트 초기 설정 및 TDD 환경 구축
- 불필요한 구버전 파일들 정리 (안전성 확인 후)

---

**🍲 Recipesoup - 감정과 요리를 연결하는 특별한 아카이빙 경험을 만들어갑니다.**

*마지막 업데이트: v2025.09.17 - 형상 관리 시스템 구축 완료*