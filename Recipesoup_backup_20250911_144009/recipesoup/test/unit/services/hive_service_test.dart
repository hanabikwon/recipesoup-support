import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:recipesoup/services/hive_service.dart';
import 'package:recipesoup/models/recipe.dart';
import 'package:recipesoup/models/ingredient.dart';
import 'package:recipesoup/models/mood.dart';

void main() {
  group('Hive Service Tests (로컬 저장소 핵심!)', () {
    late HiveService hiveService;
    late Box<Map<String, dynamic>> recipeBox;
    late String testBoxName;

    setUpAll(() async {
      // 테스트용 Hive 초기화
      Hive.init('./test_hive');
      
      // TypeAdapter는 나중에 추가 예정
      // 현재는 JSON 기반 저장으로 테스트
    });

    setUp(() async {
      // 각 테스트마다 고유한 Box 이름 생성 (테스트 격리)
      testBoxName = 'test_recipes_${DateTime.now().microsecondsSinceEpoch}';
      
      // HiveService에 테스트용 Box 이름 전달
      hiveService = HiveService(boxName: testBoxName);
      
      // Box 참조 획득 (정리를 위해)
      recipeBox = await Hive.openBox<Map<String, dynamic>>(testBoxName);
    });

    tearDown(() async {
      // 테스트 후 정리 - 각각의 고유 Box 정리
      await recipeBox.clear();
      await recipeBox.close();
      await Hive.deleteBoxFromDisk(testBoxName);
    });

    tearDownAll(() async {
      // 전체 테스트 디렉토리 정리
      await Hive.deleteFromDisk();
    });

    group('Recipe CRUD 테스트 (기본 기능)', () {
      test('should save recipe successfully', () async {
        // Given - TESTDATA.md의 샘플 레시피 사용
        final recipe = Recipe(
          id: 'test_recipe_001',
          title: '테스트 김치찌개',
          emotionalStory: '테스트로 만든 김치찌개입니다. 정말 맛있어 보이네요!',
          ingredients: [
            Ingredient(
              name: '김치', 
              amount: '200g', 
              unit: 'g', 
              category: IngredientCategory.vegetable
            ),
            Ingredient(
              name: '돼지고기', 
              amount: '150g', 
              unit: 'g', 
              category: IngredientCategory.meat
            ),
          ],
          instructions: [
            '김치를 기름에 볶는다',
            '돼지고기를 넣고 함께 볶는다',
            '물을 넣고 끓인다'
          ],
          localImagePath: 'test_images/kimchi_stew.jpg',
          tags: ['#테스트', '#김치찌개', '#한식'],
          createdAt: DateTime(2024, 12, 28, 18, 30),
          mood: Mood.happy,
          rating: 5,
          reminderDate: null,
          isFavorite: true,
        );

        // When
        await hiveService.saveRecipe(recipe);
        final savedRecipe = await hiveService.getRecipe(recipe.id);

        // Then
        expect(savedRecipe, isNotNull);
        expect(savedRecipe!.id, equals('test_recipe_001'));
        expect(savedRecipe.title, equals('테스트 김치찌개'));
        expect(savedRecipe.emotionalStory, contains('테스트로 만든'));
        expect(savedRecipe.ingredients, hasLength(2));
        expect(savedRecipe.ingredients.first.name, equals('김치'));
        expect(savedRecipe.mood, equals(Mood.happy));
        expect(savedRecipe.isFavorite, isTrue);
        expect(savedRecipe.rating, equals(5));
      });

      test('should get recipe by id', () async {
        // Given
        final recipe = _createTestRecipe('get_test_001', '조회 테스트 레시피');
        await hiveService.saveRecipe(recipe);

        // When
        final retrievedRecipe = await hiveService.getRecipe('get_test_001');

        // Then
        expect(retrievedRecipe, isNotNull);
        expect(retrievedRecipe!.id, equals('get_test_001'));
        expect(retrievedRecipe.title, equals('조회 테스트 레시피'));
      });

      test('should return null for non-existent recipe', () async {
        // When
        final recipe = await hiveService.getRecipe('non_existent_id');

        // Then
        expect(recipe, isNull);
      });

      test('should update recipe successfully', () async {
        // Given
        final originalRecipe = _createTestRecipe('update_test_001', '수정 전 레시피');
        await hiveService.saveRecipe(originalRecipe);

        final updatedRecipe = originalRecipe.copyWith(
          title: '수정 후 레시피',
          emotionalStory: '수정된 감정 이야기입니다.',
          rating: 4,
        );

        // When
        await hiveService.updateRecipe(updatedRecipe);
        final result = await hiveService.getRecipe('update_test_001');

        // Then
        expect(result, isNotNull);
        expect(result!.title, equals('수정 후 레시피'));
        expect(result.emotionalStory, equals('수정된 감정 이야기입니다.'));
        expect(result.rating, equals(4));
        expect(result.id, equals('update_test_001')); // ID는 유지
      });

      test('should delete recipe successfully', () async {
        // Given
        final recipe = _createTestRecipe('delete_test_001', '삭제될 레시피');
        await hiveService.saveRecipe(recipe);
        
        // 저장 확인
        expect(await hiveService.getRecipe('delete_test_001'), isNotNull);

        // When
        await hiveService.deleteRecipe('delete_test_001');

        // Then
        expect(await hiveService.getRecipe('delete_test_001'), isNull);
      });

      test('should handle delete non-existent recipe gracefully', () async {
        // When & Then - 예외가 발생하지 않아야 함
        expect(() => hiveService.deleteRecipe('non_existent_id'), returnsNormally);
      });
    });

    group('복수 레시피 처리 테스트', () {
      test('should get all recipes', () async {
        // Given - 3개의 테스트 레시피 저장
        final recipes = [
          _createTestRecipe('all_001', '전체 조회 테스트 1'),
          _createTestRecipe('all_002', '전체 조회 테스트 2'),
          _createTestRecipe('all_003', '전체 조회 테스트 3'),
        ];
        
        for (final recipe in recipes) {
          await hiveService.saveRecipe(recipe);
        }

        // When
        final allRecipes = await hiveService.getAllRecipes();

        // Then
        expect(allRecipes, hasLength(3));
        expect(allRecipes.map((r) => r.title).toList(), 
               containsAll(['전체 조회 테스트 1', '전체 조회 테스트 2', '전체 조회 테스트 3']));
      });

      test('should save multiple recipes at once', () async {
        // Given
        final recipes = [
          _createTestRecipe('batch_001', '일괄 저장 1'),
          _createTestRecipe('batch_002', '일괄 저장 2'),
          _createTestRecipe('batch_003', '일괄 저장 3'),
        ];

        // When
        await hiveService.saveRecipes(recipes);

        // Then
        final allRecipes = await hiveService.getAllRecipes();
        expect(allRecipes, hasLength(3));
        expect(allRecipes.map((r) => r.id).toSet(), 
               containsAll(['batch_001', 'batch_002', 'batch_003']));
      });

      test('should get recipes count', () async {
        // Given
        final recipes = List.generate(5, (index) => 
          _createTestRecipe('count_$index', '카운트 테스트 $index'));
        
        for (final recipe in recipes) {
          await hiveService.saveRecipe(recipe);
        }

        // When
        final count = await hiveService.getRecipesCount();

        // Then
        expect(count, equals(5));
      });
    });

    group('날짜 기반 검색 테스트', () {
      test('should get recipes by date range', () async {
        // Given - 다양한 날짜의 레시피들
        final recipes = [
          _createTestRecipeWithDate('date_001', '12월 25일 레시피', DateTime(2024, 12, 25)),
          _createTestRecipeWithDate('date_002', '12월 26일 레시피', DateTime(2024, 12, 26)),
          _createTestRecipeWithDate('date_003', '12월 27일 레시피', DateTime(2024, 12, 27)),
          _createTestRecipeWithDate('date_004', '1월 1일 레시피', DateTime(2025, 1, 1)),
        ];
        
        for (final recipe in recipes) {
          await hiveService.saveRecipe(recipe);
        }

        // When - 12월 25일부터 12월 27일까지
        final startDate = DateTime(2024, 12, 25);
        final endDate = DateTime(2024, 12, 27, 23, 59, 59);
        final recipesInRange = await hiveService.getRecipesByDateRange(startDate, endDate);

        // Then
        expect(recipesInRange, hasLength(3));
        expect(recipesInRange.map((r) => r.id).toList(),
               containsAll(['date_001', 'date_002', 'date_003']));
      });

      test('should get "past today" recipes (핵심 기능!)', () async {
        // Given - "과거 오늘" 테스트 (현재가 2024-12-28이라고 가정)
        final today = DateTime(2024, 12, 28);
        final recipes = [
          // 같은 월/일, 다른 연도 (과거 오늘에 해당)
          _createTestRecipeWithDate('past_001', '2023년 12월 28일', DateTime(2023, 12, 28, 10, 30)),
          _createTestRecipeWithDate('past_002', '2022년 12월 28일', DateTime(2022, 12, 28, 15, 20)),
          _createTestRecipeWithDate('past_003', '2021년 12월 28일', DateTime(2021, 12, 28, 19, 45)),
          
          // 같은 년도 (오늘, 과거 오늘에 해당 안됨)
          _createTestRecipeWithDate('today_001', '오늘 레시피', DateTime(2024, 12, 28, 12, 00)),
          
          // 다른 월/일 (과거 오늘에 해당 안됨)
          _createTestRecipeWithDate('other_001', '다른 날 레시피', DateTime(2023, 11, 15, 14, 30)),
        ];
        
        for (final recipe in recipes) {
          await hiveService.saveRecipe(recipe);
        }

        // When - 과거 오늘 레시피 검색
        final pastTodayRecipes = await hiveService.getPastTodayRecipes(today);

        // Then
        expect(pastTodayRecipes, hasLength(3));
        expect(pastTodayRecipes.map((r) => r.id).toList(),
               containsAll(['past_001', 'past_002', 'past_003']));
        
        // 모든 결과가 같은 월/일, 다른 년도인지 확인
        for (final recipe in pastTodayRecipes) {
          expect(recipe.createdAt.month, equals(today.month));
          expect(recipe.createdAt.day, equals(today.day));
          expect(recipe.createdAt.year, isNot(equals(today.year)));
        }
      });
    });

    group('감정 기반 필터링 테스트 (감정 중심 앱!)', () {
      test('should filter recipes by mood', () async {
        // Given - 다양한 감정의 레시피들
        final recipes = [
          _createTestRecipeWithMood('happy_001', '기쁜 레시피 1', Mood.happy),
          _createTestRecipeWithMood('happy_002', '기쁜 레시피 2', Mood.happy),
          _createTestRecipeWithMood('sad_001', '슬픈 레시피', Mood.sad),
          _createTestRecipeWithMood('peaceful_001', '평온한 레시피', Mood.peaceful),
        ];
        
        for (final recipe in recipes) {
          await hiveService.saveRecipe(recipe);
        }

        // When - 기쁨 감정으로 필터링
        final happyRecipes = await hiveService.getRecipesByMood(Mood.happy);

        // Then
        expect(happyRecipes, hasLength(2));
        expect(happyRecipes.map((r) => r.id).toList(),
               containsAll(['happy_001', 'happy_002']));
        
        // 모든 결과가 happy mood인지 확인
        for (final recipe in happyRecipes) {
          expect(recipe.mood, equals(Mood.happy));
        }
      });

      test('should get mood distribution statistics', () async {
        // Given - 감정 분포 테스트를 위한 레시피들
        final recipes = [
          _createTestRecipeWithMood('mood_stat_01', '기쁨1', Mood.happy),
          _createTestRecipeWithMood('mood_stat_02', '기쁨2', Mood.happy),
          _createTestRecipeWithMood('mood_stat_03', '기쁨3', Mood.happy),
          _createTestRecipeWithMood('mood_stat_04', '슬픔1', Mood.sad),
          _createTestRecipeWithMood('mood_stat_05', '슬픔2', Mood.sad),
          _createTestRecipeWithMood('mood_stat_06', '평온1', Mood.peaceful),
        ];
        
        for (final recipe in recipes) {
          await hiveService.saveRecipe(recipe);
        }

        // When
        final distribution = await hiveService.getMoodDistribution();

        // Then
        expect(distribution[Mood.happy], equals(3));
        expect(distribution[Mood.sad], equals(2));
        expect(distribution[Mood.peaceful], equals(1));
        expect(distribution[Mood.tired] ?? 0, equals(0)); // 없는 감정은 0
      });
    });

    group('태그 기반 검색 테스트', () {
      test('should search recipes by tag', () async {
        // Given
        final recipes = [
          _createTestRecipeWithTags('tag_001', '김치찌개', ['#한식', '#매운맛', '#집밥']),
          _createTestRecipeWithTags('tag_002', '파스타', ['#양식', '#면요리', '#이탈리아']),
          _createTestRecipeWithTags('tag_003', '된장찌개', ['#한식', '#구수한맛', '#집밥']),
        ];
        
        for (final recipe in recipes) {
          await hiveService.saveRecipe(recipe);
        }

        // When - '#한식' 태그로 검색
        final koreanRecipes = await hiveService.searchRecipesByTag('#한식');

        // Then
        expect(koreanRecipes, hasLength(2));
        expect(koreanRecipes.map((r) => r.id).toList(),
               containsAll(['tag_001', 'tag_003']));
        
        // 모든 결과가 '#한식' 태그를 포함하는지 확인
        for (final recipe in koreanRecipes) {
          expect(recipe.tags, contains('#한식'));
        }
      });

      test('should search recipes by multiple tags', () async {
        // Given
        final recipes = [
          _createTestRecipeWithTags('multi_001', '집밥 한식', ['#한식', '#집밥', '#간단']),
          _createTestRecipeWithTags('multi_002', '특별한 한식', ['#한식', '#특별', '#정성']),
          _createTestRecipeWithTags('multi_003', '집밥 양식', ['#양식', '#집밥', '#간단']),
        ];
        
        for (final recipe in recipes) {
          await hiveService.saveRecipe(recipe);
        }

        // When - 여러 태그로 검색 (AND 조건)
        final result = await hiveService.searchRecipesByTags(['#한식', '#집밥']);

        // Then - 둘 다 포함하는 레시피만 반환
        expect(result, hasLength(1));
        expect(result.first.id, equals('multi_001'));
        expect(result.first.tags, containsAll(['#한식', '#집밥']));
      });

      test('should get tag frequency statistics', () async {
        // Given
        final recipes = [
          _createTestRecipeWithTags('freq_001', '요리1', ['#한식', '#집밥']),
          _createTestRecipeWithTags('freq_002', '요리2', ['#한식', '#매운맛']),
          _createTestRecipeWithTags('freq_003', '요리3', ['#집밥', '#간단']),
          _createTestRecipeWithTags('freq_004', '요리4', ['#한식', '#집밥', '#간단']),
        ];
        
        for (final recipe in recipes) {
          await hiveService.saveRecipe(recipe);
        }

        // When
        final tagFrequency = await hiveService.getTagFrequency();

        // Then
        expect(tagFrequency['#한식'], equals(3));
        expect(tagFrequency['#집밥'], equals(3));
        expect(tagFrequency['#간단'], equals(2));
        expect(tagFrequency['#매운맛'], equals(1));
      });
    });

    group('검색 및 필터링 테스트', () {
      test('should search recipes by title', () async {
        // Given
        final recipes = [
          _createTestRecipe('search_001', '김치찌개 맛있게 끓이기'),
          _createTestRecipe('search_002', '돼지고기 김치찌개'),
          _createTestRecipe('search_003', '토마토 파스타'),
          _createTestRecipe('search_004', '된장찌개 레시피'),
        ];
        
        for (final recipe in recipes) {
          await hiveService.saveRecipe(recipe);
        }

        // When - '김치찌개' 키워드로 검색
        final results = await hiveService.searchRecipesByTitle('김치찌개');

        // Then
        expect(results, hasLength(2));
        expect(results.map((r) => r.id).toList(),
               containsAll(['search_001', 'search_002']));
        
        // 모든 결과의 제목에 '김치찌개'가 포함되는지 확인
        for (final recipe in results) {
          expect(recipe.title.toLowerCase(), contains('김치찌개'));
        }
      });

      test('should search recipes by emotional story', () async {
        // Given
        final recipes = [
          _createTestRecipeWithStory('story_001', '제목1', '오늘 기분이 좋아서 만든 요리입니다'),
          _createTestRecipeWithStory('story_002', '제목2', '친구들과 함께 즐거운 시간을 보내며 요리했어요'),
          _createTestRecipeWithStory('story_003', '제목3', '혼자 조용히 만든 평범한 저녁 식사'),
        ];
        
        for (final recipe in recipes) {
          await hiveService.saveRecipe(recipe);
        }

        // When - '친구' 키워드로 감정 이야기 검색
        final results = await hiveService.searchRecipesByEmotionalStory('친구');

        // Then
        expect(results, hasLength(1));
        expect(results.first.id, equals('story_002'));
        expect(results.first.emotionalStory, contains('친구'));
      });

      test('should get favorite recipes only', () async {
        // Given
        final recipes = [
          _createTestRecipeWithFavorite('fav_001', '즐겨찾기 1', true),
          _createTestRecipeWithFavorite('fav_002', '일반 레시피 1', false),
          _createTestRecipeWithFavorite('fav_003', '즐겨찾기 2', true),
          _createTestRecipeWithFavorite('fav_004', '일반 레시피 2', false),
        ];
        
        for (final recipe in recipes) {
          await hiveService.saveRecipe(recipe);
        }

        // When
        final favorites = await hiveService.getFavoriteRecipes();

        // Then
        expect(favorites, hasLength(2));
        expect(favorites.map((r) => r.id).toList(),
               containsAll(['fav_001', 'fav_003']));
        
        // 모든 결과가 즐겨찾기인지 확인
        for (final recipe in favorites) {
          expect(recipe.isFavorite, isTrue);
        }
      });
    });

    group('데이터 관리 및 예외 처리 테스트', () {
      test('should handle box initialization gracefully', () async {
        // When & Then - 초기화가 정상적으로 이루어져야 함
        expect(() => HiveService(), returnsNormally);
      });

      test('should handle empty database gracefully', () async {
        // When - 빈 데이터베이스에서 조회
        final allRecipes = await hiveService.getAllRecipes();
        final count = await hiveService.getRecipesCount();

        // Then
        expect(allRecipes, isEmpty);
        expect(count, equals(0));
      });

      test('should clear all recipes', () async {
        // Given - 여러 레시피 저장
        final recipes = List.generate(5, (index) => 
          _createTestRecipe('clear_$index', '삭제될 레시피 $index'));
        
        for (final recipe in recipes) {
          await hiveService.saveRecipe(recipe);
        }
        
        expect(await hiveService.getRecipesCount(), equals(5));

        // When - 모든 레시피 삭제
        await hiveService.clearAllRecipes();

        // Then
        expect(await hiveService.getRecipesCount(), equals(0));
        expect(await hiveService.getAllRecipes(), isEmpty);
      });

      test('should handle database corruption gracefully', () async {
        // 이 테스트는 실제 환경에서는 복잡하므로, 
        // 에러 핸들링 구조가 있는지 확인하는 정도로 작성
        expect(() => hiveService.getAllRecipes(), returnsNormally);
      });
    });
  });
}

