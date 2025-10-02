import 'package:flutter/foundation.dart';
import '../models/challenge_models.dart';
import '../services/challenge_service.dart';
import '../services/cooking_method_service.dart';

/// 깡총 챌린지 시스템 상태 관리 Provider
/// ChallengeService와 연동하여 UI 상태를 관리하는 핵심 Provider
class ChallengeProvider extends ChangeNotifier {
  // 서비스 인스턴스
  final ChallengeService _challengeService = ChallengeService();

  // 상태 변수들
  List<Challenge> _allChallenges = [];
  Map<String, ChallengeProgress> _userProgress = {};
  ChallengeStatistics? _statistics;

  bool _isLoading = false;
  String? _error;

  // 필터링 및 정렬 상태
  ChallengeCategory? _selectedCategory;
  int? _selectedDifficulty;
  String _searchQuery = '';
  ChallengeSortType _sortType = ChallengeSortType.recommended;

  // Getters
  List<Challenge> get allChallenges => _allChallenges;
  Map<String, ChallengeProgress> get userProgress => _userProgress;
  ChallengeStatistics? get statistics => _statistics;
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  ChallengeCategory? get selectedCategory => _selectedCategory;
  int? get selectedDifficulty => _selectedDifficulty;
  String get searchQuery => _searchQuery;
  ChallengeSortType get sortType => _sortType;

  /// 필터링된 챌린지 목록
  List<Challenge> get filteredChallenges {
    var challenges = _allChallenges.where((challenge) {
      // 카테고리 필터
      if (_selectedCategory != null && challenge.category != _selectedCategory) {
        return false;
      }
      
      // 난이도 필터
      if (_selectedDifficulty != null && challenge.difficulty != _selectedDifficulty) {
        return false;
      }
      
      // 검색어 필터
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return challenge.title.toLowerCase().contains(query) ||
               challenge.description.toLowerCase().contains(query) ||
               challenge.mainIngredients.any((ingredient) => 
                   ingredient.toLowerCase().contains(query)) ||
               challenge.tags.any((tag) => 
                   tag.toLowerCase().contains(query));
      }
      
      return true;
    }).toList();

    // 정렬 적용
    switch (_sortType) {
      case ChallengeSortType.recommended:
        // 추천순: 미완료 + 난이도 순
        challenges.sort((a, b) {
          final aCompleted = _userProgress[a.id]?.isCompleted ?? false;
          final bCompleted = _userProgress[b.id]?.isCompleted ?? false;
          
          if (aCompleted != bCompleted) {
            return aCompleted ? 1 : -1; // 미완료가 먼저
          }
          
          return a.difficulty.compareTo(b.difficulty); // 쉬운 것부터
        });
        break;
        
      case ChallengeSortType.difficulty:
        challenges.sort((a, b) => a.difficulty.compareTo(b.difficulty));
        break;
        
      case ChallengeSortType.timeAsc:
        challenges.sort((a, b) => a.estimatedMinutes.compareTo(b.estimatedMinutes));
        break;
        
      case ChallengeSortType.timeDesc:
        challenges.sort((a, b) => b.estimatedMinutes.compareTo(a.estimatedMinutes));
        break;
        
      case ChallengeSortType.points:
        // 포인트 시스템이 제거되었으므로 제목순으로 정렬
        challenges.sort((a, b) => a.title.compareTo(b.title));
        break;
        
      case ChallengeSortType.alphabetical:
        challenges.sort((a, b) => a.title.compareTo(b.title));
        break;
    }

