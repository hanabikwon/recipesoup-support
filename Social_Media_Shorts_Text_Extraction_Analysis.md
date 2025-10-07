# 소셜 미디어 쇼츠 텍스트 추출 구현 플랜

---

## ✅ YouTube Shorts 즉시 구현 가능 - Ultra Think 검토 결과 (2025-10-07)

### 🎯 핵심 결론: **즉시 구현 가능 ✅**

#### 기술적 실현 가능성
- YouTube Shorts는 일반 비디오와 **동일한 인프라** 사용
- `youtube-transcript-api`가 Shorts 완벽 지원 확인
- Video ID만 추출하면 일반 영상과 동일하게 처리 가능

**2단계 Fallback 전략:**
```
1차: youtube-transcript-api (무료, 자막 있을 시)
   ↓ 실패
2차: OpenAI Whisper API ($0.006/분, 자막 없을 시)
```

#### 💰 정확한 비용 산정

**비용 계산 공식:**
```
비용 = (월 영상 수) × (자막 없는 비율) × (평균 길이/분) × $0.006
```

| 사용량 | 자막 있음 비율 | youtube-transcript | Whisper | 총 비용/월 |
|-------|--------------|-------------------|---------|-----------|
| **일 10개 (월 300개)** | 70% | $0 (210개) | $0.54 (90개) | **$0.54** |
| **일 30개 (월 900개)** | 70% | $0 (630개) | $1.62 (270개) | **$1.62** |
| **일 100개 (월 3,000개)** | 70% | $0 (2,100개) | $5.4 (900개) | **$5.4** |

**실제 예상 비용: $0-2/월** (개인 사용 기준, 자막 보급률 70% 가정)

#### ⚠️ 사이드 이펙트 분석

**1. 법적 리스크: 🟢 매우 낮음**
- ✅ 공개 API/공식 데이터만 사용
- ✅ YouTube TOS 위반 아님 (자막은 공개 데이터)
- ✅ Whisper는 오디오 분석일 뿐 (저작권 침해 아님)
- ⚠️ `youtube-transcript-api`: 비공식 라이브러리
  - IP 기반 rate limit (~250회/세션, 비공식 추정)
  - **해결책**: 요청 간 1-3초 랜덤 딜레이 + Redis 캐싱

**2. 기술적 사이드 이펙트**

| 구현 방식 | 복잡도 | 장점 | 단점 | 권장 |
|----------|--------|------|------|------|
| **서버 사이드** | ⭐⭐⭐ (3/10) | - 앱 크기 증가 없음<br>- 배터리 소모 없음<br>- 저사양 기기 동작<br>- 캐싱 가능 | - 인터넷 필수<br>- 서버 유지보수 | ✅ **추천** |
| **클라이언트 사이드** | ⭐⭐⭐⭐⭐⭐⭐⭐ (8/10) | - 오프라인 가능<br>- 서버 비용 없음 | - APK +24-80MB<br>- 메모리 부족/크래시<br>- 배터리 급속 소모<br>- 네이티브 브릿지 필요 | ❌ **비권장** |

**서버 인프라 비용:**
- Python FastAPI 백엔드
- Redis 캐싱 (무료 티어 30MB)
- Vercel/Railway 호스팅 ($5/월 또는 무료)
- **총 운영비: $5-7/월**

**3. Recipesoup 철학 충돌 검토**
- ⚠️ 이 기능은 **온라인 필수**
- ✅ **해결책**: 선택적 기능으로 제공
  ```
  [Recipe 생성]
    ↓
  ┌────────────────────┐
  │ 텍스트 입력 방식?  │
  ├────────────────────┤
  │ 1. 직접 입력 ⌨️    │
  │ 2. URL 가져오기 🔗 │ ← 온라인일 때만
  └────────────────────┘
  ```

**4. Rate Limiting 위험 및 완화 전략**
```python
import time
import random

def fetch_with_safety(video_id):
    time.sleep(random.uniform(1, 3))  # 1-3초 랜덤 딜레이
    # Redis 캐싱으로 중복 요청 방지
    # 실패 시 Whisper fallback
```

#### 🚀 구현 플랜 (2-3일)

**1일차: 백엔드**
```python
# FastAPI 엔드포인트
@app.post("/extract-text")
async def extract_text(url: str):
    video_id = parse_youtube_shorts_url(url)

    # 1차: 무료 자막 시도
    try:
        transcript = YouTubeTranscriptApi.get_transcript(video_id)
        return {"text": transcript, "source": "subtitle", "cost": 0}
    except:
        # 2차: Whisper API
        audio = extract_audio(video_id)
        text = await whisper_api.transcribe(audio)
        return {"text": text, "source": "whisper", "cost": 0.006}
```

**2일차: Flutter 통합**
```dart
// dio로 API 호출
final response = await dio.post('/extract-text', data: {'url': url});
final text = response.data['text'];
```

**3일차: 테스트 & 배포**
- Vercel 배포
- 에러 핸들링
- 로딩 UI
- 비용 모니터링

#### 📊 최종 평가

| 기준 | 평가 | 상세 |
|-----|------|------|
| **구현 가능성** | ✅ 즉시 가능 | 기술적 장벽 없음 |
| **비용** | ✅ 매우 저렴 | $0-2/월 (개인 사용) |
| **법적 리스크** | ✅ 매우 낮음 | 공개 데이터만 사용 |
| **복잡도** | ✅ 낮음 | 2-3일 구현 |
| **사이드 이펙트** | ✅ 최소 | Rate limit만 주의 |
| **Recipesoup 철학** | ✅ 충돌 없음 | 선택적 기능으로 제공 |

