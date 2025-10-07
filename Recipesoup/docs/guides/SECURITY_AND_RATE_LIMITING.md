# Recipesoup 보안 아키텍처 및 Rate Limiting 설계

## 🚨 현재 보안 이슈 분석

### 발견된 문제점

#### 1. 문서와 실제 구현의 심각한 불일치

**문서상 주장 (ARCHITECTURE.md, CLAUDE.md, PROGRESS.md):**
```yaml
# "Vercel 프록시를 통한 OpenAI API 연동 - 보안 강화"
PROXY_BASE_URL: https://recipesoup-proxy-n3crx7b51-hanabikwons-projects.vercel.app
PROXY_TOKEN: e4dbe63b81f2029720374d4b76144b6f17c566d19754793ce01b4f04951780ed
AUTHENTICATION: x-app-token 헤더 기반
```

**실제 코드 (api_config.dart:10):**
```dart
static const String baseUrl = 'https://api.openai.com/v1';  // ❌ OpenAI 직접 호출!
```

#### 2. 현재 보안 구조의 위험성

```
[Flutter 앱]
   ↓ (내장된 OpenAI API Key - .env 파일)
   ↓
[https://api.openai.com/v1] ← 직접 호출
```

**치명적 보안 취약점:**
1. ❌ **API 키 앱 번들에 포함**: `.env` 파일이 빌드 시 앱에 포함됨
2. ❌ **디컴파일 위험**: 누구나 앱을 역공학하여 API 키 탈취 가능
3. ❌ **무제한 API 사용**: 키가 유출되면 OpenAI 계정의 모든 비용 청구
4. ❌ **앱스토어 심사 위험**: Apple이 하드코딩된 API 키로 거부 가능
5. ❌ **Rate Limiting 없음**: 앱 레벨에서 API 호출 제한 불가

---

## ✅ 올바른 Vercel 프록시 아키텍처

### 보안 구조

```
[Flutter 앱]
   ↓ (안전한 Proxy Token)
   ↓ x-app-token: e4dbe63b81f2029720374d4b76144b6f17c566d19754793ce01b4f04951780ed
   ↓
[Vercel Serverless Function]
   ↓ (진짜 OpenAI API Key - 환경변수)
   ↓ Authorization: Bearer sk-proj-xxx...
   ↓
[https://api.openai.com/v1]
```

### 보안 이점

1. ✅ **API 키 완전 분리**: 실제 OpenAI 키는 Vercel 서버에만 존재
2. ✅ **디컴파일 방어**: 앱에는 Proxy Token만 있어 유출 위험 최소화
3. ✅ **Rate Limiting 가능**: Vercel에서 IP/토큰 기반 호출 제한 가능
4. ✅ **모니터링 가능**: 모든 API 호출을 Vercel 레벨에서 로깅/추적
5. ✅ **앱스토어 안전**: 실제 API 키가 앱 코드에 없음

---

## 🚦 Rate Limiting 설계

### 선택된 규칙: 시간당 50회

#### 규칙 선정 이유

**정상 사용자 패턴 분석:**
```
일반 사용자:
- 하루 3-5개 레시피
- 시간당 최대 5개
→ 50회 제한에 10% 사용 ✅

주말 요리광:
- 2시간 동안 15개 업로드
- 시간당 평균 7-8개
→ 50회 제한에 15% 사용 ✅

파티 준비 (극단):
- 30분에 20개 업로드
- 시간당 환산 40개
→ 50회 제한에 80% 사용 (여전히 가능) ✅
```

**공격자 차단 효과:**
```
공격자 시나리오:
- 1시간에 10,000번 시도
- 결과: 50번만 성공, 9,950번 차단 ✅
- 비용: 50회 × $0.0001 = $0.005 (0.5센트/시간)
- 하루 24시간 공격: $0.12 (12센트)
- 한 달: $3.60 (완전히 감당 가능) ✅
```

#### 왜 분당 제한보다 시간당 제한이 나은가?

**사용자는 몰아서 사용:**
- 파티 준비: 30분 안에 15-20개 업로드
- 주말 요리: 2-3시간에 걸쳐 10-15개
- 일괄 업로드: 10분 안에 5-10개

**분당 10회 제한의 문제:**
```
파티 준비 시나리오:
- 20개 업로드 시도
- 10개 업로드 → 1분 대기 → 10개 더
- 총 2분+ 소요 (실제론 30초면 될 것을)
→ 사용자: "왜 갑자기 안 돼?" ⚠️
```

