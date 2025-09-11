import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'constants.dart';

/// OpenAI API 설정 관리
/// 환경변수(.env)에서 API 키를 가져와 안전하게 관리

class ApiConfig {
  // OpenAI API 설정
  static const String baseUrl = 'https://api.openai.com/v1';
  static const String chatCompletionsEndpoint = '/chat/completions';
  static const String model = AppConstants.openAiModel; // gpt-4o-mini
  
  /// OpenAI API 키 가져오기 및 검증
  static String? get openAiApiKey {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    
    if (apiKey == null || apiKey.isEmpty) {
      throw ApiConfigException(
        'OPENAI_API_KEY not found in .env file. '
        'Please add your API key to .env file.'
      );
    }
    
    // API 키 형식 검증 (OpenAI API 키는 sk-로 시작)
    if (!apiKey.startsWith('sk-')) {
      throw ApiConfigException(
        'Invalid OpenAI API key format. API key should start with "sk-"'
      );
    }
    
    return apiKey;
  }
  
  /// API 모델 설정 가져오기 (.env에서 커스텀 모델 사용 가능)
  static String get apiModel {
    return dotenv.env['API_MODEL'] ?? model;
  }
  
  /// API 타임아웃 설정
  static Duration get timeout => const Duration(seconds: AppConstants.apiTimeoutSeconds);
  
  /// API 재시도 횟수
  static int get retryAttempts => AppConstants.apiRetryAttempts;
  