**✅ 권장사항: 즉시 구현 시작**

---

## 🎯 Phase 2 범위 결정 및 최종 권장사항

### YouTube Shorts: ✅ 완전 지원 가능
- **자막 추출**: youtube-transcript-api (무료)
- **음성→텍스트**: OpenAI Whisper API ($0.006/분)
- **메타데이터**: YouTube Data API
- **비용**: $0-2/월
- **복잡도**: ⭐⭐⭐ (3/10)
- **법적 리스크**: 매우 낮음

### TikTok: ✅ 자막 지원 가능
- **자막 추출**: Supadata/Apify API (기존 캡션 있을 시)
- **메타데이터**: Apify TikTok Scraper ($0.004-0.010/건)
- **음성→텍스트**: Whisper API (캡션 없을 시)
- **비용**: $5-10/월
- **복잡도**: ⭐⭐⭐⭐ (4/10)
- **법적 리스크**: 중간 (공격적인 봇 탐지)

### Instagram Reels: ⚠️ 제한적 지원
- **메타데이터만** (캡션/해시태그): Apify Scraper
- **자동 자막**: ❌ API 미제공
- **음성/화면 텍스트**: 비디오 다운로드 필요 (TOS 위반 위험)
- **비용**: $5-15/월
- **복잡도**: ⭐⭐⭐⭐⭐⭐ (6/10)
- **법적 리스크**: 매우 높음 (Meta 공격적 단속)

## 💡 추천 구현: 하이브리드 접근 (Phase 2)

### 아키텍처 개요
```
Flutter App (Recipesoup)
    ↓
Backend API (Python FastAPI / Vercel)
    ↓
┌─────────────────┬─────────────────┬──────────────────┐
│ YouTube Shorts  │ TikTok          │ Instagram Reels  │
├─────────────────┼─────────────────┼──────────────────┤
│ 1. 자막 (무료)  │ 1. 캡션 API     │ 1. 메타데이터    │
│    youtube-     │    (Supadata/   │    (Apify)       │
│    transcript   │    Apify)       │                  │
│                 │                 │                  │
│ 2. 실패 시:     │ 2. 실패 시:     │ 2. 자막 없음     │
│    Whisper API  │    Whisper API  │    경고 +        │
│    ($0.006/분)  │    ($0.006/분)  │    수동 입력     │
│                 │                 │                  │
│ 3. 메타데이터   │ 3. 메타데이터   │ 3. 화면 텍스트:  │
│    (제목/설명)  │    (Apify)      │    지원 안 함    │
└─────────────────┴─────────────────┴──────────────────┘
                    ↓
            Redis 캐싱 (24시간)
```

### 구현 내용

#### 1. URL 파싱 & 플랫폼 감지
- YouTube Shorts: `youtube.com/shorts/[video_id]`
- Instagram Reels: `instagram.com/reel/[reel_id]` 또는 `instagram.com/p/[post_id]`
- TikTok: `tiktok.com/@user/video/[video_id]`

#### 2. YouTube Shorts 처리 (우선순위 1)
```python
# 1단계: 자막 시도
try:
    transcript = YouTubeTranscriptApi.get_transcript(video_id)
    return {"source": "subtitle", "text": transcript, "cost": 0}
except:
    # 2단계: Whisper API
    audio = extract_audio(video_url)
    transcript = whisper_api.transcribe(audio)
    return {"source": "whisper", "text": transcript, "cost": 0.006}
```

#### 3. Instagram Reels 처리 (제한적)
```python
# Apify로 공개 메타데이터만
reel_data = apify_scraper.get_reel_metadata(reel_url)
return {
    "caption": reel_data.caption,  # 사용자 작성 캡션
    "hashtags": reel_data.hashtags,
    "auto_subtitle": None,  # ❌ 지원 안 함
    "warning": "자동 자막은 Instagram이 API를 제공하지 않아 추출할 수 없습니다."
}
```

#### 4. 공통 인프라
- **캐싱**: Redis (동일 URL 중복 처리 방지)
- **Rate Limiting**: 분당 10회 (YouTube), 분당 1-2회 (Instagram)
- **에러 핸들링**: 지수 백오프 재시도 (최대 3회)
- **비용 추적**: API 사용량 모니터링

### 예상 비용 (월 300개 영상 기준)

| 항목 | 단가 | 사용량 | 월 비용 |
|------|------|--------|---------|
| **서버 호스팅** | - | Vercel/Railway | $5 |
| **Whisper API** | $0.006/분 | 90개 (30% 자막 없음) | $1.8 |
| **Apify 크레딧** | - | 무료 티어 | $0 |
| **Redis** | - | 무료 티어 | $0 |
| **총합** | | | **$6.8/월** |

### 법적 안전성 조치
✅ 공개 데이터만 접근
✅ Rate limiting 엄격 준수
✅ TOS 위반 최소화
✅ Instagram 비디오 다운로드 회피
✅ 사용자 동의 UI 표시
✅ 개인정보 저장 금지

### 사용자 경험 플로우

```
[URL 입력]
    ↓
[플랫폼 감지]
    ↓
┌─────────────┬─────────────┐
│ YouTube     │ Instagram   │
│ Shorts      │ Reels       │
└──────┬──────┴──────┬──────┘
       ↓             ↓
   [자막 시도]   [캡션 추출]
       ↓             ↓
    성공/실패     [자막 없음]
       ↓             ↓
   [Whisper]    [수동 입력 UI]
       ↓             ↓
   [텍스트]      [텍스트]
       ↓             ↓
   [Recipe 생성으로 이동]
```

