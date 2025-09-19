import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/challenge_models.dart';

/// 깡총 챌린지 시스템 서비스
/// 134개 챌린지 레시피 관리, 사용자 진행 상황 추적, 뱃지 시스템
/// 완전히 분리된 독립적인 챌린지 시스템
class ChallengeService {
  // 싱글톤 패턴
  static final ChallengeService _instance = ChallengeService._internal();
  factory ChallengeService() => _instance;
  ChallengeService._internal();

  // 캐싱 변수들
  static List<Challenge>? _cachedChallenges;
  static List<ChallengeBadge>? _cachedBadges;
  static Map<String, ChallengeProgress>? _cachedProgress;
  static Map<String, UserBadge>? _cachedUserBadges;
  static Map<String, Map<String, dynamic>>? _cachedCookingMethods; // 🔥 조리법 캐싱 추가
  static DateTime? _lastLoadTime;

  // 캐시 유효 시간 (30분)
  static const Duration _cacheValidDuration = Duration(minutes: 30);

  /// 모든 챌린지 데이터 로드 (JSON에서 134개)
  Future<List<Challenge>> loadAllChallenges() async {
    try {
      if (_isCacheValid() && _cachedChallenges != null) {
        if (kDebugMode) {
          debugPrint('🎯 Challenge cache hit - returning ${_cachedChallenges!.length} challenges');
        }
        return _cachedChallenges!;
      }

      if (kDebugMode) {
        debugPrint('🎯 Loading challenges from JSON...');
      }

      // JSON 파일에서 챌린지 데이터 로드
      final jsonString = await rootBundle.loadString('lib/data/challenge_recipes.json');
      final challengeList = json.decode(jsonString) as List<dynamic>;
      
      final challenges = challengeList
          .map((challengeJson) => Challenge.fromJson(challengeJson as Map<String, dynamic>))
          .where((challenge) => challenge.isActive) // 활성화된 챌린지만
          .toList();

      // 캐시 업데이트
      _cachedChallenges = challenges;
      _lastLoadTime = DateTime.now();

      if (kDebugMode) {
        debugPrint('✅ Loaded ${challenges.length} challenges');
        debugPrint('📊 Categories breakdown:');
        for (var category in ChallengeCategory.values) {
          final count = challenges.where((c) => c.category == category).length;
          debugPrint('  ${category.displayName}: $count개');
        }
      }

      return challenges;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to load challenges: $e');
      }
      
      // Fallback: 빈 리스트 반환
      return [];
    }
  }

  /// 카테고리별 챌린지 조회
  Future<List<Challenge>> getChallengesByCategory(ChallengeCategory category) async {
    final allChallenges = await loadAllChallenges();
    return allChallenges.where((challenge) => challenge.category == category).toList();
  }

  /// 특정 챌린지 조회
  Future<Challenge?> getChallengeById(String challengeId) async {
    final allChallenges = await loadAllChallenges();
    try {
      return allChallenges.firstWhere((challenge) => challenge.id == challengeId);
    } catch (e) {
      return null;
    }
  }

  /// 추천 챌린지 (사용자 진행 상황 기반)
  Future<List<Challenge>> getRecommendedChallenges({int limit = 5}) async {
    final allChallenges = await loadAllChallenges();
    final userProgress = await loadUserProgress();

    // 미완료 챌린지 중에서 추천
    final incompleteChallenges = allChallenges.where((challenge) {
      final progress = userProgress[challenge.id];
      return progress == null || !progress.isCompleted;
    }).toList();

    // 난이도별로 섞어서 추천
    incompleteChallenges.shuffle();
    
    // 각 카테고리에서 골고루 선택
    final recommendations = <Challenge>[];
    final categories = ChallengeCategory.values.toList()..shuffle();
    
    for (var category in categories) {
      final categoryRandom = incompleteChallenges
          .where((c) => c.category == category)
          .take(2)
          .toList();
      recommendations.addAll(categoryRandom);
      
      if (recommendations.length >= limit) break;
    }

    return recommendations.take(limit).toList();
  }

  /// 사용자 진행 상황 로드 (로컬 저장소에서)
  Future<Map<String, ChallengeProgress>> loadUserProgress() async {
    try {
      if (_cachedProgress != null) {
        return _cachedProgress!;
      }

      // 실제 구현에서는 Hive나 SharedPreferences 사용
      // 현재는 임시로 빈 Map 반환
      _cachedProgress = <String, ChallengeProgress>{};
      
      if (kDebugMode) {
        debugPrint('📈 Loaded user progress: ${_cachedProgress!.length} records');
      }

      return _cachedProgress!;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to load user progress: $e');
      }
      return <String, ChallengeProgress>{};
    }
  }

  /// 사용자 진행 상황 저장
  Future<void> saveUserProgress(ChallengeProgress progress) async {
    try {
      final currentProgress = await loadUserProgress();
      currentProgress[progress.challengeId] = progress;
      
      // 실제 구현에서는 Hive나 SharedPreferences에 저장
      // 현재는 캐시에만 저장
      _cachedProgress = currentProgress;

      if (kDebugMode) {
        debugPrint('💾 Saved progress for challenge: ${progress.challengeId} (${progress.status.displayName})');
      }

      // 뱃지 체크 (백그라운드)
      _checkAndAwardBadges();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to save user progress: $e');
      }
      throw Exception('챌린지 진행 상황 저장 실패');
    }
  }

  /// 챌린지 시작
  Future<ChallengeProgress> startChallenge(String challengeId) async {
    final challenge = await getChallengeById(challengeId);
    if (challenge == null) {
      throw Exception('챌린지를 찾을 수 없습니다: $challengeId');
    }

    // 선행 조건 체크
    if (challenge.prerequisiteId != null) {
      final prerequisiteProgress = (await loadUserProgress())[challenge.prerequisiteId!];
      if (prerequisiteProgress == null || !prerequisiteProgress.isCompleted) {
        throw Exception('이전 챌린지를 먼저 완료해주세요');
      }
    }

    final progress = ChallengeProgress(challengeId: challengeId).start();
    await saveUserProgress(progress);

    if (kDebugMode) {
      debugPrint('🚀 Started challenge: ${challenge.title}');
    }

    return progress;
  }

  /// 챌린지 완료
  Future<ChallengeProgress> completeChallenge(
    String challengeId, {
    String? userNote,
    String? userImagePath,
    int? userRating,
  }) async {
    final challenge = await getChallengeById(challengeId);
    if (challenge == null) {
      throw Exception('챌린지를 찾을 수 없습니다: $challengeId');
    }

    final currentProgress = (await loadUserProgress())[challengeId];
    if (currentProgress == null) {
      throw Exception('시작하지 않은 챌린지입니다');
    }

    final completedProgress = currentProgress.complete(
      userNote: userNote,
      userImagePath: userImagePath,
      userRating: userRating,
      points: 0, // 포인트 시스템 제거
    );

    await saveUserProgress(completedProgress);

    if (kDebugMode) {
      debugPrint('🏆 Completed challenge: ${challenge.title}');
    }

    return completedProgress;
  }

  /// 뱃지 시스템 로드
  Future<List<ChallengeBadge>> loadAllBadges() async {
    try {
      if (_cachedBadges != null) {
        return _cachedBadges!;
      }

      // JSON 파일에서 뱃지 데이터 로드
      final jsonString = await rootBundle.loadString('lib/data/challenge_badges.json');
      final badgeList = json.decode(jsonString) as List<dynamic>;
      
      final badges = badgeList
          .map((badgeJson) => ChallengeBadge.fromJson(badgeJson as Map<String, dynamic>))
          .where((badge) => badge.isActive)
          .toList();

      _cachedBadges = badges;

      if (kDebugMode) {
        debugPrint('🏅 Loaded ${badges.length} badges');
      }

      return badges;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to load badges: $e');
      }
      return [];
    }
  }

  /// 사용자 획득 뱃지 조회
  Future<List<UserBadge>> getUserBadges() async {
    try {
      if (_cachedUserBadges != null) {
        return _cachedUserBadges!.values.toList();
      }

      // 실제 구현에서는 로컬 저장소에서 로드
      _cachedUserBadges = <String, UserBadge>{};

      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to load user badges: $e');
      }
      return [];
    }
  }

  /// 통계 정보 조회
  Future<ChallengeStatistics> getStatistics() async {
    final allChallenges = await loadAllChallenges();
    final userProgress = await loadUserProgress();
    final userBadges = await getUserBadges();

    final completedCount = userProgress.values
        .where((progress) => progress.isCompleted)
        .length;

    final totalPoints = userProgress.values
        .where((progress) => progress.isCompleted)
        .fold(0, (sum, progress) => sum + progress.earnedPoints);

    // 카테고리별 완료 현황
    final categoryStats = <ChallengeCategory, int>{};
    for (var category in ChallengeCategory.values) {
      final categoryCompleted = allChallenges
          .where((challenge) => challenge.category == category)
          .where((challenge) {
            final progress = userProgress[challenge.id];
            return progress != null && progress.isCompleted;
          })
          .length;
      
      categoryStats[category] = categoryCompleted;
    }

    return ChallengeStatistics(
      totalChallenges: allChallenges.length,
      completedChallenges: completedCount,
      totalPoints: totalPoints,
      badgesEarned: userBadges.length,
      categoryStats: categoryStats,
      completionRate: allChallenges.isNotEmpty 
          ? (completedCount / allChallenges.length * 100) 
          : 0.0,
    );
  }

  /// 뱃지 획득 조건 체크 및 수여 (백그라운드)
  Future<void> _checkAndAwardBadges() async {
    try {
      final allBadges = await loadAllBadges();
      final userProgress = await loadUserProgress();
      final currentUserBadges = await getUserBadges();
      final currentBadgeIds = currentUserBadges.map((b) => b.badgeId).toSet();

      for (var badge in allBadges) {
        // 이미 획득한 뱃지는 스킵
        if (currentBadgeIds.contains(badge.id)) continue;

        // 뱃지 조건 체크 로직 (카테고리별로 구현)
        bool shouldAwardBadge = false;
        
        switch (badge.category) {
          case BadgeCategory.completion:
            // 완료형: N개 챌린지 완료
            final completedCount = userProgress.values
                .where((p) => p.isCompleted)
                .length;
            shouldAwardBadge = _checkCompletionBadge(badge, completedCount);
            break;
            
          case BadgeCategory.streak:
            // 연속형: N일 연속 챌린지 완료
            shouldAwardBadge = _checkStreakBadge(badge, userProgress);
            break;
            
          case BadgeCategory.mastery:
            // 숙련형: 특정 카테고리 마스터
            shouldAwardBadge = _checkMasteryBadge(badge, userProgress);
            break;
            
          case BadgeCategory.exploration:
            // 탐험형: 다양한 카테고리 도전
            shouldAwardBadge = _checkExplorationBadge(badge, userProgress);
            break;
            
          default:
            break;
        }

        if (shouldAwardBadge) {
          await _awardBadge(badge);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to check badges: $e');
      }
    }
  }

  /// 뱃지 수여
  Future<void> _awardBadge(ChallengeBadge badge) async {
    final userBadge = UserBadge(
      badgeId: badge.id,
      earnedAt: DateTime.now(),
      earnedPoints: badge.rewardPoints,
    );

    _cachedUserBadges ??= <String, UserBadge>{};
    _cachedUserBadges![badge.id] = userBadge;

    if (kDebugMode) {
      debugPrint('🏆 Badge awarded: ${badge.name} (+${badge.rewardPoints} points)');
    }
  }

  /// 완료형 뱃지 조건 체크
  bool _checkCompletionBadge(ChallengeBadge badge, int completedCount) {
    // 예시: "5개 챌린지 완료" 뱃지
    if (badge.id == 'completion_beginner' && completedCount >= 5) return true;
    if (badge.id == 'completion_intermediate' && completedCount >= 15) return true;
    if (badge.id == 'completion_advanced' && completedCount >= 30) return true;
    if (badge.id == 'completion_master' && completedCount >= 50) return true;
    
    return false;
  }

  /// 연속형 뱃지 조건 체크
  bool _checkStreakBadge(ChallengeBadge badge, Map<String, ChallengeProgress> userProgress) {
    // 연속 완료 일수 계산 로직
    final completedDates = userProgress.values
        .where((p) => p.isCompleted && p.completedAt != null)
        .map((p) => p.completedAt!)
        .toList()
      ..sort();

    if (completedDates.isEmpty) return false;

    int currentStreak = 1;
    int maxStreak = 1;

    for (int i = 1; i < completedDates.length; i++) {
      final prevDate = DateTime(
        completedDates[i-1].year, 
        completedDates[i-1].month, 
        completedDates[i-1].day
      );
      final currentDate = DateTime(
        completedDates[i].year,
        completedDates[i].month, 
        completedDates[i].day
      );

      if (currentDate.difference(prevDate).inDays == 1) {
        currentStreak++;
      } else {
        currentStreak = 1;
      }

      maxStreak = currentStreak > maxStreak ? currentStreak : maxStreak;
    }

    // 뱃지별 조건
    if (badge.id == 'streak_3days' && maxStreak >= 3) return true;
    if (badge.id == 'streak_7days' && maxStreak >= 7) return true;
    if (badge.id == 'streak_30days' && maxStreak >= 30) return true;

    return false;
  }

  /// 숙련형 뱃지 조건 체크
  bool _checkMasteryBadge(ChallengeBadge badge, Map<String, ChallengeProgress> userProgress) {
    // 카테고리별 완료 현황 체크
    // 구체적 로직은 실제 뱃지 설계에 따라 구현
    return false;
  }

  /// 탐험형 뱃지 조건 체크
  bool _checkExplorationBadge(ChallengeBadge badge, Map<String, ChallengeProgress> userProgress) {
    // 다양한 카테고리 도전 여부 체크
    // 구체적 로직은 실제 뱃지 설계에 따라 구현
    return false;
  }

  /// 캐시 유효성 확인
  bool _isCacheValid() {
    if (_lastLoadTime == null) return false;
    return DateTime.now().difference(_lastLoadTime!).compareTo(_cacheValidDuration) < 0;
  }

  /// 🔥 조리법 데이터 로드 (detailed_cooking_methods.json)
  Future<Map<String, Map<String, dynamic>>> loadCookingMethods() async {
    try {
      if (_isCacheValid() && _cachedCookingMethods != null) {
        if (kDebugMode) {
          debugPrint('🍳 Cooking methods cache hit - returning ${_cachedCookingMethods!.length} recipes');
        }
        return _cachedCookingMethods!;
      }

      if (kDebugMode) {
        debugPrint('🍳 Loading cooking methods from JSON...');
      }

      // JSON 파일에서 조리법 데이터 로드
      final jsonString = await rootBundle.loadString('lib/data/detailed_cooking_methods.json');
      final cookingMethodsData = json.decode(jsonString) as Map<String, dynamic>;
      
      // Map<String, Map<String, dynamic>> 형태로 변환
      final cookingMethods = <String, Map<String, dynamic>>{};
      cookingMethodsData.forEach((key, value) {
        cookingMethods[key] = value as Map<String, dynamic>;
      });

      // 캐시 업데이트
      _cachedCookingMethods = cookingMethods;

      if (kDebugMode) {
        debugPrint('✅ Loaded ${cookingMethods.length} cooking method recipes');
      }

      return cookingMethods;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to load cooking methods: $e');
      }
      return <String, Map<String, dynamic>>{};
    }
  }

  /// 🔥 특정 챌린지의 조리법 가져오기
  Future<Map<String, dynamic>?> getCookingMethodByRecipeId(String recipeId) async {
    try {
      final cookingMethods = await loadCookingMethods();
      
      // 다양한 형태의 ID 매칭 시도
      Map<String, dynamic>? foundMethod;
      
      // 1. 정확한 ID 매칭
      foundMethod = cookingMethods[recipeId];
      if (foundMethod != null) return foundMethod;
      
      // 2. 건강 라이프 서브카테고리 ID 매칭
      if (recipeId.startsWith('healthy_')) {
        foundMethod = cookingMethods[recipeId];
        if (foundMethod != null) return foundMethod;
      }
      
      // 3. partial 매칭 (예: emotional_001 -> emotional_happy_001)
      for (var entry in cookingMethods.entries) {
        if (entry.key.contains(recipeId) || recipeId.contains(entry.key)) {
          foundMethod = entry.value;
          break;
        }
      }

      if (foundMethod == null && kDebugMode) {
        debugPrint('⚠️ No cooking method found for recipe: $recipeId');
        debugPrint('📋 Available recipe IDs: ${cookingMethods.keys.take(5).join(', ')}...');
      }

      return foundMethod;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to get cooking method for $recipeId: $e');
      }
      return null;
    }
  }

  /// 🔥 조리법 단계 리스트 가져오기 (UI용)
  Future<List<String>> getCookingSteps(String recipeId) async {
    final cookingMethod = await getCookingMethodByRecipeId(recipeId);
    if (cookingMethod == null) return [];
    
    final steps = cookingMethod['cooking_steps'] as List<dynamic>?;
    return steps?.cast<String>() ?? [];
  }

  /// 캐시 클리어
  void clearCache() {
    _cachedChallenges = null;
    _cachedBadges = null;
    _cachedProgress = null;
    _cachedUserBadges = null;
    _cachedCookingMethods = null; // 🔥 조리법 캐시도 클리어
    _lastLoadTime = null;
    
    if (kDebugMode) {
      debugPrint('🗑️ Challenge service cache cleared');
    }
  }

  /// 서비스 상태 정보 (디버깅용)
  Map<String, dynamic> getServiceStatus() {
    return {
      'challenges_cached': _cachedChallenges?.length ?? 0,
      'badges_cached': _cachedBadges?.length ?? 0,
      'user_progress_cached': _cachedProgress?.length ?? 0,
      'user_badges_cached': _cachedUserBadges?.length ?? 0,
      'cache_valid': _isCacheValid(),
      'last_load_time': _lastLoadTime?.toIso8601String(),
    };
  }
}

/// 챌린지 통계 정보 모델
class ChallengeStatistics {
  final int totalChallenges;
  final int completedChallenges;
  final int totalPoints;
  final int badgesEarned;
  final Map<ChallengeCategory, int> categoryStats;
  final double completionRate;

  ChallengeStatistics({
    required this.totalChallenges,
    required this.completedChallenges,
    required this.totalPoints,
    required this.badgesEarned,
    required this.categoryStats,
    required this.completionRate,
  });

  @override
  String toString() {
    return 'ChallengeStats{total: $totalChallenges, completed: $completedChallenges, points: $totalPoints, badges: $badgesEarned, rate: ${completionRate.toStringAsFixed(1)}%}';
  }
}