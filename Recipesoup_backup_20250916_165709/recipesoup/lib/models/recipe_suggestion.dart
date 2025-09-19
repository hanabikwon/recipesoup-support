/// 냉장고 재료 기반 AI 레시피 추천 모델
/// OpenAI API로부터 받은 요리 추천 정보를 담는 데이터 클래스
class RecipeSuggestion {
  final String dishName;        // 추천 요리명
  final String description;     // 간단한 설명 (1-2줄)
  final String estimatedTime;   // 예상 조리시간
  final String difficulty;      // 난이도 (쉬움/보통/어려움)
  final List<String> additionalIngredients; // 추가로 필요한 재료들
  final List<String> cookingSteps; // 간단한 조리 단계들

  const RecipeSuggestion({
    required this.dishName,
    required this.description,
    required this.estimatedTime,
    required this.difficulty,
    required this.additionalIngredients,
    required this.cookingSteps,
  });

  /// JSON에서 RecipeSuggestion 객체로 변환
  factory RecipeSuggestion.fromJson(Map<String, dynamic> json) {
    return RecipeSuggestion(
      dishName: json['dishName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      estimatedTime: json['estimatedTime'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? '보통',
      additionalIngredients: List<String>.from(
        json['additionalIngredients'] as List? ?? [],
      ),
      cookingSteps: List<String>.from(
        json['cookingSteps'] as List? ?? [],
      ),
    );
  }

  /// RecipeSuggestion 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'dishName': dishName,
      'description': description,
      'estimatedTime': estimatedTime,
      'difficulty': difficulty,
      'additionalIngredients': additionalIngredients,
      'cookingSteps': cookingSteps,
    };
  }

  /// 객체 복사 (일부 필드 변경)
  RecipeSuggestion copyWith({
    String? dishName,
    String? description,
    String? estimatedTime,
    String? difficulty,
    List<String>? additionalIngredients,
    List<String>? cookingSteps,
  }) {
    return RecipeSuggestion(
      dishName: dishName ?? this.dishName,
      description: description ?? this.description,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      difficulty: difficulty ?? this.difficulty,
      additionalIngredients: additionalIngredients ?? this.additionalIngredients,
      cookingSteps: cookingSteps ?? this.cookingSteps,
    );
  }

  /// 디버깅용 문자열 표현
  @override
  String toString() {
    return 'RecipeSuggestion(dishName: $dishName, description: $description, estimatedTime: $estimatedTime, difficulty: $difficulty, additionalIngredients: $additionalIngredients, cookingSteps: $cookingSteps)';
  }

  /// 객체 동등성 비교
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RecipeSuggestion &&
      other.dishName == dishName &&
      other.description == description &&
      other.estimatedTime == estimatedTime &&
      other.difficulty == difficulty &&
      _listEquals(other.additionalIngredients, additionalIngredients) &&
      _listEquals(other.cookingSteps, cookingSteps);
  }

  @override
  int get hashCode {
    return dishName.hashCode ^
      description.hashCode ^
      estimatedTime.hashCode ^
      difficulty.hashCode ^
      additionalIngredients.hashCode ^
      cookingSteps.hashCode;
  }

  /// 리스트 동등성 비교 헬퍼 함수
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    if (identical(a, b)) return true;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}

/// 여러 레시피 추천을 담는 래퍼 클래스
class RecipeSuggestionResponse {
  final List<RecipeSuggestion> suggestions;
  final List<String> inputIngredients; // 사용자가 입력한 원래 재료들
  final DateTime generatedAt; // 추천 생성 시간

  const RecipeSuggestionResponse({
    required this.suggestions,
    required this.inputIngredients,
    required this.generatedAt,
  });

  /// JSON에서 RecipeSuggestionResponse 객체로 변환
  factory RecipeSuggestionResponse.fromJson(Map<String, dynamic> json) {
    return RecipeSuggestionResponse(
      suggestions: (json['suggestions'] as List<dynamic>?)
          ?.map((e) => RecipeSuggestion.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      inputIngredients: List<String>.from(
        json['inputIngredients'] as List? ?? [],
      ),
      generatedAt: DateTime.parse(
        json['generatedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  /// RecipeSuggestionResponse 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'suggestions': suggestions.map((e) => e.toJson()).toList(),
      'inputIngredients': inputIngredients,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  /// 빈 응답 생성 (에러 케이스용)
  static RecipeSuggestionResponse empty(List<String> inputIngredients) {
    return RecipeSuggestionResponse(
      suggestions: [],
      inputIngredients: inputIngredients,
      generatedAt: DateTime.now(),
    );
  }

  /// 추천이 있는지 확인
  bool get hasRecipes => suggestions.isNotEmpty;

  /// 첫 번째 추천 반환 (null-safe)
  RecipeSuggestion? get firstSuggestion =>
    suggestions.isNotEmpty ? suggestions.first : null;

  @override
  String toString() {
    return 'RecipeSuggestionResponse(suggestions: ${suggestions.length} items, inputIngredients: $inputIngredients, generatedAt: $generatedAt)';
  }
}