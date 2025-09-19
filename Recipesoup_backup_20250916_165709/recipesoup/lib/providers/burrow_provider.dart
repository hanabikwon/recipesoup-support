import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/burrow_milestone.dart';
import '../services/burrow_unlock_coordinator.dart';
import '../services/hive_service.dart';
import 'dart:developer' as developer;

/// 토끼굴 마일스톤 시스템 상태 관리 Provider
/// RecipeProvider와 이벤트 기반으로 통합되어 순환 참조 방지
class BurrowProvider extends ChangeNotifier {
  final BurrowUnlockCoordinator _unlockCoordinator;
  
  // 상태 변수들
  List<BurrowMilestone> _milestones = [];
  List<UnlockProgress> _progressList = [];
  bool _isLoading = false;
  String? _error;
  
  // 🔥 ULTRA THINK: RecipeProvider로부터 레시피 데이터 직접 받기 위한 콜백
  List<Recipe> Function()? _getAllRecipesCallback;
  
  // 디바운스 타이머 (성능 최적화)
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 300);
  
  // 언락 알림 큐 (순차 처리용)
  final List<UnlockQueueItem> _pendingNotifications = [];
  bool _isShowingNotification = false;
  
  // 이벤트 스트림 컨트롤러 (RecipeProvider와의 통신용)
  final _recipeEventController = StreamController<RecipeEvent>.broadcast();
  StreamSubscription<RecipeEvent>? _recipeEventSubscription;
  
  /// 생성자
  BurrowProvider({
    required BurrowUnlockCoordinator unlockCoordinator,
  }) : _unlockCoordinator = unlockCoordinator;
  
  // === Getters ===
  
  /// 모든 마일스톤
  List<BurrowMilestone> get milestones => List.unmodifiable(_milestones);
  
  /// 성장 트랙 마일스톤들 (레벨순 정렬)
  List<BurrowMilestone> get growthMilestones => _milestones
      .where((m) => m.isGrowthTrack)
      .toList()
    ..sort((a, b) => a.level.compareTo(b.level));
  
  /// 특별 공간 마일스톤들
  List<BurrowMilestone> get specialMilestones => _milestones
      .where((m) => m.isSpecialRoom && m.isUnlocked)
      .toList();
  
  /// 잠긴 특별 공간들 (숨겨진 진행도 표시용)
  List<BurrowMilestone> get lockedSpecialMilestones => _milestones
      .where((m) => m.isSpecialRoom && !m.isUnlocked)
      .toList();
  
  /// 현재 진행상황들
  List<UnlockProgress> get progressList => List.unmodifiable(_progressList);
  
  /// 로딩 상태
  bool get isLoading => _isLoading;
  
  /// 에러 메시지
  String? get error => _error;
  
  /// 대기 중인 알림 수
  int get pendingNotificationCount => _pendingNotifications.length;
  
  /// 알림 표시 중 여부
  bool get isShowingNotification => _isShowingNotification;
  
  /// 레시피 이벤트 스트림 (RecipeProvider가 구독)
  Stream<RecipeEvent> get recipeEventStream => _recipeEventController.stream;
  
  // === 초기화 및 생명주기 ===
  
  /// 초기화
  Future<void> initialize() async {
    _setLoading(true);

    try {
      // coordinator 초기화
      await _unlockCoordinator.initialize();
      await _loadData();
      _clearError();

      // 🔥 ULTRA THINK: 기존 레시피 기반 특별공간 unlock 재검사
      await _recheckSpecialRoomsForExistingRecipes();

      // 초기화 완료 후 마일스톤 상태 로깅
      developer.log('🔥 INIT DEBUG: BurrowProvider initialized with ${_milestones.length} milestones', name: 'BurrowProvider');

      final growthMilestones = _milestones.where((m) => m.isGrowthTrack).toList();
      developer.log('🔥 INIT DEBUG: Growth milestones: ${growthMilestones.length}', name: 'BurrowProvider');

      for (final milestone in growthMilestones) {
        developer.log('🔥 INIT DEBUG: L${milestone.level}: ${milestone.isUnlocked ? "UNLOCKED" : "LOCKED"} (needs ${milestone.requiredRecipes})', name: 'BurrowProvider');
      }

      developer.log('BurrowProvider initialized successfully', name: 'BurrowProvider');
    } catch (e) {
      _setError('Failed to initialize burrow system: $e');
      developer.log('Failed to initialize BurrowProvider: $e', name: 'BurrowProvider');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 데이터 로드
  Future<void> _loadData() async {
    try {
      _milestones = await _unlockCoordinator.getAllMilestones();
      _progressList = await _unlockCoordinator.getCurrentProgress();

      developer.log('Loaded ${_milestones.length} milestones and ${_progressList.length} progress items',
                   name: 'BurrowProvider');
    } catch (e) {
      developer.log('Failed to load burrow data: $e', name: 'BurrowProvider');
      rethrow;
    }
  }
  
  /// 데이터 새로고침
  Future<void> refresh() async {
    await _loadData();
    _debouncedNotify();
  }
  
  // === 레시피 이벤트 처리 (메인 로직) ===
  
  /// 새 레시피 이벤트 처리 (RecipeProvider에서 호출)
  Future<void> onRecipeAdded(Recipe recipe) async {
    try {
      debugPrint('🚨🚨🚨 BURROW CRITICAL: onRecipeAdded CALLED for: ${recipe.title}');
      developer.log('🔥 BURROW DEBUG: Processing recipe added: ${recipe.id} - ${recipe.title}', name: 'BurrowProvider');
      
      // 중복 방지: 수동 unlock 체크 제거 (BurrowUnlockCoordinator에서 처리)
      debugPrint('🔥 DUPLICATE FIX: Skipping manual unlock check to prevent duplicate popups');
      
      // 현재 마일스톤 상태 로깅
      final currentMilestones = await _unlockCoordinator.getAllMilestones();
      developer.log('🔥 BURROW DEBUG: Current milestones count: ${currentMilestones.length}', name: 'BurrowProvider');
      
      for (final milestone in currentMilestones.where((m) => m.isGrowthTrack)) {
        developer.log('🔥 BURROW DEBUG: Growth milestone L${milestone.level}: ${milestone.isUnlocked ? "UNLOCKED" : "LOCKED"} (needs ${milestone.requiredRecipes} recipes)', name: 'BurrowProvider');
      }
      
      // 마일스톤 언락 체크
      debugPrint('🚨 STEP 1: About to call checkUnlocksForRecipe for: ${recipe.title}');

      final List<BurrowMilestone> newUnlocks = await _unlockCoordinator.checkUnlocksForRecipe(recipe);
      debugPrint('🚨 STEP 2: Coordinator returned ${newUnlocks.length} new unlocks');
      
      developer.log('🔥 BURROW DEBUG: Found ${newUnlocks.length} new unlocks', name: 'BurrowProvider');
      
      if (newUnlocks.isNotEmpty) {
        // 마일스톤 상태 새로고침 (unlock 결과 반영)
        await _loadData();
        
        // 언락된 마일스톤들 상태 확인 로깅
        for (final milestone in _milestones.where((m) => m.isGrowthTrack)) {
          debugPrint('🚨 MILESTONE STATUS: L${milestone.level} = ${milestone.isUnlocked ? "UNLOCKED ✅" : "LOCKED ❌"}');
        }
        
        // 🔥 팝업 수정: newUnlocks에 포함된 모든 마일스톤을 알림 큐에 추가
        for (final unlock in newUnlocks) {
          debugPrint('🔥 POPUP FIX: Adding unlock notification for L${unlock.level}');
          _pendingNotifications.add(UnlockQueueItem(
            milestone: unlock,
            unlockedAt: DateTime.now(),
            triggerRecipeId: recipe.id,
          ));
        }

        // 진행상황 새로고침
        _progressList = await _unlockCoordinator.getCurrentProgress();
        
        developer.log('Added ${newUnlocks.length} unlocks to notification queue', name: 'BurrowProvider');
        
        // 즉시 UI 업데이트 (디바운스 제거)
        notifyListeners();
        debugPrint('🚨 CRITICAL: notifyListeners() called - UI should update now!');
      }
      
    } catch (e) {
      developer.log('Failed to process recipe added: $e', name: 'BurrowProvider');
      // 에러 발생시에도 앱이 계속 작동하도록 에러를 삼킴
    }
  }
  
  /// 레시피 수정 이벤트 처리
  Future<void> onRecipeUpdated(Recipe recipe) async {
    try {
      // 레시피 수정 시에는 새로운 언락 체크는 하지 않음 (중복 방지)
      // 단, 진행상황은 새로고침
      developer.log('Recipe updated, refreshing progress: ${recipe.id}', name: 'BurrowProvider');

      _progressList = await _unlockCoordinator.getCurrentProgress();
      _debouncedNotify();
      
    } catch (e) {
      developer.log('Failed to process recipe updated: $e', name: 'BurrowProvider');
    }
  }
  
  /// 레시피 삭제 이벤트 처리
  Future<void> onRecipeDeleted(String recipeId) async {
    try {
      // 레시피 삭제 시 진행상황 새로고침 (언락은 그대로 유지)
      developer.log('Recipe deleted, refreshing progress: $recipeId', name: 'BurrowProvider');

      _progressList = await _unlockCoordinator.getCurrentProgress();
      _debouncedNotify();
      
    } catch (e) {
      developer.log('Failed to process recipe deleted: $e', name: 'BurrowProvider');
    }
  }
  
  // === 알림 관리 ===
  
  /// 다음 언락 알림 가져오기 (UI에서 호출)
  UnlockQueueItem? getNextNotification() {
    if (_pendingNotifications.isEmpty) return null;
    return _pendingNotifications.removeAt(0);
  }
  
  /// 알림 표시 상태 설정
  void setNotificationShowing(bool isShowing) {
    if (_isShowingNotification != isShowing) {
      _isShowingNotification = isShowing;
      notifyListeners(); // 즉시 알림 (디바운스 없음)
    }
  }
  
  /// 모든 알림 클리어 (테스트용)
  void clearAllNotifications() {
    _pendingNotifications.clear();
    _isShowingNotification = false;
    _debouncedNotify();
  }
  
  // === RecipeProvider 연동 ===
  
  /// RecipeProvider에서 레시피 리스트를 가져오는 콜백 설정
  void setRecipeListCallback(List<Recipe> Function() callback) {
    _getAllRecipesCallback = callback;
    developer.log('Recipe list callback set in BurrowProvider', name: 'BurrowProvider');
  }
  
  /// 레시피 리스트 콜백 getter
  List<Recipe> Function()? get getAllRecipesCallback => _getAllRecipesCallback;
  
  // === 진행도 조회 ===
  
  /// 특정 특별 공간의 진행도 가져오기
  UnlockProgress? getProgressForRoom(SpecialRoom room) {
    try {
      return _progressList.firstWhere((p) => p.roomType == room);
    } catch (e) {
      return null; // 찾지 못함
    }
  }
  
  /// 특정 특별 공간의 진행률 가져오기 (0.0 ~ 1.0)
  double getProgressRateForRoom(SpecialRoom room) {
    final progress = getProgressForRoom(room);
    return progress?.progress ?? 0.0;
  }
  
  /// 특별 공간별 힌트 메시지 가져오기 (숨겨진 조건 노출 없이)
  String getHintForRoom(SpecialRoom room) {
    switch (room) {
      case SpecialRoom.ballroom:
        return '누군가를 위한 요리를 만들어보세요...';
      case SpecialRoom.hotSpring:
        return '힘들 때 위로가 되는 요리들...';
      case SpecialRoom.orchestra:
        return '다양한 감정으로 요리해보세요...';
      case SpecialRoom.alchemyLab:
        return '실패를 두려워하지 마세요...';
      case SpecialRoom.fineDining:
        return '완벽한 요리를 추구해보세요...';
      // 새로 추가된 특별 공간들 (11개)
      case SpecialRoom.alps:
        return '도전적인 복잡한 요리를 만들어보세요...';
      case SpecialRoom.camping:
        return '자연의 재료를 사용해보세요...';
      case SpecialRoom.autumn:
        return '계절의 감성을 담은 요리를...';
      case SpecialRoom.springPicnic:
        return '봄의 기운을 담은 요리를...';
      case SpecialRoom.surfing:
        return '바다의 맛을 요리에 담아보세요...';
      case SpecialRoom.snorkel:
        return '깊은 바다의 신비로운 맛을...';
      case SpecialRoom.summerbeach:
        return '여름 휴양지의 느낌을...';
      case SpecialRoom.baliYoga:
        return '평온하고 건강한 요리를...';
      case SpecialRoom.orientExpress:
        return '여행의 추억을 요리로...';
      case SpecialRoom.canvas:
        return '예술적 감성의 요리를...';
      case SpecialRoom.vacance:
        return '여유로운 휴식의 요리를...';
    }
  }
  
  // === 통계 및 분석 ===
  
  /// 언락된 마일스톤 수
  int get unlockedMilestoneCount => _milestones.where((m) => m.isUnlocked).length;
  
  /// 전체 마일스톤 수
  int get totalMilestoneCount => _milestones.length;
  
  /// 언락 진행률 (0.0 ~ 1.0)
  double get overallProgress => totalMilestoneCount > 0 
      ? unlockedMilestoneCount / totalMilestoneCount 
      : 0.0;
  
  /// 성장 트랙 진행률
  double get growthProgress {
    final growthList = growthMilestones;
    if (growthList.isEmpty) return 0.0;
    final unlockedCount = growthList.where((m) => m.isUnlocked).length;
    return unlockedCount / growthList.length;
  }
  
  /// 특별 공간 언락 수
  int get specialRoomsUnlocked => specialMilestones.length;
  
  // === 상태 관리 헬퍼 ===
  
  /// 디바운스된 알림 (성능 최적화)
  void _debouncedNotify() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      notifyListeners();
    });
  }
  
  /// 로딩 상태 설정 (성능 최적화 이미 적용됨)
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners(); // 로딩 상태는 즉시 알림 (실제 변경시에만)
    }
  }
  
  /// 에러 상태 설정
  void _setError(String message) {
    _error = message;
    _debouncedNotify();
  }
  
  /// 에러 상태 클리어 (성능 최적화)
  bool _clearError() {
    if (_error != null) {
      _error = null;
      return true; // 상태가 실제로 변경됨
    }
    return false; // 상태 변경 없음
  }
  
  /// 공개 에러 클리어 (UI에서 호출)
  void clearError() {
    if (_clearError()) {
      _debouncedNotify(); // 실제로 상태가 변경된 경우에만 알림
    }
  }
  
  // === 테스트용 메서드들 ===
  
  /// 테스트용 에러 설정
  @visibleForTesting
  void setError(String message) {
    _setError(message);
  }
  
  /// 테스트용 마일스톤 추가
  @visibleForTesting
  void addTestMilestone(BurrowMilestone milestone) {
    _milestones.add(milestone);
    _debouncedNotify();
  }
  
  /// 테스트용 진행상황 추가
  @visibleForTesting
  void addTestProgress(UnlockProgress progress) {
    _progressList.add(progress);
    _debouncedNotify();
  }
  
  // === 정리 ===
  
  /// 🔥 ULTRA THINK: 기존 레시피 기반 특별공간 unlock 재검사
  Future<void> _recheckSpecialRoomsForExistingRecipes() async {
    try {
      developer.log('🔥 ULTRA THINK: Starting special rooms recheck for existing recipes...', name: 'BurrowProvider');

      // 1. 기존 모든 레시피 가져오기 (HiveService 직접 호출 또는 콜백 사용)
      List<Recipe> existingRecipes = [];

      if (_getAllRecipesCallback != null) {
        // RecipeProvider 콜백 사용 (더 안전함)
        existingRecipes = _getAllRecipesCallback!();
        developer.log('🔥 ULTRA THINK: Got ${existingRecipes.length} recipes from RecipeProvider callback', name: 'BurrowProvider');
      } else {
        // Coordinator를 통한 조회 (fallback)
        try {
          existingRecipes = await _unlockCoordinator.getAllRecipes();
          developer.log('🔥 ULTRA THINK: Got ${existingRecipes.length} recipes from Coordinator', name: 'BurrowProvider');
        } catch (e) {
          developer.log('🔥 ULTRA THINK: Coordinator recipe access failed: $e', name: 'BurrowProvider');
          return; // 레시피를 가져올 수 없으면 재검사 중단
        }
      }

      if (existingRecipes.isEmpty) {
        developer.log('🔥 ULTRA THINK: No existing recipes found, skipping special rooms recheck', name: 'BurrowProvider');
        return;
      }

      // 2. 각 레시피에 대해 특별공간 unlock 조건 체크
      int totalUnlocks = 0;
      for (final recipe in existingRecipes) {
        try {
          final newUnlocks = await _unlockCoordinator.checkUnlocksForRecipe(recipe);

          if (newUnlocks.isNotEmpty) {
            totalUnlocks += newUnlocks.length as int;
            developer.log('🔥 ULTRA THINK: Recipe "${recipe.title}" triggered ${newUnlocks.length} unlocks', name: 'BurrowProvider');

            for (final milestone in newUnlocks) {
              if (milestone.isSpecialRoom) {
                developer.log('🔥 ULTRA THINK: ✅ UNLOCKED Special Room: ${milestone.specialRoom?.name}', name: 'BurrowProvider');
              }
            }
          }
        } catch (e) {
          developer.log('🔥 ULTRA THINK: Failed to check recipe "${recipe.title}": $e', name: 'BurrowProvider');
          continue; // 개별 레시피 실패 시 다음 레시피 계속 진행
        }
      }

      // 3. 데이터 새로고침 (unlock된 결과 반영)
      if (totalUnlocks > 0) {
        await _loadData();
        developer.log('🔥 ULTRA THINK: ✅ Special rooms recheck completed: $totalUnlocks total unlocks for ${existingRecipes.length} recipes', name: 'BurrowProvider');
        _debouncedNotify(); // UI 업데이트
      } else {
        developer.log('🔥 ULTRA THINK: Special rooms recheck completed: No new unlocks found', name: 'BurrowProvider');
      }

    } catch (e) {
      developer.log('🔥 ULTRA THINK: Special rooms recheck failed: $e', name: 'BurrowProvider');
      // 재검사 실패는 critical하지 않으므로 exception을 다시 throw하지 않음
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _recipeEventController.close();
    _recipeEventSubscription?.cancel();

    developer.log('BurrowProvider disposed', name: 'BurrowProvider');
    super.dispose();
  }
}

/// 레시피 이벤트 타입 (RecipeProvider와의 통신용)
enum RecipeEventType {
  added,
  updated,
  deleted,
}

/// 레시피 이벤트 클래스
class RecipeEvent {
  final RecipeEventType type;
  final Recipe? recipe;
  final String? recipeId;
  final DateTime timestamp;
  
  RecipeEvent({
    required this.type,
    this.recipe,
    this.recipeId,
  }) : timestamp = DateTime.now();
  
  @override
  String toString() => 'RecipeEvent(type: $type, recipeId: ${recipe?.id ?? recipeId})';
}