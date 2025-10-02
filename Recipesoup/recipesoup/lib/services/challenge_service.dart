import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart'; // 🔥 CRITICAL FIX: Hive persistence 추가
import '../models/challenge_models.dart';

/// 깡총 챌린지 시스템 서비스
/// 134개 챌린지 레시피 관리, 사용자 진행 상황 추적, 뱃지 시스템
/// 완전히 분리된 독립적인 챌린지 시스템
class ChallengeService {
  // 싱글톤 패턴
  static final ChallengeService _instance = ChallengeService._internal();
  factory ChallengeService() => _instance;
  ChallengeService._internal();

  // 🔥 CRITICAL FIX: Hive Box for challenge progress persistence
  Box<dynamic>? _progressBox;
  final String _progressBoxName = 'challenge_progress';
  bool _isProgressBoxInitialized = false;

  // 캐싱 변수들
  static List<Challenge>? _cachedChallenges;
  static Map<String, ChallengeProgress>? _cachedProgress;
  static Map<String, Map<String, dynamic>>? _cachedCookingMethods; // 🔥 조리법 캐싱 추가
  static DateTime? _lastLoadTime;

  // 캐시 유효 시간 (30분)
  static const Duration _cacheValidDuration = Duration(minutes: 30);

  /// 🔥 CRITICAL FIX: Hive Box 초기화 (HiveService 패턴 따름)
  Future<void> _initializeProgressBox() async {
    if (_progressBox != null && _progressBox!.isOpen) {
      return;
    }

    if (_isProgressBoxInitialized) {
      return;
    }

    try {
      _progressBox = await Hive.openBox<dynamic>(_progressBoxName);
      _isProgressBoxInitialized = true;

      if (kDebugMode) {
        debugPrint('💾 Challenge Progress Box initialized: ${_progressBox!.length} records');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to initialize Challenge Progress Box: $e');
      }
      rethrow;
    }
  }

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

  /// 사용자 진행 상황 로드 (Hive Box에서)
  Future<Map<String, ChallengeProgress>> loadUserProgress() async {
    try {
      // 🔥 CRITICAL FIX: Hive Box 초기화
      await _initializeProgressBox();

      // 메모리 캐시가 있으면 바로 반환
      if (_cachedProgress != null) {
        return _cachedProgress!;
      }

      // 🔥 CRITICAL FIX: Hive Box에서 로드
      final box = _progressBox!;
      final progressMap = <String, ChallengeProgress>{};

      for (var key in box.keys) {
        try {
          final data = box.get(key);
          if (data == null) continue;

          // 타입 안전성 확보
          final jsonData = data is Map<String, dynamic>
              ? data
              : Map<String, dynamic>.from(data as Map);

          final progress = ChallengeProgress.fromJson(jsonData);
          progressMap[key.toString()] = progress;
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Failed to load progress for key $key: $e');
          }
        }
      }

      _cachedProgress = progressMap;

      if (kDebugMode) {
        debugPrint('📈 Loaded user progress from Hive: ${_cachedProgress!.length} records');
      }

      return _cachedProgress!;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to load user progress: $e');
      }
      // 에러 발생 시에도 빈 Map 반환 (앱 크래시 방지)
      _cachedProgress = <String, ChallengeProgress>{};
      return <String, ChallengeProgress>{};
    }
  }

  /// 사용자 진행 상황 저장 (Hive Box에)
  Future<void> saveUserProgress(ChallengeProgress progress) async {
    try {
      // 🔥 CRITICAL FIX: Hive Box 초기화
      await _initializeProgressBox();

      final currentProgress = await loadUserProgress();
      currentProgress[progress.challengeId] = progress;

      // 🔥 CRITICAL FIX: Hive Box에 저장 (HiveService 패턴 따름)
      await _progressBox!.put(progress.challengeId, progress.toJson());
      await _progressBox!.flush(); // 디스크 동기화 강제

      // 🔥 ULTRA FIX: OS 파일 시스템 캐시가 디스크에 쓸 시간 확보
      await Future.delayed(Duration(milliseconds: 100));

      // 메모리 캐시 업데이트
      _cachedProgress = currentProgress;

      if (kDebugMode) {
        debugPrint('💾 Saved progress to Hive for challenge: ${progress.challengeId} (${progress.status.displayName})');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to save user progress: $e');
      }
      throw Exception('챌린지 진행 상황 저장 실패: $e');
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
    );

    await saveUserProgress(completedProgress);

    if (kDebugMode) {
      debugPrint('🏆 Completed challenge: ${challenge.title}');
    }

    return completedProgress;
  }


  /// 통계 정보 조회
  Future<ChallengeStatistics> getStatistics() async {
    final allChallenges = await loadAllChallenges();
    final userProgress = await loadUserProgress();

    final completedCount = userProgress.values
        .where((progress) => progress.isCompleted)
        .length;

    final inProgressCount = userProgress.values
        .where((progress) => progress.isStarted && !progress.isCompleted)
        .length;

    // 🔥 DEBUG: 실제 카운트 값 로깅
    if (kDebugMode) {
      debugPrint('📊 ChallengeService.getStatistics() 호출됨');
      debugPrint('   총 userProgress 개수: ${userProgress.length}');
      debugPrint('   완료된 챌린지: $completedCount개');
      debugPrint('   진행중인 챌린지: $inProgressCount개');

      // 각 progress의 상태 출력
      debugPrint('   === 모든 챌린지 상태 ===');
      for (var entry in userProgress.entries) {
        final progress = entry.value;
        final isStartedValue = progress.isStarted;
        final isCompletedValue = progress.isCompleted;
        final matchesFilter = isStartedValue && !isCompletedValue;
        debugPrint('   ${entry.key}:');
        debugPrint('      status=${progress.status.displayName}');
        debugPrint('      isStarted=$isStartedValue, isCompleted=$isCompletedValue');
        debugPrint('      진행중 필터 통과=$matchesFilter');
      }
    }

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
      inProgressChallenges: inProgressCount,
      categoryStats: categoryStats,
      completionRate: allChallenges.isNotEmpty
          ? (completedCount / allChallenges.length * 100)
          : 0.0,
    );
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
    _cachedProgress = null;
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
      'user_progress_cached': _cachedProgress?.length ?? 0,
      'cache_valid': _isCacheValid(),
      'last_load_time': _lastLoadTime?.toIso8601String(),
    };
  }
}

/// 챌린지 통계 정보 모델
class ChallengeStatistics {
  final int totalChallenges;
  final int completedChallenges;
  final int inProgressChallenges;
  final Map<ChallengeCategory, int> categoryStats;
  final double completionRate;

  ChallengeStatistics({
    required this.totalChallenges,
    required this.completedChallenges,
    required this.inProgressChallenges,
    required this.categoryStats,
    required this.completionRate,
  });

  @override
  String toString() {
    return 'ChallengeStats{total: $totalChallenges, completed: $completedChallenges, inProgress: $inProgressChallenges, rate: ${completionRate.toStringAsFixed(1)}%}';
  }
}