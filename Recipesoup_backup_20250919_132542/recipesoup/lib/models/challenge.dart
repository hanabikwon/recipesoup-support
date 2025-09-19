import 'challenge_category.dart';

/// 깡총 챌린지 모델 - 정적 챌린지 데이터 (JSON 로드)
/// 기존 Recipe 모델과 완전히 분리된 독립적인 챌린지 시스템
class Challenge {
  /// 고유 식별자 (예: "emotion_001", "world_002", "healthy_003")
  final String id;
  
  /// 챌린지 제목 
  final String title;
  
  /// 챌린지 설명/스토리
  final String description;
  
  /// 챌린지 카테고리
  final ChallengeCategory category;
  
  /// 예상 소요 시간 (분)
  final int estimatedMinutes;
  
  /// 난이도 (1: 쉬움, 2: 보통, 3: 어려움)
  final int difficulty;
  
  /// 서빙 인원 (예: "2-3인분")
  final String servings;
  
  /// 메인 재료 리스트 (간단한 문자열 배열)
  final List<String> mainIngredients;
  
  /// 요리 팁/포인트
  final String? cookingTip;
  
  /// 챌린지 이미지 경로 (assets 폴더 내)
  final String? imagePath;
  
  /// 챌린지 해시태그
  final List<String> tags;
  
  /// 선행 챌린지 ID (이전 챌린지를 완료해야 해금되는 경우)
  final String? prerequisiteId;
  
  /// 챌린지가 활성화되어 있는지 (시즌별 챌린지 등)
  final bool isActive;

  // 마이그레이션 관련 필드들 (3탭 구조 지원)
  /// 3탭 구조용 주요 재료 (v2)
  final List<String>? mainIngredientsV2;
  
  /// 소스&양념 재료
  final List<String>? sauceSeasoning;
  
  /// 상세 요리법 단계들
  final List<String>? detailedCookingMethods;
  
