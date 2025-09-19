import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/recipe_analysis.dart';
import '../utils/unicode_sanitizer.dart';

/// AI 분석 로딩 상태 콜백 함수 타입
typedef LoadingProgressCallback = void Function(String message, double progress);

/// AI 분석 단계별 상태
enum AnalysisStep {
  preparing('레시피 재료 준비중', 0.1),
  uploading('이미지 업로드 중...', 0.3),
  cooking('AI로 레시피 분석중', 0.6),
  completing('레시피 작성 완료 🐰', 1.0);

  const AnalysisStep(this.message, this.progress);
  final String message;
  final double progress;
}

/// OpenAI API 서비스 클래스
/// Recipesoup 앱의 핵심 기능인 음식 사진 분석을 담당
class OpenAiService {
  final Dio _dio;

  OpenAiService({Dio? dio}) : _dio = dio ?? _createDefaultDio();

  /// 기본 Dio 인스턴스 생성
  static Dio _createDefaultDio() {
    final dio = Dio();
    
    // 기본 설정
    dio.options = BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
      sendTimeout: ApiConfig.timeout,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    // 로그 인터셉터 (디버그 모드에서만)
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: false, // API 키 보안을 위해 request body 로그 비활성화
        responseBody: true,
        logPrint: (obj) => developer.log(obj.toString(), name: 'OpenAI API'),
      ));
    }

    return dio;
  }

  /// 음식 사진 분석 (핵심 기능!) - 스크린샷 자동 감지 및 OCR 포함
  /// 
  /// [imageData]: Base64 인코딩된 이미지 데이터
  /// [onProgress]: 로딩 진행상황 콜백 (옵션)
  /// Returns: [RecipeAnalysis] 분석 결과
  /// 
  /// 이미지 타입을 자동으로 감지해서:
  /// - 스크린샷인 경우: OCR로 텍스트 추출 + 음식 분석 동시 수행
  /// - 일반 음식 사진인 경우: 기존 방식으로 음식 분석
  /// 
  /// Throws:
  /// - [InvalidApiKeyException]: API 키가 잘못된 경우
  /// - [RateLimitException]: API 호출 한도 초과
  /// - [InvalidImageException]: 이미지 형식이 잘못된 경우
  /// - [ServerException]: 서버 오류 (5xx)
  /// - [NetworkException]: 네트워크 연결 오류
  /// - [TimeoutException]: 요청 타임아웃
  /// - [ApiException]: 기타 API 오류
  Future<RecipeAnalysis> analyzeImage(
    String imageData, {
    LoadingProgressCallback? onProgress,
  }) async {
    return await _retryOperation(() => _analyzeImageWithAutoDetection(imageData, onProgress: onProgress));
  }

  /// 스크린샷 여부 자동 감지 및 적절한 분석 방식 선택 (2단계 접근법)
  /// 1단계: 스크린샷 여부 빠른 감지
  /// 2단계: 감지 결과에 따른 적절한 프롬프트 선택
  Future<RecipeAnalysis> _analyzeImageWithAutoDetection(
    String imageData, {
    LoadingProgressCallback? onProgress,
  }) async {
    try {
      // API 키 검증
      if (!ApiConfig.validateApiKey()) {
        throw const InvalidApiKeyException('OpenAI API key is not configured');
      }

      // Base64 이미지 데이터 유효성 검증
      final validatedImageData = UnicodeSanitizer.validateBase64(imageData);
      if (validatedImageData == null) {
        throw const InvalidImageException('Invalid or corrupted image data');
      }

      onProgress?.call('이미지 타입 감지중 🔍', 0.1);
      await Future.delayed(Duration(milliseconds: 300));

      // 1단계: 스크린샷 여부 빠른 감지 (경량 API 호출)
      final isScreenshot = await _detectScreenshotType(validatedImageData);
      
      if (isScreenshot) {
        // 스크린샷인 경우: 한글 특화 OCR + 음식 분석
        onProgress?.call('스크린샷에서 한글 텍스트 추출중 📱', 0.3);
        return await _analyzeKoreanScreenshot(validatedImageData, onProgress: onProgress);
      } else {
        // 일반 음식 사진인 경우: 기존 방식 (fallback으로 안전성 보장)
        onProgress?.call('음식 사진 분석중 🍽️', 0.3);
        return await _analyzeImageOnce(validatedImageData, onProgress: onProgress);
      }

    } catch (e) {
      // 감지 실패시 기존 방식으로 fallback (사이드 이펙트 최소화)
      developer.log('Screenshot detection failed, falling back to regular analysis: $e', name: 'OpenAI Service');
      
      if (e is ApiException) {
        // API 관련 오류면 그대로 전파
        rethrow;
      } else {
        // 감지 오류면 기존 방식으로 fallback
        onProgress?.call('일반 음식 분석으로 처리중 🍽️', 0.3);
        // Base64 데이터 재검증 후 fallback
        final fallbackImageData = UnicodeSanitizer.validateBase64(imageData) ?? imageData;
        return await _analyzeImageOnce(fallbackImageData, onProgress: onProgress);
      }
    }
  }

  /// 스크린샷 여부 빠른 감지 (경량 API 호출)
  Future<bool> _detectScreenshotType(String imageData) async {
    try {
      final detectionRequest = ApiConfig.createScreenshotDetectionRequest(
        base64Image: imageData,
      );

      // Unicode 안전성 확보
      final sanitizedRequest = UnicodeSanitizer.sanitizeApiRequest(detectionRequest);

      final response = await _dio.post<Map<String, dynamic>>(
        ApiConfig.chatCompletionsEndpoint,
        data: sanitizedRequest,
        options: Options(
          headers: ApiConfig.headers,
        ),
      );

      if (response.data == null) {
        throw const ApiException('Empty response from screenshot detection');
      }

      final content = _extractContentFromResponse(response.data!);
      final detectionResult = _parseJsonResponse(content);
      
      return detectionResult['is_screenshot'] == true;

    } catch (e) {
      // 감지 실패시 false 반환 (안전한 기본값)
      developer.log('Screenshot detection failed: $e', name: 'OpenAI Service');
      return false;
    }
  }


  /// 한글 특화 스크린샷 분석 (OCR + 음식 분석)
  Future<RecipeAnalysis> _analyzeKoreanScreenshot(
    String imageData, {
    LoadingProgressCallback? onProgress,
  }) async {
    try {
      // 점진적 진행률 업데이트
      onProgress?.call('한글 텍스트 정확 추출중', 0.4);
      await Future.delayed(Duration(milliseconds: 500));

      // 한글 특화 스크린샷 분석 API 호출
      final requestData = ApiConfig.createKoreanScreenshotAnalysisRequest(
        base64Image: imageData,
        maxTokens: 1200, // 한글 OCR + 분석을 위해 충분한 토큰
      );

      // Unicode 안전성 확보
      final sanitizedRequest = UnicodeSanitizer.sanitizeApiRequest(requestData);

      onProgress?.call('AI로 한글 레시피 분석중 🥢', 0.6);
      await _showProgressiveCookingProgress(onProgress);

      final response = await _dio.post<Map<String, dynamic>>(
        ApiConfig.chatCompletionsEndpoint,
        data: sanitizedRequest,
        options: Options(
          headers: ApiConfig.headers,
        ),
      );

      if (response.data == null) {
        throw const ApiException('Empty response from Korean screenshot analysis');
      }

      final content = _extractContentFromResponse(response.data!);
      final analysisData = _parseJsonResponse(content);

      // 결과 검증 및 보완
      final result = RecipeAnalysis.fromApiResponse(analysisData);
      
      // 한글 텍스트 추출 성공 여부 로깅
      if (result.extractedText?.isNotEmpty == true) {
        developer.log('Korean OCR successful: ${result.extractedText?.length} characters extracted', name: 'OpenAI Service');
      } else {
        developer.log('Korean OCR yielded no text, but image analysis continues', name: 'OpenAI Service');
      }

      // 한글 스크린샷 분석 완료!
      onProgress?.call('한글 스크린샷 분석 완료! 📱🇰🇷', AnalysisStep.completing.progress);
      await Future.delayed(Duration(milliseconds: 500));

      return result;

    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error during Korean screenshot analysis: $e');
    }
  }

  /// 텍스트 기반 레시피 분석 (URL 스크래핑 결과 분석) - 로딩 상태 콜백 포함
  /// 
  /// [blogText]: 블로그 등에서 추출한 레시피 텍스트
  /// [onProgress]: 로딩 진행상황 콜백 (옵션)
  /// Returns: [RecipeAnalysis] 분석 결과
  /// 
  /// Throws: 동일한 예외 발생 가능
  Future<RecipeAnalysis> analyzeText(
    String blogText, {
    LoadingProgressCallback? onProgress,
  }) async {
    return await _retryOperation(() => _analyzeTextOnce(blogText, onProgress: onProgress));
  }

  /// 단일 텍스트 분석 수행 (재시도 로직 없이) - 로딩 상태 포함
  Future<RecipeAnalysis> _analyzeTextOnce(
    String blogText, {
    LoadingProgressCallback? onProgress,
  }) async {
    try {
      // API 키 검증
      if (!ApiConfig.validateApiKey()) {
        throw const InvalidApiKeyException('OpenAI API key is not configured');
      }

      // 텍스트 길이 제한 확인 (너무 긴 텍스트는 잘라냄)
      String processedText = blogText;
      if (blogText.length > 10000) {
        processedText = blogText.substring(0, 10000);
        developer.log('텍스트가 너무 길어서 10000자로 제한함', name: 'OpenAI Service');
      }

      // 텍스트 Unicode 안전성 확보
      processedText = UnicodeSanitizer.sanitize(processedText);

      // 점진적 진행률 업데이트 - AI로 레시피 분석중
      await _showProgressiveCookingProgress(onProgress);

      // 요청 데이터 구성
      final requestData = ApiConfig.createTextAnalysisRequest(
        text: processedText,
        maxTokens: 800,
      );

      // Unicode 안전성 확보
      final sanitizedRequest = UnicodeSanitizer.sanitizeApiRequest(requestData);

      // API 호출
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConfig.chatCompletionsEndpoint,
        data: sanitizedRequest,
        options: Options(
          headers: ApiConfig.headers,
        ),
      );

      // 응답 확인
      if (response.data == null) {
        throw const ApiException('Empty response from OpenAI API');
      }

      // 응답 파싱
      final content = _extractContentFromResponse(response.data!);
      final analysisData = _parseJsonResponse(content);

      // 레시피 작성 완료!
      onProgress?.call(AnalysisStep.completing.message, AnalysisStep.completing.progress);
      await Future.delayed(Duration(milliseconds: 500)); // 완료 메시지 표시

      return RecipeAnalysis.fromApiResponse(analysisData);

    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error during text analysis: $e');
    }
  }

  /// 단일 이미지 분석 수행 (재시도 로직 없이) - 로딩 상태 포함
  Future<RecipeAnalysis> _analyzeImageOnce(
    String imageData, {
    LoadingProgressCallback? onProgress,
  }) async {
    try {
      // 1단계: 준비 중
      onProgress?.call(AnalysisStep.preparing.message, AnalysisStep.preparing.progress);
      await Future.delayed(Duration(milliseconds: 300)); // UI 업데이트 대기
      
      // API 키 검증
      if (!ApiConfig.validateApiKey()) {
        throw const InvalidApiKeyException('OpenAI API key is not configured');
      }

      // 요청 데이터 구성
      final requestData = ApiConfig.createImageAnalysisRequest(
        base64Image: imageData,
        prompt: ApiConfig.foodAnalysisPrompt,
        maxTokens: 800, // 충분한 토큰 할당
      );

      // Unicode 안전성 확보
      final sanitizedRequest = UnicodeSanitizer.sanitizeApiRequest(requestData);

      // 점진적 진행률 업데이트 - AI로 레시피 분석중
      await _showProgressiveCookingProgress(onProgress);

      // API 호출
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConfig.chatCompletionsEndpoint,
        data: sanitizedRequest,
        options: Options(
          headers: ApiConfig.headers,
        ),
      );

      // 응답 확인
      if (response.data == null) {
        throw const ApiException('Empty response from OpenAI API');
      }

      // 응답 파싱
      final content = _extractContentFromResponse(response.data!);
      final analysisData = _parseJsonResponse(content);

      // 레시피 작성 완료!
      onProgress?.call(AnalysisStep.completing.message, AnalysisStep.completing.progress);
      await Future.delayed(Duration(milliseconds: 500)); // 완료 메시지 표시

      return RecipeAnalysis.fromApiResponse(analysisData);

    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error during image analysis: $e');
    }
  }

  /// API 응답에서 content 추출
  String _extractContentFromResponse(Map<String, dynamic> responseData) {
    try {
      final choices = responseData['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw const ApiException('No choices in API response');
      }

      final firstChoice = choices.first as Map<String, dynamic>;
      final message = firstChoice['message'] as Map<String, dynamic>?;
      if (message == null) {
        throw const ApiException('No message in API response');
      }

      final content = message['content'] as String?;
      if (content == null || content.isEmpty) {
        throw const ApiException('Empty content in API response');
      }

      return content.trim();
    } catch (e) {
      throw ApiException('Failed to extract content from API response: $e');
    }
  }

  /// JSON 응답 파싱
  Map<String, dynamic> _parseJsonResponse(String content) {
    try {
      // JSON 코드 블록 정리 (```json ... ``` 형식일 경우 추출)
      String jsonContent = content;
      
      // 코드 블록 패턴
      final codeBlockRegex = RegExp(r'```(?:json)?\s*(.*?)\s*```', dotAll: true);
      final match = codeBlockRegex.firstMatch(content);
      if (match != null) {
        jsonContent = match.group(1)?.trim() ?? content;
      }

      // JSON 파싱
      final parsed = jsonDecode(jsonContent);
      if (parsed is! Map<String, dynamic>) {
        throw const ApiException('API response is not a valid JSON object');
      }

      return parsed;
    } catch (e) {
      developer.log('JSON parsing error: $e\nContent: $content', name: 'OpenAI Service');
      throw ApiException('Failed to parse JSON response: $e');
    }
  }

  /// Dio 예외 처리
  ApiException _handleDioException(DioException e) {
    // 응답 기반 상태 코드 예외 처리
    final statusCode = e.response?.statusCode;
    final errorData = e.response?.data;

    switch (statusCode) {
      case 401:
        return const InvalidApiKeyException('Invalid or missing API key');
      case 429:
        return const RateLimitException('API rate limit exceeded. Please try again later');
      case 400:
        final message = _extractErrorMessage(errorData) ?? 'Bad request';
        return InvalidImageException('Invalid request: $message');
      case 500:
      case 502:
      case 503:
      case 504:
        final message = _extractErrorMessage(errorData) ?? 'Server error';
        return ServerException('OpenAI server error: $message', statusCode!);
      default:
        // DioExceptionType 기반 처리
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            return const TimeoutException('Request timeout. Please check your internet connection');
          case DioExceptionType.connectionError:
            return const NetworkException('Network connection error. Please check your internet connection');
          case DioExceptionType.badResponse:
            final message = _extractErrorMessage(errorData) ?? e.message ?? 'Unknown error';
            return ApiException('API error: $message', statusCode: statusCode);
          default:
            return ApiException('Request failed: ${e.message}', statusCode: statusCode);
        }
    }
  }

  /// 오류 응답에서 메시지 추출
  String? _extractErrorMessage(dynamic errorData) {
    if (errorData == null) return null;
    
    try {
      if (errorData is Map<String, dynamic>) {
        final error = errorData['error'];
        if (error is Map<String, dynamic>) {
          return error['message'] as String?;
        }
      }
    } catch (e) {
      // 오류 메시지 파싱 실패시 무시
    }
    
    return null;
  }

  /// 재시도 로직이 포함된 작업 수행
  Future<T> _retryOperation<T>(Future<T> Function() operation) async {
    Exception? lastException;

    for (int attempt = 1; attempt <= ApiConfig.retryAttempts; attempt++) {
      try {
        return await operation();
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());

        // 재시도하면 안 되는 예외들
        if (e is InvalidApiKeyException || 
            e is RateLimitException || 
            e is InvalidImageException) {
          rethrow;
        }

        // 마지막 시도에서 예외 발생시 재던지기
        if (attempt == ApiConfig.retryAttempts) {
          rethrow;
        }

        // 재시도 전 대기 (exponential backoff)
        final delay = Duration(milliseconds: 1000 * attempt);
        await Future.delayed(delay);

        developer.log(
          'Retrying OpenAI API call (attempt $attempt/${ApiConfig.retryAttempts})',
          name: 'OpenAI Service',
        );
      }
    }

    // 이곳에 도달할 수 없지만, 타입 안전성을 위해 예외 던지기
    throw lastException ?? const ApiException('Unknown retry error');
  }

  /// API 상태 확인 (헬스 체크)
  Future<bool> checkApiHealth() async {
    try {
      // Unicode 안전성 확보
      final sanitizedRequest = UnicodeSanitizer.sanitizeApiRequest(ApiConfig.healthCheckRequest);

      final response = await _dio.post<Map<String, dynamic>>(
        ApiConfig.chatCompletionsEndpoint,
        data: sanitizedRequest,
        options: Options(
          headers: ApiConfig.headers,
        ),
      );

      return response.statusCode == 200 && response.data != null;
    } catch (e) {
      developer.log('API health check failed: $e', name: 'OpenAI Service');
      return false;
    }
  }

  /// 점진적 진행률 업데이트 - AI로 레시피 분석중 단계
  /// 30% → 40% → 50% → 60% → 70% → 80% → 90% → 100% 점진적 증가
  Future<void> _showProgressiveCookingProgress(LoadingProgressCallback? onProgress) async {
    if (onProgress == null) return;
    
    // 점진적 진행률 단계 정의
    final progressSteps = [
      {'progress': 0.3, 'message': 'AI로 레시피 분석중', 'delay': 200},
      {'progress': 0.4, 'message': 'AI로 레시피 분석중', 'delay': 300},
      {'progress': 0.5, 'message': 'AI로 레시피 분석중', 'delay': 400},
      {'progress': 0.6, 'message': 'AI로 레시피 분석중', 'delay': 500},
      {'progress': 0.7, 'message': 'AI로 레시피 분석중', 'delay': 400},
      {'progress': 0.8, 'message': 'AI로 레시피 분석중', 'delay': 300},
      {'progress': 0.9, 'message': 'AI로 레시피 분석중', 'delay': 200},
      {'progress': 0.95, 'message': '레시피 마무리중', 'delay': 200},
    ];
    
    // 각 단계별로 점진적 업데이트
    for (final step in progressSteps) {
      onProgress(
        step['message'] as String,
        step['progress'] as double,
      );
      await Future.delayed(Duration(milliseconds: step['delay'] as int));
    }
  }

  /// 리소스 정리 (메모리 해제)
  void dispose() {
    _dio.close();
  }
}