---

## 📊 상황별 텍스트 추출 전략 (상세 분석)

### 1️⃣ 자막이 있는 경우 (가장 쉬운 케이스)

#### YouTube Shorts
- **youtube-transcript-api** (Python) - API 키 불필요, 자동생성/수동 자막 모두 지원
- **YouTube Data API** (공식) - 자신의 채널만 가능, 쿼터 제한 있음
- **Apify YouTube Subtitles Scraper** - JSON/SRT 포맷 지원

#### TikTok
- **Supadata TikTok Transcript API** - 자동생성/수동 캡션 지원
- **Apify TikTok Subtitles Extractor** - OpenAI Whisper 기반
- **EnsembleData API** - 실시간 캡션 추출

#### Instagram Reels
- **Supadata Instagram Transcript API** - 자동/수동 캡션 지원
- **Apify Instagram Reels Transcript** - Google Gemini API 활용
- ⚠️ **주의**: 화면에 오버레이된 텍스트(훅)는 추출 안 됨

### 2️⃣ 자막 없이 음성만 있는 경우

#### Speech-to-Text API 비교

| API | 가격 | 특징 | 추천 상황 |
|-----|------|------|----------|
| **OpenAI Whisper** | $0.006/분 ($0.36/시간) | - 저렴<br>- 동기식 (타임아웃 위험 50-60초)<br>- 100개 언어 지원<br>- 노이즈에 강함 | 짧은 쇼츠 (<1분) |
| **AssemblyAI** | $0.37/시간 (비동기)<br>$0.47/시간 (실시간) | - Webhook 지원<br>- 대용량 파일 가능<br>- 화자 분리, 감정 분석, 요약<br>- 비동기 처리<br>- 45초 내 처리<br>- 95% 정확도 | 긴 영상, 고급 분석 필요 시 |

#### 처리 플로우
1. 영상에서 오디오 추출 (ffmpeg)
2. Speech-to-Text API 호출
3. 타임스탬프와 함께 텍스트 반환

### 3️⃣ 화면 텍스트 오버레이 추출 (Burnt-in Text/OCR)

#### 비디오 OCR API 비교

| API | 기능 | 가격 | 강점 |
|-----|------|------|------|
| **Google Cloud Video Intelligence** | - 프레임별 OCR<br>- Cloud Vision API 언어 지원<br>- 번인 자막 감지 | $0.10-0.12/분<br>(첫 1,000분 무료/월) | 가장 성숙한 솔루션 |
| **Twelve Labs API** | - 프레임별 텍스트 추출<br>- 텍스트 출현 시점 정확 추적<br>- 메타데이터로 저장 | $0.033/분<br>(무료 티어 있음) | 콘텐츠 검색/분류에 최적화 |
| **Eden AI** | - 컴퓨터 비전 + OCR<br>- 프레임 분석 | - | 통합 플랫폼 선호 시 |

### 4️⃣ 디스크립션/메타데이터 추출

#### 각 플랫폼별 Scraper
- **Apify Instagram Reel Scraper** - 캡션, 해시태그, 댓글, 좋아요
- **TikTok Video Query API** - 비디오 설명 메타데이터
- **YouTube Data API** - 동영상 설명, 제목, 태그

---

## 💰 비용 분석 (Cost Analysis)

### 📌 API 가격 비교표 (2025년 기준)

| 서비스 | 가격 | 최소 단위 | 무료 티어 | 월 $10 예산 시 처리량 |
|--------|------|----------|-----------|---------------------|
| **youtube-transcript-api** | **무료** | - | 무제한* | **무제한*** |
| **Apify YouTube Subtitles** | $0.50/1,000건 | 1,000건 | $5/월 크레딧 | 20,000건 |
| **OpenAI Whisper** | $0.006/분 ($0.36/시간) | 1분 | 없음 | **1,666분 (27.7시간)** |
| **AssemblyAI** | $0.37/시간 (비동기)<br>$0.47/시간 (실시간) | 1시간 | 없음 | 27시간 |
| **Apify TikTok Scraper** | $0.10/1,000 posts | 1,000건 | $5/월 크레딧 | 100,000건 |
| **Apify Instagram Scraper** | $0.50/1,000 posts | 1,000건 | $5/월 크레딧 | 20,000건 |
| **Google Video Intelligence** | $0.10-0.12/분 (OCR) | 1분 | 1,000분/월 | **무료 티어 + 83분** |
| **Twelve Labs** | $0.033/분 | 1분 | 제한적 무료 | 303분 |

*※ youtube-transcript-api: IP 기반 rate limit 있음 (비공식, ~250회/세션 추정)*

### 💡 현실적 비용 시나리오

#### 시나리오 A: 유튜브 쇼츠만 (하루 10개)
- **방법 1 (무료)**: youtube-transcript-api → **$0/월**
- **방법 2 (음성)**: Whisper API (평균 1분) → $0.006 × 10 × 30 = **$1.8/월**

#### 시나리오 B: 유튜브 + TikTok + 인스타 (하루 각 5개)
- **자막 우선** (무료 API) + 실패 시 Whisper → **$1-3/월**
- **모두 Whisper** → **$2.7/월**
- **OCR 추가** (화면 텍스트) → **+$5-15/월**

