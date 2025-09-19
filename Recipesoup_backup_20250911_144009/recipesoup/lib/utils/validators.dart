import '../models/recipe.dart';
import '../models/ingredient.dart';

/// 검증 결과를 담는 클래스
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? sanitizedValue;
  final String? suggestion;
  final bool hasEmotionalKeywords;

  ValidationResult({
    required this.isValid,
    this.errorMessage,
    this.sanitizedValue,
    this.suggestion,
    this.hasEmotionalKeywords = false,
  });
}

/// Recipesoup 앱을 위한 검증 유틸리티
class RecipeValidators {
  /// 감정 키워드 목록 (한국어)
  static const List<String> emotionalKeywords = [
    '기쁨', '행복', '슬픔', '그리움', '위로', '평온', '편안함', '감사', '설렘', '피로',
    '기뻐서', '행복해서', '슬퍼서', '그리워서', '위로받고', '평온하게', '편안하게', '감사하며', '설레서', '피곤해서',
    '사랑', '추억', '따뜻', '차가운', '외로운', '혼자', '함께', '가족', '친구', '연인',
    '마음', '기분', '느낌', '감정', '생각', '기억', '경험', '좋다', '좋은', '나쁘다', '싫다'
  ];

  /// 레시피 제목 검증
  ValidationResult validateRecipeTitle(String title) {
    final trimmed = title.trim();

    if (trimmed.isEmpty) {
      return ValidationResult(
        isValid: false,
        errorMessage: '레시피 제목은 필수 입력 항목입니다.',
      );
    }

    if (trimmed.length > 100) {
      return ValidationResult(
        isValid: false,
        errorMessage: '레시피 제목은 100자를 초과할 수 없습니다.',
      );
    }

    return ValidationResult(
      isValid: true,
      sanitizedValue: trimmed,
    );
  }

  /// 감정 이야기 검증 (핵심 기능!)
  ValidationResult validateEmotionalStory(String story) {
    final trimmed = story.trim();

    if (trimmed.isEmpty) {
      return ValidationResult(
        isValid: false,
        errorMessage: '감정 이야기는 필수 입력 항목입니다.',
      );
    }

    if (trimmed.length > 1000) {
      return ValidationResult(
        isValid: false,
        errorMessage: '감정 이야기는 1000자를 초과할 수 없습니다.',
      );
    }

    final hasEmotions = _detectEmotionalKeywords(trimmed);
    String? suggestion;

    if (!hasEmotions) {
      suggestion = '감정을 표현하는 단어를 포함해보세요 (예: 기쁨, 슬픔, 그리움 등).';
    } else if (trimmed.length < 10) {
      suggestion = '더 자세한 감정 표현을 추가해보세요.';
    }

    return ValidationResult(
      isValid: true,
      sanitizedValue: trimmed,
      hasEmotionalKeywords: hasEmotions,
      suggestion: suggestion,
    );
  }

