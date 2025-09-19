import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:recipesoup/services/openai_service.dart';
import 'package:recipesoup/config/api_config.dart';

// Mock 클래스 생성을 위한 어노테이션
@GenerateMocks([Dio])
import 'openai_service_test.mocks.dart';

void main() {
  group('OpenAI Service Tests', () {
    late OpenAiService service;
    late MockDio mockDio;

    setUpAll(() async {
      // 테스트용 환경변수 설정
      dotenv.testLoad(fileInput: '''
OPENAI_API_KEY=sk-test-key-for-testing-only-not-real
API_MODEL=gpt-4o-mini
DEBUG_MODE=false
''');
    });

    setUp(() {
      mockDio = MockDio();
      service = OpenAiService(dio: mockDio);
    });

    group('음식 사진 분석 테스트 (핵심 기능!)', () {
      test('should analyze food image successfully', () async {
        // Given
        const testImageData = 'test_base64_image_data';
        final mockResponse = Response<Map<String, dynamic>>(
          data: {
            'choices': [
              {
                'message': {
                  'content': '''
{
  "dish_name": "김치찌개",
  "ingredients": [
    {"name": "김치", "amount": "200g"},
    {"name": "돼지고기", "amount": "150g"},
    {"name": "두부", "amount": "1/2모"}
  ],
  "instructions": [
    "김치를 기름에 볶는다",
    "돼지고기를 넣고 함께 볶는다",
    "물을 넣고 끓인다"
  ],
  "estimated_time": "30분",
  "difficulty": "쉬움",
  "servings": "2-3인분"
}
                  '''
                }
              }
            ]
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')))
            .thenAnswer((_) async => mockResponse);

        // When
        final result = await service.analyzeImage(testImageData);

        // Then
        expect(result.dishName, equals('김치찌개'));
        expect(result.ingredients, hasLength(3));
        expect(result.ingredients.first.name, equals('김치'));
        expect(result.ingredients.first.amount, equals('200g'));
        expect(result.instructions, hasLength(3));
        expect(result.instructions.first, contains('김치'));
        expect(result.estimatedTime, equals('30분'));
        expect(result.difficulty, equals('쉬움'));
        expect(result.servings, equals('2-3인분'));

        // API 호출 검증
        verify(mockDio.post(
          '${ApiConfig.baseUrl}${ApiConfig.chatCompletionsEndpoint}',
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).called(1);
      });

      test('should handle testimg1.jpg analysis (김치찌개)', () async {
        // Given - TESTDATA.md의 testimg1 시나리오
        const testImageData = 'testimg1_base64_data';
        final mockResponse = Response<Map<String, dynamic>>(
          data: {
            'choices': [
              {
                'message': {
                  'content': '''
{
  "dish_name": "김치찌개",
  "ingredients": [
    {"name": "김치", "amount": "200g"},
    {"name": "돼지고기", "amount": "150g"},
    {"name": "두부", "amount": "1/2모"},
    {"name": "양파", "amount": "1/2개"},
    {"name": "대파", "amount": "1대"}
  ],
  "instructions": [
    "김치를 기름에 볶는다",
    "돼지고기를 넣고 함께 볶는다", 
    "물을 넣고 끓인다",
    "두부와 양파를 넣는다",
    "대파를 넣고 마무리한다"
  ],
  "estimated_time": "30분",
  "difficulty": "쉬움",
  "servings": "2-3인분"
}
                  '''
                }
              }
            ]
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')))
            .thenAnswer((_) async => mockResponse);

        // When
        final result = await service.analyzeImage(testImageData);

        // Then - TESTDATA.md 예상 결과와 일치
        expect(result.dishName, equals('김치찌개'));
        expect(result.ingredients.map((i) => i.name).toList(), 
               containsAll(['김치', '돼지고기', '두부', '양파', '대파']));
        expect(result.difficulty, equals('쉬움'));
        expect(result.servings, equals('2-3인분'));
      });

      test('should handle testimg2.jpg analysis (파스타)', () async {
        // Given - TESTDATA.md의 testimg2 시나리오
        const testImageData = 'testimg2_base64_data';
        final mockResponse = Response<Map<String, dynamic>>(
          data: {
            'choices': [
              {
                'message': {
                  'content': '''
{
  "dish_name": "토마토 파스타",
  "ingredients": [
    {"name": "파스타면", "amount": "200g"},
    {"name": "토마토소스", "amount": "1캔"},
    {"name": "마늘", "amount": "3쪽"},
    {"name": "올리브오일", "amount": "2큰술"},
    {"name": "바질", "amount": "적당량"}
  ],
  "instructions": [
    "파스타면을 삶는다",
    "마늘을 올리브오일에 볶는다",
    "토마토소스를 넣고 끓인다",
    "삶은 면을 넣고 섞는다",
    "바질을 올려 완성한다"
  ],
  "estimated_time": "20분",
  "difficulty": "보통",
  "servings": "1-2인분"
}
                  '''
                }
              }
            ]
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')))
            .thenAnswer((_) async => mockResponse);

        // When
        final result = await service.analyzeImage(testImageData);

        // Then - TESTDATA.md 예상 결과와 일치
        expect(result.dishName, equals('토마토 파스타'));
        expect(result.ingredients.map((i) => i.name).toList(),
               containsAll(['파스타면', '토마토소스', '마늘', '올리브오일', '바질']));
        expect(result.difficulty, equals('보통'));
        expect(result.servings, equals('1-2인분'));
      });

      test('should handle testimg3.jpg analysis (한정식)', () async {
        // Given - TESTDATA.md의 testimg3 시나리오 (복잡한 상차림)
        const testImageData = 'testimg3_base64_data';
        final mockResponse = Response<Map<String, dynamic>>(
          data: {
            'choices': [
              {
                'message': {
                  'content': '''
{
  "dish_name": "한정식 상차림",
  "ingredients": [
    {"name": "밥", "amount": "4공기"},
    {"name": "미역국", "amount": "1냄비"},
    {"name": "김치", "amount": "적당량"},
    {"name": "나물 반찬", "amount": "여러 종류"},
    {"name": "구이", "amount": "1가지"}
  ],
  "instructions": [
    "각각의 반찬을 정성스럽게 준비한다",
    "상에 조화롭게 배치한다", 
    "국과 밥을 함께 차린다"
  ],
  "estimated_time": "2시간 이상",
  "difficulty": "어려움",
  "servings": "4인분 이상"
}
                  '''
                }
              }
            ]
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')))
            .thenAnswer((_) async => mockResponse);

        // When
        final result = await service.analyzeImage(testImageData);

        // Then - TESTDATA.md 예상 결과와 일치
        expect(result.dishName, equals('한정식 상차림'));
        expect(result.difficulty, equals('어려움'));
        expect(result.servings, equals('4인분 이상'));
        expect(result.estimatedTime, equals('2시간 이상'));
      });
    });

    group('API 에러 처리 테스트 (예외 케이스)', () {
      test('should throw InvalidApiKeyException for 401 error', () async {
        // Given
        const testImageData = 'test_image';
        when(mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            statusCode: 401,
            data: {'error': {'message': 'Incorrect API key'}},
            requestOptions: RequestOptions(path: '/test'),
          ),
        ));

        // When & Then
        expect(
          () => service.analyzeImage(testImageData),
          throwsA(isA<InvalidApiKeyException>()),
        );
      });

      test('should throw RateLimitException for 429 error', () async {
        // Given
        const testImageData = 'test_image';
        when(mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            statusCode: 429,
            data: {'error': {'message': 'Rate limit reached'}},
            requestOptions: RequestOptions(path: '/test'),
          ),
        ));

        // When & Then
        expect(
          () => service.analyzeImage(testImageData),
          throwsA(isA<RateLimitException>()),
        );
      });

      test('should throw InvalidImageException for 400 error', () async {
        // Given
        const testImageData = 'invalid_image_data';
        when(mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            statusCode: 400,
            data: {'error': {'message': 'Invalid image format'}},
            requestOptions: RequestOptions(path: '/test'),
          ),
        ));

        // When & Then
        expect(
          () => service.analyzeImage(testImageData),
          throwsA(isA<InvalidImageException>()),
        );
      });

      test('should throw ServerException for 5xx errors', () async {
        // Given
        const testImageData = 'test_image';
        when(mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            statusCode: 500,
            data: {'error': {'message': 'Internal server error'}},
            requestOptions: RequestOptions(path: '/test'),
          ),
        ));

        // When & Then
        expect(
          () => service.analyzeImage(testImageData),
          throwsA(isA<ServerException>()),
        );
      });

      test('should throw NetworkException for connection error', () async {
        // Given
        const testImageData = 'test_image';
        when(mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionError,
          message: 'Connection failed',
        ));

        // When & Then
        expect(
          () => service.analyzeImage(testImageData),
          throwsA(isA<NetworkException>()),
        );
      });

      test('should throw TimeoutException for timeout', () async {
        // Given
        const testImageData = 'test_image';
        when(mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.receiveTimeout,
          message: 'Receive timeout',
        ));

        // When & Then
        expect(
          () => service.analyzeImage(testImageData),
          throwsA(isA<TimeoutException>()),
        );
      });
    });

    group('JSON 파싱 테스트', () {
      test('should handle malformed JSON response', () async {
        // Given
        const testImageData = 'test_image';
        final mockResponse = Response<Map<String, dynamic>>(
          data: {
            'choices': [
              {
                'message': {
                  'content': 'Invalid JSON content that cannot be parsed'
                }
              }
            ]
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')))
            .thenAnswer((_) async => mockResponse);

        // When & Then
        expect(
          () => service.analyzeImage(testImageData),
          throwsA(isA<ApiException>()),
        );
      });

      test('should handle empty response', () async {
        // Given
        const testImageData = 'test_image';
        final mockResponse = Response<Map<String, dynamic>>(
          data: {},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')))
            .thenAnswer((_) async => mockResponse);

        // When & Then
        expect(
          () => service.analyzeImage(testImageData),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('재시도 로직 테스트', () {
      test('should retry on temporary failure and succeed', () async {
        // Given
        const testImageData = 'test_image';
        final successResponse = Response<Map<String, dynamic>>(
          data: {
            'choices': [
              {
                'message': {
                  'content': '''
{
  "dish_name": "재시도 성공",
  "ingredients": [{"name": "테스트", "amount": "1개"}],
  "instructions": ["재시도 테스트"],
  "estimated_time": "1분",
  "difficulty": "쉬움",
  "servings": "1인분"
}
                  '''
                }
              }
            ]
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        // 첫 번째 호출은 실패, 두 번째 호출은 성공을 위한 카운터
        int callCount = 0;
        when(mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')))
            .thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            // 첫 번째 호출: 실패
            throw DioException(
              requestOptions: RequestOptions(path: '/test'),
              type: DioExceptionType.connectionError,
            );
          } else {
            // 두 번째 호출: 성공
            return successResponse;
          }
        });

        // When
        final result = await service.analyzeImage(testImageData);

        // Then
        expect(result.dishName, equals('재시도 성공'));
        verify(mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')))
            .called(2); // 재시도로 인해 2번 호출
      });
    });

    group('API 설정 테스트', () {
      test('should use correct API endpoint and headers', () async {
        // Given
        const testImageData = 'test_image';
        final mockResponse = Response<Map<String, dynamic>>(
          data: {
            'choices': [
              {
                'message': {
                  'content': '''
{
  "dish_name": "테스트 요리",
  "ingredients": [],
  "instructions": [],
  "estimated_time": "0분",
  "difficulty": "쉬움",
  "servings": "1인분"
}
                  '''
                }
              }
            ]
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')))
            .thenAnswer((_) async => mockResponse);

        // When
        await service.analyzeImage(testImageData);

        // Then
        verify(mockDio.post(
          '${ApiConfig.baseUrl}${ApiConfig.chatCompletionsEndpoint}',
          data: argThat(containsValue('gpt-4o-mini'), named: 'data'),
          options: anyNamed('options'),
        )).called(1);
      });
    });

    group('블로그 텍스트 분석 테스트 (새 기능!)', () {
      test('should analyze blog text and extract recipe successfully', () async {
        // Given - 블로그에서 추출한 텍스트 
        const blogText = '''
        맛있는 김치찌개 만들기
        
        오늘은 날씨가 추워서 따뜻한 김치찌개를 만들어봤어요.
        
        재료:
        - 김치 200g
        - 돼지고기 150g  
        - 두부 1/2모
        - 양파 1/2개
        - 대파 1대
        - 물 500ml
        
        만드는 방법:
        1. 김치를 기름에 볶아주세요
        2. 돼지고기를 넣고 함께 볶아주세요
        3. 물을 넣고 끓여주세요
        4. 두부와 양파를 넣어주세요
        5. 대파를 넣고 마무리해주세요
        
        조리시간: 30분
        난이도: 쉬움
        ''';

        final mockResponse = Response<Map<String, dynamic>>(
          data: {
            'choices': [
              {
                'message': {
                  'content': '''
{
  "dish_name": "김치찌개",
  "ingredients": [
    {"name": "김치", "amount": "200g"},
    {"name": "돼지고기", "amount": "150g"},
    {"name": "두부", "amount": "1/2모"},
    {"name": "양파", "amount": "1/2개"},
    {"name": "대파", "amount": "1대"}
  ],
  "instructions": [
    "김치를 기름에 볶아주세요",
    "돼지고기를 넣고 함께 볶아주세요",
    "물을 넣고 끓여주세요",
    "두부와 양파를 넣어주세요",
    "대파를 넣고 마무리해주세요"
  ],
  "estimated_time": "30분",
  "difficulty": "쉬움",
  "servings": "2-3인분"
}
                  '''
                }
              }
            ]
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')))
            .thenAnswer((_) async => mockResponse);

        // When
        final result = await service.analyzeText(blogText);

        // Then
        expect(result.dishName, equals('김치찌개'));
        expect(result.ingredients, hasLength(5));
        expect(result.ingredients.first.name, equals('김치'));
        expect(result.ingredients.first.amount, equals('200g'));
        expect(result.instructions, hasLength(5));
        expect(result.instructions.first, contains('김치를 기름에 볶아'));
        expect(result.estimatedTime, equals('30분'));
        expect(result.difficulty, equals('쉬움'));

        // API 호출 검증
        verify(mockDio.post(
          '${ApiConfig.baseUrl}${ApiConfig.chatCompletionsEndpoint}',
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).called(1);
      });

      test('should analyze Naver blog extracted text', () async {
        // Given - 네이버 블로그에서 추출한 실제 텍스트 패턴
        const naverBlogText = '''
        집에서 쉽게 만드는 토마토 파스타
        
        재료 (2인분)
        스파게티 면 200g
        토마토소스 1캔  
        마늘 4쪽
        올리브오일 3큰술
        바질잎 적당량
        
        조리법
        1단계: 물을 끓이고 소금을 넣어주세요
        2단계: 스파게티 면을 8분간 삶아주세요  
        3단계: 팬에 올리브오일을 두르고 마늘을 볶아주세요
        4단계: 토마토소스를 넣고 끓여주세요
        5단계: 면을 넣고 잘 버무려주세요
        6단계: 바질잎을 올려 완성해주세요
        
        TIP: 면수를 조금 넣으면 더 맛있어요!
        ''';

        final mockResponse = Response<Map<String, dynamic>>(
          data: {
            'choices': [
              {
                'message': {
                  'content': '''
{
  "dish_name": "토마토 파스타",
  "ingredients": [
    {"name": "스파게티 면", "amount": "200g"},
    {"name": "토마토소스", "amount": "1캔"},
    {"name": "마늘", "amount": "4쪽"},
    {"name": "올리브오일", "amount": "3큰술"},
    {"name": "바질잎", "amount": "적당량"}
  ],
  "instructions": [
    "물을 끓이고 소금을 넣어주세요",
    "스파게티 면을 8분간 삶아주세요",
    "팬에 올리브오일을 두르고 마늘을 볶아주세요",
    "토마토소스를 넣고 끓여주세요",
    "면을 넣고 잘 버무려주세요",
    "바질잎을 올려 완성해주세요"
  ],
  "estimated_time": "20분",
  "difficulty": "보통",
  "servings": "2인분"
}
                  '''
                }
              }
            ]
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')))
            .thenAnswer((_) async => mockResponse);

        // When
        final result = await service.analyzeText(naverBlogText);

        // Then
        expect(result.dishName, equals('토마토 파스타'));
        expect(result.servings, equals('2인분'));
        expect(result.ingredients.map((i) => i.name).toList(),
               containsAll(['스파게티 면', '토마토소스', '마늘', '올리브오일', '바질잎']));
        expect(result.instructions, hasLength(6));
      });

      test('should handle complex recipe text with multiple sections', () async {
        // Given - 복잡한 구조의 블로그 텍스트
        const complexBlogText = '''
        한정식 상차림 준비하기
        
        안녕하세요! 오늘은 가족들을 위해 정성스럽게 한정식을 준비해봤습니다.
        
        메인 메뉴:
        • 갈비찜
        • 미역국
        • 잡채
        
        반찬류:
        - 김치 (배추김치, 깍두기)
        - 나물 (시금치나물, 콩나물)
        - 구이 (고등어구이)
        - 조림 (연근조림)
        
        준비 재료 (4인분 기준):
        [갈비찜]
        갈비 1kg, 배 1개, 양파 2개, 당근 1개
        간장 5큰술, 설탕 3큰술, 마늘 1통
        
        [미역국]  
        미역 30g, 쇠고기 200g, 참기름 2큰술
        
        조리 과정:
        1. 갈비는 찬물에 2시간 담가 핏물을 빼주세요
        2. 양념장을 만들어주세요  
        3. 갈비를 양념에 재워주세요
        4. 압력솥에 넣고 40분간 끓여주세요
        5. 미역은 불려서 쇠고기와 함께 볶아주세요
        6. 물을 넣고 끓여 미역국을 완성해주세요
        
        소요시간: 약 3시간
        난이도: 어려움
        
        가족들이 정말 맛있게 드셔서 뿌듯했습니다! ^^
        ''';

        final mockResponse = Response<Map<String, dynamic>>(
          data: {
            'choices': [
              {
                'message': {
                  'content': '''
{
  "dish_name": "한정식 상차림",
  "ingredients": [
    {"name": "갈비", "amount": "1kg"},
    {"name": "배", "amount": "1개"},
    {"name": "양파", "amount": "2개"},
    {"name": "미역", "amount": "30g"},
    {"name": "쇠고기", "amount": "200g"},
    {"name": "김치", "amount": "적당량"},
    {"name": "나물류", "amount": "여러 종류"}
  ],
  "instructions": [
    "갈비는 찬물에 2시간 담가 핏물을 빼주세요",
    "양념장을 만들어주세요",
    "갈비를 양념에 재워주세요",
    "압력솥에 넣고 40분간 끓여주세요",
    "미역은 불려서 쇠고기와 함께 볶아주세요",
    "물을 넣고 끓여 미역국을 완성해주세요"
  ],
  "estimated_time": "3시간",
  "difficulty": "어려움",
  "servings": "4인분"
}
                  '''
                }
              }
            ]
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')))
            .thenAnswer((_) async => mockResponse);

        // When
        final result = await service.analyzeText(complexBlogText);

        // Then
        expect(result.dishName, equals('한정식 상차림'));
        expect(result.difficulty, equals('어려움'));
        expect(result.estimatedTime, equals('3시간'));
        expect(result.servings, equals('4인분'));
        expect(result.ingredients, hasLength(7));
        expect(result.instructions, hasLength(6));
      });
    });

    group('텍스트 분석 에러 처리 테스트', () {
      test('should handle empty text input', () async {
        // Given
        const emptyText = '';

        // When & Then
        expect(
          () => service.analyzeText(emptyText),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should handle text without recipe content', () async {
        // Given
        const nonRecipeText = '''
        오늘의 일기
        
        오늘은 날씨가 좋았다. 
        친구와 영화를 보러 갔다.
        저녁에는 독서를 했다.
        내일은 운동을 해야겠다.
        ''';

        final mockResponse = Response<Map<String, dynamic>>(
          data: {
            'choices': [
              {
                'message': {
                  'content': '''
{
  "dish_name": "",
  "ingredients": [],
  "instructions": [],
  "estimated_time": "",
  "difficulty": "",
  "servings": ""
}
                  '''
                }
              }
            ]
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')))
            .thenAnswer((_) async => mockResponse);

        // When
        final result = await service.analyzeText(nonRecipeText);

        // Then
        expect(result.dishName, isEmpty);
        expect(result.ingredients, isEmpty);
        expect(result.instructions, isEmpty);
      });

      test('should handle very long text input', () async {
        // Given - 매우 긴 텍스트 (토큰 제한 테스트)
        final longText = 'Very long recipe text... ' * 1000; // 매우 긴 텍스트

        // API에서 적절히 처리되었다고 가정
        final mockResponse = Response<Map<String, dynamic>>(
          data: {
            'choices': [
              {
                'message': {
                  'content': '''
{
  "dish_name": "긴 레시피",
  "ingredients": [{"name": "재료1", "amount": "적당량"}],
  "instructions": ["간단 조리법"],
  "estimated_time": "30분",
  "difficulty": "보통", 
  "servings": "2인분"
}
                  '''
                }
              }
            ]
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')))
            .thenAnswer((_) async => mockResponse);

        // When
        final result = await service.analyzeText(longText);

        // Then
        expect(result.dishName, equals('긴 레시피'));
        expect(result.ingredients, hasLength(1));
        expect(result.instructions, hasLength(1));
      });

      test('should handle API error during text analysis', () async {
        // Given
        const testText = '레시피 텍스트';
        when(mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            statusCode: 429,
            data: {'error': {'message': 'Rate limit reached'}},
            requestOptions: RequestOptions(path: '/test'),
          ),
        ));

        // When & Then
        expect(
          () => service.analyzeText(testText),
          throwsA(isA<RateLimitException>()),
        );
      });
    });

    group('텍스트 전처리 테스트', () {
      test('should clean and normalize text before analysis', () async {
        // Given - 불필요한 공백과 특수문자가 많은 텍스트
        const messyText = '''
        
        
        ===  맛있는 요리!!!  ===
        
        
        재료:   김치    200g  ,   돼지고기   150g    
        
        
        만드는법:
        1.    김치를      볶는다   
        2.      고기를    넣는다     
        
        
        *** 끝 ***
        
        
        ''';

        final mockResponse = Response<Map<String, dynamic>>(
          data: {
            'choices': [
              {
                'message': {
                  'content': '''
{
  "dish_name": "김치 요리",
  "ingredients": [
    {"name": "김치", "amount": "200g"},
    {"name": "돼지고기", "amount": "150g"}
  ],
  "instructions": [
    "김치를 볶는다",
    "고기를 넣는다"
  ],
  "estimated_time": "20분",
  "difficulty": "쉬움",
  "servings": "2인분"
}
                  '''
                }
              }
            ]
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')))
            .thenAnswer((_) async => mockResponse);

        // When
        final result = await service.analyzeText(messyText);

        // Then - 정상적으로 분석됨
        expect(result.dishName, equals('김치 요리'));
        expect(result.ingredients, hasLength(2));
        expect(result.instructions, hasLength(2));
        expect(result.ingredients.first.name, equals('김치'));
        expect(result.ingredients.first.amount, equals('200g'));
      });
    });
  });
}