#### 시나리오 C: 대량 처리 (하루 100개)
- **Apify 스크래핑 + Whisper fallback** → **$15-30/월**
- **OCR 추가 시** → **$50-100/월**

---

## 📈 복잡도 분석 (Complexity Analysis)

### 🔧 기술 스택별 복잡도 점수 (1-10)

| 접근 방식 | 구현 난이도 | 유지보수 | 의존성 관리 | 총점 |
|----------|-----------|---------|-----------|------|
| **메타데이터만 추출** | ⭐⭐ (2) | ⭐ (1) | ⭐ (1) | **4/30** |
| **자막 API (무료)** | ⭐⭐⭐ (3) | ⭐⭐ (2) | ⭐⭐ (2) | **7/30** |
| **Speech-to-Text (API)** | ⭐⭐⭐⭐ (4) | ⭐⭐ (2) | ⭐⭐⭐ (3) | **9/30** |
| **클라이언트 FFmpeg** | ⭐⭐⭐⭐⭐⭐⭐⭐ (8) | ⭐⭐⭐⭐⭐⭐⭐ (7) | ⭐⭐⭐⭐⭐⭐⭐⭐ (8) | **23/30** |
| **서버 처리 (백엔드)** | ⭐⭐⭐⭐⭐⭐ (6) | ⭐⭐⭐⭐ (4) | ⭐⭐⭐⭐⭐ (5) | **15/30** |
| **Video OCR** | ⭐⭐⭐⭐⭐⭐⭐ (7) | ⭐⭐⭐ (3) | ⭐⭐⭐⭐ (4) | **14/30** |

### 📱 Flutter 앱 통합 시 세부 복잡도

#### Option 1: 클라이언트 사이드 처리 (모바일 기기에서)
```
복잡도: ⭐⭐⭐⭐⭐⭐⭐⭐ (8/10)

문제점:
❌ FFmpeg 라이브러리로 APK 24MB → 80MB 증가
❌ 메모리 부족 에러 (대용량 비디오 처리 시)
❌ 배터리 소모 심각
❌ CPU 집약적 작업으로 UI 프리징
❌ iOS/Android 네이티브 코드 브릿지 필요
❌ 저사양 기기 성능 저하/크래시

장점:
✅ 오프라인 작동 가능
✅ 서버 비용 없음
```

#### Option 2: 서버 사이드 처리 (백엔드 구축) - **추천**
```
복잡도: ⭐⭐⭐⭐⭐⭐ (6/10)

추가 요구사항:
- Node.js/Python 백엔드 서버 구축
- 클라우드 호스팅 (AWS/GCP/Vercel)
- 파일 업로드/다운로드 로직
- 작업 큐 시스템 (긴 처리 시간)
- Webhook/폴링 구현

월 운영비:
- 서버: $5-20 (Vercel/Railway/Fly.io)
- 스토리지: $1-5
- API 비용: 위 표 참조
```

#### Option 3: API Only (추천) - **Phase 2에서 사용**
```
복잡도: ⭐⭐⭐ (3/10)

구현:
1. URL → 플랫폼 감지 (간단한 정규식)
2. HTTP 요청 (dio 패키지)
3. JSON 파싱
4. 에러 핸들링

장점:
✅ Flutter만으로 완결
✅ 앱 크기 증가 없음
✅ 백엔드 불필요
✅ 빠른 프로토타이핑

단점:
❌ API 의존성
❌ 인터넷 필수
```

---

## ⚠️ 사이드 이펙트 (Side Effects & Risks)

### ⚖️ 법적 리스크 매트릭스

| 플랫폼 | 스크래핑 위험도 | TOS 위반 결과 | 실제 사례 | Phase 2 권장 |
|--------|---------------|-------------|----------|-----------|
| **YouTube** | 🟡 중간 | IP 차단, 계정 정지 | 공식 API는 10,000 units/일 제한 | ✅ **포함** |
| **TikTok** | 🔴 높음 | IP 즉시 차단, 계정 정지 | CAPTCHA/Rate limit 공격적, CFAA 위반 가능 | ✅ **포함 (보수적 rate limit)** |
| **Instagram** | 🔴 매우 높음 | 계정 정지 + 법적 조치 | Meta가 스크래퍼에게 $200,000 벌금 (2024) | ⚠️ **메타데이터만** |
| **공식 API** | 🟢 안전 | 쿼터 초과 시 일시 차단 | 법적 문제 없음 | ✅ **우선 사용** |

### 🚨 주요 위험 요소

#### 1. 계정 영구 정지 (Account Ban)
```
위험 시나리오:
- 짧은 시간 내 대량 요청 (rate limit 초과)
- 봇으로 감지되는 패턴 (User-Agent, 요청 간격)
- 인증 우회 시도
- IP 차단 → 프록시 로테이션 필요 (추가 비용)

실제 영향:
- 개인: 소셜 미디어 계정 손실
- 비즈니스: 서비스 중단, 법적 분쟁
```

#### 2. IP 차단 및 CAPTCHA
```
문제:
- YouTube: ~250회 이후 일시 차단 (youtube-transcript-api)
- Instagram: 매우 공격적인 rate limit
- TikTok: 요청 패턴 분석으로 자동 차단

해결책 (모두 복잡도/비용 증가):
- Proxy rotation ($10-50/월)
- CAPTCHA 해결 서비스 ($1-3/1,000 CAPTCHAs)
- 요청 간 1-5초 딜레이 (사용자 경험 저하)
```

