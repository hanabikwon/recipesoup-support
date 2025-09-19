import 'package:flutter_test/flutter_test.dart';
import 'package:recipesoup/utils/validators.dart';
import 'package:recipesoup/models/recipe.dart';
import 'package:recipesoup/models/ingredient.dart';
import 'package:recipesoup/models/mood.dart';

void main() {
  group('Validators Tests (감정 중심 입력 검증!)', () {
    late RecipeValidators validators;
    
    setUp(() {
      validators = RecipeValidators();
    });
    
    group('레시피 제목 검증 테스트', () {
      test('should validate recipe title length', () {
        // Given - 다양한 길이의 제목들
        final validTitle = '맛있는 김치찌개';
        final tooLong = 'A' * 101; // 100자 초과
        final empty = '';
        final justRight = 'A' * 100; // 정확히 100자
        final singleChar = 'A';
        
        // When & Then
        expect(validators.validateRecipeTitle(validTitle).isValid, isTrue);
        expect(validators.validateRecipeTitle(justRight).isValid, isTrue);
        expect(validators.validateRecipeTitle(singleChar).isValid, isTrue);
        
        final tooLongResult = validators.validateRecipeTitle(tooLong);
        expect(tooLongResult.isValid, isFalse);
        expect(tooLongResult.errorMessage, contains('100자'));
        
        final emptyResult = validators.validateRecipeTitle(empty);
        expect(emptyResult.isValid, isFalse);
        expect(emptyResult.errorMessage, contains('필수'));
      });
      
      test('should trim whitespace in title validation', () {
        final titleWithSpaces = '  김치찌개  ';
        final result = validators.validateRecipeTitle(titleWithSpaces);
        
        expect(result.isValid, isTrue);
        expect(result.sanitizedValue, equals('김치찌개'));
      });
      
      test('should reject only whitespace titles', () {
        final onlySpaces = '   ';
        final result = validators.validateRecipeTitle(onlySpaces);
        
        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('필수'));
      });
    });
    
    group('감정 이야기 검증 테스트 (핵심!)', () {
      test('should validate emotional story as required field', () {
        // Given - Recipesoup의 핵심: emotionalStory는 필수!
        final validStory = '오늘 기분이 좋아서 김치찌개를 끓였어요';
        final empty = '';
        final tooLong = 'A' * 1001; // 1000자 초과
        final maxLength = 'A' * 1000; // 정확히 1000자
        
        // When & Then
        expect(validators.validateEmotionalStory(validStory).isValid, isTrue);
        expect(validators.validateEmotionalStory(maxLength).isValid, isTrue);
        
        final emptyResult = validators.validateEmotionalStory(empty);
        expect(emptyResult.isValid, isFalse);
        expect(emptyResult.errorMessage, contains('감정 이야기는 필수'));
        
        final tooLongResult = validators.validateEmotionalStory(tooLong);
        expect(tooLongResult.isValid, isFalse);
        expect(tooLongResult.errorMessage, contains('1000자'));
      });
      
      test('should provide helpful guidance for emotional story', () {
        final shortStory = '좋다';
        final result = validators.validateEmotionalStory(shortStory);
        
        expect(result.isValid, isTrue);
        expect(result.suggestion, contains('더 자세한 감정'));
      });
      
      test('should detect and encourage emotional keywords', () {
        final emotionalStory = '슬픈 마음으로 혼자 라면을 끓여먹었다';
        final plainStory = '라면을 끓였다';
        
        final emotionalResult = validators.validateEmotionalStory(emotionalStory);
        final plainResult = validators.validateEmotionalStory(plainStory);
        
        expect(emotionalResult.isValid, isTrue);
        expect(emotionalResult.hasEmotionalKeywords, isTrue);
        
        expect(plainResult.isValid, isTrue);
        expect(plainResult.hasEmotionalKeywords, isFalse);
        expect(plainResult.suggestion, contains('감정을 표현'));
      });
    });
    
    group('재료 리스트 검증 테스트', () {
      test('should validate ingredient list', () {
        // Given
        final validIngredients = [
          Ingredient(name: '김치', amount: '200g', unit: 'g', category: IngredientCategory.vegetable),
          Ingredient(name: '돼지고기', amount: '150g', unit: 'g', category: IngredientCategory.meat),
        ];
        final emptyList = <Ingredient>[];
        final tooManyIngredients = List.generate(51, (i) => 
          Ingredient(name: '재료$i', category: IngredientCategory.other));
        
        // When & Then
        expect(validators.validateIngredients(validIngredients).isValid, isTrue);
        expect(validators.validateIngredients(emptyList).isValid, isTrue); // 빈 리스트 허용
        
        final tooManyResult = validators.validateIngredients(tooManyIngredients);
        expect(tooManyResult.isValid, isFalse);
        expect(tooManyResult.errorMessage, contains('50개'));
      });
      
      test('should validate individual ingredient names', () {
        final validIngredient = Ingredient(name: '김치', category: IngredientCategory.vegetable);
        final emptyName = Ingredient(name: '', category: IngredientCategory.vegetable);
        final longName = Ingredient(name: 'A' * 51, category: IngredientCategory.vegetable);
        
        expect(validators.validateIngredientName(validIngredient.name).isValid, isTrue);
        
        final emptyResult = validators.validateIngredientName(emptyName.name);
        expect(emptyResult.isValid, isFalse);
        expect(emptyResult.errorMessage, contains('재료명'));
        
        final longResult = validators.validateIngredientName(longName.name);
        expect(longResult.isValid, isFalse);
        expect(longResult.errorMessage, contains('50자'));
      });
    });
    
    group('조리법 검증 테스트', () {
      test('should validate cooking instructions', () {
        final validInstructions = [
          '김치를 기름에 볶는다',
          '고기를 넣고 함께 볶는다',
          '물을 넣고 끓인다'
        ];
        final emptyList = <String>[];
        final tooManySteps = List.generate(31, (i) => '단계 ${i + 1}');
        
        expect(validators.validateInstructions(validInstructions).isValid, isTrue);
        expect(validators.validateInstructions(emptyList).isValid, isTrue); // 빈 리스트 허용
        
        final tooManyResult = validators.validateInstructions(tooManySteps);
        expect(tooManyResult.isValid, isFalse);
        expect(tooManyResult.errorMessage, contains('30단계'));
      });
      
      test('should validate individual instruction length', () {
        final validStep = '김치를 적당히 볶아주세요';
        final tooLong = 'A' * 201; // 200자 초과
        final empty = '';
        
        expect(validators.validateInstructionStep(validStep).isValid, isTrue);
        
        final tooLongResult = validators.validateInstructionStep(tooLong);
        expect(tooLongResult.isValid, isFalse);
        expect(tooLongResult.errorMessage, contains('200자'));
        
        final emptyResult = validators.validateInstructionStep(empty);
        expect(emptyResult.isValid, isFalse);
        expect(emptyResult.errorMessage, contains('빈 단계'));
      });
    });
    
    group('태그 검증 테스트', () {
      test('should validate tag format', () {
        final validTags = ['#기쁨', '#김치찌개', '#한식'];
        final invalidTags = ['기쁨', 'no_hash', '#', '#${'A' * 20}']; // # 없음, # 만 있음, 너무 긺
        
        expect(validators.validateTags(validTags).isValid, isTrue);
        
        final invalidResult = validators.validateTags(invalidTags);
        expect(invalidResult.isValid, isFalse);
        expect(invalidResult.errorMessage, contains('# 으로 시작'));
      });
      
      test('should limit number of tags', () {
        final tooManyTags = List.generate(21, (i) => '#태그$i'); // 20개 초과
        
        final result = validators.validateTags(tooManyTags);
        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('20개'));
      });
      
      test('should validate individual tag length', () {
        final validTag = '#좋은하루';
        final tooLong = '#${'A' * 20}'; // 21자 (20자 초과)
        final justRight = '#${'A' * 18}'; // 19자 (# 포함해서 20자)
        
        expect(validators.validateSingleTag(validTag).isValid, isTrue);
        expect(validators.validateSingleTag(justRight).isValid, isTrue);
        
        final result = validators.validateSingleTag(tooLong);
        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('20자'));
      });
    });
    
    group('평점 검증 테스트', () {
      test('should validate rating range', () {
        // When & Then
        expect(validators.validateRating(1).isValid, isTrue);
        expect(validators.validateRating(3).isValid, isTrue);
        expect(validators.validateRating(5).isValid, isTrue);
        expect(validators.validateRating(null).isValid, isTrue); // null 허용
        
        expect(validators.validateRating(0).isValid, isFalse);
        expect(validators.validateRating(6).isValid, isFalse);
        expect(validators.validateRating(-1).isValid, isFalse);
      });
    });
    
    group('전체 레시피 검증 테스트', () {
      test('should validate complete recipe', () {
        // Given - 완전한 유효한 레시피
        final validRecipe = Recipe(
          id: 'test_001',
          title: '행복한 김치찌개',
          emotionalStory: '오늘 기분이 좋아서 가족을 위해 정성스럽게 김치찌개를 끓였어요',
          ingredients: [
            Ingredient(name: '김치', amount: '200g', unit: 'g', category: IngredientCategory.vegetable),
          ],
          instructions: ['김치를 볶고 끓인다'],
          tags: ['#기쁨', '#김치찌개'],
          createdAt: DateTime.now(),
          mood: Mood.happy,
          rating: 5,
        );
        
        // When
        final result = validators.validateRecipe(validRecipe);
        
        // Then
        expect(result.isValid, isTrue);
        expect(result.errorMessage, isNull);
      });
      
      test('should catch multiple validation errors', () {
        // Given - 여러 문제가 있는 레시피
        final invalidRecipe = Recipe(
          id: 'test_002',
          title: '', // 빈 제목
          emotionalStory: '', // 빈 감정 이야기 (치명적!)
          ingredients: [],
          instructions: [],
          tags: ['invalid_tag'], // 잘못된 태그 형식
          createdAt: DateTime.now(),
          mood: Mood.sad,
          rating: 6, // 잘못된 평점
        );
        
        // When
        final result = validators.validateRecipe(invalidRecipe);
        
        // Then
        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('제목'));
        expect(result.errorMessage, contains('감정 이야기'));
        expect(result.errorMessage, contains('태그'));
        expect(result.errorMessage, contains('평점'));
      });
    });
    
    group('입력 정제 및 제안 테스트', () {
      test('should sanitize and suggest improvements', () {
        final messy = '  김치찌개!!@#  ';
        final result = validators.validateRecipeTitle(messy);
        
        expect(result.sanitizedValue, equals('김치찌개!!@#'));
        expect(result.isValid, isTrue);
      });
      
      test('should provide helpful suggestions', () {
        final shortStory = '맛있다';
        final result = validators.validateEmotionalStory(shortStory);
        
        expect(result.isValid, isTrue);
        expect(result.suggestion, isNotNull);
        expect(result.suggestion, contains('감정'));
      });
      
      test('should detect common validation patterns', () {
        // 자주 실수하는 패턴들
        final almostValidTag = 'hashtag'; // # 빼먹음
        final result = validators.validateSingleTag(almostValidTag);
        
        expect(result.isValid, isFalse);
        expect(result.suggestion, contains('#'));
      });
    });
  });
}