import 'ingredient.dart';
import 'recipe.dart';
import 'mood.dart';

/// OpenAI API의 음식 사진 분석 결과를 담는 모델
/// API 응답을 Recipe 모델로 변환하기 전의 중간 데이터 구조
class RecipeAnalysis {
  /// 분석된 요리 이름
  final String dishName;
  
  /// 분석된 재료 리스트
  final List<AnalysisIngredient> ingredients;
  
  /// 분석된 소스나 양념 (옵션)
  final String? sauce;
  
  /// 분석된 조리 방법 (단계별)
  final List<String> instructions;
  
  /// 예상 조리 시간
  final String estimatedTime;
  
  /// 예상 난이도 (쉬움/보통/어려움)
  final String difficulty;
  
  /// 예상 인분 수
  final String servings;
  
  /// AI가 생성한 태그 리스트
  final List<String> tags;

  /// 스크린샷 이미지인지 여부
  final bool isScreenshot;
  
  /// OCR로 추출된 텍스트 (스크린샷인 경우)
  final String? extractedText;

  const RecipeAnalysis({
    required this.dishName,
    required this.ingredients,
    this.sauce,
    required this.instructions,
    required this.estimatedTime,
    required this.difficulty,
    required this.servings,
    this.tags = const [],
    this.isScreenshot = false,
    this.extractedText,
  });

  /// OpenAI API JSON 응답에서 생성
  factory RecipeAnalysis.fromApiResponse(Map<String, dynamic> json) {
    return RecipeAnalysis(
      dishName: json['dish_name'] as String? ?? '알 수 없는 요리',
      ingredients: (json['ingredients'] as List<dynamic>?)
          ?.map((i) => AnalysisIngredient.fromJson(i as Map<String, dynamic>))
          .toList() ?? [],
      sauce: json['sauce'] as String?,
      instructions: (json['instructions'] as List<dynamic>?)
          ?.cast<String>() ?? [],
      estimatedTime: json['estimated_time'] as String? ?? '알 수 없음',
      difficulty: json['difficulty'] as String? ?? '보통',
      servings: json['servings'] as String? ?? '1-2인분',
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      isScreenshot: json['is_screenshot'] as bool? ?? false,
      extractedText: json['extracted_text'] as String?,
    );
  }

  /// Recipe 모델로 변환하기 위한 Ingredient 리스트 생성
  List<Ingredient> toIngredients() {
    return ingredients.map((ai) => ai.toIngredient()).toList();
  }

  /// RecipeAnalysis를 Recipe 모델로 변환 (OCR 정보 포함)
  Recipe toRecipe({
    required String emotionalStory, // 사용자가 추가한 감정 메모
    required Mood mood, // 사용자가 선택한 감정 상태
    int? rating, // 사용자 평점
    List<String>? additionalTags, // 사용자 추가 태그
  }) {
    // 기본 태그와 사용자 추가 태그 병합
    final allTags = <String>[...tags];
    if (additionalTags != null) {
      allTags.addAll(additionalTags);
    }

    return Recipe.generateNew(
      title: dishName,
      emotionalStory: emotionalStory,
      mood: mood,
      ingredients: toIngredients(),
      sauce: sauce,
      instructions: instructions,
      tags: allTags,
      rating: rating,
      // OCR 관련 정보 포함
      isScreenshot: isScreenshot,
      extractedText: extractedText,
    );
  }

  /// 유효성 검증
  bool get isValid {
    return dishName.isNotEmpty && 
           ingredients.isNotEmpty && 
           instructions.isNotEmpty;
  }

  @override
  String toString() => 'RecipeAnalysis(dishName: $dishName, ingredients: ${ingredients.length}, instructions: ${instructions.length}, isScreenshot: $isScreenshot, hasExtractedText: ${extractedText?.isNotEmpty ?? false})';
}

/// OpenAI API 분석 결과의 재료 정보
/// API 응답에서 받은 재료 데이터를 Ingredient 모델로 변환하기 전 단계
class AnalysisIngredient {
  /// 재료명
  final String name;
  