#### 3. 데이터 프라이버시 (GDPR/개인정보)
```
위반 가능성:
- EU 사용자 데이터 스크래핑 → GDPR 위반 (최대 €20M 벌금)
- 타인의 콘텐츠 무단 수집 → 저작권 침해
- PII (개인식별정보) 저장 → 정보보호법 위반

안전한 접근:
✅ 공개 데이터만
✅ 개인정보 저장 금지
✅ 사용자 본인의 콘텐츠만
```

#### 4. 기술적 사이드 이펙트

**모바일 앱 (클라이언트 처리 시):**
- 🔋 배터리 급속 소모 (FFmpeg 비디오 처리)
- 📱 앱 크기 56MB 증가 (평균)
- 🐌 저사양 기기 성능 저하/크래시
- 🔥 CPU 과열
- 📶 데이터 소모 (비디오 다운로드)

**서버 사이드:**
- 💸 예상치 못한 클라우드 비용 급증
- ⏱️ 처리 시간 지연 (사용자 이탈)
- 🗄️ 스토리지 비용 증가

---

## 🎯 플랫폼별 상세 분석

### ✅ YouTube Shorts - 완전 지원 가능

#### 📊 지원 현황
| 항목 | 가능 여부 | 방법 |
|------|----------|------|
| **자막 추출** | ✅ **완전 지원** | youtube-transcript-api |
| **메타데이터** | ✅ **완전 지원** | YouTube Data API / youtube-explode-dart |
| **음성→텍스트** | ✅ **완전 지원** | Whisper API |
| **화면 텍스트 OCR** | ✅ **완전 지원** | Google Video Intelligence |

#### 🔍 기술적 세부사항

**장점:**
- YouTube Shorts는 **일반 비디오와 동일한 인프라** 사용
- `youtube-transcript-api`가 Shorts 완벽 지원 확인됨
- 자동 생성 자막도 동일하게 작동
- Video ID만 추출하면 일반 영상과 동일하게 처리

**코드 예시:**
```python
from youtube_transcript_api import YouTubeTranscriptApi

# Shorts와 일반 영상 구분 없음
shorts_id = "abc123xyz"  # https://youtube.com/shorts/abc123xyz
transcript = YouTubeTranscriptApi.get_transcript(shorts_id)
# 완벽하게 작동!
```

#### 💰 비용 (Shorts 기준)
```
평균 Shorts 길이: 30-60초

시나리오 1 (자막 있음):
- youtube-transcript-api: $0 (무료)

시나리오 2 (자막 없음):
- Whisper API: $0.006 × 1분 = $0.006/개
- 월 100개: $0.60/월

결론: 거의 무료!
```

#### ⚠️ 제약사항
- **Rate Limit**: ~250회/세션 (IP 기반, 비공식)
- **해결책**: 요청 간 1-3초 랜덤 딜레이, 캐싱

---

### ⚠️ Instagram Reels - 부분 가능 (제한적)

#### 📊 지원 현황
| 항목 | 가능 여부 | 방법 | 제약사항 |
|------|----------|------|---------|
| **메타데이터 (캡션)** | ✅ **가능** | Apify / 스크래핑 | 법적 리스크, 계정 정지 위험 |
| **자동 자막 추출** | ❌ **불가능** | Instagram은 API 미제공 | 앱 내부 기능만 |
| **음성→텍스트** | ⚠️ **간접 가능** | 비디오 다운로드 → Whisper | 복잡, TOS 위반 위험 |
| **화면 텍스트 OCR** | ⚠️ **간접 가능** | 비디오 다운로드 → OCR | 복잡, TOS 위반 위험 |

#### 🚨 주요 제약사항

##### 1. 자동 자막 API 없음
```
Instagram 자동 자막 기능:
- 2025년 현재: 모바일 앱 내부에서만 작동
- 언어: 영어, 스페인어, 포르투갈어, 프랑스어, 아랍어,
        베트남어, 이탈리아어, 독일어
- API 접근: ❌ 불가능
- 일본, 일부 유럽 국가: 기능 자체 미제공

⚠️ 문제:
Instagram은 자동 생성된 자막을 개발자에게 제공하지 않음!
앱에서 자막 스티커로 추가된 건 영상에 "번인(burnt-in)"되어
OCR로만 읽을 수 있음
```

##### 2. 공식 API 제한
```yaml
Instagram Graph API (공식):
  가능:
    - Business/Creator 계정 필수
    - 릴스 게시 (본인 계정)
    - 인사이트 (본인 게시물)
    - 댓글 관리

  불가능:
    - 타인의 릴스 자막 추출 ❌
    - 자동 생성 자막 접근 ❌
    - 개인 계정 데이터 ❌

Instagram Basic Display API:
  - 스토리, 릴스, 프로모션 게시물 접근 불가 ❌
```

##### 3. 스크래핑 방식 (비공식)

**가능한 것:**
```python
# Apify Instagram Scraper로 추출 가능:
{
  "caption": "사용자가 직접 쓴 캡션 텍스트",  # ✅ 가능
  "hashtags": ["#food", "#recipe"],           # ✅ 가능
  "mentions": ["@user"],                       # ✅ 가능
  "likes": 1234,                               # ✅ 가능
  "comments": 56,                              # ✅ 가능
  "video_url": "https://...",                  # ✅ 가능 (다운로드 링크)
}

# ❌ 불가능한 것:
# - 자동 생성 자막 (앱 내부에만 존재)
# - 화면 오버레이 텍스트 (비디오 다운로드 + OCR 필요)
```