  /// 마이그레이션 완료 여부
  final bool migrationCompleted;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.estimatedMinutes,
    required this.difficulty,
    required this.servings,
    required this.mainIngredients,
    this.cookingTip,
    this.imagePath,
    required this.tags,
    this.prerequisiteId,
    this.isActive = true,
    // 마이그레이션 필드들
    this.mainIngredientsV2,
    this.sauceSeasoning,
    this.detailedCookingMethods,
    this.migrationCompleted = false,
  });

  /// JSON에서 Challenge 객체 생성
  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: ChallengeCategory.fromId(json['category'] as String) ?? 
                ChallengeCategory.emotional,
      estimatedMinutes: json['estimated_minutes'] as int? ?? 30,
      difficulty: json['difficulty'] as int? ?? 1,
      servings: json['servings'] as String? ?? '2인분',
      mainIngredients: (json['main_ingredients'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      cookingTip: json['cooking_tip'] as String?,
      imagePath: json['image_path'] as String?,
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      prerequisiteId: json['prerequisite_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      // 마이그레이션 필드들
      mainIngredientsV2: (json['main_ingredients_v2'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      sauceSeasoning: (json['sauce_seasoning'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      detailedCookingMethods: (json['detailed_cooking_methods'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      migrationCompleted: json['migrationCompleted'] as bool? ?? false,
    );
  }

  /// Challenge 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'title': title,
      'description': description,
      'category': category.id,
      'estimated_minutes': estimatedMinutes,
      'difficulty': difficulty,
      'servings': servings,
      'main_ingredients': mainIngredients,
      'cooking_tip': cookingTip,
      'image_path': imagePath,
      'tags': tags,
      'prerequisite_id': prerequisiteId,
      'is_active': isActive,
      'migrationCompleted': migrationCompleted,
    };
    
    // 마이그레이션 필드들이 있으면 추가
    if (mainIngredientsV2 != null) {
      json['main_ingredients_v2'] = mainIngredientsV2;
    }
    if (sauceSeasoning != null) {
      json['sauce_seasoning'] = sauceSeasoning;
    }
    if (detailedCookingMethods != null) {
      json['detailed_cooking_methods'] = detailedCookingMethods;
    }
    
    return json;
  }

  /// 난이도 텍스트 반환
  String get difficultyText {
    switch (difficulty) {
      case 1:
        return '쉬움';
      case 2:
        return '보통';
      case 3:
        return '어려움';
      default:
        return '보통';
    }
  }

  /// 예상 소요 시간 텍스트
  String get timeText {
    if (estimatedMinutes < 60) {
      return '$estimatedMinutes분';
    } else {
      final hours = estimatedMinutes ~/ 60;
      final minutes = estimatedMinutes % 60;
      return minutes > 0 ? '$hours시간 $minutes분' : '$hours시간';
    }
  }

  /// 카테고리별 색상 코드
  String get categoryColor {
    switch (category) {
      // 메인 카테고리
      case ChallengeCategory.emotional:
        return '#E8A5C0'; // 핑크 계열 (홈화면과 일치하는 부드러운 핑크)
      case ChallengeCategory.worldCuisine:
        return '#4ECDC4'; // 청록 계열
      case ChallengeCategory.healthy:
        return '#45B7D1'; // 파랑 계열
      
      // 감정별 서브카테고리
      case ChallengeCategory.emotionalHappy:
        return '#F4D03F'; // 기쁨 골드 (홈화면과 일치하는 부드러운 골드)
      case ChallengeCategory.emotionalComfort:
        return '#E8A5C0'; // 위로 핑크 (홈화면과 일치하는 부드러운 핑크)
      case ChallengeCategory.emotionalNostalgic:
        return '#9B7FB3'; // 그리움 라벤더
      case ChallengeCategory.emotionalEnergy:
        return '#F39C12'; // 활력 오렌지 (홈화면과 일치하는 부드러운 오렌지)
      
      // 세계 요리 서브카테고리
      case ChallengeCategory.worldAsian:
        return '#E57373'; // 아시아 레드 (부드러운 레드)
      case ChallengeCategory.worldEuropean:
        return '#3498DB'; // 유럽 블루
      case ChallengeCategory.worldAmerican:
        return '#27AE60'; // 아메리카 그린
      case ChallengeCategory.worldFusion:
        return '#E67E22'; // 중동 오렌지
      
      // 건강 라이프 서브카테고리
      case ChallengeCategory.healthyNatural:
        return '#7BC04A'; // 자연 올리브 그린
      case ChallengeCategory.healthyEnergy:
        return '#F7DC6F'; // 에너지 옐로우 (부드러운 에너지 색상)
      case ChallengeCategory.healthyCare:
        return '#3498DB'; // 건강 블루
      case ChallengeCategory.healthyHealing:
        return '#9B59B6'; // 힐링 퍼플
    }
  }

  /// copyWith 메서드 (immutable 객체 수정용)
  Challenge copyWith({
    String? id,
    String? title,
    String? description,
    ChallengeCategory? category,
    int? estimatedMinutes,
    int? difficulty,
    String? servings,
    List<String>? mainIngredients,
    String? cookingTip,
    String? imagePath,
    List<String>? tags,
    String? prerequisiteId,
    bool? isActive,
    // 마이그레이션 필드들
    List<String>? mainIngredientsV2,
    List<String>? sauceSeasoning,
    List<String>? detailedCookingMethods,
    bool? migrationCompleted,
  }) {
    return Challenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      difficulty: difficulty ?? this.difficulty,
      servings: servings ?? this.servings,
      mainIngredients: mainIngredients ?? this.mainIngredients,
      cookingTip: cookingTip ?? this.cookingTip,
      imagePath: imagePath ?? this.imagePath,
      tags: tags ?? this.tags,
      prerequisiteId: prerequisiteId ?? this.prerequisiteId,
      isActive: isActive ?? this.isActive,
      // 마이그레이션 필드들
      mainIngredientsV2: mainIngredientsV2 ?? this.mainIngredientsV2,
      sauceSeasoning: sauceSeasoning ?? this.sauceSeasoning,
      detailedCookingMethods: detailedCookingMethods ?? this.detailedCookingMethods,
      migrationCompleted: migrationCompleted ?? this.migrationCompleted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Challenge && 
      runtimeType == other.runtimeType &&
      id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Challenge{id: $id, title: $title, category: ${category.displayName}}';
  }
}