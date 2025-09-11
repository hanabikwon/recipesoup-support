import 'package:flutter_test/flutter_test.dart';
import 'package:recipesoup/models/recipe.dart';
import 'package:recipesoup/models/ingredient.dart';
import 'package:recipesoup/models/mood.dart';

void main() {
  group('Recipe Model Tests', () {
    // 테스트용 샘플 레시피 (TESTDATA.md 기반)
    late Recipe sampleRecipe;
    late List<Ingredient> sampleIngredients;
    late List<String> sampleInstructions;
    late List<String> sampleTags;
    late DateTime sampleDate;

    setUp(() {
      sampleDate = DateTime(2024, 12, 15, 18, 30);
      
      sampleIngredients = [
        Ingredient(
          name: '안심 스테이크', 
          amount: '200', 
          unit: 'g', 
          category: IngredientCategory.meat
        ),
        Ingredient(
          name: '로즈마리', 
          amount: '2', 
          unit: '줄기', 
          category: IngredientCategory.seasoning
        ),
        Ingredient(
          name: '마늘', 
          amount: '3', 
          unit: '쪽', 
          category: IngredientCategory.seasoning
        ),
      ];
      
      sampleInstructions = [
        '스테이크를 실온에 30분간 둬서 온도를 맞춰주세요',
        '소금과 후춧가루로 간을 해주세요',
        '팬을 달궈서 올리브오일을 두르고 스테이크를 올려주세요',
      ];
      
      sampleTags = ['#기념일', '#스테이크', '#승진', '#특별한날'];
      
      sampleRecipe = Recipe(
        id: 'recipe_001',
        title: '승진 기념 스테이크',
        emotionalStory: '드디어 승진이 확정되었어요! 너무 기뻐서 평소 아끼던 좋은 스테이크를 꺼내 구워먹었습니다.',
        ingredients: sampleIngredients,
        instructions: sampleInstructions,
        localImagePath: 'test_images/steak_001.jpg',
        tags: sampleTags,
        createdAt: sampleDate,
        mood: Mood.happy,
        rating: 5,
        isFavorite: true,
      );
    });

    test('should create recipe with all required fields', () {
      // Given & When (setUp에서 생성됨)
      
      // Then
      expect(sampleRecipe.id, equals('recipe_001'));
      expect(sampleRecipe.title, equals('승진 기념 스테이크'));
      expect(sampleRecipe.emotionalStory, isNotEmpty); // 감정 메모 필수!
      expect(sampleRecipe.ingredients, hasLength(3));
      expect(sampleRecipe.instructions, hasLength(3));
      expect(sampleRecipe.mood, equals(Mood.happy));
      expect(sampleRecipe.rating, equals(5));
      expect(sampleRecipe.isFavorite, isTrue);
    });

    test('should require emotionalStory as core feature', () {
      // Given & When & Then
      expect(() => Recipe(
        id: 'test',
        title: '테스트',
        emotionalStory: '', // 빈 문자열은 허용하지만...
        ingredients: [],
        instructions: [],
        tags: [],
        createdAt: DateTime.now(),
        mood: Mood.happy,
      ), returnsNormally); // 생성은 되지만

      // 검증에서는 실패해야 함
      final recipe = Recipe(
        id: 'test',
        title: '테스트',
        emotionalStory: '',
        ingredients: [],
        instructions: [],
        tags: [],
        createdAt: DateTime.now(),
        mood: Mood.happy,
      );
      
      expect(recipe.isValid, isFalse); // emotionalStory 빈 문자열로 invalid
    });

    test('should convert to JSON correctly', () {
      // Given (sampleRecipe)
      
      // When
      final json = sampleRecipe.toJson();
      
      // Then
      expect(json['id'], equals('recipe_001'));
      expect(json['title'], equals('승진 기념 스테이크'));
      expect(json['emotionalStory'], contains('승진이 확정'));
      expect(json['ingredients'], hasLength(3));
      expect(json['instructions'], hasLength(3));
      expect(json['mood'], equals('happy')); // enum name으로 저장
      expect(json['rating'], equals(5));
      expect(json['isFavorite'], isTrue);
      expect(json['tags'], equals(sampleTags));
    });

    test('should create from JSON correctly', () {
      // Given
      final json = {
        'id': 'recipe_002',
        'title': '엄마 생각나는 미역국',
        'emotionalStory': '힘든 일이 있어서 기분이 좋지 않았어요. 집에 와서 엄마가 생일때마다 끓여주던 미역국이 그리워서 만들어먹었습니다.',
        'ingredients': [
          {
            'name': '미역',
            'amount': '30',
            'unit': 'g',
            'category': 'vegetable'
          },
          {
            'name': '쇠고기',
            'amount': '150',
            'unit': 'g',
            'category': 'meat'
          }
        ],
        'instructions': [
          '미역을 찬물에 30분간 불려주세요',
          '불린 미역을 적당한 크기로 썰어주세요'
        ],
        'tags': ['#엄마음식', '#위로', '#미역국', '#집밥'],
        'createdAt': '2024-12-10T19:45:00.000Z',
        'mood': 'sad',
        'rating': 4,
        'isFavorite': false
      };
      
      // When
      final recipe = Recipe.fromJson(json);
      
      // Then
      expect(recipe.id, equals('recipe_002'));
      expect(recipe.title, equals('엄마 생각나는 미역국'));
      expect(recipe.emotionalStory, contains('엄마가'));
      expect(recipe.ingredients, hasLength(2));
      expect(recipe.ingredients.first.name, equals('미역'));
      expect(recipe.mood, equals(Mood.sad));
      expect(recipe.tags, contains('#엄마음식'));
    });

    test('should create copy with updated fields', () {
      // Given (sampleRecipe)
      
      // When
      final updated = sampleRecipe.copyWith(
        rating: 4,
        isFavorite: false,
        tags: ['#기념일', '#업데이트됨'],
      );
      
      // Then
      expect(updated.id, equals(sampleRecipe.id)); // 변경되지 않음
      expect(updated.title, equals(sampleRecipe.title)); // 변경되지 않음
      expect(updated.rating, equals(4)); // 변경됨
      expect(updated.isFavorite, isFalse); // 변경됨
      expect(updated.tags, contains('#업데이트됨')); // 변경됨
      expect(updated.mood, equals(sampleRecipe.mood)); // 변경되지 않음
    });

    test('should validate recipe correctly', () {
      // Given
      final validRecipe = sampleRecipe;
      
      final invalidRecipe = Recipe(
        id: '',
        title: '',
        emotionalStory: '',
        ingredients: [],
        instructions: [],
        tags: [],
        createdAt: DateTime.now(),
        mood: Mood.happy,
      );
      
      // When & Then
      expect(validRecipe.isValid, isTrue);
      expect(invalidRecipe.isValid, isFalse);
    });

    test('should generate unique ID if not provided', () {
      // Given & When
      final recipe1 = Recipe.generateNew(
        title: '테스트 레시피 1',
        emotionalStory: '테스트용 감정 이야기',
        mood: Mood.happy,
      );
      
      final recipe2 = Recipe.generateNew(
        title: '테스트 레시피 2',
        emotionalStory: '테스트용 감정 이야기',
        mood: Mood.peaceful,
      );
      
      // Then
      expect(recipe1.id, isNotEmpty);
      expect(recipe2.id, isNotEmpty);
      expect(recipe1.id, isNot(equals(recipe2.id))); // 서로 다른 ID
    });

    test('should support date-based sorting for "과거 오늘" feature', () {
      // Given
      final today = DateTime(2024, 12, 15);
      final lastYear = DateTime(2023, 12, 15);
      final lastMonth = DateTime(2024, 11, 15);
      
      final recipes = [
        sampleRecipe.copyWith(createdAt: today),
        sampleRecipe.copyWith(createdAt: lastYear),
        sampleRecipe.copyWith(createdAt: lastMonth),
      ];
      
      // When
      recipes.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // 최신순
      final pastTodayRecipes = recipes.where((r) => 
        r.createdAt.month == today.month && 
        r.createdAt.day == today.day && 
        r.createdAt.year != today.year
      ).toList();
      
      // Then
      expect(recipes.first.createdAt, equals(today)); // 가장 최근
      expect(pastTodayRecipes, hasLength(1)); // 작년 같은 날
      expect(pastTodayRecipes.first.createdAt, equals(lastYear));
    });

    test('should handle tag-based searching', () {
      // Given
      final recipes = [
        sampleRecipe, // #기념일, #스테이크, #승진, #특별한날
        sampleRecipe.copyWith(
          tags: ['#혼밥', '#간편식', '#저녁'],
        ),
        sampleRecipe.copyWith(
          tags: ['#가족', '#기념일', '#생일'],
        ),
      ];
      
      // When
      final anniversaryRecipes = recipes.where((r) => 
        r.tags.any((tag) => tag.contains('기념일'))
      ).toList();
      
      final soloRecipes = recipes.where((r) => 
        r.tags.any((tag) => tag.contains('혼밥'))
      ).toList();
      
      // Then
      expect(anniversaryRecipes, hasLength(2)); // #기념일 태그 포함
      expect(soloRecipes, hasLength(1)); // #혼밥 태그 포함
    });

    test('should handle mood-based filtering', () {
      // Given
      final recipes = [
        sampleRecipe, // Mood.happy
        sampleRecipe.copyWith(mood: Mood.sad),
        sampleRecipe.copyWith(mood: Mood.peaceful),
        sampleRecipe.copyWith(mood: Mood.happy),
      ];
      
      // When
      final happyRecipes = recipes.where((r) => r.mood == Mood.happy).toList();
      final sadRecipes = recipes.where((r) => r.mood == Mood.sad).toList();
      
      // Then
      expect(happyRecipes, hasLength(2));
      expect(sadRecipes, hasLength(1));
    });
  });
}