**시간당 50회 제한의 장점:**
```
파티 준비 시나리오:
- 20개 연속 업로드 → ✅ 모두 성공
- 30초에 완료
→ 사용자 경험: 매끄러움 ✅
```

### 예상 비용

```yaml
사용자당 최대:
  하루: 50회 (현실적으론 10-20회)
  월: 1,500회 (50 × 30일)
  비용: $0.15/월/사용자

전체 앱 (1,000명 기준):
  최대: $150/월
  현실적: $30-50/월

공격자 피해:
  시간당: $0.005
  하루: $0.12
  월: $3.60 ✅ 완전히 감당 가능
```

---

## 👤 사용자 경험 설계

### Rate Limit 도달 시 안내 메시지

**최종 선택: 친절한 메시지 🐰**

```dart
// Flutter 다이얼로그
AlertDialog(
  title: Row(
    children: [
      Text('잠시만 기다려주세요'),
      SizedBox(width: 8),
      Text('🐰'),
    ],
  ),
  content: Text('요리 분석을 너무 많이 하셨어요! 🐰\n잠시 휴식 후 다시 시도해주세요.'),
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text('확인'),
    ),
  ],
)
```

**다른 옵션들:**
```
레벨 1 (간단): "시간당 사용 한도를 초과했습니다. 잠시 후 다시 시도해주세요."
레벨 2 (상세): "시간당 사용 한도(50회)를 초과했습니다. 1시간 후 다시 이용하실 수 있습니다."
레벨 3 (친절): "요리 분석을 너무 많이 하셨어요! 🐰 잠시 휴식 후 다시 시도해주세요." ✅
```

### 동작 흐름

```
1. 사용자가 사진 분석 버튼 클릭
   ↓
2. Flutter 앱 → Vercel 프록시 호출
   ↓
3. Vercel에서 Rate Limit 체크
   ↓
4-a. 50회 이내: ✅ OpenAI 호출 → 결과 반환
4-b. 50회 초과: ❌ 429 에러 + 안내 메시지 반환
   ↓
5. Flutter 앱에서 에러 처리
   - 429 에러 → 다이얼로그로 안내
   - "요리 분석을 너무 많이 하셨어요! 🐰"
```

---

## 📊 모니터링 시스템 설계

### 1. 실시간 로깅 (Vercel 내장)

**로깅 항목:**
```javascript
// 요청 시작
console.log(`[${timestamp}] Request started`, {
  ip: clientIp,
  method: req.method,
  userAgent: req.headers['user-agent']
});

// Rate Limit 현황
console.log(`[Rate Limit] IP: ${clientIp}, Count: ${count}/50`);

// Rate Limit 차단 (⚠️ 주의 필요)
console.warn(`[BLOCKED] IP: ${clientIp} exceeded rate limit (${count}/50)`);

// 성공
console.log(`[SUCCESS] IP: ${clientIp}, Duration: ${duration}ms, Cost: ~$0.0001`);

// 에러
console.error(`[ERROR] IP: ${clientIp}`, {
  error: error.message,
  stack: error.stack
});
```

**확인 방법:**
```
Vercel Dashboard → Your Project → Logs
실시간으로 모든 로그 확인 가능
```

### 2. 통계 집계 (Redis/KV)

**일일 통계:**
```javascript
// 통계 카운터
await kv.incr(`stats:daily:${today}:requests`);      // 총 요청 수
await kv.incr(`stats:daily:${today}:success`);       // 성공 요청
await kv.incr(`stats:daily:${today}:blocked`);       // 차단 요청
await kv.incr(`stats:daily:${today}:hour:${hour}`);  // 시간별 분포
```

**모니터링 대시보드 (선택):**
```javascript
// api/stats.js - 통계 조회 엔드포인트
export default async function handler(req, res) {
  const today = new Date().toISOString().split('T')[0];

  const stats = {
    total: await kv.get(`stats:daily:${today}:requests`) || 0,
    success: await kv.get(`stats:daily:${today}:success`) || 0,
    blocked: await kv.get(`stats:daily:${today}:blocked`) || 0,
    hourly: {}
  };

  // 시간별 통계
  for (let h = 0; h < 24; h++) {
    stats.hourly[h] = await kv.get(`stats:daily:${today}:hour:${h}`) || 0;
  }

  return res.json(stats);
}
```