  /// 분량 (API에서 제공된 형태 그대로)
  final String? amount;

  const AnalysisIngredient({
    required this.name,
    this.amount,
  });

  /// API JSON에서 생성
  factory AnalysisIngredient.fromJson(Map<String, dynamic> json) {
    return AnalysisIngredient(
      name: json['name'] as String,
      amount: json['amount'] as String?,
    );
  }

  /// Ingredient 모델로 변환
  Ingredient toIngredient() {
    // amount에서 숫자와 단위 분리 시도
    String? extractedAmount;
    String? extractedUnit;
    IngredientCategory? category;

    if (amount != null && amount!.isNotEmpty) {
      // 간단한 패턴 매칭으로 숫자와 단위 분리
      final regex = RegExp(r'^(\d+(?:\.\d+)?(?:/\d+)?)\s*([가-힣a-zA-Z]+)?$');
      final match = regex.firstMatch(amount!.trim());
      
      if (match != null) {
        extractedAmount = match.group(1);
        extractedUnit = match.group(2);
      } else {
        // 패턴에 맞지 않으면 전체를 amount로 사용
        extractedAmount = amount;
      }
    }

    // 재료명을 기반으로 카테고리 추론 (간단한 키워드 매칭)
    category = _inferCategory(name);

    return Ingredient(
      name: name,
      amount: extractedAmount,
      unit: extractedUnit,
      category: category,
    );
  }

  /// 재료명 기반 카테고리 추론
  static IngredientCategory? _inferCategory(String ingredientName) {
    final name = ingredientName.toLowerCase();

    // 채소류
    if (name.contains('김치') || name.contains('양파') || name.contains('당근') ||
        name.contains('감자') || name.contains('배추') || name.contains('시금치') ||
        name.contains('브로콜리') || name.contains('토마토') || name.contains('오이') ||
        name.contains('상추') || name.contains('미역') || name.contains('다시마') ||
        name.contains('애호박') || name.contains('버섯') || name.contains('마늘') ||
        name.contains('생강') || name.contains('대파') || name.contains('파') ||
        name.contains('바질') || name.contains('로즈마리')) {
      return IngredientCategory.vegetable;
    }

    // 고기류
    if (name.contains('쇠고기') || name.contains('돼지고기') || name.contains('닭고기') ||
        name.contains('닭가슴살') || name.contains('삼겹살') || name.contains('갈비') ||
        name.contains('스테이크') || name.contains('고기')) {
      return IngredientCategory.meat;
    }

    // 해산물류
    if (name.contains('새우') || name.contains('오징어') || name.contains('조개') ||
        name.contains('멸치') || name.contains('참치') || name.contains('고등어') ||
        name.contains('연어') || name.contains('생선')) {
      return IngredientCategory.seafood;
    }

    // 유제품류
    if (name.contains('우유') || name.contains('치즈') || name.contains('계란') ||
        name.contains('버터') || name.contains('생크림') || name.contains('요구르트') ||
        name.contains('달걀')) {
      return IngredientCategory.dairy;
    }

    // 곡물류
    if (name.contains('쌀') || name.contains('밀가루') || name.contains('파스타') ||
        name.contains('면') || name.contains('식빵') || name.contains('현미') ||
        name.contains('메밀') || name.contains('밥')) {
      return IngredientCategory.grain;
    }

    // 조미료류
    if (name.contains('소금') || name.contains('설탕') || name.contains('간장') ||
        name.contains('고춧가루') || name.contains('참기름') || name.contains('올리브오일') ||
        name.contains('식용유') || name.contains('기름') || name.contains('식초') ||
        name.contains('후추') || name.contains('된장') || name.contains('고추장') ||
        name.contains('마요네즈') || name.contains('케첩') || name.contains('소스') ||
        name.contains('조미료') || name.contains('양념')) {
      return IngredientCategory.seasoning;
    }

    // 기타
    return IngredientCategory.other;
  }

  @override
  String toString() => 'AnalysisIngredient(name: $name, amount: $amount)';
}