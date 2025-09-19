/// 깡총 챌린지 카테고리 모델
/// 3개 메인 카테고리 + 각각 4개 서브카테고리 = 총 15개 카테고리
enum ChallengeCategory {
  /// 감정별 챌린지 (36개) - 메인 카테고리
  emotional('감정별 챌린지', '😊', 'emotional', '마음에 따라 만드는 특별한 요리들'),
  
  /// 세계 맛 여행 (51개) - 메인 카테고리
  worldCuisine('세계 맛 여행', '🌏', 'world_cuisine', '집에서 즐기는 세계 각국의 맛'),
  
  /// 건강 라이프 (47개) - 메인 카테고리
  healthy('건강 라이프', '💚', 'healthy', '몸과 마음이 건강해지는 요리'),
  
  // === 감정별 챌린지 서브카테고리 ===
  /// 감정별 - 기쁨과 축하 서브카테고리 (9개)
  emotionalHappy('기쁨과 축하', '🎉', 'emotional_happy', '특별한 날과 기쁜 순간을 위한 축하 요리'),
  
  /// 감정별 - 위로와 치유 서브카테고리 (9개)
  emotionalComfort('위로와 치유', '🤗', 'emotional_comfort', '마음이 힘들 때 따뜻함을 주는 위로 요리'),
  
  /// 감정별 - 그리움과 추억 서브카테고리 (9개)
  emotionalNostalgic('그리움과 추억', '💭', 'emotional_nostalgic', '옛 추억을 되살리는 그리운 맛의 요리'),
  
  /// 감정별 - 활력과 동기부여 서브카테고리 (9개)
  emotionalEnergy('활력과 동기부여', '💪', 'emotional_energy', '새로운 도전과 활력을 주는 에너지 요리'),
  
  // === 세계 맛 여행 서브카테고리 ===
  /// 세계 요리 - 아시아 요리 서브카테고리 (13개)
  worldAsian('아시아 요리', '🍜', 'world_asian', '동양의 정취가 가득한 아시아 각국의 요리'),
  
  /// 세계 요리 - 유럽 요리 서브카테고리 (13개)
  worldEuropean('유럽 요리', '🍝', 'world_european', '로맨틱하고 우아한 유럽 전통 요리'),
  
  /// 세계 요리 - 아메리카 요리 서브카테고리 (13개)
  worldAmerican('아메리카 요리', '🍔', 'world_american', '대륙의 풍미가 담긴 아메리카 대륙 요리'),
  
  /// 세계 요리 - 퓨전 요리 서브카테고리 (12개)
  worldFusion('퓨전 요리', '🍽️', 'world_fusion', '창의적인 동서양 융합 요리'),
  
  // === 건강 라이프 서브카테고리 ===
  /// 건강 라이프 - 자연 친화 서브카테고리 (12개)
  healthyNatural('자연 친화', '🌱', 'healthy_natural', '유기농 재료로 만드는 자연 그대로의 요리'),
  
  /// 건강 라이프 - 에너지 충전 서브카테고리 (12개)
  healthyEnergy('에너지 충전', '⚡', 'healthy_energy', '활력이 필요할 때 먹는 에너지 요리'),
  
  /// 건강 라이프 - 건강 관리 서브카테고리 (11개)
  healthyCare('건강 관리', '🏥', 'healthy_care', '특정 건강 고민을 위한 맞춤형 관리 요리'),
  
  /// 건강 라이프 - 몸과 마음 케어 서브카테고리 (12개)
  healthyHealing('몸과 마음 케어', '🧘', 'healthy_healing', '스트레스 해소와 심신 안정을 위한 치유 요리');

  const ChallengeCategory(this.displayName, this.emoji, this.id, this.description);
  
  /// 화면에 표시되는 이름
  final String displayName;
  
  /// 카테고리를 나타내는 이모지
  final String emoji;
  
  /// API/JSON에서 사용되는 식별자
  final String id;
  
  /// 카테고리 설명
  final String description;

