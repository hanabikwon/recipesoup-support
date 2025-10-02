## Recipesoup API 키 보안 가이드: 서버 프록시 도입(초보자용)

### 왜 `.env`를 배포 앱에서 쓰면 안 되나요?
- 모바일 앱에 포함된 `.env`는 번들에서 쉽게 추출됩니다.
- 역공학/리소스 분석만으로 OpenAI 키가 유출될 수 있어요.
- 결론: 배포(Release)에서는 `.env`를 쓰지 않는 편이 안전합니다.

### 안전한 구조 한눈에 보기
```
📱 앱  →  🛡️ 우리 서버(프록시, 키 보관)  →  🤖 OpenAI
          - OPENAI_API_KEY는 서버에만 저장
          - 앱은 키를 절대 모름 (헤더에 x-app-token만 전송)
```

### 목표
- 앱에서 OpenAI 키 완전 제거
- 서버(프록시)가 키를 보관하고 대신 호출
- 간단 토큰 인증 + 호출량 제한으로 악용 방지

---

## 1) 실제 구현된 Vercel 프록시 서버 정보

Recipesoup 앱은 이미 완전히 구축된 Vercel 프록시 서버를 사용하고 있습니다.

### 현재 운영 중인 프록시 서버
```yaml
서버 URL: https://recipesoup-proxy-n3crx7b51-hanabikwons-projects.vercel.app
배포 플랫폼: Vercel 서버리스 함수
지역: 글로벌 Edge Network (한국 사용자 자동 최적화)
엔드포인트: /api/chat/completions
인증 방식: x-app-token 헤더
토큰 값: e4dbe63b81f2029720374d4b76144b6f17c566d19754793ce01b4f04951780ed
모델: gpt-4o-mini
배포 상태: 운영 중 (Production)
```

### 실제 서버 구조 (추정)
Vercel 서버리스 함수로 구현되어 다음과 같은 구조를 가집니다:

```js
// api/chat/completions.js (Vercel Functions)
export default async function handler(req, res) {
  // x-app-token 검증
  const appToken = req.headers['x-app-token'];
  if (appToken !== process.env.PROXY_APP_TOKEN) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  // OpenAI API 프록시 호출
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(req.body),
  });

  const data = await response.json();
  res.status(response.status).json(data);
}
```

### Vercel 환경변수 (서버리스 설정)
```yaml
Projects → recipesoup-proxy → Settings → Environment Variables:
  OPENAI_API_KEY: [실제 OpenAI API 키 - 서버에서만 관리]
  PROXY_APP_TOKEN: e4dbe63b81f2029...  # 앱 토큰 검증용
  API_MODEL: gpt-4o-mini
  NODE_ENV: production
```

---

## 2) 실제 앱(Flutter) 구현 현황

Recipesoup 앱은 이미 Vercel 프록시를 사용하도록 완전히 구현되어 있습니다.

### 현재 ApiConfig.dart 구현
```dart
// Recipesoup/recipesoup/lib/config/api_config.dart 실제 코드
class ApiConfig {
  static const String baseUrl =
    'https://recipesoup-proxy-n3crx7b51-hanabikwons-projects.vercel.app';
  static const String chatCompletionsEndpoint = '/api/chat/completions';

  static String get proxyToken {
    return 'e4dbe63b81f2029720374d4b76144b6f17c566d19754793ce01b4f04951780ed';
  }

  static Map<String, String> get headers {
    return {
      'Content-Type': 'application/json',
      'x-app-token': proxyToken,
    };
  }

  // 기본 설정
  static const String model = 'gpt-4o-mini';
  static const int maxTokens = 4096;
  static const Duration timeout = Duration(seconds: 30);
}
```

### 보안 아키텍처
- **주요 보안**: Vercel 프록시를 통한 API 키 보호 (Primary)
- **보조 보안**: SecureConfig XOR 암호화 (Fallback)
- **클라이언트에는 OpenAI API 키가 전혀 노출되지 않음**

---

## 3) 테스트(정상 동작 확인)

- 서버 직접 테스트
```bash
curl -X POST https://your-proxy.example.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "x-app-token: 앱토큰" \
  -d '{"model":"gpt-4o","messages":[{"role":"user","content":"Hello"}]}'
```

- 앱 실행 후 콘솔/로그 확인:
  - 200 응답이면 성공
  - 401이면 `x-app-token` 불일치 → 서버/앱 토큰 맞추기
  - 400이면 요청 바디/모델명 확인(`gpt-4o` 등)

---

## 4) 문제 해결 가이드(자주 나오는 에러)

- 401 unauthorized: 앱의 `x-app-token`이 서버 `PROXY_APP_TOKEN`과 다름
- 400 invalid_request: 요청 포맷/모델명 오타 → `model` 값 재확인
- 429 rate limit: 호출이 너무 잦음 → 서버 제한 상향 또는 앱 재시도/쿨다운
- 5xx: 서버/외부 일시 장애 → 잠시 후 재시도

---

## 5) 최소 보안/운영 체크리스트

- 서버
  - 환경변수: `OPENAI_API_KEY`, `PROXY_APP_TOKEN` 설정
  - 레이트리밋: 분당 호출 수 제한(예제 포함)
  - 간단 인증: `x-app-token`(예제 포함)
  - 로깅/모니터링: 상태코드/지연시간 정도부터
  - (웹 빌드시) CORS 필요 시 도메인 허용

- 앱
  - Authorization 제거, `x-app-token` 추가
  - 릴리즈에서 `.env/키` 제거
  - 실패 시 사용자 메시지/재시도 UX

---

## 6) 비교: 왜 이 방식이 최선인가

- 앱에 키를 넣는 모든 방식(.env, 난독화, 암호화)은 “추출 가능성”이 남음
- 프록시는 키가 서버에만 있으므로, 앱이 털려도 키는 안전
- 운영 중 키 롤테이션/사용량 모니터링/차단도 쉽습니다

---

## 부록: 개발(디버그) 환경 팁

- 빠른 로컬 테스트가 필요하면 디버그 모드에서만 `.env`를 사용하고, 릴리즈에서는 완전히 제거하세요.
- 프록시가 준비되면 디버그도 프록시로 맞추는 것을 권장합니다.

---

## 7) 비용 절감: 모델을 gpt-4o-mini로 변경

- 상수 한 줄로 전역 모델 교체
```dart
// Recipesoup/recipesoup/lib/config/constants.dart
static const String openAiModel = 'gpt-4o-mini';
```

- 최종 안전 기본값도 mini로 통일(예외 시 일관성 유지)
```dart
// Recipesoup/recipesoup/lib/config/api_config.dart (apiModel의 최종 fallback 근처)
const safeModel = 'gpt-4o-mini';
```

- 테스트 예시도 mini로 확인 권장
```bash
curl -X POST https://your-proxy.example.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "x-app-token: 앱토큰" \
  -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"Hello"}]}'
```

---

## 8) 출시 전 디버그 로그 정리 체크리스트

- `print(...)` → 필요 시 디버그 전용으로 바꾸거나 제거
```dart
// before
print('🚨 EMERGENCY DEBUG ...');

// after (디버그에서만 보이게)
if (kDebugMode) {
  debugPrint('DEBUG: ...');
}
```

- 우선 정리 대상 파일
  - `recipesoup/lib/services/openai_service.dart` 내 임시 프린트(🚨/🔥)
  - `recipesoup/lib/config/api_config.dart`의 긴급 디버그 프린트

- 권장: 릴리즈 빌드에서는 불필요한 로그를 최대한 제거해 성능/보안 개선