    return challenges;
  }

  /// 추천 챌린지 (홈 화면용)
  List<Challenge> get recommendedChallenges {
    if (_allChallenges.isEmpty) return [];
    
    // 미완료 챌린지 중에서 추천
    final incomplete = _allChallenges.where((challenge) {
      final progress = _userProgress[challenge.id];
      return progress == null || !progress.isCompleted;
    }).toList();
    
    // 각 카테고리에서 1개씩, 난이도 1-2 우선
    final recommendations = <Challenge>[];
    
    for (var category in ChallengeCategory.values) {
      final categoryEasy = incomplete
          .where((c) => c.category == category && c.difficulty <= 2)
          .take(1)
          .toList();
      recommendations.addAll(categoryEasy);
      
      if (recommendations.length >= 3) break;
    }
    
    return recommendations.take(3).toList();
  }


  /// 초기 데이터 로드
  Future<void> loadInitialData() async {
    if (_isLoading) return;
    
    _setLoading(true);
    _clearError();
    
    try {
      // 병렬로 데이터 로드
      final futures = await Future.wait([
        _challengeService.loadAllChallenges(),
        _challengeService.loadUserProgress(),
      ]);

      _allChallenges = futures[0] as List<Challenge>;
      _userProgress = futures[1] as Map<String, ChallengeProgress>;

      // 통계 업데이트
      await _updateStatistics();

      if (kDebugMode) {
        debugPrint('✅ ChallengeProvider initialized:');
        debugPrint('  📋 Challenges: ${_allChallenges.length}');
        debugPrint('  📈 User Progress: ${_userProgress.length}');
      }
    } catch (e) {
      _setError('챌린지 데이터 로드 실패: $e');
      if (kDebugMode) {
        if (kDebugMode) {
          debugPrint('❌ Failed to load challenge data: $e');
        }
      }
    } finally {
      _setLoading(false);
    }
  }

  /// 챌린지 시작
  Future<bool> startChallenge(String challengeId) async {
    try {
      _clearError();

      final progress = await _challengeService.startChallenge(challengeId);
      _userProgress[challengeId] = progress;

      // 통계 업데이트 (진행중 개수 변경)
      await _refreshUserData();

      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// 챌린지 완료
  Future<bool> completeChallenge(
    String challengeId, {
    String? userNote,
    String? userImagePath,
    int? userRating,
    List<String>? completionPhotos,
  }) async {
    try {
      _clearError();

      final progress = await _challengeService.completeChallenge(
        challengeId,
        userNote: userNote,
        userImagePath: userImagePath,
        userRating: userRating,
      );

      _userProgress[challengeId] = progress;

      // 통계 업데이트 (await 완료 후 notifyListeners)
      await _refreshUserData();

      // 통계 업데이트 완료 후 UI 업데이트
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// 챌린지 포기
  Future<bool> abandonChallenge(String challengeId) async {
    try {
      _clearError();
      
      final currentProgress = _userProgress[challengeId];
      if (currentProgress != null) {
        final abandonedProgress = currentProgress.abandon();
        await _challengeService.saveUserProgress(abandonedProgress);
        _userProgress[challengeId] = abandonedProgress;
        
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// 챌린지 재시작
  Future<bool> restartChallenge(String challengeId) async {
    try {
      _clearError();
      
      final currentProgress = _userProgress[challengeId];
      if (currentProgress != null) {
        final restartedProgress = currentProgress.restart();
        await _challengeService.saveUserProgress(restartedProgress);
        _userProgress[challengeId] = restartedProgress;
        
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// 챌린지 진행 상태 업데이트 (단계별 진행 시 사용)
  Future<bool> updateChallengeProgress(
    String challengeId, {
    int? currentStep,
    int? rating,
    String? review,
  }) async {
    try {
      _clearError();
      
      final currentProgress = _userProgress[challengeId];
      if (currentProgress != null && (currentProgress.isInProgress || currentProgress.isCompleted)) {
        final updatedProgress = currentProgress.copyWith(
          currentStep: currentStep,
          userRating: rating,
          userNote: review,
        );
        
        await _challengeService.saveUserProgress(updatedProgress);
        _userProgress[challengeId] = updatedProgress;
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// 카테고리 필터 설정
  void setCategory(ChallengeCategory? category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  /// 난이도 필터 설정
  void setDifficulty(int? difficulty) {
    if (_selectedDifficulty != difficulty) {
      _selectedDifficulty = difficulty;
      notifyListeners();
    }
  }

  /// 검색어 설정
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  /// 정렬 방식 설정
  void setSortType(ChallengeSortType sortType) {
    if (_sortType != sortType) {
      _sortType = sortType;
      notifyListeners();
    }
  }

  /// 모든 필터 초기화
  void clearFilters() {
    bool changed = false;
    
    if (_selectedCategory != null) {
      _selectedCategory = null;
      changed = true;
    }
    
    if (_selectedDifficulty != null) {
      _selectedDifficulty = null;
      changed = true;
    }
    
    if (_searchQuery.isNotEmpty) {
      _searchQuery = '';
      changed = true;
    }
    
    if (_sortType != ChallengeSortType.recommended) {
      _sortType = ChallengeSortType.recommended;
      changed = true;
    }
    
    if (changed) {
      notifyListeners();
    }
  }

  /// 특정 챌린지 조회
  Challenge? getChallengeById(String challengeId) {
    try {
      return _allChallenges.firstWhere((challenge) => challenge.id == challengeId);
    } catch (e) {
      return null;
    }
  }

  /// 챌린지 진행 상황 조회
  ChallengeProgress? getProgressById(String challengeId) {
    return _userProgress[challengeId];
  }

  /// 데이터 새로고침
  Future<void> refresh() async {
    await loadInitialData();
  }

  /// 사용자 데이터 업데이트 (통계)
  Future<void> _refreshUserData() async {
    try {
      _statistics = await _challengeService.getStatistics();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to refresh user data: $e');
      }
    }
  }

  /// 통계 업데이트
  Future<void> _updateStatistics() async {
    try {
      _statistics = await _challengeService.getStatistics();
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) {
          debugPrint('⚠️ Failed to update statistics: $e');
        }
      }
    }
  }

  /// 로딩 상태 설정
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// 에러 설정
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// 에러 클리어
  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// 캐시 클리어
  void clearCache() {
    _challengeService.clearCache();
    _allChallenges.clear();
    _userProgress.clear();
    _statistics = null;
    clearFilters();

    if (kDebugMode) {
      debugPrint('🗑️ ChallengeProvider cache cleared');
    }
  }

  /// 🔥 특정 챌린지의 조리법 단계 가져오기 (UI용)
  Future<List<String>> getCookingSteps(String challengeId) async {
    try {
      // ChallengeService를 통해 조리법 단계 로드
      final cookingSteps = await _challengeService.getCookingSteps(challengeId);
      
      if (kDebugMode && cookingSteps.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('🍳 Loaded ${cookingSteps.length} cooking steps for challenge: $challengeId');
        }
      }
      
      return cookingSteps;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) {
          debugPrint('❌ Failed to get cooking steps for $challengeId: $e');
        }
      }
      return [];
    }
  }

  /// 🔥 특정 챌린지의 전체 조리법 정보 가져오기 (DetailedCookingMethod 반환)
  Future<DetailedCookingMethod?> getCookingMethodDetails(String challengeId) async {
    try {
      // CookingMethodService를 통해 상세 조리법 로드
      final cookingMethodService = CookingMethodService();
      final cookingMethod = await cookingMethodService.getCookingMethodById(challengeId);

      if (kDebugMode && cookingMethod != null) {
        debugPrint('✅ Loaded cooking method details for challenge: $challengeId');
      }

      return cookingMethod;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to get cooking method details for $challengeId: $e');
      }
      return null;
    }
  }

  /// 디버그 정보
  Map<String, dynamic> getDebugInfo() {
    return {
      'total_challenges': _allChallenges.length,
      'user_progress_count': _userProgress.length,
      'is_loading': _isLoading,
      'has_error': _error != null,
      'error': _error,
      'selected_category': _selectedCategory?.displayName,
      'selected_difficulty': _selectedDifficulty,
      'search_query': _searchQuery,
      'sort_type': _sortType.toString(),
      'filtered_count': filteredChallenges.length,
      'service_status': _challengeService.getServiceStatus(),
    };
  }
}

/// 챌린지 정렬 타입
enum ChallengeSortType {
  recommended('추천순'),
  difficulty('난이도순'),
  timeAsc('시간 짧은순'),
  timeDesc('시간 긴순'),
  points('포인트순'),
  alphabetical('가나다순');

  const ChallengeSortType(this.displayName);
  final String displayName;
}