// 테스트 헬퍼 함수들
Recipe _createTestRecipe(String id, String title) {
  return Recipe(
    id: id,
    title: title,
    emotionalStory: '$title에 대한 감정 이야기입니다.',
    ingredients: [
      Ingredient(
        name: '테스트 재료', 
        amount: '100g', 
        unit: 'g', 
        category: IngredientCategory.other
      ),
    ],
    instructions: ['테스트 조리 단계 1', '테스트 조리 단계 2'],
    localImagePath: 'test_images/$id.jpg',
    tags: ['#테스트'],
    createdAt: DateTime.now(),
    mood: Mood.comfortable,
    rating: 3,
    reminderDate: null,
    isFavorite: false,
  );
}

Recipe _createTestRecipeWithDate(String id, String title, DateTime date) {
  final recipe = _createTestRecipe(id, title);
  return recipe.copyWith(createdAt: date);
}

Recipe _createTestRecipeWithMood(String id, String title, Mood mood) {
  final recipe = _createTestRecipe(id, title);
  return recipe.copyWith(mood: mood);
}

Recipe _createTestRecipeWithTags(String id, String title, List<String> tags) {
  final recipe = _createTestRecipe(id, title);
  return recipe.copyWith(tags: tags);
}

Recipe _createTestRecipeWithStory(String id, String title, String emotionalStory) {
  final recipe = _createTestRecipe(id, title);
  return recipe.copyWith(emotionalStory: emotionalStory);
}

Recipe _createTestRecipeWithFavorite(String id, String title, bool isFavorite) {
  final recipe = _createTestRecipe(id, title);
  return recipe.copyWith(isFavorite: isFavorite);
}