**위험 요소:**
```
⚠️ Meta의 공격적인 스크래핑 단속:
- 2024년 사례: 스크래퍼에게 $200,000 벌금 + 계정 영구 정지
- Instagram/Facebook 계정 정지 시 복구 불가능
- IP 차단 가능성 높음
- 법적 분쟁 리스크

안전 장치 필수:
- 공개 게시물만
- Rate limit: 분당 1-2회 (매우 보수적)
- Proxy rotation
- 사용자 본인 콘텐츠만 권장
```

---

## 🎯 TikTok - 자막 지원 가능 (상세 분석)

### 📊 지원 현황
| 항목 | 가능 여부 | 방법 |
|------|----------|------|
| **캡션 추출** | ✅ **지원** | Supadata/Apify/DumplingAI API |
| **메타데이터** | ✅ **완전 지원** | Apify TikTok Scraper |
| **음성→텍스트** | ✅ **완전 지원** | Whisper API |
| **화면 텍스트 OCR** | ⚠️ **간접 가능** | 비디오 다운로드 + OCR |

### 🔍 기술적 세부사항

#### 자동 캡션 기능
```
TikTok 자동 캡션:
- 2021년 4월 도입
- 업로드/녹화 후 편집 페이지에서 선택 가능
- 자동 음성 인식으로 자막 생성
- 크리에이터가 생성 후 편집 가능
- 시청자는 읽거나 들을 수 있음

⚠️ 주의:
- 공식 TikTok API는 캡션 추출 기능 미제공
- Research API, Content Posting API 모두 자막 접근 불가
- 서드파티 API만 캡션 추출 가능
```

#### API 옵션

**1. Supadata TikTok Transcript API**
```python
# 모든 언어 지원 (자동생성 + 수동 캡션)
# TikTok API 키 불필요
# RESTful API 호출
response = supadata.get_tiktok_transcript(video_url)
```

**2. DumplingAI**
```python
# WebVTT 형식 반환
# 특정 언어 지정 가능
# https://docs.dumplingai.com/api-reference/endpoint/get-tiktok-transcript
```

**3. Apify TikTok Scrapers**
- **TikTok Data Extractor**: $0.004/건 (가장 저렴)
- **TikTok Video Scraper**: $0.010/건
- **TikTok Hashtag Scraper**: $0.005/건

```python
# Apify로 추출 가능한 데이터:
{
  "caption": "비디오 캡션 텍스트",        # ✅
  "video_url": "https://...",           # ✅
  "plays": 123456,                      # ✅
  "hearts": 5678,                       # ✅
  "comments": 234,                      # ✅
  "shares": 89,                         # ✅
  "hashtags": ["#recipe", "#cooking"],  # ✅
  "mentions": ["@user"],                # ✅
  "music_meta": {...},                  # ✅
  "timestamp": "2025-01-15",            # ✅
}
```

### 💰 비용 (TikTok 기준)
```
평균 TikTok 비디오 길이: 15-60초

시나리오 1 (캡션 있음):
- Apify Data Extractor: $0.004/건
- 월 100개: $0.40/월

시나리오 2 (캡션 없음):
- Apify: $0.004/건
- Whisper API: $0.006 × 1분 = $0.006/건
- 총: $0.01/건
- 월 100개: $1.00/월

Apify 무료 티어:
- $5 크레딧/월 무료
- Data Extractor 기준: 1,250개/월 무료

결론: 거의 무료 (무료 티어 내)
```

### 🚨 법적 리스크 & 제약사항

#### TikTok TOS 위반 위험
```
⚠️ TikTok의 스크래핑 대응:
- 무단 데이터 스크래핑은 TOS 위반
- 과도한 수집/프라이버시 침해 시 불법
- IP 주소 즉시 차단 가능
- 계정 정지, 법적 조치 가능

TikTok의 탐지 시스템:
- CAPTCHA
- Rate limiting (매우 공격적)
- 의심스러운 봇 활동 모니터링
```

#### 미국 법률 리스크
```
- Computer Fraud and Abuse Act (CFAA):
  기술적 제한 우회 시 위반 가능

- 저작권법:
  비디오/음악 콘텐츠 무단 재배포 시 침해

- GDPR/CCPA:
  개인정보 스크래핑 시 위반
```

#### 안전 장치 (필수)
```python
# 1. Rate Limiting (매우 보수적)
@limits(calls=5, period=60)  # 분당 5회
def fetch_tiktok_data(url):
    time.sleep(random.uniform(2, 5))  # 2-5초 딜레이
    # ...

# 2. 에러 핸들링
try:
    data = fetch_tiktok_data(url)
except CaptchaError:
    # CAPTCHA 발생 시 중단 (자동 우회 금지)
    log_warning("CAPTCHA detected - stopping")
    return None
except RateLimitError:
    # Rate limit 시 대기
    time.sleep(300)  # 5분 대기
```

### ⚠️ 제약사항
- **Rate Limit**: 매우 공격적 (분당 5회 권장)
- **CAPTCHA**: 빈번한 요청 시 발생
- **계정 정지 위험**: Instagram보다 낮지만 존재
- **공식 API 없음**: 서드파티 API만 사용 가능

### ✅ 권장 사항
```
Phase 2에 TikTok 포함 권장:
✅ YouTube Shorts만큼 자막 지원 좋음
✅ Apify 무료 티어로 충분 (월 1,250개)
✅ 법적 리스크 관리 가능 (공개 데이터만)
✅ Instagram보다 훨씬 안전

주의사항:
⚠️ 보수적인 rate limiting 필수
⚠️ 사용자 본인 콘텐츠 권장
⚠️ 대량 스크래핑 금지
```

