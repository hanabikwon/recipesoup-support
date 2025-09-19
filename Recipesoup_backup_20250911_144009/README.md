# Flutter 앱 개발 문서 템플릿 세트

## 개요
이 문서 세트는 Claude Code를 활용한 Flutter 앱 개발을 위한 표준 템플릿입니다. 
체계적이고 효율적인 앱 개발을 위해 필요한 모든 문서 구조를 제공합니다.

## 문서 구조

### 📄 핵심 문서
1. **CLAUDE.md** - 프로젝트 개요 및 작업 가이드
   - 프로젝트 기본 정보
   - 기술 스택 정의
   - 작업 프로세스 가이드
   - 환경 설정 정보

2. **ARCHITECTURE.md** - 시스템 구조
   - 전체 시스템 아키텍처
   - 데이터 모델 정의
   - API 구조 및 명세
   - 데이터베이스 스키마

3. **PROGRESS.md** - 개발 진행 상황
   - 단계별 개발 체크리스트
   - 완료/진행중/계획 작업
   - 이슈 및 해결 사항
   - 중요 변경 사항 기록

4. **DESIGN.md** - UI/UX 디자인 가이드
   - 디자인 원칙 및 시스템
   - 컬러 팔레트 및 타이포그래피
   - 컴포넌트 스타일 가이드
   - 화면별 디자인 명세

5. **TESTPLAN.md** - 테스트 전략
   - 테스트 레벨별 계획
   - 테스트 케이스 정의
   - 자동화 및 수동 테스트
   - 테스트 커버리지 목표

6. **TESTDATA.md** - 테스트 데이터
   - 샘플 데이터 세트
   - Mock API 응답
   - 테스트 시나리오 데이터
   - 엣지 케이스 데이터

7. **NOTE.md** - 개발 주의사항
   - 자주 발생하는 문제와 해결법
   - Flutter 개발 팁
   - 플랫폼별 주의사항
   - 성능 최적화 가이드

### 📁 wireframes/ 폴더
UI 화면 설계를 위한 XML 템플릿 모음:
- `splash.xml` - 스플래시 화면
- `main.xml` - 메인 화면
- `loading.xml` - 로딩 화면
- `error.xml` - 에러 화면
- `empty.xml` - 빈 상태 화면
- `form.xml` - 입력 폼 화면
- `list.xml` - 리스트 화면
- `detail.xml` - 상세 화면
- `settings.xml` - 설정 화면

## 사용 방법

### 1. 프로젝트 시작
1. 이 문서 세트를 새 프로젝트 폴더에 복사
2. 각 문서의 `[대괄호]` 부분을 실제 프로젝트 정보로 교체
3. 불필요한 섹션은 삭제하고 필요한 섹션 추가

### 2. 문서 업데이트 규칙
- **작업 전**: 관련 문서 확인
- **작업 중**: PROGRESS.md에 진행 상황 기록
- **작업 후**: 변경사항을 관련 문서에 반영
- **이슈 발생**: NOTE.md에 문제와 해결 방법 기록

### 3. 개발 프로세스
```
1. CLAUDE.md 확인 → 프로젝트 이해
2. ARCHITECTURE.md 참조 → 구조 파악
3. DESIGN.md + wireframes/ → UI 구현
4. TESTPLAN.md + TESTDATA.md → 테스트
5. PROGRESS.md 업데이트 → 진행 상황 추적
6. NOTE.md 참조 → 문제 해결
```

### 4. Claude Code와 함께 사용하기
```
@CLAUDE.md      # 프로젝트 개요 확인
@ARCHITECTURE.md # 구조 참조
@PROGRESS.md    # 현재 상태 파악
@DESIGN.md      # UI 가이드 확인
```

## 문서 커스터마이징

### 프로젝트 타입별 권장사항

#### 🛍️ 전자상거래 앱
- ARCHITECTURE.md: 결제 시스템, 장바구니 구조 추가
- TESTDATA.md: 상품 데이터, 주문 시나리오 추가
- wireframes/: 상품 목록, 장바구니, 결제 화면 추가

#### 🗨️ 소셜 네트워킹 앱
- ARCHITECTURE.md: 실시간 통신, 알림 시스템 추가
- DESIGN.md: 피드, 프로필, 채팅 UI 가이드 추가
- wireframes/: 피드, 프로필, 채팅 화면 추가

#### 🏋️ 헬스케어/피트니스 앱
- ARCHITECTURE.md: 센서 연동, 데이터 추적 구조 추가
- DESIGN.md: 차트, 통계 시각화 가이드 추가
- wireframes/: 대시보드, 운동 기록 화면 추가

#### 📚 교육 앱
- ARCHITECTURE.md: 콘텐츠 관리, 진도 추적 추가
- TESTDATA.md: 강의 콘텐츠, 퀴즈 데이터 추가
- wireframes/: 강의 목록, 학습 화면 추가

## 모범 사례

### ✅ DO
- 모든 중요 결정사항을 문서화
- 정기적으로 PROGRESS.md 업데이트
- 코드 변경 시 관련 문서도 함께 수정
- 이슈와 해결방법을 NOTE.md에 기록

### ❌ DON'T
- 문서 없이 큰 변경사항 적용
- 오래된 정보를 문서에 방치
- 복잡한 구조를 문서화하지 않고 진행
- 테스트 계획 없이 개발

## 버전 관리
- 문서도 코드와 함께 Git으로 관리
- 주요 변경사항은 커밋 메시지에 명시
- 릴리즈 시점에 문서 전체 검토

## 팀 협업
1. **개발자**: ARCHITECTURE.md, PROGRESS.md 중점 관리
2. **디자이너**: DESIGN.md, wireframes/ 관리
3. **QA**: TESTPLAN.md, TESTDATA.md 관리
4. **PM**: CLAUDE.md, PROGRESS.md 모니터링

## 문제 해결
문서 사용 중 문제가 있다면:
1. NOTE.md의 트러블슈팅 섹션 확인
2. 각 문서의 예시 참고
3. 팀 내 문서 담당자에게 문의

## 추가 리소스
- [Flutter 공식 문서](https://flutter.dev/docs)
- [Material Design 가이드라인](https://material.io/design)
- [Flutter 앱 아키텍처 가이드](https://flutter.dev/docs/development/data-and-backend/state-mgmt/intro)

---

**이 문서 세트를 사용하여 체계적이고 효율적인 Flutter 앱 개발을 시작하세요!**

*마지막 업데이트: 2024*