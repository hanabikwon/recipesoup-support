/// 챌린지 뱃지 시스템 모델
/// 사용자가 특정 조건을 만족했을 때 획득하는 성취 뱃지
class ChallengeBadge {
  /// 뱃지 고유 ID
  final String id;
  
  /// 뱃지 이름
  final String name;
  
  /// 뱃지 설명
  final String description;
  
  /// 뱃지 이모지/아이콘
  final String icon;
  
  /// 뱃지 획득 조건 설명
  final String requirement;
  
  /// 뱃지 티어 (1: 브론즈, 2: 실버, 3: 골드, 4: 플래티넘)
  final BadgeTier tier;
  
  /// 뱃지 카테고리
  final BadgeCategory category;
  
  /// 획득시 보상 포인트
  final int rewardPoints;
  
  /// 뱃지가 활성화되어 있는지
  final bool isActive;
  
  /// 숨겨진 뱃지인지 (특별한 조건에서만 공개)
  final bool isHidden;

  ChallengeBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.requirement,
    this.tier = BadgeTier.bronze,
    required this.category,
    this.rewardPoints = 50,
    this.isActive = true,
    this.isHidden = false,
  });

  /// JSON에서 ChallengeBadge 객체 생성
  factory ChallengeBadge.fromJson(Map<String, dynamic> json) {
    return ChallengeBadge(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      requirement: json['requirement'] as String,
      tier: BadgeTier.fromString(json['tier'] as String? ?? 'bronze'),
      category: BadgeCategory.fromString(json['category'] as String? ?? 'completion'),
      rewardPoints: json['reward_points'] as int? ?? 50,
      isActive: json['is_active'] as bool? ?? true,
      isHidden: json['is_hidden'] as bool? ?? false,
    );
  }

  /// ChallengeBadge 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'requirement': requirement,
      'tier': tier.value,
      'category': category.value,
      'reward_points': rewardPoints,
      'is_active': isActive,
      'is_hidden': isHidden,
    };
  }

  /// 뱃지 색상 (티어별)
  String get tierColor {
    switch (tier) {
      case BadgeTier.bronze:
        return '#CD7F32'; // 브론즈
      case BadgeTier.silver:
        return '#C0C0C0'; // 실버
      case BadgeTier.gold:
        return '#FFD700'; // 골드
      case BadgeTier.platinum:
        return '#E5E4E2'; // 플래티넘
    }
  }

  /// copyWith 메서드
  ChallengeBadge copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    String? requirement,
    BadgeTier? tier,
    BadgeCategory? category,
    int? rewardPoints,
    bool? isActive,
    bool? isHidden,
  }) {
    return ChallengeBadge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      requirement: requirement ?? this.requirement,
      tier: tier ?? this.tier,
      category: category ?? this.category,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      isActive: isActive ?? this.isActive,
      isHidden: isHidden ?? this.isHidden,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChallengeBadge &&
      runtimeType == other.runtimeType &&
      id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChallengeBadge{id: $id, name: $name, tier: ${tier.displayName}}';
  }
}

/// 뱃지 티어 (난이도별 등급)
enum BadgeTier {
  bronze('bronze', '브론즈', '🥉'),
  silver('silver', '실버', '🥈'),
  gold('gold', '골드', '🥇'),
  platinum('platinum', '플래티넘', '💎');

  const BadgeTier(this.value, this.displayName, this.emoji);

  final String value;
  final String displayName;
  final String emoji;

  static BadgeTier fromString(String value) {
    for (var tier in BadgeTier.values) {
      if (tier.value == value) {
        return tier;
      }
    }
    return BadgeTier.bronze;
  }
}

/// 뱃지 카테고리
enum BadgeCategory {
  completion('completion', '완료형', '✅'),
  streak('streak', '연속형', '🔥'),
  mastery('mastery', '숙련형', '🌟'),
  exploration('exploration', '탐험형', '🗺️'),
  social('social', '소셜형', '👥'),
  special('special', '특별형', '🎁');

  const BadgeCategory(this.value, this.displayName, this.emoji);

  final String value;
  final String displayName;
  final String emoji;

  static BadgeCategory fromString(String value) {
    for (var category in BadgeCategory.values) {
      if (category.value == value) {
        return category;
      }
    }
    return BadgeCategory.completion;
  }
}

/// 사용자가 획득한 뱃지 기록
class UserBadge {
  /// 뱃지 ID
  final String badgeId;
  
  /// 획득 날짜
  final DateTime earnedAt;
  
  /// 획득한 포인트
  final int earnedPoints;
  
  /// 뱃지 획득시의 상태 (진행률 등)
  final Map<String, dynamic>? metadata;

  UserBadge({
    required this.badgeId,
    required this.earnedAt,
    required this.earnedPoints,
    this.metadata,
  });

  /// JSON에서 UserBadge 객체 생성
  factory UserBadge.fromJson(Map<String, dynamic> json) {
    return UserBadge(
      badgeId: json['badge_id'] as String,
      earnedAt: DateTime.fromMillisecondsSinceEpoch(json['earned_at'] as int),
      earnedPoints: json['earned_points'] as int? ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// UserBadge 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'badge_id': badgeId,
      'earned_at': earnedAt.millisecondsSinceEpoch,
      'earned_points': earnedPoints,
      'metadata': metadata,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserBadge &&
      runtimeType == other.runtimeType &&
      badgeId == other.badgeId;

  @override
  int get hashCode => badgeId.hashCode;

  @override
  String toString() {
    return 'UserBadge{badgeId: $badgeId, earnedAt: $earnedAt}';
  }
}