  /// ID로 카테고리 찾기
  static ChallengeCategory? fromId(String id) {
    for (var category in ChallengeCategory.values) {
      if (category.id == id) {
        return category;
      }
    }
    return null;
  }

  /// 전체 챌린지 개수 계산 (메인 + 서브카테고리)
  static int get totalChallengeCount {
    // 감정별: 36 + (9+9+9+9) = 72개
    // 세계 요리: 51 + (13+13+13+12) = 102개  
    // 건강 라이프: 47 + (12+12+11+12) = 94개
    return 72 + 102 + 94; // 268개
  }

  /// 각 카테고리별 예상 챌린지 개수
  int get expectedCount {
    switch (this) {
      // 메인 카테고리
      case ChallengeCategory.emotional:
        return 36;
      case ChallengeCategory.worldCuisine:
        return 51;
      case ChallengeCategory.healthy:
        return 47;
      
      // 감정별 서브카테고리
      case ChallengeCategory.emotionalHappy:
        return 9;
      case ChallengeCategory.emotionalComfort:
        return 9;
      case ChallengeCategory.emotionalNostalgic:
        return 9;
      case ChallengeCategory.emotionalEnergy:
        return 9;
      
      // 세계 요리 서브카테고리  
      case ChallengeCategory.worldAsian:
        return 13;
      case ChallengeCategory.worldEuropean:
        return 13;
      case ChallengeCategory.worldAmerican:
        return 13;
      case ChallengeCategory.worldFusion:
        return 12;
      
      // 건강 라이프 서브카테고리
      case ChallengeCategory.healthyNatural:
        return 12;
      case ChallengeCategory.healthyEnergy:
        return 12;
      case ChallengeCategory.healthyCare:
        return 11;
      case ChallengeCategory.healthyHealing:
        return 12;
    }
  }
  
  /// 메인 카테고리 체크
  bool get isMainCategory {
    return this == ChallengeCategory.emotional ||
           this == ChallengeCategory.worldCuisine ||
           this == ChallengeCategory.healthy;
  }
  
  /// 서브카테고리의 부모 메인 카테고리 반환
  ChallengeCategory? get parentCategory {
    switch (this) {
      case ChallengeCategory.emotionalHappy:
      case ChallengeCategory.emotionalComfort:
      case ChallengeCategory.emotionalNostalgic:
      case ChallengeCategory.emotionalEnergy:
        return ChallengeCategory.emotional;
        
      case ChallengeCategory.worldAsian:
      case ChallengeCategory.worldEuropean:
      case ChallengeCategory.worldAmerican:
      case ChallengeCategory.worldFusion:
        return ChallengeCategory.worldCuisine;
        
      case ChallengeCategory.healthyNatural:
      case ChallengeCategory.healthyEnergy:
      case ChallengeCategory.healthyCare:
      case ChallengeCategory.healthyHealing:
        return ChallengeCategory.healthy;
        
      default:
        return null; // 메인 카테고리들
    }
  }
  
  /// 특정 메인 카테고리의 서브카테고리들 반환
  static List<ChallengeCategory> getSubcategories(ChallengeCategory mainCategory) {
    switch (mainCategory) {
      case ChallengeCategory.emotional:
        return [
          ChallengeCategory.emotionalHappy,
          ChallengeCategory.emotionalComfort,
          ChallengeCategory.emotionalNostalgic,
          ChallengeCategory.emotionalEnergy,
        ];
      case ChallengeCategory.worldCuisine:
        return [
          ChallengeCategory.worldAsian,
          ChallengeCategory.worldEuropean,
          ChallengeCategory.worldAmerican,
          ChallengeCategory.worldFusion,
        ];
      case ChallengeCategory.healthy:
        return [
          ChallengeCategory.healthyNatural,
          ChallengeCategory.healthyEnergy,
          ChallengeCategory.healthyCare,
          ChallengeCategory.healthyHealing,
        ];
      default:
        return [];
    }
  }
}