  /// 요청 헤더 생성
  static Map<String, String> get headers {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $openAiApiKey',
    };
  }
  
  /// 이미지 분석 요청 생성 (음식 사진 분석용)
  static Map<String, dynamic> createImageAnalysisRequest({
    required String base64Image,
    required String prompt,
    int? maxTokens,
  }) {
    return {
      'model': apiModel,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': prompt,
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/jpeg;base64,$base64Image',
              },
            },
          ],
        },
      ],
      'max_tokens': maxTokens ?? 500,
      'temperature': 0.7, // 창의성과 정확성 균형을 위한 설정
    };
  }

  /// 스크린샷 감지 요청 생성 (빠른 판별용)
  static Map<String, dynamic> createScreenshotDetectionRequest({
    required String base64Image,
  }) {
    return {
      'model': apiModel,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': screenshotDetectionPrompt,
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/jpeg;base64,$base64Image',
              },
            },
          ],
        },
      ],
      'max_tokens': 20, // 간단한 true/false 답변만 필요
      'temperature': 0.1, // 정확성을 위해 매우 낮은 temperature
    };
  }

  /// 한글 특화 스크린샷 분석 요청 생성
  static Map<String, dynamic> createKoreanScreenshotAnalysisRequest({
    required String base64Image,
    int? maxTokens,
  }) {
    return {
      'model': apiModel,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': koreanScreenshotAnalysisPrompt,
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/jpeg;base64,$base64Image',
              },
            },
          ],
        },
      ],
      'max_tokens': maxTokens ?? 1000, // 한글 OCR + 분석을 위해 충분한 토큰
      'temperature': 0.2, // OCR 정확성과 자연스러운 분석의 균형
    };
  }
  
  /// 텍스트 분석 요청 생성 (블로그 텍스트 분석용)
  static Map<String, dynamic> createTextAnalysisRequest({
    required String text,
    int? maxTokens,
  }) {
    return {
      'model': apiModel,
      'messages': [
        {
          'role': 'user',
          'content': createTextAnalysisPrompt(text),
        },
      ],
      'max_tokens': maxTokens ?? 800,
      'temperature': 0.3, // 일관성을 위해 낮은 temperature
    };
  }

  /// 키워드 기반 퀵레시피 생성 요청
  static Map<String, dynamic> createKeywordRecipeRequest({
    required String keyword,
    int? maxTokens,
  }) {
    return {
      'model': apiModel,
      'messages': [
        {
          'role': 'user',
          'content': createKeywordRecipePrompt(keyword),
        },
      ],
      'max_tokens': maxTokens ?? 800,
      'temperature': 0.7, // 창의적인 레시피 생성을 위해
    };
  }
  
  /// 스크린샷 여부 간단 감지용 프롬프트
  static String get screenshotDetectionPrompt {
    return '''
이 이미지가 스크린샷(SNS 게시물, 앱 화면, 웹페이지 캡처 등)인지 일반 음식 사진인지만 판단해주세요.

스크린샷 특징:
- UI 요소 (버튼, 아이콘, 상태바)
- 텍스트 오버레이
- SNS 인터페이스 (좋아요, 댓글 등)
- 앱 화면이나 웹페이지

{"is_screenshot": true/false} 형식으로만 답변해주세요.''';
  }

  /// 한글 특화 스크린샷 OCR 및 음식 분석용 프롬프트
  static String get koreanScreenshotAnalysisPrompt {
    return '''
이것은 한국어 텍스트가 포함된 요리 관련 스크린샷입니다. 다음 작업을 수행해주세요:

**1단계: 한글 텍스트 정확 추출**
- 이미지의 모든 한글 텍스트를 정확히 읽어주세요
- 재료명, 분량, 조리법 등 요리 관련 정보를 놓치지 마세요
- 특히 "큰술", "작은술", "컵", "g", "ml" 등 단위를 정확히 읽어주세요

**2단계: 스마트 레시피 완성**
- 추출한 텍스트 정보가 부분적이라면 해당 요리에 필요한 기본 재료들을 AI가 보완해주세요
- 예: "히야시추카소바"라면 중화면, 계란, 오이, 토마토 등 기본 재료 추가
- 조리법은 단계별로 명확하게 작성하되, 순서 번호는 절대 중복하지 마세요

**중요한 분류 기준 (URL import와 동일):**
- ingredients: 고기, 채소, 곡물, 해산물, 유제품 등 주된 재료만 포함
- sauce: 기름(올리브오일, 참기름), 양념(소금, 후추, 간장, 된장), 향신료(마늘, 생강), 소스류 모두 포함

아래 JSON 형식으로 답변해주세요:

{
  "is_screenshot": true,
  "extracted_text": "이미지에서 추출한 모든 텍스트를 여기에 정확히 기록",
  "dish_name": "요리 이름 (한국어)",
  "ingredients": [
    {"name": "재료명", "amount": "분량"}
  ],
  "sauce": "참기름 1큰술, 간장 1큰술, 고춧가루 1작은술, 마늘 2쪽, 소금 적당량",
  "instructions": [
    "첫 번째 조리 단계",
    "두 번째 조리 단계",
    "세 번째 조리 단계"
  ],
  "estimated_time": "예상 시간",
  "difficulty": "쉬움/보통/어려움",
  "servings": "인분 수",
  "tags": ["#스크린샷", "#한식", "#기타태그"]
}

**🔥 매우 중요한 주의사항:**
1. **extracted_text**: 이미지의 모든 텍스트를 빠짐없이 정확히 기록
2. **재료 보완**: 스크린샷에 소스 비율만 있다면 해당 요리의 기본 재료들을 AI가 추가 (예: 히야시추카소바 → 중화면, 계란, 오이, 토마토 등)
3. **분량 정확성**: "2인분"이면 모든 재료를 2인분 기준으로 구체적 분량 제시 (예: 중화면 200g, 계란 2개)
4. **조리법 상세성**: 해당 요리의 특성에 맞는 상세한 조리법 작성 (예: 히야시추카소바면 찬물에 면 헹구기, 얼음물 준비, 고명 배치 등)
5. **정확한 태그**: 요리의 원산지에 맞는 태그 사용 (히야시추카소바 → #일식, 김치찌개 → #한식)
6. **불필요한 태그 제거**: #스크린샷 같은 기술적 태그는 절대 포함하지 마세요
7. **조리법 순서**: instructions 배열의 각 항목은 "재료를 준비한다", "면을 삶는다" 식으로 작성하고, "1.", "2." 같은 순서 번호는 절대 포함하지 마세요
8. **단위 정확성**: "큰술", "작은술", "컵", "g", "ml" 등을 정확히 인식
9. **소스 분량 철저**: sauce 필드에는 URL import처럼 정확한 분량과 함께 기록 (예: "간장 2큰술, 식초 2큰술, 설탕 2큰술, 참기름 1큰술")
10. **재료와 소스 분리**: ingredients는 주재료만, sauce는 모든 조미료/양념을 구체적 분량과 함께

한국어로 자연스럽게 답변해주세요.''';
  }

  /// 음식 사진 분석용 프롬프트 템플릿 생성
  static String get foodAnalysisPrompt {
    return '''
이 음식 사진을 분석해서 아래 형식의 JSON 형태로 답변해주세요:

1. dish_name: 요리 이름 (한국어)
2. ingredients: 주재료 리스트 (조미료, 소스, 양념 제외)
3. sauce: 소스/조미료/양념 (기름, 소금, 간장, 설탕, 향신료 등 모든 조미료)
4. instructions: 조리법 단계 (3-7단계)
5. estimated_time: 예상 조리 시간
6. difficulty: 난이도 (쉬움/보통/어려움)
7. servings: 예상 인분 수

**중요한 분류 기준:**
- ingredients: 고기, 채소, 곡물, 해산물, 유제품 등 주된 재료만 포함
- sauce: 기름(올리브오일, 참기름), 양념(소금, 후추, 간장, 된장), 향신료(마늘, 생강), 소스류 모두 포함

JSON 형식 예제:
{
  "dish_name": "스파게티 나폴리탄",
  "ingredients": [
    {"name": "스파게티 면", "amount": "200g"},
    {"name": "양파", "amount": "1개"},
    {"name": "피망", "amount": "1개"},
    {"name": "소세지", "amount": "100g"}
  ],
  "sauce": "토마토 소스 1컵, 올리브오일 2큰술, 소금 적당량, 후추 적당량, 마늘 2쪽",
  "instructions": [
    "큰 냄비에 물을 끓이고 소금을 넣은 후 스파게티 면을 삶는다",
    "양파와 피망을 썰고 소세지를 볶는다",
    "토마토 소스와 조미료를 넣고 볶는다",
    "삶은 면을 넣고 잘 섞어 완성한다"
  ],
  "estimated_time": "20분",
  "difficulty": "쉬움",
  "servings": "2인분",
  "tags": ["#이탈리안", "#파스타", "#간편식", "#혼밥"]
}

중요: 
1. instructions는 "1단계:", "첫 번째" 같은 순서 표시 없이 바로 조리 방법만 적어주세요. UI에서 자동으로 번호를 매깁니다.
2. 재료와 소스/조미료를 철저히 분리해서 작성해주세요.
3. tags는 요리 종류, 상황, 감정을 나타내는 적절한 해시태그 2-4개를 생성해주세요 (예: #한식, #간편식, #혼밥, #편안함).

한국 요리명과 한국어로 자연스럽게 답변해주세요.
''';
  }
  
  /// 텍스트 기반 레시피 분석용 프롬프트 템플릿 (블로그 등)
  static String createTextAnalysisPrompt(String blogText) {
    return '''
다음 블로그 텍스트에서 레시피 정보를 추출해서 아래 형식의 JSON으로 답변해주세요:

블로그 내용:
"""
$blogText
"""

추출할 정보:
1. dish_name: 요리 이름 (한국어)
2. ingredients: 주재료 리스트 (조미료, 소스, 양념 제외)
3. sauce: 소스/조미료/양념 (기름, 소금, 간장, 설탕, 향신료 등 모든 조미료)
4. instructions: 조리법 단계 (3-7단계로 정리)
5. estimated_time: 예상 조리 시간
6. difficulty: 난이도 (쉬움/보통/어려움)
7. servings: 예상 인분 수
8. tips: 조리 팁이나 주의사항 (있다면)

**중요한 분류 기준:**
- ingredients: 고기, 채소, 곡물, 해산물, 유제품 등 주된 재료만 포함
- sauce: 기름(올리브오일, 참기름), 양념(소금, 후추, 간장, 된장), 향신료(마늘, 생강), 소스류 모두 포함

JSON 형식 예제:
{
  "dish_name": "김치찌개",
  "ingredients": [
    {"name": "김치", "amount": "200g"},
    {"name": "돼지고기", "amount": "150g"},
    {"name": "두부", "amount": "1/2모"}
  ],
  "sauce": "참기름 1큰술, 간장 1큰술, 고춧가루 1작은술, 마늘 2쪽, 소금 적당량",
  "instructions": [
    "김치를 기름에 볶는다",
    "돼지고기를 넣고 함께 볶는다",
    "물을 넣고 끓인다"
  ],
  "estimated_time": "30분",
  "difficulty": "쉬움",
  "servings": "2-3인분",
  "tags": ["#한식", "#김치찌개", "#국물요리", "#가족식사"],
  "tips": ["김치가 신 것을 사용하면 더 맛있다", "두부는 나중에 넣어야 부서지지 않는다"]
}

중요: 
1. instructions는 "1단계:", "첫 번째" 같은 순서 표시 없이 바로 조리 방법만 적어주세요. UI에서 자동으로 번호를 매깁니다.
2. 재료와 소스/조미료를 철저히 분리해서 작성해주세요.
3. tags는 요리 종류, 상황, 감정을 나타내는 적절한 해시태그 2-4개를 생성해주세요 (예: #한식, #간편식, #혼밥, #편안함).

한국 요리명과 한국어로 자연스럽게 답변하고, 만약 레시피 내용이 명확하지 않다면 가능한 범위에서 추정해서 작성해주세요.
''';
  }

  /// 키워드 기반 퀵레시피 생성 프롬프트 템플릿
  static String createKeywordRecipePrompt(String keyword) {
    return '''
"$keyword" 레시피를 자세히 만들어주세요. 한국어로 답변하고 다음 JSON 형식을 정확히 따라주세요:

**중요한 분류 기준:**
- ingredients: 고기, 채소, 곡물, 해산물, 유제품 등 주된 재료만 포함
- sauce: 기름(올리브오일, 참기름), 양념(소금, 후추, 간장, 된장), 향신료(마늘, 생강), 소스류 모두 포함

{
  "dish_name": "요리 이름",
  "ingredients": [
    {"name": "재료명", "amount": "양"},
    {"name": "재료명", "amount": "양"}
  ],
  "sauce": "소스/조미료/양념 (기름, 소금, 간장, 설탕, 향신료 등)",
  "instructions": [
    "큰 냄비에 물을 끓이고 소금을 넣은 후 스파게티 면을 포장지에 적힌 시간만큼 삶는다",
    "면이 삶아지는 동안, 양파와 피망을 얇게 썰고 소세지는 반으로 자른다"
  ],
  "estimated_time": "조리 시간",
  "difficulty": "난이도 (쉬움/보통/어려움)",
  "servings": "인분 수",
  "tags": ["#요리종류", "#상황", "#감정"]
}

중요: 
1. instructions 배열의 각 항목은 "1단계:", "2단계:" 같은 순서 표시 없이 바로 조리 방법만 적어주세요. UI에서 자동으로 번호를 매깁니다.
2. 재료와 소스/조미료를 철저히 분리해서 작성해주세요.
3. 재료와 조리법을 상세하고 실용적으로 작성해주세요. 초보자도 따라할 수 있도록 단계별로 설명해주세요.
4. tags는 요리 종류, 상황, 감정을 나타내는 적절한 해시태그 2-4개를 생성해주세요 (예: #한식, #간편식, #혼밥, #편안함).
''';
  }
  
  /// 통계 분석용 프롬프트 템플릿 생성
  static String createStatsAnalysisPrompt(List<Map<String, dynamic>> recipeData) {
    return '''
아래 레시피 데이터를 분석해서 개인 요리 패턴 (4줄 요약 정도)을 분석해주세요:

레시피 데이터:
${recipeData.toString()}

분석해서 아래 항목들을 중심으로 간결하게 텍스트로 작성해주세요:
1. 자주 만드는 요리 종류 top 3
2. 요리하는 감정 패턴 분석
3. 요리 빈도와 패턴
4. 개인적인 요리 특징과
5. 앞으로의 요리 추천

250자 이내로 간결하게 정리해서 작성해주세요.
''';
  }
  
  /// API 상태 확인을 위한 간단한 요청
  static Map<String, dynamic> get healthCheckRequest {
    return {
      'model': apiModel,
      'messages': [
        {
          'role': 'user',
          'content': 'Hello',
        },
      ],
      'max_tokens': 5,
    };
  }
  
  /// 환경변수 초기화
  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');
  }
  
  /// API 키 유효성 검증
  static bool validateApiKey() {
    try {
      final key = openAiApiKey;
      return key != null && key.isNotEmpty && key.startsWith('sk-');
    } catch (e) {
      return false;
    }
  }
  
  /// 디버그/릴리즈 모드 확인
  static bool get isDebugMode {
    final debugMode = dotenv.env['DEBUG_MODE'];
    return debugMode?.toLowerCase() == 'true';
  }
  
  /// 앱 버전 확인 (.env에서 커스텀 버전 사용 가능)
  static String get appVersion {
    return dotenv.env['APP_VERSION'] ?? AppConstants.appVersion;
  }
}

/// API 설정 관련 예외 클래스들

class ApiConfigException implements Exception {
  final String message;
  
  const ApiConfigException(this.message);
  
  @override
  String toString() => 'ApiConfigException: $message';
}

/// API 응답 관련 예외 클래스들
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  
  const ApiException(this.message, {this.statusCode, this.code});
  
  @override
  String toString() => 'ApiException: $message (Status: $statusCode, Code: $code)';
}

class NetworkException extends ApiException {
  const NetworkException(super.message);
}

class RateLimitException extends ApiException {
  const RateLimitException(super.message) : super(statusCode: 429, code: 'rate_limit_exceeded');
}

class InvalidApiKeyException extends ApiException {
  const InvalidApiKeyException(super.message) : super(statusCode: 401, code: 'invalid_api_key');
}

class InvalidImageException extends ApiException {
  const InvalidImageException(super.message) : super(statusCode: 400, code: 'invalid_image');
}

class ServerException extends ApiException {
  const ServerException(super.message, int statusCode) : super(statusCode: statusCode, code: 'server_error');
}

class TimeoutException extends ApiException {
  const TimeoutException(super.message) : super(code: 'timeout');
}