  /// 재료 리스트 검증
  ValidationResult validateIngredients(List<Ingredient> ingredients) {
    if (ingredients.length > 50) {
      return ValidationResult(
        isValid: false,
        errorMessage: '재료는 50개를 초과할 수 없습니다.',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// 개별 재료명 검증
  ValidationResult validateIngredientName(String name) {
    final trimmed = name.trim();

    if (trimmed.isEmpty) {
      return ValidationResult(
        isValid: false,
        errorMessage: '재료명은 필수 입력 항목입니다.',
      );
    }

    if (trimmed.length > 50) {
      return ValidationResult(
        isValid: false,
        errorMessage: '재료명은 50자를 초과할 수 없습니다.',
      );
    }

    return ValidationResult(
      isValid: true,
      sanitizedValue: trimmed,
    );
  }

  /// 조리법 검증
  ValidationResult validateInstructions(List<String> instructions) {
    if (instructions.length > 30) {
      return ValidationResult(
        isValid: false,
        errorMessage: '조리법은 30단계를 초과할 수 없습니다.',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// 개별 조리 단계 검증
  ValidationResult validateInstructionStep(String step) {
    final trimmed = step.trim();

    if (trimmed.isEmpty) {
      return ValidationResult(
        isValid: false,
        errorMessage: '빈 단계는 입력할 수 없습니다.',
      );
    }

    if (trimmed.length > 200) {
      return ValidationResult(
        isValid: false,
        errorMessage: '각 조리 단계는 200자를 초과할 수 없습니다.',
      );
    }

    return ValidationResult(
      isValid: true,
      sanitizedValue: trimmed,
    );
  }

  /// 태그 리스트 검증
  ValidationResult validateTags(List<String> tags) {
    if (tags.length > 20) {
      return ValidationResult(
        isValid: false,
        errorMessage: '태그는 20개를 초과할 수 없습니다.',
      );
    }

    for (String tag in tags) {
      final result = validateSingleTag(tag);
      if (!result.isValid) {
        return ValidationResult(
          isValid: false,
          errorMessage: '모든 태그는 # 으로 시작해야 하며 20자를 초과할 수 없습니다.',
        );
      }
    }

    return ValidationResult(isValid: true);
  }

  /// 개별 태그 검증
  ValidationResult validateSingleTag(String tag) {
    final trimmed = tag.trim();

    if (!trimmed.startsWith('#') || trimmed.length <= 1) {
      return ValidationResult(
        isValid: false,
        errorMessage: '태그는 #으로 시작해야 합니다.',
        suggestion: '# 을 앞에 붙여보세요.',
      );
    }

    if (trimmed.length > 20) {
      return ValidationResult(
        isValid: false,
        errorMessage: '태그는 20자를 초과할 수 없습니다.',
      );
    }

    return ValidationResult(
      isValid: true,
      sanitizedValue: trimmed,
    );
  }

  /// 평점 검증
  ValidationResult validateRating(int? rating) {
    if (rating == null) {
      return ValidationResult(isValid: true); // null 허용
    }

    if (rating < 1 || rating > 5) {
      return ValidationResult(
        isValid: false,
        errorMessage: '평점은 1점에서 5점 사이여야 합니다.',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// 전체 레시피 검증
  ValidationResult validateRecipe(Recipe recipe) {
    List<String> errors = [];

    // 제목 검증
    final titleResult = validateRecipeTitle(recipe.title);
    if (!titleResult.isValid) {
      errors.add('제목: ${titleResult.errorMessage}');
    }

    // 감정 이야기 검증 (핵심!)
    final storyResult = validateEmotionalStory(recipe.emotionalStory);
    if (!storyResult.isValid) {
      errors.add('감정 이야기: ${storyResult.errorMessage}');
    }

    // 재료 검증
    final ingredientsResult = validateIngredients(recipe.ingredients);
    if (!ingredientsResult.isValid) {
      errors.add('재료: ${ingredientsResult.errorMessage}');
    }

    // 조리법 검증
    final instructionsResult = validateInstructions(recipe.instructions);
    if (!instructionsResult.isValid) {
      errors.add('조리법: ${instructionsResult.errorMessage}');
    }

    // 태그 검증
    final tagsResult = validateTags(recipe.tags);
    if (!tagsResult.isValid) {
      errors.add('태그: ${tagsResult.errorMessage}');
    }

    // 평점 검증
    final ratingResult = validateRating(recipe.rating);
    if (!ratingResult.isValid) {
      errors.add('평점: ${ratingResult.errorMessage}');
    }

    if (errors.isNotEmpty) {
      return ValidationResult(
        isValid: false,
        errorMessage: errors.join('\n'),
      );
    }

    return ValidationResult(isValid: true);
  }

  /// 감정 키워드 감지
  bool _detectEmotionalKeywords(String text) {
    final lowerText = text.toLowerCase();
    return emotionalKeywords.any((keyword) => 
        lowerText.contains(keyword.toLowerCase()));
  }
}