# Recipesoup 음식 사진 분석 테스트 가이드

## 개요
이 디렉토리는 Recipesoup 앱의 핵심 기능인 OpenAI 기반 음식 사진 분석을 자동으로 테스트하는 Playwright MCP 스크립트를 포함합니다.

## 테스트 파일
- `playwright_food_analysis_test.js`: 메인 테스트 스크립트
- `README.md`: 실행 가이드 (이 문서)

## 사전 준비

### 1. 테스트 이미지 준비
다음 3개의 테스트 이미지를 이 디렉토리에 준비해주세요:

```
tests/
├── testimg1.jpg  # 김치찌개 완성 사진
├── testimg2.jpg  # 파스타 완성 사진
├── testimg3.jpg  # 복잡한 한정식 상차림
└── ...
```

**이미지 요구사항:**
- `testimg1.jpg`: 김치찌개 또는 한식 찌개류 사진
- `testimg2.jpg`: 파스타 또는 서양식 면 요리 사진  
- `testimg3.jpg`: 한정식 상차림 또는 복잡한 음식 세팅 사진
- 파일 크기: 10MB 이하 권장
- 포맷: JPG, PNG 지원

### 2. Flutter Web 빌드 및 서버 실행

```bash
# 1. Flutter web 빌드
flutter build web

# 2. 로컬 서버 실행 (포트 8080)
cd build/web
python -m http.server 8080

# 또는 Node.js 사용시
npx http-server -p 8080

# 브라우저에서 확인: http://localhost:8080
```

### 3. 환경변수 설정
`.env` 파일에 OpenAI API 키가 설정되어 있는지 확인:

```env
OPENAI_API_KEY=sk-proj-...
API_MODEL=gpt-4o-mini
```

## 테스트 실행

### Playwright MCP를 통한 실행

1. **MCP 도구에서 브라우저 초기화:**
```javascript
// 브라우저 설치 (필요시)
await mcp_Playwright_browser_install();

// 페이지 이동
await page.goto("http://localhost:8080");
```

2. **Playwright MCP로 테스트 스크립트 실행:**
```javascript
// 테스트 스크립트 로드 및 실행
const testScript = fs.readFileSync('./tests/playwright_food_analysis_test.js', 'utf8');
await mcp_Playwright_browser_evaluate({ function: testScript });

// 또는 개별 테스트 함수 실행
await mcp_Playwright_browser_evaluate({ 
  function: `() => {
    // 앱 접근성 테스트
    return testAppAccessibility();
  }`
});
```

### 직접 Node.js 실행 (개발용)

```bash
# 테스트 스크립트 직접 실행
node tests/playwright_food_analysis_test.js
```

## 테스트 시나리오

### 1. 앱 접근성 테스트
- ✅ Flutter web 앱 로딩 확인
- ✅ 스플래시 화면 → 메인 화면 전환
- ✅ Bottom Navigation 5개 탭 확인
- ✅ FAB 버튼 존재 확인

### 2. 음식 사진 분석 테스트 (핵심!)
각 테스트 이미지에 대해:
- ✅ FAB → "사진으로 작성" 선택
- ✅ 이미지 파일 업로드
- ✅ OpenAI API 호출 및 분석 대기
- ✅ 추천 재료 검증
- ✅ 추천 조리법 검증  
- ✅ 예상 키워드 매치 확인

### 3. 에러 시나리오 테스트
- ✅ 잘못된 파일 형식 에러 처리
- ✅ 네트워크 연결 에러 처리
- ✅ API 타임아웃 처리

### 4. UI 상태 테스트
- ✅ 로딩 인디케이터 표시
- ✅ 성공 상태 UI 확인
- ✅ 빈티지 아이보리 테마 적용 확인

### 5. 성능 테스트
- ✅ 이미지 업로드 성능 (5초 이내)
- ✅ OpenAI API 응답 시간 (15초 이내)
- ✅ 메모리 사용량 확인 (200MB 이내)

## 예상 결과