**확인 예시:**
```bash
curl https://recipesoup-proxy-xxx.vercel.app/api/stats

# 응답:
{
  "total": 1234,
  "success": 1150,
  "blocked": 84,
  "hourly": {
    "0": 12,
    "1": 5,
    "2": 3,
    ...
    "14": 89,
    ...
  }
}
```

### 3. 모니터링 지표

**추적할 항목:**
```yaml
성능 지표:
  - 평균 응답 시간 (Duration)
  - 성공률 (Success / Total)
  - 에러율 (Error / Total)

보안 지표:
  - Rate Limit 차단률 (Blocked / Total)
  - 의심스러운 IP (Blocked > 10)
  - 시간대별 트래픽 패턴

비용 지표:
  - 시간당 API 호출 수
  - 일일 예상 비용
  - 월간 예상 비용
```

### 4. 알림 설정 (선택)

**이상 트래픽 감지:**
```javascript
// 차단 횟수가 너무 많으면 알림
if (blockedCount > 100) {
  // 이메일 또는 Slack 알림
  await sendAlert({
    type: 'HIGH_RATE_LIMIT_BLOCKS',
    ip: clientIp,
    count: blockedCount,
    timestamp: new Date()
  });
}
```

---

## 🛠️ 구현 코드

### 1. Vercel 서버리스 함수

**파일 위치:** `api/chat.js` (Vercel 프로젝트 루트)

```javascript
// api/chat.js
import { kv } from '@vercel/kv';

export default async function handler(req, res) {
  const startTime = Date.now();
  const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || 'unknown';
  const timestamp = new Date().toISOString();

  try {
    // 1. Token 검증
    const appToken = req.headers['x-app-token'];
    if (!appToken || appToken !== process.env.PROXY_APP_TOKEN) {
      console.warn(`[${timestamp}] [UNAUTHORIZED] IP: ${clientIp} - Invalid token`);
      return res.status(401).json({ error: 'Unauthorized' });
    }

    console.log(`[${timestamp}] [REQUEST] IP: ${clientIp}, Method: ${req.method}`);

    // 2. Rate Limiting - 시간당 50회
    const rateLimitKey = `rate:${clientIp}`;
    const count = await kv.incr(rateLimitKey);

    if (count === 1) {
      await kv.expire(rateLimitKey, 3600); // 1시간 후 초기화
    }

    console.log(`[${timestamp}] [RATE_LIMIT] IP: ${clientIp}, Count: ${count}/50`);

    if (count > 50) {
      console.warn(`[${timestamp}] [BLOCKED] IP: ${clientIp} exceeded rate limit (${count}/50)`);

      // 통계 업데이트
      const today = new Date().toISOString().split('T')[0];
      await kv.incr(`stats:daily:${today}:blocked`);

      return res.status(429).json({
        error: '요리 분석을 너무 많이 하셨어요! 🐰\n잠시 휴식 후 다시 시도해주세요.',
        retryAfter: 3600,
        remaining: 0
      });
    }

    // 3. 통계 업데이트
    const today = new Date().toISOString().split('T')[0];
    const hour = new Date().getHours();
    await kv.incr(`stats:daily:${today}:requests`);
    await kv.incr(`stats:daily:${today}:hour:${hour}`);

    // 4. OpenAI API 호출
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(req.body)
    });

    if (!response.ok) {
      const errorData = await response.json();
      console.error(`[${timestamp}] [OPENAI_ERROR] IP: ${clientIp}, Status: ${response.status}`, errorData);

      return res.status(response.status).json({
        error: 'OpenAI API 오류가 발생했습니다.',
        details: errorData
      });
    }

    const data = await response.json();

    // 5. 성공 로그
    const duration = Date.now() - startTime;
    console.log(`[${timestamp}] [SUCCESS] IP: ${clientIp}, Duration: ${duration}ms, Cost: ~$0.0001`);

    // 통계 업데이트
    await kv.incr(`stats:daily:${today}:success`);

    // 6. 응답 헤더에 Rate Limit 정보 추가
    res.setHeader('X-RateLimit-Limit', '50');
    res.setHeader('X-RateLimit-Remaining', Math.max(0, 50 - count));
    res.setHeader('X-RateLimit-Reset', Math.floor(Date.now() / 1000) + 3600);

    return res.status(200).json(data);

  } catch (error) {
    const duration = Date.now() - startTime;
    console.error(`[${timestamp}] [ERROR] IP: ${clientIp}, Duration: ${duration}ms`, {
      error: error.message,
      stack: error.stack
    });

    return res.status(500).json({
      error: '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.'
    });
  }
}
```

