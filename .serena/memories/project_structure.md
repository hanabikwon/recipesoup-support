# Recipesoup 프로젝트 구조

## 루트 디렉토리
```
/Users/hanabi/Downloads/practice/Recipesoup/
├── recipesoup/                  # 메인 Flutter 프로젝트
├── wireframes/                  # XML 와이어프레임 템플릿
├── tests/                       # 외부 테스트 (Playwright 등)
├── ARCHITECTURE.md              # 시스템 아키텍처 문서
├── DESIGN.md                    # UI/UX 디자인 가이드
├── PROGRESS.md                  # 개발 진행 상황
├── TESTPLAN.md                  # 테스트 전략
├── NOTE.md                      # 개발 주의사항
├── README.md                    # 프로젝트 개요
└── 기타 문서들
```

## Flutter 프로젝트 구조 (recipesoup/)
```
recipesoup/
├── lib/                         # 메인 소스 코드
│   ├── main.dart               # 앱 진입점
│   ├── config/                 # 설정 파일들
│   │   ├── constants.dart      # 상수 정의
│   │   ├── theme.dart          # 빈티지 아이보리 테마
│   │   ├── api_config.dart     # OpenAI API 설정
│   │   └── burrow_assets.dart  # 게임화 요소 에셋
│   ├── models/                 # 데이터 모델
│   │   ├── recipe.dart         # 레시피 모델
│   │   ├── ingredient.dart     # 재료 모델
│   │   ├── mood.dart           # 감정 Enum
│   │   ├── burrow_milestone.dart # 마일스톤 모델
│   │   └── recipe_analysis.dart # AI 분석 결과
│   ├── services/               # 비즈니스 로직
│   │   ├── openai_service.dart # OpenAI API 통신
│   │   ├── hive_service.dart   # Hive 로컬 DB
│   │   ├── image_service.dart  # 이미지 로컬 저장
│   │   ├── stats_service.dart  # 개인 통계 분석
│   │   ├── url_scraper_service.dart # URL 스크래핑
│   │   └── burrow_unlock_service.dart # 게임화 요소
│   ├── screens/                # 화면 컴포넌트
│   │   ├── splash_screen.dart  # 스플래시
│   │   ├── main_screen.dart    # Bottom Navigation 컨테이너
│   │   ├── home_screen.dart    # 홈 탭
│   │   ├── search_screen.dart  # 검색 탭
│   │   ├── stats_screen.dart   # 통계 탭
│   │   ├── archive_screen.dart # 보관함 탭
│   │   ├── settings_screen.dart # 설정 탭
│   │   ├── create_screen.dart  # 레시피 작성
│   │   ├── detail_screen.dart  # 레시피 상세보기
│   │   ├── photo_import_screen.dart # 사진으로 작성
│   │   ├── url_import_screen.dart   # URL로 작성
│   │   └── burrow/             # 게임화 요소 화면
│   ├── widgets/                # 재사용 가능한 위젯
│   │   ├── common/             # 공통 위젯
│   │   ├── home/               # 홈 관련 위젯
│   │   ├── recipe/             # 레시피 관련 위젯
│   │   └── burrow/             # 게임화 요소 위젯
│   ├── providers/              # 상태 관리
│   │   ├── recipe_provider.dart # 레시피 상태
│   │   ├── stats_provider.dart  # 통계 상태
│   │   └── burrow_provider.dart # 게임화 요소 상태
│   ├── utils/                  # 유틸리티 함수
│   │   ├── validators.dart     # 입력 검증
│   │   ├── image_utils.dart    # 이미지 처리
│   │   ├── date_utils.dart     # 날짜 처리
│   │   └── 기타 유틸리티들
│   └── data/content/           # 정적 컨텐츠 (JSON)
├── test/                       # 테스트 파일
│   ├── unit/                   # 단위 테스트
│   ├── widget/                 # 위젯 테스트
│   └── integration/            # 통합 테스트
├── assets/                     # 에셋 파일
│   ├── images/                 # 이미지
│   └── fonts/                  # 폰트
├── android/                    # Android 플랫폼 코드
├── ios/                        # iOS 플랫폼 코드
├── web/                        # Web 플랫폼 코드
├── macos/                      # macOS 플랫폼 코드
├── windows/                    # Windows 플랫폼 코드
├── linux/                      # Linux 플랫폼 코드
├── pubspec.yaml               # 의존성 관리
├── analysis_options.yaml     # 정적 분석 설정
├── .env.example              # 환경변수 예시
└── README.md                 # 프로젝트 설명
```

## 특징
- **Bottom Navigation** 기반 5탭 구조
- **완전 오프라인** 지원 (로컬 Hive DB)
- **Provider 패턴** 상태 관리
- **Material Design 3** 기반 UI
- **크로스 플랫폼** 지원 (모든 주요 플랫폼)
- **TDD 테스트** 구조 (단위/위젯/통합)