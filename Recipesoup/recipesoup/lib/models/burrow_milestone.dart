import '../config/burrow_assets.dart';

/// 토끼굴 마일스톤 시스템 데이터 모델
/// 성장 트랙과 특별 공간 언락을 관리

/// 토끼굴 타입 (성장 트랙 vs 특별 공간)
enum BurrowType {
  growth,  // 성장 트랙 (레시피 수량 기반)
  special  // 특별 공간 (행동 기반 언락)
}

/// 특별 공간 타입
enum SpecialRoom {
  ballroom,     // 무도회장 - 사교적 요리사
  hotSpring,    // 온천탕 - 힐링 요리사
  orchestra,    // 음악회장 - 감정 마에스트로
  alchemyLab,   // 실험실 - 도전적 요리사
  fineDining,   // 파인다이닝 - 완벽주의자
  
  // 새로 추가된 특별 공간들 (11개)
  alps,         // 알프스 별장 - 극한 도전자
  camping,      // 캠핑장 - 자연 애호가
  autumn,       // 가을 정원 - 계절 감성가
  springPicnic, // 봄 피크닉 - 외출 요리사
  surfing,      // 서핑 비치 - 해변 요리사
  snorkel,      // 스노클링 코브 - 바다 탐험가
  summerbeach,  // 여름 해변 - 휴양지 요리사
  baliYoga,     // 발리 요가 - 명상 요리사
  orientExpress, // 오리엔트 특급열차 - 여행 요리사
  canvas,       // 아틀리에 - 예술가 요리사
  vacance,      // 바캉스 빌라 - 휴식 요리사
}

/// 토끼굴 마일스톤 모델
class BurrowMilestone {
  /// 고유 식별자
  final String id;
  
  /// 마일스톤 레벨 (성장 트랙: 1-5, 특별 공간: 100+)
  final int level;
  
  /// 필요한 레시피 수 (성장 트랙용, 특별 공간은 null)
  final int? requiredRecipes;
  
  /// 마일스톤 제목
  final String title;
  
  /// 마일스톤 설명
  final String description;
  
  /// 이미지 경로
  final String imagePath;
  
  /// 언락 여부
  bool isUnlocked;
  
  /// 언락된 시간
  DateTime? unlockedAt;
  
  /// 토끼굴 타입
  final BurrowType burrowType;
  
  /// 특별 공간 타입 (특별 공간인 경우)
  final SpecialRoom? specialRoom;
  
  /// 언락 조건들 (특별 공간용)
  final Map<String, dynamic>? unlockConditions;

  BurrowMilestone({
    required this.id,
    required this.level,
    this.requiredRecipes,
    required this.title,
    required this.description,
    required this.imagePath,
    this.isUnlocked = false,
    this.unlockedAt,
    required this.burrowType,
    this.specialRoom,
    this.unlockConditions,
  });
  
  /// 성장 트랙 마일스톤 팩토리 (이미지 경로 자동 설정)
  factory BurrowMilestone.growth({
    String? id, // 선택적, 없으면 자동 생성
    required int level,
    required int requiredRecipes,
    required String title,
    required String description,
    String? imagePath, // 선택적으로 만들어서 자동 설정 가능
  }) {
    return BurrowMilestone(
      id: id ?? 'growth_$level',
      level: level,
      requiredRecipes: requiredRecipes,
      title: title,
      description: description,
      imagePath: imagePath ?? BurrowAssets.getMilestoneImagePath(level),
      burrowType: BurrowType.growth,
    );
  }
  
  /// 특별 공간 마일스톤 팩토리 (이미지 경로 자동 설정)
  factory BurrowMilestone.special({
    String? id, // 선택적, 없으면 자동 생성
    required SpecialRoom room,
    required String title,
    required String description,
    String? imagePath, // 선택적으로 만들어서 자동 설정 가능
    Map<String, dynamic>? unlockConditions,
  }) {
    return BurrowMilestone(
      id: id ?? 'special_${room.name}_${room.index + 100}',
      level: room.index + 100, // 특별 공간은 100+ 레벨
      title: title,
      description: description,
      imagePath: imagePath ?? BurrowAssets.getSpecialRoomImagePath(room.name),
      burrowType: BurrowType.special,
      specialRoom: room,
      unlockConditions: unlockConditions,
    );
  }
  