### 2. Flutter API 설정 수정

**파일:** `lib/config/api_config.dart`

```dart
class ApiConfig {
  // Vercel 프록시 URL로 변경
  static const String baseUrl = 'https://recipesoup-proxy-n3crx7b51-hanabikwons-projects.vercel.app';
  static const String chatCompletionsEndpoint = '/api/chat';

  // Proxy Token (실제 OpenAI API 키는 Vercel에만 존재)
  static const String proxyToken = 'e4dbe63b81f2029720374d4b76144b6f17c566d19754793ce01b4f04951780ed';

  /// API 요청 헤더
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'x-app-token': proxyToken, // Proxy 인증
  };

  // 기존 OpenAI API 키 관련 코드는 제거
  // static String? get openAiApiKey => ... (삭제)
}
```

### 3. Flutter 에러 처리 추가

**파일:** `lib/services/openai_service.dart`

```dart
/// Rate Limit 예외 클래스
class RateLimitException implements Exception {
  final String message;
  final int? retryAfter;

  RateLimitException(this.message, {this.retryAfter});

  @override
  String toString() => message;
}

class OpenAiService {
  final Dio _dio;

  OpenAiService({Dio? dio}) : _dio = dio ?? _createDefaultDio();

  static Dio _createDefaultDio() {
    final dio = Dio();
    dio.options = BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
      sendTimeout: ApiConfig.timeout,
      headers: ApiConfig.headers, // Proxy Token 포함
    );

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: false,
        responseBody: true,
        logPrint: (obj) => developer.log(obj.toString(), name: 'OpenAI API'),
      ));
    }

    return dio;
  }

  /// 음식 사진 분석
  Future<RecipeAnalysis> analyzeImage(
    String imageData, {
    LoadingProgressCallback? onProgress,
  }) async {
    try {
      // Base64 이미지 데이터 유효성 검증
      final validatedImageData = UnicodeSanitizer.validateBase64(imageData);
      if (validatedImageData == null) {
        throw const InvalidImageException('Invalid or corrupted image data');
      }

      onProgress?.call('이미지 업로드 중...', 0.3);

      // Vercel 프록시 호출
      final response = await _dio.post(
        ApiConfig.chatCompletionsEndpoint,
        data: {
          'model': ApiConfig.apiModel,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': '이 음식 사진을 분석해주세요...',
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$validatedImageData',
                  },
                },
              ],
            },
          ],
          'max_tokens': 1000,
        },
      );

      onProgress?.call('레시피 작성 완료 🐰', 1.0);

      return RecipeAnalysis.fromJson(response.data);

    } on DioException catch (e) {
      // Rate Limit 에러 처리
      if (e.response?.statusCode == 429) {
        final data = e.response?.data;
        final message = data?['error'] ?? '요리 분석을 너무 많이 하셨어요! 🐰\n잠시 휴식 후 다시 시도해주세요.';
        final retryAfter = data?['retryAfter'] as int?;

        throw RateLimitException(message, retryAfter: retryAfter);
      }

      // 기타 에러 처리
      if (e.response?.statusCode == 401) {
        throw const InvalidApiKeyException('Unauthorized access');
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw TimeoutException('요청 시간이 초과되었습니다.');
      }

      throw NetworkException('네트워크 오류가 발생했습니다.');

    } catch (e) {
      if (e is RateLimitException) rethrow;
      throw ApiException('분석 중 오류가 발생했습니다: $e');
    }
  }
}
```

### 4. Flutter UI에서 Rate Limit 에러 표시

**파일:** `lib/screens/photo_import_screen.dart` (또는 분석 화면)