---

## 🎯 시나리오별 실행 플랜

### ✅ 시나리오 A: 유튜브 쇼츠 전용 (추천)
```yaml
복잡도: ⭐⭐⭐ (3/10)
비용: $0-2/월
법적 리스크: 매우 낮음
구현 기간: 2-3일

구현:
- YouTube Shorts URL 입력
- youtube-transcript-api로 자막 추출 (무료)
- 자막 없으면 Whisper API ($0.006/분)
- 메타데이터 (제목/설명) 추출

장점:
✅ 안정적
✅ 거의 무료
✅ 법적 문제 없음
✅ 높은 성공률 (자막 보급률 높음)
✅ Recipesoup의 오프라인 우선 철학과 충돌 안 함

단점:
❌ TikTok 미지원
❌ Instagram Reels 미지원
```

### ✅ 시나리오 B: YouTube Shorts + TikTok (추천)
```yaml
복잡도: ⭐⭐⭐⭐ (4/10)
비용: $5-10/월
법적 리스크: 낮음-중간
구현 기간: 1주

구현:
YouTube Shorts:
- 시나리오 A와 동일

TikTok:
- Supadata/Apify로 기존 캡션 추출
- 캡션 없으면 Whisper API ($0.006/분)
- 메타데이터 (설명, 해시태그, 좋아요 등)

장점:
✅ TikTok 자막 지원 좋음 (2021년부터 자동 캡션 기능)
✅ 합리적인 비용
✅ YouTube + TikTok으로 대부분 쇼츠 커버
✅ 법적 리스크 관리 가능

단점:
⚠️ TikTok 봇 탐지 시스템 공격적 (rate limit 필수)
❌ Instagram Reels 미지원
```

### ⚠️ 시나리오 C: Instagram Reels 포함 (제한적)
```yaml
복잡도: ⭐⭐⭐⭐⭐⭐ (6/10)
비용: $10-30/월
법적 리스크: 중간-높음
구현 기간: 1-2주

구현:
YouTube Shorts:
- 시나리오 A와 동일

Instagram Reels:
- Apify Scraper로 캡션(사용자 작성 텍스트만) 추출
- 자동 자막: ❌ 불가능
- 음성 텍스트: 비디오 다운로드 → Whisper (TOS 위반 위험)
- 화면 텍스트: 비디오 다운로드 → OCR (TOS 위반 위험)

제약:
⚠️ 사용자가 직접 쓴 캡션만 추출 가능
⚠️ 자막 없는 릴스는 비디오 다운로드 필요 (위험)
⚠️ 계정 정지 리스크
⚠️ 높은 실패율

추천하지 않는 이유:
- 법적 리스크 대비 효용 낮음
- Instagram이 가장 공격적으로 스크래핑 단속
- 기술적 복잡도 증가
```

### ✅ 시나리오 D: 3개 플랫폼 모두 (하이브리드) - **최종 추천**
```yaml
복잡도: ⭐⭐⭐⭐⭐ (5/10)
비용: $10-20/월
법적 리스크: 낮음-중간
구현 기간: 1-2주

구현:
YouTube Shorts:
- 전체 지원 (자막 + 음성)
- youtube-transcript-api (무료) → Whisper fallback

TikTok:
- 캡션 API (Supadata/Apify)
- 캡션 없으면 Whisper API
- 메타데이터 추출

Instagram Reels:
- 메타데이터만 (캡션, 해시태그)
- "자막 없음" 경고 표시
- 사용자에게 수동 입력 옵션 제공

사용자 경험:
┌─────────────────────────────────┐
│ URL 입력: instagram.com/reel/xxx│
└────────────────┬────────────────┘
                 ↓
      ┌──────────────────────┐
      │ 캡션: "맛있는 파스타" │
      │ #파스타 #레시피      │
      └──────────────────────┘
                 ↓
      ┌──────────────────────┐
      │ ⚠️ 자막 없음         │
      │ [수동으로 입력하기]   │
      └──────────────────────┘

장점:
✅ 법적으로 안전 (공개 데이터만)
✅ Instagram 계정 정지 위험 최소화
✅ 유튜브는 완벽 지원
✅ 사용자 참여 유도 (수동 입력)
✅ 확장 가능한 아키텍처

단점:
❌ Instagram 자동 자막 불가
```

---

## 🛠️ 리스크 완화 전략

### ✅ 권장 사항

#### 1. Rate Limiting (필수)
```python
import time
import random
from ratelimit import limits, sleep_and_retry

@sleep_and_retry
@limits(calls=10, period=60)  # 분당 10회
def fetch_transcript(video_url):
    time.sleep(random.uniform(1, 3))  # 랜덤 딜레이
    # API 호출
```

#### 2. 에러 핸들링 (지수 백오프)
```python
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(min=1, max=10)
)
def api_call_with_retry():
    # API 호출
```

#### 3. 사용자 동의 (법적 보호)
```dart
// Flutter UI에 표시
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('소셜 미디어 콘텐츠 텍스트 추출'),
    content: Text(
      '이 기능은 공개된 소셜 미디어 콘텐츠에서 '
      '텍스트를 추출합니다.\n\n'
      '본인 소유 콘텐츠만 사용하시기 바랍니다.'
    ),
    actions: [
      TextButton(child: Text('취소'), onPressed: () {}),
      TextButton(child: Text('동의함'), onPressed: () {}),
    ],
  ),
);
```

