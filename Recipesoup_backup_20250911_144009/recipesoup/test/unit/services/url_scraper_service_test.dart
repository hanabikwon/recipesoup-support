import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:recipesoup/services/url_scraper_service.dart';

// Mock 클래스 생성을 위한 어노테이션
@GenerateMocks([http.Client])
import 'url_scraper_service_test.mocks.dart';

void main() {
  group('UrlScraperService Tests', () {
    late UrlScraperService service;
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
      service = UrlScraperService();
    });

    group('웹페이지 스크래핑 테스트', () {
      test('should scrape recipe content from blog URL successfully', () async {
        // Given
        const testUrl = 'https://blog.naver.com/test/recipe';
        const mockHtmlContent = '''
        <!DOCTYPE html>
        <html>
        <head>
          <title>맛있는 김치찌개 레시피</title>
        </head>
        <body>
          <div class="post-content">
            <h1>김치찌개 만드는 법</h1>
            <p>재료: 김치 200g, 돼지고기 150g, 두부 1/2모</p>
            <p>만드는 법:</p>
            <ol>
              <li>김치를 기름에 볶아주세요</li>
              <li>돼지고기를 넣고 함께 볶아주세요</li>
              <li>물을 넣고 끓여주세요</li>
            </ol>
            <p>오늘은 날씨가 추워서 따뜻한 김치찌개를 만들어봤어요.</p>
          </div>
        </body>
        </html>
        ''';

        final mockResponse = http.Response(
          mockHtmlContent,
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );

        when(mockClient.get(
          Uri.parse(testUrl),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => mockResponse);

        // When
        final result = await service.scrapeRecipeFromUrl(testUrl);

        // Then
        expect(result.sourceUrl, equals(testUrl));
        expect(result.title, equals('맛있는 김치찌개 레시피'));
        expect(result.hasRecipeContent, isTrue);
        expect(result.text, contains('김치'));
        expect(result.text, contains('돼지고기'));
        expect(result.text, contains('두부'));
        expect(result.text, contains('볶아주세요'));
        expect(result.text, contains('끓여주세요'));

        // HTTP 호출 검증
        verify(mockClient.get(
          Uri.parse(testUrl),
          headers: anyNamed('headers'),
        )).called(1);
      });

      test('should detect recipe content with recipe keywords', () async {
        // Given
        const testUrl = 'https://example.com/recipe';
        const mockHtmlContent = '''
        <html>
        <body>
          <h1>파스타 요리법</h1>
          <p>재료: 파스타면, 토마토소스, 올리브오일</p>
          <p>조리시간: 20분</p>
          <p>1. 면을 삶는다</p>
          <p>2. 소스를 만든다</p>
          <p>3. 면과 소스를 섞는다</p>
        </body>
        </html>
        ''';

        final mockResponse = http.Response(mockHtmlContent, 200);
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockResponse);

        // When
        final result = await service.scrapeRecipeFromUrl(testUrl);

        // Then
        expect(result.hasRecipeContent, isTrue);
        expect(result.text, contains('재료'));
        expect(result.text, contains('조리시간'));
        expect(result.text, contains('파스타면'));
      });

      test('should not detect recipe content without recipe keywords', () async {
        // Given
        const testUrl = 'https://example.com/news';
        const mockHtmlContent = '''
        <html>
        <body>
          <h1>오늘의 뉴스</h1>
          <p>정치 소식입니다.</p>
          <p>경제 상황에 대한 분석입니다.</p>
          <p>스포츠 결과를 알려드립니다.</p>
        </body>
        </html>
        ''';

        final mockResponse = http.Response(mockHtmlContent, 200);
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockResponse);

        // When
        final result = await service.scrapeRecipeFromUrl(testUrl);

        // Then
        expect(result.hasRecipeContent, isFalse);
        expect(result.text, contains('뉴스'));
        expect(result.text, isNot(contains('재료')));
        expect(result.text, isNot(contains('조리법')));
      });
    });

    group('플랫폼별 파싱 테스트', () {
      test('should parse Naver blog content correctly', () async {
        // Given - 네이버 블로그 특화 HTML 구조
        const testUrl = 'https://blog.naver.com/user123/recipe123';
        const mockNaverHtml = '''
        <html>
        <body>
          <div class="se-module se-module-text">
            <p class="se-text-paragraph">
              <span class="se-text">맛있는 김치찌개 만들기</span>
            </p>
          </div>
          <div class="se-module se-module-text">
            <p class="se-text-paragraph">
              <span class="se-text">재료: 김치 200g, 돼지고기 100g</span>
            </p>
          </div>
          <div class="se-module se-module-text">
            <p class="se-text-paragraph">
              <span class="se-text">1. 김치를 볶아주세요</span>
            </p>
            <p class="se-text-paragraph">  
              <span class="se-text">2. 고기를 넣고 볶아주세요</span>
            </p>
          </div>
        </body>
        </html>
        ''';

        final mockResponse = http.Response(mockNaverHtml, 200);
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockResponse);

        // When
        final result = await service.scrapeRecipeFromUrl(testUrl);

        // Then
        expect(result.hasRecipeContent, isTrue);
        expect(result.text, contains('김치찌개'));
        expect(result.text, contains('재료'));
        expect(result.text, contains('김치 200g'));
        expect(result.text, contains('돼지고기 100g'));
        expect(result.text, contains('볶아주세요'));
      });

      test('should parse Tistory blog content correctly', () async {
        // Given - 티스토리 블로그 특화 HTML 구조
        const testUrl = 'https://user123.tistory.com/123';
        const mockTistoryHtml = '''
        <html>
        <body>
          <div class="entry-content">
            <h2>파스타 레시피</h2>
            <p>준비물:</p>
            <ul>
              <li>파스타면 200g</li>
              <li>토마토소스 1캔</li>
              <li>마늘 3쪽</li>
            </ul>
            <p>조리 순서:</p>
            <ol>
              <li>물을 끓인다</li>
              <li>면을 넣고 8분간 삶는다</li>
              <li>소스를 만든다</li>
            </ol>
          </div>
        </body>
        </html>
        ''';

        final mockResponse = http.Response(mockTistoryHtml, 200);
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockResponse);

        // When
        final result = await service.scrapeRecipeFromUrl(testUrl);

        // Then
        expect(result.hasRecipeContent, isTrue);
        expect(result.text, contains('파스타 레시피'));
        expect(result.text, contains('준비물'));
        expect(result.text, contains('파스타면 200g'));
        expect(result.text, contains('조리 순서'));
        expect(result.text, contains('물을 끓인다'));
      });

      test('should handle general website content', () async {
        // Given - 일반 웹사이트 HTML
        const testUrl = 'https://recipe-site.com/korean-food';
        const mockGeneralHtml = '''
        <html>
        <head>
          <title>한식 요리 - 집에서 만드는 김치볶음밥</title>
        </head>
        <body>
          <article>
            <h1>집에서 만드는 김치볶음밥</h1>
            <section class="ingredients">
              <h3>필요한 재료</h3>
              <p>밥 2공기, 김치 150g, 계란 2개, 파 1대</p>
            </section>
            <section class="instructions">
              <h3>만드는 방법</h3>
              <p>1. 김치를 잘게 썬다</p>
              <p>2. 팬에 기름을 두르고 김치를 볶는다</p>
              <p>3. 밥을 넣고 함께 볶는다</p>
            </section>
          </article>
        </body>
        </html>
        ''';

        final mockResponse = http.Response(mockGeneralHtml, 200);
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockResponse);

        // When
        final result = await service.scrapeRecipeFromUrl(testUrl);

        // Then
        expect(result.title, contains('김치볶음밥'));
        expect(result.hasRecipeContent, isTrue);
        expect(result.text, contains('필요한 재료'));
        expect(result.text, contains('밥 2공기'));
        expect(result.text, contains('만드는 방법'));
        expect(result.text, contains('김치를 잘게 썬다'));
      });
    });

    group('에러 처리 테스트', () {
      test('should throw UrlScrapingException for connection error', () async {
        // Given
        const testUrl = 'https://unreachable-site.com';
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenThrow(http.ClientException('Connection failed'));

        // When & Then
        expect(
          () => service.scrapeRecipeFromUrl(testUrl),
          throwsA(isA<UrlScrapingException>()),
        );
      });

      test('should throw UrlScrapingException for 404 error', () async {
        // Given
        const testUrl = 'https://example.com/not-found';
        final mockResponse = http.Response('Not Found', 404);
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockResponse);

        // When & Then
        expect(
          () => service.scrapeRecipeFromUrl(testUrl),
          throwsA(isA<UrlScrapingException>()),
        );
      });

      test('should throw UrlScrapingException for 500 error', () async {
        // Given
        const testUrl = 'https://example.com/server-error';
        final mockResponse = http.Response('Internal Server Error', 500);
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockResponse);

        // When & Then
        expect(
          () => service.scrapeRecipeFromUrl(testUrl),
          throwsA(isA<UrlScrapingException>()),
        );
      });

      test('should handle timeout gracefully', () async {
        // Given
        const testUrl = 'https://slow-site.com';
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenThrow(http.ClientException('Timeout'));

        // When & Then
        expect(
          () => service.scrapeRecipeFromUrl(testUrl),
          throwsA(isA<UrlScrapingException>()),
        );
      });
    });

    group('URL 유효성 검증 테스트', () {
      test('should handle invalid URL format', () async {
        // Given
        const invalidUrl = 'not-a-valid-url';

        // When & Then
        expect(
          () => service.scrapeRecipeFromUrl(invalidUrl),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should handle empty URL', () async {
        // Given
        const emptyUrl = '';

        // When & Then
        expect(
          () => service.scrapeRecipeFromUrl(emptyUrl),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should accept various valid URL formats', () async {
        // Given
        final validUrls = [
          'https://blog.naver.com/user/123',
          'http://tistory.com/recipe',
          'https://recipe-site.co.kr/korean-food',
        ];

        const mockHtmlContent = '''
        <html><body>
          <h1>테스트 레시피</h1>
          <p>재료: 테스트 재료</p>
        </body></html>
        ''';

        final mockResponse = http.Response(mockHtmlContent, 200);
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockResponse);

        // When & Then
        for (final url in validUrls) {
          expect(
            () => service.scrapeRecipeFromUrl(url),
            returnsNormally,
          );
        }
      });
    });

    group('콘텐츠 정리 테스트', () {
      test('should clean HTML tags and normalize whitespace', () async {
        // Given
        const testUrl = 'https://example.com/recipe';
        const messyHtml = '''
        <html>
        <body>
          <div>
            <h1>  제목  </h1>
            <p>   여러     공백이    있는   텍스트   </p>
            <script>alert('script')</script>
            <style>.class { color: red; }</style>
            <p><strong>재료:</strong> <em>김치</em>, <span>돼지고기</span></p>
          </div>
        </body>
        </html>
        ''';

        final mockResponse = http.Response(messyHtml, 200);
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockResponse);

        // When
        final result = await service.scrapeRecipeFromUrl(testUrl);

        // Then
        expect(result.text, isNot(contains('<script>')));
        expect(result.text, isNot(contains('<style>')));
        expect(result.text, isNot(contains('alert')));
        expect(result.text, contains('제목'));
        expect(result.text, contains('여러 공백이 있는 텍스트'));
        expect(result.text, contains('재료'));
        expect(result.text, contains('김치'));
        expect(result.text, contains('돼지고기'));
      });

      test('should extract meaningful content and ignore noise', () async {
        // Given
        const testUrl = 'https://example.com/blog';
        const noisyHtml = '''
        <html>
        <body>
          <nav>네비게이션 메뉴</nav>
          <aside>광고 콘텐츠</aside>
          <main>
            <article>
              <h1>오늘의 요리: 된장찌개</h1>
              <p>재료: 된장 2큰술, 두부 1모, 애호박 1개</p>
              <p>조리법: 물을 끓이고 된장을 풀어주세요</p>
            </article>
          </main>
          <footer>푸터 정보</footer>
          <div class="comments">댓글들...</div>
        </body>
        </html>
        ''';

        final mockResponse = http.Response(noisyHtml, 200);
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockResponse);

        // When
        final result = await service.scrapeRecipeFromUrl(testUrl);

        // Then
        expect(result.text, contains('된장찌개'));
        expect(result.text, contains('재료'));
        expect(result.text, contains('된장 2큰술'));
        expect(result.text, contains('조리법'));
        // 노이즈는 포함되지 않음
        expect(result.text, isNot(contains('네비게이션 메뉴')));
        expect(result.text, isNot(contains('광고 콘텐츠')));
        expect(result.text, isNot(contains('푸터 정보')));
      });
    });

    group('레시피 키워드 감지 테스트', () {
      test('should detect Korean recipe keywords', () async {
        // Given
        const testUrl = 'https://example.com/recipe';
        final recipeKeywords = [
          '재료', '조리법', '만드는법', '요리법', '레시피',
          '준비물', '조리시간', '난이도', '인분'
        ];

        for (final keyword in recipeKeywords) {
          final htmlWithKeyword = '''
          <html><body>
            <h1>테스트 요리</h1>
            <p>$keyword: 테스트 내용</p>
          </body></html>
          ''';

          final mockResponse = http.Response(htmlWithKeyword, 200);
          when(mockClient.get(any, headers: anyNamed('headers')))
              .thenAnswer((_) async => mockResponse);

          // When
          final result = await service.scrapeRecipeFromUrl(testUrl);

          // Then
          expect(result.hasRecipeContent, isTrue,
              reason: 'Should detect "$keyword" as recipe content');
        }
      });

      test('should detect English recipe keywords', () async {
        // Given
        const testUrl = 'https://example.com/recipe';
        final englishKeywords = [
          'ingredients', 'recipe', 'cooking', 'instructions',
          'preparation', 'servings', 'cook time'
        ];

        for (final keyword in englishKeywords) {
          final htmlWithKeyword = '''
          <html><body>
            <h1>Test Recipe</h1>
            <p>$keyword: test content</p>
          </body></html>
          ''';

          final mockResponse = http.Response(htmlWithKeyword, 200);
          when(mockClient.get(any, headers: anyNamed('headers')))
              .thenAnswer((_) async => mockResponse);

          // When
          final result = await service.scrapeRecipeFromUrl(testUrl);

          // Then
          expect(result.hasRecipeContent, isTrue,
              reason: 'Should detect "$keyword" as recipe content');
        }
      });

      test('should require minimum keyword count for recipe detection', () async {
        // Given - 키워드가 하나만 있는 경우
        const testUrl = 'https://example.com/maybe-recipe';
        const htmlWithOneKeyword = '''
        <html><body>
          <h1>일반 글</h1>
          <p>오늘 요리를 해봤어요.</p>
          <p>맛있게 먹었습니다.</p>
        </body></html>
        ''';

        final mockResponse = http.Response(htmlWithOneKeyword, 200);
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockResponse);

        // When
        final result = await service.scrapeRecipeFromUrl(testUrl);

        // Then - 키워드가 충분하지 않으면 레시피로 판단하지 않음
        expect(result.hasRecipeContent, isFalse);
      });
    });

    group('문자 인코딩 처리 테스트', () {
      test('should handle UTF-8 encoded content', () async {
        // Given
        const testUrl = 'https://example.com/recipe';
        const utf8Content = '''
        <html>
        <head>
          <meta charset="UTF-8">
          <title>한글 레시피</title>
        </head>
        <body>
          <h1>김치찌개 만들기</h1>
          <p>재료: 김치, 돼지고기, 두부</p>
          <p>특별한 양념: 고춧가루, 마늘, 생강</p>
        </body>
        </html>
        ''';

        final mockResponse = http.Response(
          utf8Content,
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockResponse);

        // When
        final result = await service.scrapeRecipeFromUrl(testUrl);

        // Then
        expect(result.title, contains('한글 레시피'));
        expect(result.text, contains('김치찌개'));
        expect(result.text, contains('고춧가루'));
        expect(result.hasRecipeContent, isTrue);
      });

      test('should handle EUC-KR encoded content', () async {
        // Given
        const testUrl = 'https://old-site.com/recipe';
        // EUC-KR 인코딩된 HTML (시뮬레이션)
        const eucKrContent = '''
        <html>
        <head>
          <meta charset="EUC-KR">
        </head>
        <body>
          <h1>전통 요리법</h1>
          <p>재료 준비</p>
        </body>
        </html>
        ''';

        final mockResponse = http.Response(
          eucKrContent,
          200,
          headers: {'content-type': 'text/html; charset=euc-kr'},
        );
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockResponse);

        // When
        final result = await service.scrapeRecipeFromUrl(testUrl);

        // Then - 인코딩 처리 후 정상적으로 추출
        expect(result.text, contains('전통 요리법'));
        expect(result.text, contains('재료 준비'));
      });
    });
  });
}