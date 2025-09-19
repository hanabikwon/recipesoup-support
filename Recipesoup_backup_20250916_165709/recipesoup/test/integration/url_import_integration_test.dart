import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';

import 'package:recipesoup/main.dart' as app;
import 'package:recipesoup/services/url_scraper_service.dart';
import 'package:recipesoup/services/openai_service.dart';
import 'package:recipesoup/providers/recipe_provider.dart';
import 'package:recipesoup/models/recipe_analysis.dart';
import 'package:recipesoup/screens/url_import_screen.dart';
import 'package:recipesoup/screens/create_screen.dart';
import 'package:recipesoup/screens/main_screen.dart';

// Mock 클래스 생성을 위한 어노테이션
@GenerateMocks([UrlScraperService, OpenAiService])
import 'url_import_integration_test.mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('URL Recipe Import Integration Tests', () {
    late MockUrlScraperService mockUrlScraper;
    late MockOpenAiService mockOpenAi;

    setUp(() {
      mockUrlScraper = MockUrlScraperService();
      mockOpenAi = MockOpenAiService();
    });

    group('전체 URL 가져오기 플로우 테스트', () {
      testWidgets('should complete full URL import workflow from FAB to recipe creation',
          (WidgetTester tester) async {
        // Given - 앱 실행
        app.main();
        await tester.pumpAndSettle();

        // 메인 화면에서 시작
        expect(find.byType(MainScreen), findsOneWidget);

        // When - FAB 메뉴에서 "링크로 가져오기" 선택
        final fabButton = find.byType(FloatingActionButton);
        expect(fabButton, findsOneWidget);
        await tester.tap(fabButton);
        await tester.pumpAndSettle();

        // FAB 확장 메뉴가 나타나는지 확인
        expect(find.text('링크로 가져오기'), findsOneWidget);
        await tester.tap(find.text('링크로 가져오기'));
        await tester.pumpAndSettle();

        // Then - UrlImportScreen으로 네비게이션 확인
        expect(find.byType(UrlImportScreen), findsOneWidget);
        expect(find.text('블로그 레시피 가져오기'), findsOneWidget);
      });

      testWidgets('should process valid blog URL and create recipe successfully',
          (WidgetTester tester) async {
        // Given - URL Import Screen에서 시작
        const testUrl = 'https://blog.naver.com/test/recipe123';
        const expectedDishName = '김치찌개';

        // Mock 응답 설정
        when(mockUrlScraper.scrapeRecipeFromUrl(testUrl)).thenAnswer((_) async => 
            ScrapedContent(
              sourceUrl: testUrl,
              title: '맛있는 김치찌개 레시피',
              text: '''
              김치찌개 만들기
              
              재료:
              - 김치 200g
              - 돼지고기 150g
              - 두부 1/2모
              
              만드는 방법:
              1. 김치를 기름에 볶아주세요
              2. 돼지고기를 넣고 함께 볶아주세요
              3. 물을 넣고 끓여주세요
              ''',
              hasRecipeContent: true,
              scrapedAt: DateTime.now(),
            ));

        when(mockOpenAi.analyzeText(any)).thenAnswer((_) async => RecipeAnalysis(
              dishName: expectedDishName,
              ingredients: [
                AnalysisIngredient(name: '김치', amount: '200g'),
                AnalysisIngredient(name: '돼지고기', amount: '150g'),
                AnalysisIngredient(name: '두부', amount: '1/2모'),
              ],
              instructions: [
                '김치를 기름에 볶아주세요',
                '돼지고기를 넣고 함께 볶아주세요',
                '물을 넣고 끓여주세요',
              ],
              estimatedTime: '30분',
              difficulty: '쉬움',
              servings: '2-3인분',
            ));

        await tester.pumpWidget(MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => RecipeProvider()),
              Provider.value(value: mockUrlScraper),
              Provider.value(value: mockOpenAi),
            ],
            child: const UrlImportScreen(),
          ),
        ));

        // When - URL 입력 및 분석 실행
        await tester.enterText(find.byType(TextFormField), testUrl);
        await tester.tap(find.text('레시피 가져오기'));
        await tester.pump();

        // 로딩 상태 확인
        expect(find.text('분석 중...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // 분석 완료까지 대기
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Then - 스크래핑 결과 확인
        expect(find.text('웹페이지 내용'), findsOneWidget);
        expect(find.text('맛있는 김치찌개 레시피'), findsOneWidget);
        expect(find.text('레시피 관련: 예'), findsOneWidget);

        // AI 분석 결과 확인
        expect(find.text('AI 분석 결과'), findsOneWidget);
        expect(find.text(expectedDishName), findsOneWidget);
        expect(find.text('김치 200g'), findsOneWidget);
        expect(find.text('돼지고기 150g'), findsOneWidget);
        expect(find.text('김치를 기름에 볶아주세요'), findsOneWidget);

        // 레시피 작성 버튼 확인
        expect(find.text('레시피 작성'), findsOneWidget);

        // When - 레시피 작성 화면으로 이동
        await tester.tap(find.text('레시피 작성'));
        await tester.pumpAndSettle();

        // Then - CreateScreen으로 네비게이션 및 데이터 전달 확인
        expect(find.byType(CreateScreen), findsOneWidget);
        expect(find.text(expectedDishName), findsOneWidget); // 요리명이 미리 입력되어야 함
        expect(find.text(testUrl), findsOneWidget); // Source URL이 입력되어야 함
      });
    });

    group('다양한 블로그 플랫폼 테스트', () {
      testWidgets('should handle Naver blog URL successfully', (WidgetTester tester) async {
        // Given - 네이버 블로그 URL
        const naverUrl = 'https://blog.naver.com/user123/recipe456';
        
        when(mockUrlScraper.scrapeRecipeFromUrl(naverUrl)).thenAnswer((_) async =>
            ScrapedContent(
              sourceUrl: naverUrl,
              title: '네이버 블로그 레시피',
              text: '재료: 파스타면 200g, 토마토소스 1캔\n조리법: 면을 삶고 소스와 섞는다',
              hasRecipeContent: true,
              scrapedAt: DateTime.now(),
            ));

        when(mockOpenAi.analyzeText(any)).thenAnswer((_) async => RecipeAnalysis(
              dishName: '토마토 파스타',
              ingredients: [AnalysisIngredient(name: '파스타면', amount: '200g')],
              instructions: ['면을 삶고 소스와 섞는다'],
              estimatedTime: '20분',
              difficulty: '보통',
              servings: '2인분',
            ));

        await tester.pumpWidget(MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => RecipeProvider()),
              Provider.value(value: mockUrlScraper),
              Provider.value(value: mockOpenAi),
            ],
            child: const UrlImportScreen(),
          ),
        ));

        // When - 네이버 블로그 URL 처리
        await tester.enterText(find.byType(TextFormField), naverUrl);
        await tester.tap(find.text('레시피 가져오기'));
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Then
        expect(find.text('토마토 파스타'), findsOneWidget);
        expect(find.text('파스타면 200g'), findsOneWidget);
      });

      testWidgets('should handle Tistory blog URL successfully', (WidgetTester tester) async {
        // Given - 티스토리 블로그 URL
        const tistoryUrl = 'https://user123.tistory.com/789';

        when(mockUrlScraper.scrapeRecipeFromUrl(tistoryUrl)).thenAnswer((_) async =>
            ScrapedContent(
              sourceUrl: tistoryUrl,
              title: '티스토리 요리 블로그',
              text: '재료: 계란 2개, 밥 1공기\n만드는 법: 계란을 풀고 밥과 함께 볶는다',
              hasRecipeContent: true,
              scrapedAt: DateTime.now(),
            ));

        when(mockOpenAi.analyzeText(any)).thenAnswer((_) async => RecipeAnalysis(
              dishName: '계란볶음밥',
              ingredients: [
                AnalysisIngredient(name: '계란', amount: '2개'),
                AnalysisIngredient(name: '밥', amount: '1공기'),
              ],
              instructions: ['계란을 풀고 밥과 함께 볶는다'],
              estimatedTime: '15분',
              difficulty: '쉬움',
              servings: '1인분',
            ));

        await tester.pumpWidget(MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => RecipeProvider()),
              Provider.value(value: mockUrlScraper),
              Provider.value(value: mockOpenAi),
            ],
            child: const UrlImportScreen(),
          ),
        ));

        // When - 티스토리 URL 처리
        await tester.enterText(find.byType(TextFormField), tistoryUrl);
        await tester.tap(find.text('레시피 가져오기'));
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Then
        expect(find.text('계란볶음밥'), findsOneWidget);
        expect(find.text('계란 2개'), findsOneWidget);
        expect(find.text('밥 1공기'), findsOneWidget);
      });

      testWidgets('should handle general recipe website URL', (WidgetTester tester) async {
        // Given - 일반 요리 사이트 URL
        const generalUrl = 'https://recipe-site.com/korean-food/123';

        when(mockUrlScraper.scrapeRecipeFromUrl(generalUrl)).thenAnswer((_) async =>
            ScrapedContent(
              sourceUrl: generalUrl,
              title: '한식 요리 사이트',
              text: '한정식 준비\n재료: 갈비 1kg, 미역 30g\n조리: 갈비를 재우고 미역국을 끓인다',
              hasRecipeContent: true,
              scrapedAt: DateTime.now(),
            ));

        when(mockOpenAi.analyzeText(any)).thenAnswer((_) async => RecipeAnalysis(
              dishName: '한정식 상차림',
              ingredients: [
                AnalysisIngredient(name: '갈비', amount: '1kg'),
                AnalysisIngredient(name: '미역', amount: '30g'),
              ],
              instructions: ['갈비를 재우고 미역국을 끓인다'],
              estimatedTime: '2시간',
              difficulty: '어려움',
              servings: '4인분',
            ));

        await tester.pumpWidget(MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => RecipeProvider()),
              Provider.value(value: mockUrlScraper),
              Provider.value(value: mockOpenAi),
            ],
            child: const UrlImportScreen(),
          ),
        ));

        // When - 일반 사이트 URL 처리
        await tester.enterText(find.byType(TextFormField), generalUrl);
        await tester.tap(find.text('레시피 가져오기'));
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Then
        expect(find.text('한정식 상차림'), findsOneWidget);
        expect(find.text('갈비 1kg'), findsOneWidget);
        expect(find.text('어려움'), findsOneWidget);
      });
    });

    group('에러 처리 통합 테스트', () {
      testWidgets('should handle network error gracefully', (WidgetTester tester) async {
        // Given - 네트워크 에러 시뮬레이션
        const unreachableUrl = 'https://unreachable-site.com/recipe';

        when(mockUrlScraper.scrapeRecipeFromUrl(unreachableUrl))
            .thenThrow(NetworkException('Connection failed'));

        await tester.pumpWidget(MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => RecipeProvider()),
              Provider.value(value: mockUrlScraper),
              Provider.value(value: mockOpenAi),
            ],
            child: const UrlImportScreen(),
          ),
        ));

        // When - 네트워크 에러 발생
        await tester.enterText(find.byType(TextFormField), unreachableUrl);
        await tester.tap(find.text('레시피 가져오기'));
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Then - 에러 메시지 표시 확인
        expect(find.text('오류가 발생했습니다'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Connection failed'), findsOneWidget);
      });

      testWidgets('should handle non-recipe content gracefully', (WidgetTester tester) async {
        // Given - 레시피가 아닌 콘텐츠
        const nonRecipeUrl = 'https://news-site.com/article/123';

        when(mockUrlScraper.scrapeRecipeFromUrl(nonRecipeUrl)).thenAnswer((_) async =>
            ScrapedContent(
              sourceUrl: nonRecipeUrl,
              title: '뉴스 기사',
              text: '오늘의 정치 소식입니다. 경제 상황에 대한 분석...',
              hasRecipeContent: false,
              scrapedAt: DateTime.now(),
            ));

        await tester.pumpWidget(MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => RecipeProvider()),
              Provider.value(value: mockUrlScraper),
              Provider.value(value: mockOpenAi),
            ],
            child: const UrlImportScreen(),
          ),
        ));

        // When - 레시피가 아닌 콘텐츠 처리
        await tester.enterText(find.byType(TextFormField), nonRecipeUrl);
        await tester.tap(find.text('레시피 가져오기'));
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Then - 경고 메시지 표시
        expect(find.text('이 페이지에서 레시피 관련 내용을 찾을 수 없습니다'), findsOneWidget);
        expect(find.text('다른 URL을 시도해보세요'), findsOneWidget);
        expect(find.text('레시피 관련: 아니오'), findsOneWidget);
      });

      testWidgets('should handle OpenAI API error gracefully', (WidgetTester tester) async {
        // Given - OpenAI API 에러 시뮬레이션
        const validUrl = 'https://blog.naver.com/test/recipe';

        when(mockUrlScraper.scrapeRecipeFromUrl(validUrl)).thenAnswer((_) async =>
            ScrapedContent(
              sourceUrl: validUrl,
              title: '테스트 레시피',
              text: '재료: 김치 200g\n만드는 법: 김치를 볶는다',
              hasRecipeContent: true,
              scrapedAt: DateTime.now(),
            ));

        when(mockOpenAi.analyzeText(any))
            .thenThrow(RateLimitException('API rate limit exceeded'));

        await tester.pumpWidget(MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => RecipeProvider()),
              Provider.value(value: mockUrlScraper),
              Provider.value(value: mockOpenAi),
            ],
            child: const UrlImportScreen(),
          ),
        ));

        // When - OpenAI API 에러 발생
        await tester.enterText(find.byType(TextFormField), validUrl);
        await tester.tap(find.text('레시피 가져오기'));
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Then - API 에러 처리 확인
        expect(find.text('AI 분석 중 오류가 발생했습니다'), findsOneWidget);
        expect(find.text('API rate limit exceeded'), findsOneWidget);
        
        // 스크래핑 결과는 여전히 표시되어야 함
        expect(find.text('웹페이지 내용'), findsOneWidget);
      });
    });

    group('사용자 경험 테스트', () {
      testWidgets('should provide proper feedback during long operations', (WidgetTester tester) async {
        // Given - 긴 처리 시간을 시뮬레이션
        const slowUrl = 'https://slow-site.com/recipe';

        when(mockUrlScraper.scrapeRecipeFromUrl(slowUrl)).thenAnswer((_) => 
            Future.delayed(const Duration(seconds: 3), () => ScrapedContent(
              sourceUrl: slowUrl,
              title: '느린 사이트 레시피',
              text: '재료: 테스트\n방법: 테스트 조리법',
              hasRecipeContent: true,
              scrapedAt: DateTime.now(),
            )));

        when(mockOpenAi.analyzeText(any)).thenAnswer((_) => 
            Future.delayed(const Duration(seconds: 2), () => RecipeAnalysis(
              dishName: '테스트 요리',
              ingredients: [AnalysisIngredient(name: '테스트', amount: '1개')],
              instructions: ['테스트 조리법'],
              estimatedTime: '10분',
              difficulty: '쉬움',
              servings: '1인분',
            )));

        await tester.pumpWidget(MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => RecipeProvider()),
              Provider.value(value: mockUrlScraper),
              Provider.value(value: mockOpenAi),
            ],
            child: const UrlImportScreen(),
          ),
        ));

        // When - 긴 작업 시작
        await tester.enterText(find.byType(TextFormField), slowUrl);
        await tester.tap(find.text('레시피 가져오기'));
        await tester.pump();

        // Then - 로딩 상태 확인
        expect(find.text('분석 중...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // 버튼이 비활성화되었는지 확인
        final button = tester.widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, '분석 중...'));
        expect(button.onPressed, isNull);

        // 작업 완료까지 대기
        await tester.pumpAndSettle(const Duration(seconds: 6));

        // 완료 상태 확인
        expect(find.text('테스트 요리'), findsOneWidget);
        expect(find.text('레시피 작성'), findsOneWidget);
      });

      testWidgets('should allow user to cancel and retry', (WidgetTester tester) async {
        // Given
        await tester.pumpWidget(MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => RecipeProvider()),
              Provider.value(value: mockUrlScraper),
              Provider.value(value: mockOpenAi),
            ],
            child: const UrlImportScreen(),
          ),
        ));

        // When - 잘못된 URL 입력
        await tester.enterText(find.byType(TextFormField), 'invalid-url');
        await tester.tap(find.text('레시피 가져오기'));
        await tester.pump();

        // Then - 유효성 검증 에러 표시
        expect(find.text('올바른 URL 형식이 아닙니다'), findsOneWidget);

        // When - 올바른 URL로 재시도
        const validUrl = 'https://example.com/recipe';
        when(mockUrlScraper.scrapeRecipeFromUrl(validUrl)).thenAnswer((_) async =>
            ScrapedContent(
              sourceUrl: validUrl,
              title: '수정된 레시피',
              text: '재료: 수정됨\n방법: 수정된 조리법',
              hasRecipeContent: true,
              scrapedAt: DateTime.now(),
            ));

        when(mockOpenAi.analyzeText(any)).thenAnswer((_) async => RecipeAnalysis(
              dishName: '수정된 요리',
              ingredients: [AnalysisIngredient(name: '수정됨', amount: '1개')],
              instructions: ['수정된 조리법'],
              estimatedTime: '15분',
              difficulty: '보통',
              servings: '2인분',
            ));

        await tester.enterText(find.byType(TextFormField), validUrl);
        await tester.tap(find.text('레시피 가져오기'));
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Then - 성공적으로 처리됨
        expect(find.text('수정된 요리'), findsOneWidget);
      });
    });

    group('데이터 무결성 테스트', () {
      testWidgets('should preserve all analyzed data through navigation', (WidgetTester tester) async {
        // Given - 완전한 분석 결과
        const testUrl = 'https://test.com/full-recipe';
        final completeAnalysis = RecipeAnalysis(
          dishName: '완전한 레시피',
          ingredients: [
            AnalysisIngredient(name: '재료1', amount: '100g'),
            AnalysisIngredient(name: '재료2', amount: '200ml'),
            AnalysisIngredient(name: '재료3', amount: '1개'),
          ],
          instructions: [
            '첫 번째 단계',
            '두 번째 단계',
            '세 번째 단계',
          ],
          estimatedTime: '45분',
          difficulty: '보통',
          servings: '3인분',
        );

        when(mockUrlScraper.scrapeRecipeFromUrl(testUrl)).thenAnswer((_) async =>
            ScrapedContent(
              sourceUrl: testUrl,
              title: '완전한 테스트 레시피',
              text: '완전한 레시피 콘텐츠',
              hasRecipeContent: true,
              scrapedAt: DateTime.now(),
            ));

        when(mockOpenAi.analyzeText(any)).thenAnswer((_) async => completeAnalysis);

        await tester.pumpWidget(MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => RecipeProvider()),
              Provider.value(value: mockUrlScraper),
              Provider.value(value: mockOpenAi),
            ],
            child: const UrlImportScreen(),
          ),
        ));

        // When - 분석 완료 후 레시피 작성으로 이동
        await tester.enterText(find.byType(TextFormField), testUrl);
        await tester.tap(find.text('레시피 가져오기'));
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // 모든 분석 결과 확인
        expect(find.text('완전한 레시피'), findsOneWidget);
        expect(find.text('재료1 100g'), findsOneWidget);
        expect(find.text('재료2 200ml'), findsOneWidget);
        expect(find.text('재료3 1개'), findsOneWidget);
        expect(find.text('첫 번째 단계'), findsOneWidget);
        expect(find.text('45분'), findsOneWidget);
        expect(find.text('보통'), findsOneWidget);
        expect(find.text('3인분'), findsOneWidget);

        await tester.tap(find.text('레시피 작성'));
        await tester.pumpAndSettle();

        // Then - CreateScreen에서 모든 데이터가 유지되는지 확인
        expect(find.byType(CreateScreen), findsOneWidget);
        expect(find.text('완전한 레시피'), findsOneWidget);
        expect(find.text(testUrl), findsOneWidget); // Source URL 확인
      });
    });
  });
}

// 테스트 유틸리티 클래스
class TestUtils {
  static Future<void> waitForNetworkCall(WidgetTester tester, {Duration timeout = const Duration(seconds: 10)}) async {
    await tester.pumpAndSettle(timeout);
  }

  static Future<void> enterUrlAndProcess(WidgetTester tester, String url) async {
    await tester.enterText(find.byType(TextFormField), url);
    await tester.tap(find.text('레시피 가져오기'));
    await tester.pump();
  }

  static void verifyAnalysisResult(WidgetTester tester, RecipeAnalysis analysis) {
    expect(find.text(analysis.dishName), findsOneWidget);
    for (final ingredient in analysis.ingredients) {
      expect(find.textContaining(ingredient.name), findsOneWidget);
    }
    for (final instruction in analysis.instructions) {
      expect(find.textContaining(instruction), findsOneWidget);
    }
  }
}

// 커스텀 예외 클래스들 (테스트용)
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  
  @override
  String toString() => message;
}

class RateLimitException implements Exception {
  final String message;
  RateLimitException(this.message);
  
  @override
  String toString() => message;
}

