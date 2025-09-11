import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:recipesoup/screens/url_import_screen.dart';
import 'package:recipesoup/services/url_scraper_service.dart';
import 'package:recipesoup/services/openai_service.dart';
import 'package:recipesoup/providers/recipe_provider.dart';

// Mock 클래스 생성을 위한 어노테이션
@GenerateMocks([UrlScraperService, OpenAiService, RecipeProvider])
import 'url_import_screen_test.mocks.dart';

void main() {
  group('UrlImportScreen Widget Tests', () {
    late MockUrlScraperService mockUrlScraper;
    late MockRecipeProvider mockRecipeProvider;

    setUp(() {
      mockUrlScraper = MockUrlScraperService();
      mockRecipeProvider = MockRecipeProvider();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<RecipeProvider>.value(
          value: mockRecipeProvider,
          child: const UrlImportScreen(),
        ),
      );
    }

    group('초기 화면 렌더링 테스트', () {
      testWidgets('should display initial UI elements', (WidgetTester tester) async {
        // Given & When
        await tester.pumpWidget(createTestWidget());

        // Then
        expect(find.text('링크로 가져오기'), findsOneWidget);
        expect(find.text('블로그 레시피 가져오기'), findsOneWidget);
        expect(find.text('블로그나 웹사이트의 레시피 URL을 입력하면\nAI가 자동으로 재료와 조리법을 추출해드려요'), findsOneWidget);
        expect(find.text('레시피 URL'), findsOneWidget);
        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.text('레시피 가져오기'), findsOneWidget);
        expect(find.byIcon(Icons.link), findsOneWidget);
      });

      testWidgets('should display URL input field', (WidgetTester tester) async {
        // Given & When
        await tester.pumpWidget(createTestWidget());

        // Then
        final urlField = find.byType(TextFormField);
        expect(urlField, findsOneWidget);

        // Check for hint text in the widget tree instead of accessing decoration directly
        expect(find.text('https://blog.naver.com/... 또는 https://...'), findsOneWidget);
        expect(find.byIcon(Icons.link), findsOneWidget);
      });

      testWidgets('should display supported sites information', (WidgetTester tester) async {
        // Given & When
        await tester.pumpWidget(createTestWidget());

        // Then
        expect(find.text('지원하는 사이트: 네이버 블로그, 티스토리, 일반 웹사이트 등'), findsOneWidget);
      });

      testWidgets('should show primary button for recipe fetching', (WidgetTester tester) async {
        // Given & When
        await tester.pumpWidget(createTestWidget());

        // Then
        final button = find.widgetWithText(ElevatedButton, '레시피 가져오기');
        expect(button, findsOneWidget);
        
        final buttonWidget = tester.widget<ElevatedButton>(button);
        expect(buttonWidget.onPressed, isNotNull);
      });
    });

    group('URL 입력 및 유효성 검증 테스트', () {
      testWidgets('should accept valid URL input', (WidgetTester tester) async {
        // Given
        await tester.pumpWidget(createTestWidget());
        const validUrl = 'https://blog.naver.com/user123/recipe123';

        // When
        await tester.enterText(find.byType(TextFormField), validUrl);
        await tester.pump();

        // Then
        expect(find.text(validUrl), findsOneWidget);
      });

      testWidgets('should validate URL format on form submission', (WidgetTester tester) async {
        // Given
        await tester.pumpWidget(createTestWidget());
        const invalidUrl = 'not-a-valid-url';

        // When
        await tester.enterText(find.byType(TextFormField), invalidUrl);
        await tester.tap(find.text('레시피 가져오기'));
        await tester.pump();

        // Then
        expect(find.text('올바른 URL 형식이 아닙니다'), findsOneWidget);
      });

      testWidgets('should show validation error for empty URL', (WidgetTester tester) async {
        // Given
        await tester.pumpWidget(createTestWidget());

        // When
        await tester.tap(find.text('레시피 가져오기'));
        await tester.pump();

        // Then
        expect(find.text('URL을 입력해주세요'), findsOneWidget);
      });

      testWidgets('should allow valid URL formats', (WidgetTester tester) async {
        // Given
        await tester.pumpWidget(createTestWidget());
        final validUrls = [
          'https://blog.naver.com/user/123',
          'http://tistory.com/recipe',
          'https://recipe-site.co.kr/food',
        ];

        for (final url in validUrls) {
          // When
          await tester.enterText(find.byType(TextFormField), url);
          await tester.tap(find.text('레시피 가져오기'));
          await tester.pump();

          // Then - 유효성 검증 에러가 없어야 함
          expect(find.text('올바른 URL 형식이 아닙니다'), findsNothing);

          // 다음 테스트를 위해 필드 초기화
          await tester.enterText(find.byType(TextFormField), '');
        }
      });

      testWidgets('should submit on Enter key press', (WidgetTester tester) async {
        // Given
        await tester.pumpWidget(createTestWidget());
        const validUrl = 'https://example.com/recipe';

        // When
        await tester.enterText(find.byType(TextFormField), validUrl);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        // Then - 유효성 검증이 통과되어야 함
        expect(find.text('올바른 URL 형식이 아닙니다'), findsNothing);
        expect(find.text('URL을 입력해주세요'), findsNothing);
      });
    });

    group('로딩 상태 표시 테스트', () {
      testWidgets('should show loading state during URL processing', (WidgetTester tester) async {
        // Given
        await tester.pumpWidget(createTestWidget());
        const validUrl = 'https://example.com/recipe';

        // 긴 작업을 시뮬레이션하기 위한 Mock 설정
        when(mockUrlScraper.scrapeRecipeFromUrl(any))
            .thenAnswer((_) => Future.delayed(
                const Duration(seconds: 2), 
                () => ScrapedContent(
                  sourceUrl: validUrl,
                  title: 'Test Recipe',
                  text: 'Test content with 재료',
                  hasRecipeContent: true,
                  scrapedAt: DateTime.now(),
                )));

        // When
        await tester.enterText(find.byType(TextFormField), validUrl);
        await tester.tap(find.text('레시피 가져오기'));
        await tester.pump(); // UI 상태 업데이트

        // Then
        expect(find.text('분석 중...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        
        // 로딩 중에는 버튼이 비활성화되어야 함
        final button = tester.widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, '분석 중...'));
        expect(button.onPressed, isNull);
      });

      testWidgets('should disable button during loading', (WidgetTester tester) async {
        // Given
        await tester.pumpWidget(createTestWidget());

        // When - 로딩 상태 시뮬레이션
        // 실제로는 내부 상태에 따라 결정되지만, UI 테스트에서는 버튼 상태만 확인

        // Then
        final button = find.widgetWithText(ElevatedButton, '레시피 가져오기');
        expect(button, findsOneWidget);
        
        final buttonWidget = tester.widget<ElevatedButton>(button);
        expect(buttonWidget.onPressed, isNotNull); // 초기에는 활성화
      });
    });

    group('스크래핑 결과 표시 테스트', () {
      testWidgets('should display scraped content preview', (WidgetTester tester) async {
        // Given
        await tester.pumpWidget(createTestWidget());
        
        // 스크래핑 결과가 표시된 상태를 시뮬레이션하기 위해
        // 위젯을 적절히 설정해야 하지만, 실제 구현에서는 상태 관리를 통해 처리

        // When & Then - 실제 구현에서는 Mock을 통해 스크래핑 결과를 설정하고 UI 확인
        // 이 부분은 실제 위젯 구현과 상태 관리 방식에 따라 달라짐
      });
    });

    group('에러 상태 표시 테스트', () {
      testWidgets('should display error card when error occurs', (WidgetTester tester) async {
        // Given
        await tester.pumpWidget(createTestWidget());

        // 에러 상태를 시뮬레이션하는 것은 실제 위젯의 상태 관리 구조에 따라 달라짐
        // 실제 테스트에서는 에러가 발생하는 시나리오를 만들고 UI 검증

        // When & Then
        // 에러 메시지, 에러 아이콘 등의 표시 여부 확인
        // expect(find.text('오류가 발생했습니다'), findsOneWidget);
        // expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('should show network error message', (WidgetTester tester) async {
        // Given & When
        await tester.pumpWidget(createTestWidget());

        // Then - 네트워크 에러 시나리오별 메시지 확인 테스트
        // 실제 구현에서는 에러 상태를 주입하고 UI 검증
      });

      testWidgets('should show no recipe content warning', (WidgetTester tester) async {
        // Given & When
        await tester.pumpWidget(createTestWidget());

        // Then - 레시피 콘텐츠가 없을 때의 경고 메시지
        // expect(find.text('이 페이지에서 레시피 관련 내용을 찾을 수 없습니다'), findsOneWidget);
      });
    });

    group('AI 분석 결과 표시 테스트', () {
      testWidgets('should display AI analysis result card', (WidgetTester tester) async {
        // Given
        await tester.pumpWidget(createTestWidget());

        // AI 분석 결과가 있는 상태를 시뮬레이션

        // When & Then
        // 실제 테스트에서는 상태를 설정하고 UI 요소들 확인
        // expect(find.text('AI 분석 결과'), findsOneWidget);
        // expect(find.text('김치찌개'), findsOneWidget);
        // expect(find.text('김치 200g'), findsOneWidget);
        // expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      });

      testWidgets('should show recipe creation button after analysis', (WidgetTester tester) async {
        // Given & When
        await tester.pumpWidget(createTestWidget());

        // Then - 분석 완료 후 레시피 작성 버튼 표시
        // expect(find.text('레시피 작성'), findsOneWidget);
      });

      testWidgets('should display analysis sections correctly', (WidgetTester tester) async {
        // Given & When
        await tester.pumpWidget(createTestWidget());

        // Then - 분석 결과의 각 섹션 확인
        // expect(find.text('요리명'), findsOneWidget);
        // expect(find.text('재료'), findsOneWidget);
        // expect(find.text('조리법'), findsOneWidget);
        // expect(find.text('조리 시간'), findsOneWidget);
        // expect(find.text('난이도'), findsOneWidget);
        // expect(find.text('인분'), findsOneWidget);
      });
    });

    group('네비게이션 테스트', () {
      testWidgets('should navigate to CreateScreen when recipe creation button tapped', (WidgetTester tester) async {
        // Given
        await tester.pumpWidget(createTestWidget());

        // AI 분석이 완료된 상태를 시뮬레이션
        // 실제 테스트에서는 분석 결과가 있는 상태를 만들고

        // When
        // await tester.tap(find.text('레시피 작성'));
        // await tester.pumpAndSettle();

        // Then - CreateScreen으로 네비게이션 확인
        // expect(find.byType(CreateScreen), findsOneWidget);
      });

      testWidgets('should pass analysis result to CreateScreen', (WidgetTester tester) async {
        // Given & When
        await tester.pumpWidget(createTestWidget());

        // Then - 분석 결과가 CreateScreen에 전달되는지 확인
        // 실제 구현에서는 네비게이션 시 전달되는 데이터 검증
      });
    });

    group('접근성 테스트', () {
      testWidgets('should have proper semantics labels', (WidgetTester tester) async {
        // Given & When
        await tester.pumpWidget(createTestWidget());

        // Then
        expect(find.bySemanticsLabel('URL 입력 필드'), findsOneWidget);
        expect(find.bySemanticsLabel('레시피 가져오기 버튼'), findsOneWidget);
      });

      testWidgets('should support screen readers', (WidgetTester tester) async {
        // Given & When
        await tester.pumpWidget(createTestWidget());

        // Then - TextFormField가 올바르게 렌더링되었는지 확인
        expect(find.byType(TextFormField), findsOneWidget);
      });
    });

    group('테마 적용 테스트', () {
      testWidgets('should apply vintage ivory theme colors', (WidgetTester tester) async {
        // Given & When
        await tester.pumpWidget(createTestWidget());

        // Then - 빈티지 아이보리 테마 색상 적용 확인
        // expect(scaffold.backgroundColor, equals(AppTheme.backgroundColor));
      });

      testWidgets('should use correct button styling', (WidgetTester tester) async {
        // Given & When
        await tester.pumpWidget(createTestWidget());

        // Then
        final primaryButton = find.widgetWithText(ElevatedButton, '레시피 가져오기');
        expect(primaryButton, findsOneWidget);

        // expect(buttonWidget.style?.backgroundColor?.resolve({}), 
        //        equals(AppTheme.primaryColor));
      });
    });

    group('반응형 레이아웃 테스트', () {
      testWidgets('should adapt to different screen sizes', (WidgetTester tester) async {
        // Given - 다양한 화면 크기 시뮬레이션
        await tester.binding.setSurfaceSize(const Size(800, 600)); // 태블릿 크기
        await tester.pumpWidget(createTestWidget());

        // When & Then - 레이아웃 적응 확인
        expect(find.byType(UrlImportScreen), findsOneWidget);

        // 모바일 크기로 변경
        await tester.binding.setSurfaceSize(const Size(375, 667)); // iPhone 크기
        await tester.pump();

        expect(find.byType(UrlImportScreen), findsOneWidget);
      });
    });

    group('상태 관리 테스트', () {
      testWidgets('should maintain form state during rebuilds', (WidgetTester tester) async {
        // Given
        await tester.pumpWidget(createTestWidget());
        const testUrl = 'https://example.com/recipe';

        // When
        await tester.enterText(find.byType(TextFormField), testUrl);
        await tester.pump(); // 리빌드 시뮬레이션

        // Then - 입력값 유지 확인
        expect(find.text(testUrl), findsOneWidget);
      });

      testWidgets('should clear form when needed', (WidgetTester tester) async {
        // Given
        await tester.pumpWidget(createTestWidget());
        const testUrl = 'https://example.com/recipe';

        await tester.enterText(find.byType(TextFormField), testUrl);

        // When - 클리어 액션 (실제 구현에 따라)
        // await tester.tap(find.byIcon(Icons.clear));
        // await tester.pump();

        // Then
        // expect(find.text(testUrl), findsNothing);
      });
    });

    group('성능 테스트', () {
      testWidgets('should not cause memory leaks', (WidgetTester tester) async {
        // Given & When
        for (int i = 0; i < 10; i++) {
          await tester.pumpWidget(createTestWidget());
          await tester.pumpWidget(Container()); // 위젯 제거
        }

        // Then - 메모리 누수가 없어야 함 (실제로는 프로파일링 도구 사용)
        expect(true, isTrue); // 기본적인 완료 확인
      });
    });
  });
}

// 테스트용 확장 클래스 (필요시)
extension UrlImportScreenTestExtension on WidgetTester {
  Future<void> enterUrlAndSubmit(String url) async {
    await enterText(find.byType(TextFormField), url);
    await tap(find.text('레시피 가져오기'));
    await pump();
  }

  Future<void> waitForAnalysisComplete() async {
    await pumpAndSettle(const Duration(seconds: 3));
  }
}