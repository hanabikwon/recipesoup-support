/// 재료 카테고리 분류
enum IngredientCategory {
  vegetable,    // 채소
  meat,         // 고기
  seafood,      // 해산물
  dairy,        // 유제품
  grain,        // 곡물
  seasoning,    // 조미료
  other;        // 기타

  /// UI 표시용 한국어 이름
  String get displayName {
    switch (this) {
      case IngredientCategory.vegetable:
        return '채소';
      case IngredientCategory.meat:
        return '고기';
      case IngredientCategory.seafood:
        return '해산물';
      case IngredientCategory.dairy:
        return '유제품';
      case IngredientCategory.grain:
        return '곡물';
      case IngredientCategory.seasoning:
        return '조미료';
      case IngredientCategory.other:
        return '기타';
    }
  }

  /// 문자열에서 카테고리 변환
  static IngredientCategory? fromString(String value) {
    for (final category in IngredientCategory.values) {
      if (category.name == value) {
        return category;
      }
    }
    return null;
  }
}

/// 구조화된 재료 모델
/// 자유로운 재료 입력을 지원하면서도 체계적인 분류 가능
class Ingredient {
  /// 재료명 (필수)
  final String name;
  
  /// 용량 (선택사항, 예: "200", "적당량")
  final String? amount;
  
  /// 단위 (선택사항, 예: "g", "개", "컵")
  final String? unit;
  
  /// 재료 카테고리 (선택사항)
  final IngredientCategory? category;

  const Ingredient({
    required this.name,
    this.amount,
    this.unit,
    this.category,
  });

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (amount != null) 'amount': amount,
      if (unit != null) 'unit': unit,
      if (category != null) 'category': category!.name,
    };
  }

  /// JSON에서 생성
  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'] as String,
      amount: json['amount'] as String?,
      unit: json['unit'] as String?,
      category: json['category'] != null 
          ? IngredientCategory.fromString(json['category'] as String)
          : null,
    );
  }

  /// 복사본 생성 (일부 필드 변경)
  Ingredient copyWith({
    String? name,
    String? amount,
    String? unit,
    IngredientCategory? category,
  }) {
    return Ingredient(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      category: category ?? this.category,
    );
  }

  /// UI 표시용 텍스트
  String get displayText {
    if (amount != null && unit != null) {
      return '$name $amount$unit';
    } else if (amount != null) {
      return '$name $amount';
    } else {
      return name;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ingredient &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          amount == other.amount &&
          unit == other.unit &&
          category == other.category;

  @override
  int get hashCode => Object.hash(name, amount, unit, category);

  @override
  String toString() => displayText;
}