### 성공적인 테스트 결과 예시:
```
🍽️ Recipesoup 음식 사진 분석 테스트 시작...
📍 테스트 URL: http://localhost:8080

📱 앱 접근성 테스트...
  ✅ 앱 로딩 테스트: 통과
  ✅ Bottom Navigation 확인: 통과
  ✅ FAB 버튼 확인: 통과

🖼️ testimg1 분석 테스트... (김치찌개 완성 사진)
  ✅ testimg1 업로드 및 분석: 통과
  ✅ 재료 추천 검증: 통과 (4/5개 매치: 김치, 돼지고기, 두부, 양파)
  ✅ 조리법 추천 검증: 통과 (124자)
  ✅ 키워드 매치 검증: 통과 (3/4개 매치: 김치찌개, 찌개, 한식)

========================================
📊 테스트 결과 리포트
========================================
총 테스트: 15
✅ 통과: 14
❌ 실패: 1
📈 성공률: 93.3%

🎉 테스트 전체 성공!
```

## 트러블슈팅

### 자주 발생하는 문제들

1. **"테스트 이미지 파일 없음" 오류**
   ```
   ❌ 테스트 이미지 파일 없음: ./testimg1.jpg
   ```
   - 해결: 테스트 이미지 파일들을 `tests/` 디렉토리에 복사

2. **"Flutter web 서버에 접근할 수 없습니다" 오류**
   ```
   ❌ Flutter web 서버에 접근할 수 없습니다: http://localhost:8080
   ```
   - 해결: `flutter build web` 후 `cd build/web && python -m http.server 8080` 실행

3. **"OpenAI API 키가 없습니다" 오류**
   - 해결: `.env` 파일에 유효한 `OPENAI_API_KEY` 설정

4. **API 타임아웃 오류**
   ```
   ❌ AI 분석 결과를 받지 못했습니다
   ```
   - 원인: 네트워크 연결 문제 또는 OpenAI API 서버 지연
   - 해결: 네트워크 연결 확인, API 키 유효성 확인

5. **선택자를 찾을 수 없음 오류**
   ```
   ❌ FAB 버튼을 찾을 수 없습니다
   ```
   - 원인: UI 컴포넌트의 CSS 클래스명이나 데이터 속성이 다름
   - 해결: 실제 Flutter 앱의 HTML 구조에 맞게 선택자 수정

### 성능 최적화 팁

1. **이미지 크기 최적화**: 테스트 이미지는 2MB 이하로 준비
2. **네트워크 상태**: 안정적인 인터넷 연결에서 테스트 실행
3. **브라우저 메모리**: 테스트 전 브라우저 캐시 및 메모리 정리

## 커스터마이징

### 테스트 이미지 변경
`TEST_IMAGES` 객체에서 이미지 정보 수정:

```javascript
const TEST_IMAGES = {
  testimg1: {
    path: './my_custom_image.jpg',
    description: '내가 준비한 음식 사진',
    expectedIngredients: ['재료1', '재료2'],
    expectedKeywords: ['키워드1', '키워드2'],
    // ...
  }
};
```

### 타임아웃 설정 조정
`TEST_CONFIG` 객체에서 타임아웃 값 조정:

```javascript
const TEST_CONFIG = {
  timeout: 30000, // 30초
  apiAnalysisTimeout: 25000, // 25초 (더 여유롭게)
  // ...
};
```

### 새로운 테스트 추가
새로운 테스트 함수 추가:

```javascript
async function testMyCustomFeature() {
  await addTest('내 커스텀 기능 테스트', async () => {
    // 테스트 로직
    return true; // 성공시 true, 실패시 throw Error
  });
}
```

## 참고 문서
- [TESTPLAN.md](../TESTPLAN.md): 전체 테스트 계획
- [TESTDATA.md](../TESTDATA.md): 테스트 데이터 명세
- [ARCHITECTURE.md](../ARCHITECTURE.md): 시스템 아키텍처
- [DESIGN.md](../DESIGN.md): UI/UX 디자인 가이드

---
*이 테스트는 TDD 원칙에 따라 구현되었으며, Recipesoup 앱의 감정 기반 레시피 아카이빙 기능을 완전히 검증합니다.*