```dart
Future<void> _analyzeImage() async {
  try {
    setState(() {
      _isAnalyzing = true;
    });

    final result = await _openAiService.analyzeImage(
      _imageBase64Data,
      onProgress: (message, progress) {
        setState(() {
          _analysisProgress = progress;
          _analysisMessage = message;
        });
      },
    );

    // 성공: 결과 표시
    setState(() {
      _analysisResult = result;
      _isAnalyzing = false;
    });

  } on RateLimitException catch (e) {
    // Rate Limit 에러: 친절한 다이얼로그 표시
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Text('잠시만 기다려주세요'),
              SizedBox(width: 8),
              Text('🐰'),
            ],
          ),
          content: Text(e.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('확인'),
            ),
          ],
        ),
      );
    }

    setState(() {
      _isAnalyzing = false;
    });

  } on NetworkException catch (e) {
    // 네트워크 에러
    _showErrorDialog('네트워크 오류', e.toString());

  } catch (e) {
    // 기타 에러
    _showErrorDialog('오류 발생', e.toString());
  }
}

void _showErrorDialog(String title, String message) {
  if (mounted) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }
}
```

---

## 🔧 환경변수 설정 가이드

### Vercel 프로젝트 설정

1. **Vercel 대시보드 접속**
   ```
   https://vercel.com/dashboard
   → Your Project 선택
   → Settings
   → Environment Variables
   ```

2. **필수 환경변수 추가**
   ```
   OPENAI_API_KEY=sk-proj-xxx...  (실제 OpenAI API 키)
   PROXY_APP_TOKEN=e4dbe63b81f2029720374d4b76144b6f17c566d19754793ce01b4f04951780ed
   ```

3. **모든 환경에 적용**
   - Production ✅
   - Preview ✅
   - Development ✅

### Flutter 앱 설정

**`.env` 파일은 더 이상 필요 없음!**

기존에 `.env` 파일에 있던 `OPENAI_API_KEY`는 이제 Vercel에서 관리되므로, Flutter 앱에서는 제거해도 됩니다.

**단, 다른 설정들은 유지:**
```bash
# .env
API_MODEL=gpt-4o-mini
APP_VERSION=1.0.0
DEBUG_MODE=true
ENVIRONMENT=development
```

---

## ✅ 배포 체크리스트

### Vercel 배포 전:
- [ ] `api/chat.js` 파일 작성 완료
- [ ] Vercel 프로젝트 생성
- [ ] 환경변수 설정 (OPENAI_API_KEY, PROXY_APP_TOKEN)
- [ ] `vercel deploy` 명령 실행
- [ ] 배포 URL 확인 (예: https://recipesoup-proxy-xxx.vercel.app)

### Flutter 앱 수정 후:
- [ ] `api_config.dart`에서 baseUrl을 Vercel URL로 변경
- [ ] `openai_service.dart`에서 Rate Limit 에러 처리 추가
- [ ] UI에서 친절한 에러 메시지 표시 구현
- [ ] 테스트: 실제로 사진 분석이 동작하는지 확인

### 최종 검증:
- [ ] 정상 사용자 시나리오 테스트 (1-10회 분석)
- [ ] Rate Limit 테스트 (51회 연속 호출 시 차단 확인)
- [ ] Vercel Logs에서 모니터링 확인
- [ ] 비용 모니터링 설정

---

## 📈 성공 기준

### 보안:
- ✅ 앱 디컴파일 시 실제 OpenAI API 키 노출 안 됨
- ✅ Proxy Token만 노출 (교체 가능)
- ✅ Apple 앱스토어 심사 통과 가능

### 성능:
- ✅ 정상 사용자: 영향 없음
- ✅ 공격자: 99.5% 차단
- ✅ 월간 비용: $50 이하 (1,000명 기준)

### 사용자 경험:
- ✅ 파티 준비 (20개): 문제 없음
- ✅ 주말 요리 (15개): 문제 없음
- ✅ Rate Limit 도달 시: 친절한 메시지 표시

---

## 🔄 향후 개선 방향

### 단기 (선택):
- [ ] 통계 대시보드 UI 구현 (`api/stats.js`)
- [ ] 이메일/Slack 알림 시스템 추가
- [ ] 사용자별 개인화 Rate Limit (등록 사용자 vs 비등록)

### 중장기 (선택):
- [ ] Cloudflare Workers로 마이그레이션 (더 빠른 응답)
- [ ] Redis 대신 분산 캐시 사용
- [ ] 멀티 리전 배포 (글로벌 서비스)

---

**마지막 업데이트:** 2025-10-02
**작성자:** Ultra Think Analysis
**상태:** ✅ 구현 준비 완료
