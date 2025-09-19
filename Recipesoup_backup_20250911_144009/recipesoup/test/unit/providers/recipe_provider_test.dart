import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:recipesoup/models/recipe.dart';
import 'package:recipesoup/models/ingredient.dart';
import 'package:recipesoup/models/mood.dart';
import 'package:recipesoup/providers/recipe_provider.dart';
import 'package:recipesoup/services/hive_service.dart';

// Generate mock classes
@GenerateMocks([HiveService])
import 'recipe_provider_test.mocks.dart';

void main() {
  group('RecipeProvider Tests (감정 기반 상태 관리 핵심!)', () {
    late RecipeProvider recipeProvider;
    late MockHiveService mockHiveService;
    
    setUp(() {
      mockHiveService = MockHiveService();
      recipeProvider = RecipeProvider(hiveService: mockHiveService);
    });
    
    group('초기 상태 테스트', () {
      test('should initialize with empty state', () {
        // Then
        expect(recipeProvider.recipes, isEmpty);
        expect(recipeProvider.selectedRecipe, isNull);
        expect(recipeProvider.isLoading, isFalse);
        expect(recipeProvider.error, isNull);
        expect(recipeProvider.todayMemories, isEmpty);
      });
    });
    
    group('레시피 로딩 테스트', () {
      test('should load recipes successfully', () async {
        // Given - 테스트 레시피 데이터
        final testRecipes = [
          Recipe(
            id: 'test_001',
            title: '행복한 김치찌개',
            emotionalStory: '오늘 기분이 좋아서 만든 김치찌개',
            ingredients: [
              Ingredient(name: '김치', amount: '200g', unit: 'g', category: IngredientCategory.vegetable),
              Ingredient(name: '돼지고기', amount: '150g', unit: 'g', category: IngredientCategory.meat),
            ],
            instructions: ['김치를 볶는다', '고기를 넣고 끓인다'],
            tags: ['#기쁨', '#김치찌개'],
            createdAt: DateTime.now(),
            mood: Mood.happy,
            rating: 5,
            isFavorite: true,
          ),
          Recipe(
            id: 'test_002',
            title: '슬픈 미역국',
            emotionalStory: '힘든 날 위로받고 싶어서 끓인 미역국',
            ingredients: [
              Ingredient(name: '미역', amount: '30g', unit: 'g', category: IngredientCategory.vegetable),
            ],
            instructions: ['미역을 불리고 끓인다'],
            tags: ['#슬픔', '#미역국'],
            createdAt: DateTime.now().subtract(Duration(days: 1)),
            mood: Mood.sad,
            rating: 4,
            isFavorite: false,
          ),
        ];
        
        // Mock setup
        when(mockHiveService.getAllRecipes()).thenAnswer((_) async => testRecipes);
        
        // When
        await recipeProvider.loadRecipes();
        
        // Then
        expect(recipeProvider.recipes, hasLength(2));
        expect(recipeProvider.recipes.first.title, equals('행복한 김치찌개'));
        expect(recipeProvider.isLoading, isFalse);
        expect(recipeProvider.error, isNull);
        verify(mockHiveService.getAllRecipes()).called(1);
      });
      
      test('should handle loading error gracefully', () async {
        // Given - 에러 시뮬레이션
        when(mockHiveService.getAllRecipes()).thenThrow(Exception('데이터베이스 오류'));
        
        // When
        await recipeProvider.loadRecipes();
        
        // Then
        expect(recipeProvider.recipes, isEmpty);
        expect(recipeProvider.isLoading, isFalse);
        expect(recipeProvider.error, contains('데이터베이스 오류'));
        verify(mockHiveService.getAllRecipes()).called(1);
      });
      
      test('should set loading state during operation', () async {
        // Given
        when(mockHiveService.getAllRecipes()).thenAnswer((_) async {
          await Future.delayed(Duration(milliseconds: 100));
          return <Recipe>[];
        });
        
        // When - 로딩 시작
        final loadingFuture = recipeProvider.loadRecipes();
        
        // Then - 로딩 중 상태 확인
        expect(recipeProvider.isLoading, isTrue);
        
        // 로딩 완료 대기
        await loadingFuture;
        expect(recipeProvider.isLoading, isFalse);
      });
    });
    
    group('레시피 추가 테스트', () {
      test('should add recipe successfully', () async {
        // Given - 새로운 레시피
        final newRecipe = Recipe(
          id: 'new_001',
          title: '새로운 파스타',
          emotionalStory: '설렘에 가득찬 새로운 도전',
          ingredients: [
            Ingredient(name: '파스타면', amount: '200g', unit: 'g', category: IngredientCategory.grain),
          ],
          instructions: ['면을 삶는다', '소스와 섞는다'],
          tags: ['#설렘', '#파스타'],
          createdAt: DateTime.now(),
          mood: Mood.excited,
          rating: 5,
          isFavorite: false,
        );
        
        // Mock setup
        when(mockHiveService.saveRecipe(newRecipe)).thenAnswer((_) async => 'new_001');
        
        // When
        await recipeProvider.addRecipe(newRecipe);
        
        // Then
        expect(recipeProvider.recipes, contains(newRecipe));
        expect(recipeProvider.recipes.first, equals(newRecipe)); // 최신 순으로 맨 앞에
        expect(recipeProvider.error, isNull);
        verify(mockHiveService.saveRecipe(newRecipe)).called(1);
      });
      
      test('should handle add recipe error', () async {
        // Given - 레시피와 에러 시뮬레이션
        final recipe = Recipe(
          id: 'error_001',
          title: '에러 테스트',
          emotionalStory: '에러 시뮬레이션',
          ingredients: [],
          instructions: [],
          tags: [],
          createdAt: DateTime.now(),
          mood: Mood.sad,
        );
        
        when(mockHiveService.saveRecipe(recipe)).thenThrow(Exception('저장 실패'));
        
        // When
        await recipeProvider.addRecipe(recipe);
        
        // Then
        expect(recipeProvider.recipes, isEmpty);
        expect(recipeProvider.error, contains('저장 실패'));
        verify(mockHiveService.saveRecipe(recipe)).called(1);
      });
    });
    
    group('레시피 수정 테스트', () {
      test('should update recipe successfully', () async {
        // Given - 기존 레시피 로드
        final originalRecipe = Recipe(
          id: 'update_001',
          title: '원본 레시피',
          emotionalStory: '원본 감정 이야기',
          ingredients: [],
          instructions: [],
          tags: [],
          createdAt: DateTime.now(),
          mood: Mood.peaceful,
          rating: 3,
        );
        
        when(mockHiveService.getAllRecipes()).thenAnswer((_) async => [originalRecipe]);
        await recipeProvider.loadRecipes();
        
        // 수정된 레시피
        final updatedRecipe = originalRecipe.copyWith(
          title: '수정된 레시피',
          emotionalStory: '수정된 감정 이야기',
          rating: 5,
        );
        
        // Mock setup
        when(mockHiveService.updateRecipe(updatedRecipe)).thenAnswer((_) async {});
        
        // When
        await recipeProvider.updateRecipe(updatedRecipe);
        
        // Then
        final foundRecipe = recipeProvider.recipes.firstWhere((r) => r.id == 'update_001');
        expect(foundRecipe.title, equals('수정된 레시피'));
        expect(foundRecipe.emotionalStory, equals('수정된 감정 이야기'));
        expect(foundRecipe.rating, equals(5));
        verify(mockHiveService.updateRecipe(updatedRecipe)).called(1);
      });
    });
    
    group('레시피 삭제 테스트', () {
      test('should delete recipe successfully', () async {
        // Given - 기존 레시피들
        final recipes = [
          Recipe(id: 'delete_001', title: '삭제될 레시피', emotionalStory: '테스트', ingredients: [], instructions: [], tags: [], createdAt: DateTime.now(), mood: Mood.happy),
          Recipe(id: 'keep_002', title: '유지될 레시피', emotionalStory: '테스트', ingredients: [], instructions: [], tags: [], createdAt: DateTime.now(), mood: Mood.peaceful),
        ];
        
        when(mockHiveService.getAllRecipes()).thenAnswer((_) async => recipes);
        await recipeProvider.loadRecipes();
        
        // Mock setup
        when(mockHiveService.deleteRecipe('delete_001')).thenAnswer((_) async => true);
        
        // When
        await recipeProvider.deleteRecipe('delete_001');
        
        // Then
        expect(recipeProvider.recipes, hasLength(1));
        expect(recipeProvider.recipes.first.id, equals('keep_002'));
        verify(mockHiveService.deleteRecipe('delete_001')).called(1);
      });
    });
    
    group('검색 및 필터링 테스트', () {
      setUp(() async {
        // 테스트용 레시피들 로드
        final testRecipes = [
          Recipe(id: '1', title: '김치찌개', emotionalStory: '기쁜 하루', ingredients: [], instructions: [], tags: ['#한식', '#기쁨'], createdAt: DateTime.now(), mood: Mood.happy),
          Recipe(id: '2', title: '파스타', emotionalStory: '설렘 가득한', ingredients: [], instructions: [], tags: ['#양식', '#설렘'], createdAt: DateTime.now(), mood: Mood.excited),
          Recipe(id: '3', title: '미역국', emotionalStory: '슬픈 마음을 달래려', ingredients: [], instructions: [], tags: ['#한식', '#슬픔'], createdAt: DateTime.now(), mood: Mood.sad),
        ];
        
        when(mockHiveService.getAllRecipes()).thenAnswer((_) async => testRecipes);
        await recipeProvider.loadRecipes();
      });
      
      test('should search recipes by title', () {
        // When - 제목으로 검색
        final results = recipeProvider.searchRecipes('김치');
        
        // Then
        expect(results, hasLength(1));
        expect(results.first.title, contains('김치'));
      });
      
      test('should filter recipes by mood', () {
        // When - 감정별 필터링
        final happyRecipes = recipeProvider.searchRecipes('', mood: Mood.happy);
        
        // Then
        expect(happyRecipes, hasLength(1));
        expect(happyRecipes.first.mood, equals(Mood.happy));
      });
      
      test('should search with combined filters', () {
        // When - 제목 + 감정 조합 검색
        final results = recipeProvider.searchRecipes('파스타', mood: Mood.excited);
        
        // Then
        expect(results, hasLength(1));
        expect(results.first.title, equals('파스타'));
        expect(results.first.mood, equals(Mood.excited));
      });
      
      test('should return empty for no matches', () {
        // When - 매치되지 않는 검색
        final results = recipeProvider.searchRecipes('존재하지않는요리');
        
        // Then
        expect(results, isEmpty);
      });
    });
    
    group('"과거 오늘" 기능 테스트', () {
      test('should return past today memories', () async {
        // Given - 다양한 날짜의 레시피들
        final today = DateTime.now();
        final lastYear = DateTime(today.year - 1, today.month, today.day, 18, 30);
        final twoYearsAgo = DateTime(today.year - 2, today.month, today.day, 12, 0);
        final differentDay = DateTime(today.year - 1, today.month, today.day + 1, 19, 0);
        
        final testRecipes = [
          Recipe(id: '1', title: '작년 오늘', emotionalStory: '1년 전 추억', ingredients: [], instructions: [], tags: [], createdAt: lastYear, mood: Mood.nostalgic),
          Recipe(id: '2', title: '2년 전 오늘', emotionalStory: '2년 전 추억', ingredients: [], instructions: [], tags: [], createdAt: twoYearsAgo, mood: Mood.nostalgic),
          Recipe(id: '3', title: '다른 날', emotionalStory: '다른 날 요리', ingredients: [], instructions: [], tags: [], createdAt: differentDay, mood: Mood.happy),
          Recipe(id: '4', title: '오늘 요리', emotionalStory: '오늘 만든 요리', ingredients: [], instructions: [], tags: [], createdAt: today, mood: Mood.happy),
        ];
        
        when(mockHiveService.getAllRecipes()).thenAnswer((_) async => testRecipes);
        await recipeProvider.loadRecipes();
        
        // When
        final memories = recipeProvider.todayMemories;
        
        // Then - 같은 월/일이지만 다른 년도만 반환
        expect(memories, hasLength(2));
        expect(memories.any((r) => r.title == '작년 오늘'), isTrue);
        expect(memories.any((r) => r.title == '2년 전 오늘'), isTrue);
        expect(memories.any((r) => r.title == '다른 날'), isFalse);
        expect(memories.any((r) => r.title == '오늘 요리'), isFalse);
      });
    });
    
    group('선택된 레시피 관리 테스트', () {
      test('should select and deselect recipe', () {
        // Given
        final recipe = Recipe(
          id: 'select_001',
          title: '선택될 레시피',
          emotionalStory: '선택 테스트',
          ingredients: [],
          instructions: [],
          tags: [],
          createdAt: DateTime.now(),
          mood: Mood.happy,
        );
        
        // When - 선택
        recipeProvider.selectRecipe(recipe);
        
        // Then
        expect(recipeProvider.selectedRecipe, equals(recipe));
        
        // When - 선택 해제
        recipeProvider.clearSelection();
        
        // Then
        expect(recipeProvider.selectedRecipe, isNull);
      });
    });
    
    group('에러 상태 관리 테스트', () {
      test('should clear error state', () async {
        // Given - 에러 발생
        when(mockHiveService.getAllRecipes()).thenThrow(Exception('테스트 에러'));
        await recipeProvider.loadRecipes();
        expect(recipeProvider.error, isNotNull);
        
        // When - 에러 클리어
        recipeProvider.clearError();
        
        // Then
        expect(recipeProvider.error, isNull);
      });
      
      test('should reset error on successful operation', () async {
        // Given - 에러 상태
        recipeProvider.setError('이전 에러');
        expect(recipeProvider.error, isNotNull);
        
        // When - 성공적인 로딩
        when(mockHiveService.getAllRecipes()).thenAnswer((_) async => <Recipe>[]);
        await recipeProvider.loadRecipes();
        
        // Then - 에러 자동 클리어
        expect(recipeProvider.error, isNull);
      });
    });
    
    group('리스너 알림 테스트', () {
      test('should notify listeners on state changes', () async {
        // Given
        int notificationCount = 0;
        recipeProvider.addListener(() {
          notificationCount++;
        });
        
        // When - 각종 상태 변경 작업들
        when(mockHiveService.getAllRecipes()).thenAnswer((_) async => <Recipe>[]);
        await recipeProvider.loadRecipes(); // 로딩 시작 + 완료 = 2회
        
        when(mockHiveService.saveRecipe(any)).thenAnswer((_) async => 'test_id');
        await recipeProvider.addRecipe(Recipe(
          id: 'notify_test',
          title: '알림 테스트',
          emotionalStory: '테스트',
          ingredients: [],
          instructions: [],
          tags: [],
          createdAt: DateTime.now(),
          mood: Mood.happy,
        )); // 1회
        
        // Then - 총 3회 알림 발생
        expect(notificationCount, equals(3));
      });
    });
  });
}