  /// JSON 변환 (Hive 저장용)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level': level,
      'requiredRecipes': requiredRecipes,
      'title': title,
      'description': description,
      'imagePath': imagePath,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'burrowType': burrowType.name,
      'specialRoom': specialRoom?.name,
      'unlockConditions': unlockConditions,
    };
  }
  
  /// JSON에서 생성 (Hive 로드용)
  factory BurrowMilestone.fromJson(Map<String, dynamic> json) {
    return BurrowMilestone(
      id: json['id'] as String,
      level: json['level'] as int,
      requiredRecipes: json['requiredRecipes'] as int?,
      title: json['title'] as String,
      description: json['description'] as String,
      imagePath: json['imagePath'] as String,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null 
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      burrowType: BurrowType.values.firstWhere(
        (e) => e.name == json['burrowType'],
        orElse: () => BurrowType.growth,
      ),
      specialRoom: json['specialRoom'] != null
          ? SpecialRoom.values.firstWhere(
              (e) => e.name == json['specialRoom'],
            )
          : null,
      unlockConditions: json['unlockConditions'] as Map<String, dynamic>?,
    );
  }
  
  /// 마일스톤 언락
  void unlock() {
    isUnlocked = true;
    unlockedAt = DateTime.now();
  }
  
  /// 성장 트랙 여부
  bool get isGrowthTrack => burrowType == BurrowType.growth;
  
  /// 특별 공간 여부
  bool get isSpecialRoom => burrowType == BurrowType.special;
  
  /// 복사본 생성
  BurrowMilestone copyWith({
    String? id,
    int? level,
    int? requiredRecipes,
    String? title,
    String? description,
    String? imagePath,
    bool? isUnlocked,
    DateTime? unlockedAt,
    BurrowType? burrowType,
    SpecialRoom? specialRoom,
    Map<String, dynamic>? unlockConditions,
  }) {
    return BurrowMilestone(
      id: id ?? this.id,
      level: level ?? this.level,
      requiredRecipes: requiredRecipes ?? this.requiredRecipes,
      title: title ?? this.title,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      burrowType: burrowType ?? this.burrowType,
      specialRoom: specialRoom ?? this.specialRoom,
      unlockConditions: unlockConditions ?? this.unlockConditions,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BurrowMilestone &&
          runtimeType == other.runtimeType &&
          level == other.level &&
          burrowType == other.burrowType &&
          specialRoom == other.specialRoom;

  @override
  int get hashCode => Object.hash(level, burrowType, specialRoom);

  @override
  String toString() => 'BurrowMilestone(level: $level, title: $title, type: $burrowType, unlocked: $isUnlocked)';
}

/// 언락 진행 상황 추적 모델
class UnlockProgress {
  /// 특별 공간 타입
  final SpecialRoom roomType;
  
  /// 현재 달성 수
  int currentCount;
  
  /// 필요한 달성 수
  final int requiredCount;
  
  /// 처리된 레시피 ID들 (중복 방지용)
  final Set<String> processedRecipeIds;
  
  /// 추가 메타데이터 (언급된 사람들, 감정별 카운트 등)
  final Map<String, dynamic> metadata;
  
  UnlockProgress({
    required this.roomType,
    this.currentCount = 0,
    required this.requiredCount,
    Set<String>? processedRecipeIds,
    Map<String, dynamic>? metadata,
  }) : processedRecipeIds = processedRecipeIds ?? <String>{},
       metadata = metadata ?? <String, dynamic>{};
  
  /// 진행률 계산 (0.0 ~ 1.0)
  double get progress => currentCount / requiredCount;
  
  /// 완료 여부
  bool get isCompleted => currentCount >= requiredCount;
  
  /// 레시피 처리 여부 확인 (중복 방지)
  bool hasProcessedRecipe(String recipeId) {
    return processedRecipeIds.contains(recipeId);
  }
  
  /// 레시피 처리 마킹 (중복 방지)
  bool markRecipeAsProcessed(String recipeId) {
    if (processedRecipeIds.contains(recipeId)) {
      return false; // 이미 처리됨
    }
    processedRecipeIds.add(recipeId);
    return true; // 새로 처리됨
  }
  
  /// 카운트 증가
  void incrementCount() {
    if (!isCompleted) {
      currentCount++;
    }
  }
  
  /// 메타데이터 설정
  void setMetadata(String key, dynamic value) {
    metadata[key] = value;
  }
  
  /// 메타데이터 조회
  T? getMetadata<T>(String key) {
    return metadata[key] as T?;
  }
  
  /// JSON 변환 (Hive 저장용)
  Map<String, dynamic> toJson() {
    return {
      'roomType': roomType.name,
      'currentCount': currentCount,
      'requiredCount': requiredCount,
      'processedRecipeIds': processedRecipeIds.toList(),
      'metadata': metadata,
    };
  }
  
  /// JSON에서 생성 (Hive 로드용)
  factory UnlockProgress.fromJson(Map<String, dynamic> json) {
    return UnlockProgress(
      roomType: SpecialRoom.values.firstWhere(
        (e) => e.name == json['roomType'],
      ),
      currentCount: json['currentCount'] as int? ?? 0,
      requiredCount: json['requiredCount'] as int,
      processedRecipeIds: Set<String>.from(
        json['processedRecipeIds'] as List<dynamic>? ?? []
      ),
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map<String, dynamic>? ?? {}
      ),
    );
  }
  
  /// 복사본 생성
  UnlockProgress copyWith({
    SpecialRoom? roomType,
    int? currentCount,
    int? requiredCount,
    Set<String>? processedRecipeIds,
    Map<String, dynamic>? metadata,
  }) {
    return UnlockProgress(
      roomType: roomType ?? this.roomType,
      currentCount: currentCount ?? this.currentCount,
      requiredCount: requiredCount ?? this.requiredCount,
      processedRecipeIds: processedRecipeIds ?? Set.from(this.processedRecipeIds),
      metadata: metadata ?? Map.from(this.metadata),
    );
  }

  @override
  String toString() => 'UnlockProgress(room: $roomType, $currentCount/$requiredCount, processed: ${processedRecipeIds.length})';
}

/// 언락 큐 아이템 (동시 다중 언락 방지용)
class UnlockQueueItem {
  /// 언락될 마일스톤
  final BurrowMilestone milestone;
  
  /// 언락 시간
  final DateTime unlockedAt;
  
  /// 언락 트리거 레시피 ID (참고용)
  final String? triggerRecipeId;
  
  const UnlockQueueItem({
    required this.milestone,
    required this.unlockedAt,
    this.triggerRecipeId,
  });
  
  @override
  String toString() => 'UnlockQueueItem(milestone: ${milestone.title}, triggeredBy: $triggerRecipeId)';
}