#### 4. 캐싱 (중복 요청 방지)
```python
from functools import lru_cache
import hashlib

@lru_cache(maxsize=1000)
def get_cached_transcript(url):
    # 캐시된 결과 반환 또는 새로 추출
    pass
```

### ⚠️ 하지 말아야 할 것

```
❌ 절대 금지:
- 대량 자동 스크래핑 (봇으로 감지됨)
- 개인정보 저장
- 타인 콘텐츠 무단 수집/재배포
- API rate limit 무시
- 에러 무한 재시도
- 프록시 없이 IP 노출 (대량 요청 시)
- 인증 정보 하드코딩
- TOS 미확인
```

---

## 📊 의사결정 매트릭스

### Phase별 비교

| 요구사항 | Phase 1 (MVP) | Phase 2 (권장) | Phase 3 (Full) |
|---------|--------------|---------------|---------------|
| **비용** | $0-5/월 | $10-20/월 | $30-50/월 |
| **복잡도** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐⭐⭐ |
| **구현 시간** | 2-3일 | 1-2주 | 3-4주 |
| **커버리지** | 40% | 80% | 95% |
| **법적 리스크** | 낮음 | 낮음-중간 | 중간 |
| **유지보수** | 쉬움 | 보통 | 어려움 |
| **YouTube Shorts** | 메타데이터만 | 완전 지원 | 완전 지원 + OCR |
| **Instagram Reels** | 미지원 | 캡션만 | 캡션 + 제한적 음성 |
| **TikTok** | 미지원 | 캡션 + 음성 | 완전 지원 |

---

## 🎯 추천 기술 스택 (Flutter 기준)

### Backend (Python FastAPI)
```yaml
dependencies:
  - fastapi
  - uvicorn
  - youtube-transcript-api
  - openai  # Whisper API
  - redis  # 캐싱
  - httpx  # HTTP 클라이언트
```

### Flutter
```yaml
dependencies:
  dio: ^5.0.0              # HTTP 클라이언트
  hive: ^2.0.0             # 로컬 캐싱
  provider: ^6.0.0         # 상태 관리 (기존)

  # API 클라이언트는 dio로 직접 구현
```

### 인프라
- **호스팅**: Vercel (무료/Pro $20/월) 또는 Railway ($5/월)
- **캐싱**: Redis Cloud (무료 티어 30MB)
- **모니터링**: Sentry (무료 티어)

---

## 📝 구현 체크리스트

### Phase 2 구현 순서

- [ ] **1주차: 백엔드 기초**
  - [ ] FastAPI 프로젝트 생성
  - [ ] URL 파싱 로직 (플랫폼 감지)
  - [ ] YouTube Shorts 지원
    - [ ] youtube-transcript-api 통합
    - [ ] Whisper API fallback
  - [ ] Redis 캐싱 설정
  - [ ] Rate limiting 구현

- [ ] **2주차: Flutter 통합**
  - [ ] API 클라이언트 (dio)
  - [ ] UI/UX (URL 입력 → 결과 표시)
  - [ ] 에러 핸들링
  - [ ] 로딩 상태 관리
  - [ ] 로컬 캐싱 (Hive)

- [ ] **3주차: TikTok & Instagram Reels (선택)**
  - [ ] TikTok 지원
    - [ ] Supadata/Apify API 통합
    - [ ] Whisper fallback
    - [ ] Rate limiting (분당 5회)
  - [ ] Instagram Reels (메타데이터만)
    - [ ] Apify 통합
    - [ ] 수동 입력 UI
  - [ ] 사용자 동의 다이얼로그

- [ ] **4주차: 테스트 & 배포**
  - [ ] 단위 테스트
  - [ ] 통합 테스트
  - [ ] 비용 모니터링 설정
  - [ ] Vercel/Railway 배포
  - [ ] 문서화

---

## 💡 결론

### ✅ 최종 권장사항: Phase 2 - 하이브리드 접근

**이유:**
1. ✅ Recipesoup의 오프라인 우선 철학과 충돌하지 않음 (선택적 기능)
2. ✅ 월 $10-20은 개인 프로젝트로 감당 가능
3. ✅ 80-85% 커버리지로 대부분 사용 사례 충족
4. ✅ 확장 가능한 아키텍처 (나중에 Phase 3 가능)
5. ✅ 법적 리스크 최소화 (공개 데이터 + rate limit)
6. ✅ YouTube Shorts 완벽 지원
7. ✅ TikTok 자막 지원 좋음 (Apify 무료 티어로 충분)
8. ⚠️ Instagram Reels는 제한적 (캡션만)

### 🎯 Phase 2 플랫폼 우선순위
```
1순위: YouTube Shorts (완전 지원, 무료)
2순위: TikTok (자막 좋음, 거의 무료)
3순위: Instagram Reels (메타데이터만, 제한적)
```

### 🚀 다음 단계
- **1주차**: YouTube Shorts 전용 MVP 구현
- **2주차**: TikTok 추가 (Apify 무료 티어 활용)
- **3주차**: 사용자 피드백 수집
- **선택**: Instagram Reels 캡션만 추가 (1-2일)
- **장기**: Phase 3 고려 (OCR, 고급 분석)

---

**문서 작성일**: 2025-10-07
**프로젝트**: Recipesoup - 감정 기반 레시피 아카이빙 앱
**작성자**: Claude Code Analysis
