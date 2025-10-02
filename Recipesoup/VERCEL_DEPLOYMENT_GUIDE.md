# Vercel 프록시 배포 가이드

## 개요
Recipesoup 앱의 OpenAI API 보안 강화 및 Rate Limiting을 위한 Vercel 서버리스 함수 배포 가이드입니다.

## 전제 조건
- Vercel 계정 (https://vercel.com)
- Node.js 18+ 설치
- Vercel CLI 설치: `npm install -g vercel`

## 1. Vercel 프로젝트 초기 설정

### 1.1 Vercel CLI 로그인
```bash
vercel login
```

### 1.2 프로젝트 링크
```bash
cd /Users/hanabi/Downloads/practice/Recipesoup
vercel link
```

프롬프트에서:
- **Set up and deploy?** → Yes
- **Which scope?** → 본인 계정 선택
- **Link to existing project?** → No (첫 배포시)
- **Project name?** → `recipesoup-proxy`
- **In which directory?** → `./` (현재 디렉토리)

## 2. Vercel KV (Redis) 설정

### 2.1 Vercel 대시보드에서 KV 스토어 생성
1. https://vercel.com/dashboard 접속
2. 본인 프로젝트 (`recipesoup-proxy`) 선택
3. **Storage** 탭 클릭
4. **Create Database** → **KV** 선택
5. Database name: `recipesoup-rate-limit`
6. Region: `Seoul, South Korea (icn1)` 선택 (한국 사용자 최적화)
7. **Create** 클릭

### 2.2 KV 연결
- Storage 탭에서 생성된 KV를 프로젝트에 연결
- **Connect to Project** 클릭
- `recipesoup-proxy` 선택 후 **Connect**

## 3. 환경변수 설정

### 3.1 Vercel 대시보드에서 환경변수 추가
1. 프로젝트 선택 → **Settings** 탭
2. **Environment Variables** 클릭
3. 다음 환경변수 추가:

#### OPENAI_API_KEY (Required)
- **Key**: `OPENAI_API_KEY`
- **Value**: `sk-proj-...` (실제 OpenAI API 키)
- **Environment**: Production, Preview, Development 모두 체크
- **Add** 클릭

#### PROXY_APP_TOKEN (Required)
- **Key**: `PROXY_APP_TOKEN`
- **Value**: `e4dbe63b81f2029720374d4b76144b6f17c566d19754793ce01b4f04951780ed`
- **Environment**: Production, Preview, Development 모두 체크
- **Add** 클릭

### 3.2 환경변수 검증
```bash
vercel env ls
```

예상 출력:
```
OPENAI_API_KEY          production, preview, development
PROXY_APP_TOKEN         production, preview, development
KV_REST_API_URL         production, preview, development (자동 생성)
KV_REST_API_TOKEN       production, preview, development (자동 생성)
```

## 4. 로컬 테스트

### 4.1 의존성 설치
```bash
npm install
```

### 4.2 로컬 개발 서버 실행
```bash
vercel dev
```

예상 출력:
```
Vercel CLI 33.x.x
> Ready! Available at http://localhost:3000
```

### 4.3 로컬 테스트 실행
```bash
# 터미널에서 테스트
curl -X POST http://localhost:3000/api/chat \
  -H "Content-Type: application/json" \
  -H "x-app-token: e4dbe63b81f2029720374d4b76144b6f17c566d19754793ce01b4f04951780ed" \
  -d '{
    "model": "gpt-4o-mini",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 50
  }'
```

예상 응답:
```json
{
  "id": "chatcmpl-...",
  "choices": [...]
}
```

응답 헤더 확인:
```
X-RateLimit-Limit: 50
X-RateLimit-Remaining: 49
X-RateLimit-Reset: 1234567890
```

## 5. Production 배포

### 5.1 프로덕션 배포
```bash
vercel --prod
```

배포 완료 후 URL 출력:
```
✅ Production: https://recipesoup-proxy-xxxx.vercel.app
```

### 5.2 배포 검증
```bash
# Production URL로 테스트
curl -X POST https://recipesoup-proxy-xxxx.vercel.app/api/chat \
  -H "Content-Type: application/json" \
  -H "x-app-token: e4dbe63b81f2029720374d4b76144b6f17c566d19754793ce01b4f04951780ed" \
  -d '{
    "model": "gpt-4o-mini",
    "messages": [{"role": "user", "content": "테스트"}],
    "max_tokens": 50
  }'
```

## 6. Rate Limiting 테스트

### 6.1 정상 요청 (50회 이하)
```bash
for i in {1..45}; do
  echo "Request $i"
  curl -s -X POST https://recipesoup-proxy-xxxx.vercel.app/api/chat \
    -H "Content-Type: application/json" \
    -H "x-app-token: e4dbe63b81f2029720374d4b76144b6f17c566d19754793ce01b4f04951780ed" \
    -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"Hi"}],"max_tokens":10}' \
    | jq -r '.choices[0].message.content'
  sleep 1
done
```

### 6.2 Rate Limit 초과 테스트 (51회째)
```bash
# 51번째 요청
curl -X POST https://recipesoup-proxy-xxxx.vercel.app/api/chat \
  -H "Content-Type: application/json" \
  -H "x-app-token: e4dbe63b81f2029720374d4b76144b6f17c566d19754793ce01b4f04951780ed" \
  -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"Hi"}],"max_tokens":10}'
```

예상 응답 (429 Error):
```json
{
  "error": "요리 분석을 너무 많이 하셨어요! 🐰\n잠시 휴식 후 다시 시도해주세요.",
  "retryAfter": 3600,
  "remaining": 0
}
```

## 7. 모니터링 및 로깅

### 7.1 Vercel 대시보드에서 로그 확인
1. https://vercel.com/dashboard 접속
2. `recipesoup-proxy` 프로젝트 선택
3. **Logs** 탭 클릭

로그 예시:
```
[2025-10-02T12:34:56.789Z] [REQUEST] IP: 123.45.67.89, Method: POST
[2025-10-02T12:34:56.789Z] [RATE_LIMIT] IP: 123.45.67.89, Count: 1/50
[2025-10-02T12:34:57.123Z] [SUCCESS] IP: 123.45.67.89, Duration: 334ms, Cost: ~$0.0001
```

### 7.2 Rate Limit 통계 확인
Vercel KV 대시보드에서 확인:
- `stats:daily:YYYY-MM-DD:requests` - 일일 총 요청 수
- `stats:daily:YYYY-MM-DD:blocked` - 차단된 요청 수
- `stats:daily:YYYY-MM-DD:success` - 성공한 요청 수
- `stats:daily:YYYY-MM-DD:errors` - 에러 발생 수

## 8. Flutter 앱 설정 업데이트

### 8.1 api_config.dart 수정
```dart
// recipesoup/lib/config/api_config.dart
class ApiConfig {
  // Vercel 프록시 URL로 변경
  static const String baseUrl = 'https://recipesoup-proxy-xxxx.vercel.app';
  static const String chatCompletionsEndpoint = '/api/chat';

  // Proxy Token (실제 OpenAI API 키는 Vercel에만 존재)
  static const String proxyToken = 'e4dbe63b81f2029720374d4b76144b6f17c566d19754793ce01b4f04951780ed';

  /// API 요청 헤더
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'x-app-token': proxyToken,
  };
}
```

### 8.2 Flutter 앱 재빌드 및 테스트
```bash
cd /Users/hanabi/Downloads/practice/Recipesoup/recipesoup
flutter clean
flutter pub get
flutter run -d chrome  # 웹 테스트
# 또는
flutter run -d 00008101-001378E41A28001E  # iPhone 실기 테스트
```

## 9. 트러블슈팅

### 9.1 "Unauthorized" 에러
**원인**: x-app-token이 잘못되었거나 누락
**해결**:
```dart
// Flutter api_config.dart에서 토큰 확인
static const String proxyToken = 'e4dbe63b81f2029720374d4b76144b6f17c566d19754793ce01b4f04951780ed';
```

Vercel 환경변수 `PROXY_APP_TOKEN`이 동일한지 확인

### 9.2 "OpenAI API 오류" 에러
**원인**: OPENAI_API_KEY가 잘못되었거나 만료됨
**해결**:
1. OpenAI 계정에서 유효한 API 키 확인
2. Vercel 대시보드 → Settings → Environment Variables → OPENAI_API_KEY 업데이트
3. 재배포: `vercel --prod`

### 9.3 Rate Limit이 작동하지 않음
**원인**: Vercel KV가 제대로 연결되지 않음
**해결**:
1. Vercel 대시보드 → Storage 탭 → KV 연결 상태 확인
2. 환경변수 `KV_REST_API_URL`, `KV_REST_API_TOKEN` 존재 확인
3. 재배포: `vercel --prod`

### 9.4 CORS 에러
**원인**: Flutter 웹에서 Cross-Origin 요청 차단
**해결**: api/chat.js 파일의 CORS 헤더 확인
```javascript
res.setHeader('Access-Control-Allow-Origin', '*');
res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
res.setHeader('Access-Control-Allow-Headers', 'Content-Type, x-app-token');
```

## 10. 성능 최적화

### 10.1 Region 설정
`vercel.json`에서 한국 리전 사용:
```json
{
  "regions": ["icn1"]  // Seoul, South Korea
}
```

### 10.2 메모리 및 타임아웃
```json
{
  "functions": {
    "api/**/*.js": {
      "memory": 1024,
      "maxDuration": 30
    }
  }
}
```

### 10.3 캐싱 전략
현재 Rate Limiting용 KV만 사용 중. 향후 응답 캐싱 추가 가능.

## 11. 비용 관리

### 11.1 Vercel 무료 티어
- Serverless Functions: 100GB-hours/month
- KV Requests: 30,000 reads + 1,000 writes/day
- Bandwidth: 100GB/month

### 11.2 예상 사용량
- Rate Limit: 시간당 50회 × 24시간 × 30일 = 36,000 요청/월
- 사용자 100명 기준: 3.6M 요청/월 → 무료 티어 초과 가능

### 11.3 모니터링
Vercel 대시보드 → Usage 탭에서 사용량 추적

## 12. 보안 체크리스트

- [x] OpenAI API 키는 Vercel 환경변수에만 존재
- [x] x-app-token 검증으로 앱 전용 접근 제어
- [x] Rate Limiting (50/hour)으로 남용 방지
- [x] CORS 설정으로 허용된 도메인만 접근
- [x] 로그에 민감 정보 노출 안 됨
- [x] 에러 메시지에 내부 정보 누출 안 됨

## 13. 배포 체크리스트

배포 전 확인 사항:
- [ ] Vercel 계정 및 프로젝트 생성
- [ ] Vercel KV 스토어 생성 및 연결
- [ ] 환경변수 설정 (OPENAI_API_KEY, PROXY_APP_TOKEN)
- [ ] 로컬 테스트 성공 (`vercel dev`)
- [ ] Production 배포 (`vercel --prod`)
- [ ] Rate Limiting 테스트 (50회 초과)
- [ ] Flutter api_config.dart URL 업데이트
- [ ] Flutter 앱 재빌드 및 테스트
- [ ] 모니터링 대시보드 확인
- [ ] 보안 체크리스트 완료

## 14. 추가 리소스

- **Vercel 문서**: https://vercel.com/docs
- **Vercel KV 문서**: https://vercel.com/docs/storage/vercel-kv
- **Vercel CLI 가이드**: https://vercel.com/docs/cli
- **OpenAI API 문서**: https://platform.openai.com/docs

---

**작성일**: 2025-10-02
**버전**: 1.0.0
**작성자**: Recipesoup Team
