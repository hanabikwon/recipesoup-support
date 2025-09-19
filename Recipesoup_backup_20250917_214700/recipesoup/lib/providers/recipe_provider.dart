import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:recipesoup/models/recipe.dart';
import 'package:recipesoup/models/mood.dart';
import 'package:recipesoup/services/hive_service.dart';
import 'dart:developer' as developer;

/// 감정 기반 레시피 상태 관리 Provider
/// Recipesoup 앱의 핵심 상태 관리 클래스
class RecipeProvider extends ChangeNotifier {
  final HiveService _hiveService;
  
  // 상태 변수들
  List<Recipe> _recipes = [];
  Recipe? _selectedRecipe;
  bool _isLoading = false;
  String? _error;
  
  // 버로우 시스템 콜백 (순환 참조 방지)
  Function(Recipe)? _onRecipeAdded;
  Function(Recipe)? _onRecipeUpdated;
  Function(String)? _onRecipeDeleted;
  
  // 생성자 - DI를 위한 HiveService 주입
  RecipeProvider({HiveService? hiveService}) 
      : _hiveService = hiveService ?? HiveService() {
    // 🔥 CRITICAL DEBUG: HiveService 인스턴스 상태 로깅
    debugPrint('🔥 RECIPE PROVIDER DEBUG: Using HiveService instance: ${_hiveService.hashCode}');
    developer.log('🔥 RecipeProvider initialized with HiveService: ${_hiveService.hashCode}', name: 'RecipeProvider');
  }
  
  // Getters
  List<Recipe> get recipes => List.unmodifiable(_recipes);
  Recipe? get selectedRecipe => _selectedRecipe;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// "과거 오늘" 기능 - 같은 월/일, 다른 년도 레시피들
  List<Recipe> get todayMemories {
    final today = DateTime.now();
    return _recipes.where((recipe) {
      final recipeDate = recipe.createdAt;
      return recipeDate.month == today.month && 
             recipeDate.day == today.day &&
             recipeDate.year != today.year;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
  
  /// 최근 레시피들 (최신순 정렬)
  List<Recipe> get recentRecipes {
    return List.from(_recipes)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
  
  // === 버로우 시스템 통합 (콜백 기반) ===
  
  /// 버로우 시스템 콜백 설정 (순환 참조 방지)
  void setBurrowCallbacks({
    Function(Recipe)? onRecipeAdded,
    Function(Recipe)? onRecipeUpdated,
    Function(String)? onRecipeDeleted,
  }) {
    _onRecipeAdded = onRecipeAdded;
    _onRecipeUpdated = onRecipeUpdated;
    _onRecipeDeleted = onRecipeDeleted;
    developer.log('Burrow callbacks configured', name: 'RecipeProvider');
  }
  
  /// 모든 레시피 로딩 (안전한 로딩 - 기존 데이터 보존)
  Future<void> loadRecipes() async {
    _setLoading(true);
    
    try {
      final loadedRecipes = await _hiveService.getAllRecipes();
      
      // 🔥 CRITICAL FIX: 로드된 데이터가 유효할 때만 교체
      if (loadedRecipes.isNotEmpty || _recipes.isEmpty) {
        _recipes = loadedRecipes;
        _recipes.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // 최신순 정렬
        _clearError();
        developer.log('Successfully loaded ${_recipes.length} recipes', name: 'RecipeProvider');
      } else {
        // 로드된 데이터가 비어있고 기존 데이터가 있으면 기존 데이터 유지
        developer.log('No recipes loaded, keeping existing ${_recipes.length} recipes', name: 'RecipeProvider');
      }
    } catch (e) {
      _setError('Failed to load recipes: $e');
      developer.log('Failed to load recipes, keeping existing ${_recipes.length} recipes: $e', name: 'RecipeProvider');
      // 🔥 CRITICAL FIX: 에러 발생시 기존 _recipes 데이터 유지 (덮어쓰지 않음)
    } finally {
      _setLoading(false);
    }
  }
  
  /// 새 레시피 추가
  Future<void> addRecipe(Recipe recipe) async {
    try {
      await _hiveService.saveRecipe(recipe);
      
      // 로컬 상태 업데이트 (최신순으로 맨 앞에 추가)
      _recipes.insert(0, recipe);
      _clearError();
      notifyListeners();
      
      // 🔥 CRITICAL FIX: 버로우 시스템 알림 (데이터 확인 후 호출)
      try {
        debugPrint('🔥🔥🔥 RECIPE DEBUG: Starting burrow callback for recipe: ${recipe.title}');
        debugPrint('🔥🔥🔥 RECIPE DEBUG: Burrow callback is ${_onRecipeAdded != null ? "SET" : "NULL"}');
        
        // 🔥 CRITICAL FIX: 데이터 저장 확인 및 재시도 메커니즘
        bool dataVerified = false;
        for (int attempt = 1; attempt <= 5; attempt++) {
          debugPrint('🔥 VERIFICATION ATTEMPT $attempt: Checking if recipe is saved...');
          
          // 더 긴 지연 (박스 동기화 완료 보장)
          await Future.delayed(Duration(milliseconds: 200 * attempt));
          
          try {
            // HiveService를 통해 직접 데이터 확인
            final savedRecipe = await _hiveService.getRecipe(recipe.id);
            if (savedRecipe != null) {
              debugPrint('🔥 SUCCESS: Recipe verified in Hive on attempt $attempt');
              dataVerified = true;
              break;
            } else {
              debugPrint('🔥 RETRY: Recipe not found in Hive, attempt $attempt/5');
            }
          } catch (e) {
            debugPrint('🔥 ERROR in verification attempt $attempt: $e');
          }
        }
        
        if (!dataVerified) {
          debugPrint('🔥 CRITICAL ERROR: Recipe not verified after 5 attempts, calling callback anyway');
          developer.log('CRITICAL: Recipe not verified in Hive after 5 attempts', name: 'RecipeProvider');
        }
        
        // 🔥 CRITICAL FIX: 데이터 확인 후 콜백 호출
        _onRecipeAdded?.call(recipe);
        
        developer.log('🔥 RECIPE DEBUG: Burrow callback completed (data verified: $dataVerified)', name: 'RecipeProvider');
      } catch (burrowError) {
        developer.log('🔥 BURROW ERROR: $burrowError (레시피 저장은 성공)', name: 'RecipeProvider');
        debugPrint('🔥 BURROW ERROR: $burrowError (레시피 저장은 성공)');
      }
      
      developer.log('🔥 RECIPE ADDED SUCCESSFULLY: ${recipe.title} (ID: ${recipe.id})', name: 'RecipeProvider');
    } catch (e) {
      _setError('Failed to add recipe: $e');
      developer.log('🔥 FAILED TO ADD RECIPE: $e', name: 'RecipeProvider');
      // 로컬 상태 롯백 (에러 발생시 레시피 추가 실패)
      _recipes.removeWhere((r) => r.id == recipe.id);
      notifyListeners();
      rethrow; // UI에 에러 전달
    }
  }
  
  /// 레시피 수정
  Future<void> updateRecipe(Recipe updatedRecipe) async {
    try {
      await _hiveService.updateRecipe(updatedRecipe);
      
      // 로컬 상태에서 해당 레시피 찾아서 업데이트
      final index = _recipes.indexWhere((r) => r.id == updatedRecipe.id);
      if (index != -1) {
        _recipes[index] = updatedRecipe;
        
        // 선택된 레시피도 업데이트
        if (_selectedRecipe?.id == updatedRecipe.id) {
          _selectedRecipe = updatedRecipe;
        }
        
        _clearError();
        notifyListeners();
        
        // 버로우 시스템에 알림 (비동기, 에러 발생시에도 레시피 수정은 성공)
        try {
          _onRecipeUpdated?.call(updatedRecipe);
        } catch (burrowError) {
          developer.log('Burrow system error (non-critical): $burrowError', name: 'RecipeProvider');
          // 버로우 시스템 에러는 레시피 수정 성공에 영향을 주지 않음
        }
        
        developer.log('Updated recipe: ${updatedRecipe.title}', name: 'RecipeProvider');
      }
    } catch (e) {
      _setError('Failed to update recipe: $e');
      developer.log('Failed to update recipe: $e', name: 'RecipeProvider');
    }
  }
  
  /// 레시피 삭제
  Future<void> deleteRecipe(String recipeId) async {
    try {
      await _hiveService.deleteRecipe(recipeId);
      
      // 로컬 상태에서 제거
      _recipes.removeWhere((r) => r.id == recipeId);
      
      // 선택된 레시피가 삭제된 레시피라면 선택 해제
      if (_selectedRecipe?.id == recipeId) {
        _selectedRecipe = null;
      }
      
      _clearError();
      notifyListeners();
      
      // 버로우 시스템에 알림 (비동기, 에러 발생시에도 레시피 삭제는 성공)
      try {
        _onRecipeDeleted?.call(recipeId);
      } catch (burrowError) {
        developer.log('Burrow system error (non-critical): $burrowError', name: 'RecipeProvider');
        // 버로우 시스템 에러는 레시피 삭제 성공에 영향을 주지 않음
      }
      
      developer.log('Deleted recipe: $recipeId', name: 'RecipeProvider');
    } catch (e) {
      _setError('Failed to delete recipe: $e');
      developer.log('Failed to delete recipe: $e', name: 'RecipeProvider');
    }
  }
  
  /// 레시피 검색 - 제목 기반 + 감정 필터
  List<Recipe> searchRecipes(String query, {Mood? mood}) {
    return _recipes.where((recipe) {
      // 제목 검색 (대소문자 무시)
      final matchesTitle = query.isEmpty || 
          recipe.title.toLowerCase().contains(query.toLowerCase());
      
      // 감정 필터
      final matchesMood = mood == null || recipe.mood == mood;
      
      return matchesTitle && matchesMood;
    }).toList();
  }
  
  /// 태그별 레시피 검색
  List<Recipe> searchByTag(String tag) {
    return _recipes.where((recipe) => 
        recipe.tags.any((t) => t.toLowerCase().contains(tag.toLowerCase()))
    ).toList();
  }
  
  /// 즐겨찾기 레시피들
  List<Recipe> get favoriteRecipes {
    return _recipes.where((recipe) => recipe.isFavorite).toList();
  }
  
  /// 특정 감정의 레시피들
  List<Recipe> getRecipesByMood(Mood mood) {
    return _recipes.where((recipe) => recipe.mood == mood).toList();
  }
  
  /// 레시피 선택
  void selectRecipe(Recipe recipe) {
    _selectedRecipe = recipe;
    notifyListeners();
    developer.log('Selected recipe: ${recipe.title}', name: 'RecipeProvider');
  }
  
  /// 선택 해제
  void clearSelection() {
    _selectedRecipe = null;
    notifyListeners();
    developer.log('Cleared recipe selection', name: 'RecipeProvider');
  }
  
  /// 즐겨찾기 토글
  Future<void> toggleFavorite(String recipeId) async {
    final recipe = _recipes.firstWhere((r) => r.id == recipeId);
    final updatedRecipe = recipe.copyWith(isFavorite: !recipe.isFavorite);
    await updateRecipe(updatedRecipe);
  }
  
  /// 에러 상태 설정 (private)
  void _setError(String message) {
    _error = message;
    notifyListeners();
  }
  
  /// 에러 상태 클리어
  void clearError() {
    _clearError();
  }
  
  /// 에러 상태 클리어 (private)
  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
  
  /// 로딩 상태 설정 (private)
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }
  
  /// 모든 레시피 삭제 (데이터 정리용)
  Future<void> clearAllRecipes() async {
    try {
      await _hiveService.clearAllRecipes();
      _recipes.clear();
      _selectedRecipe = null;
      _clearError();
      notifyListeners();
      developer.log('All recipes cleared from provider', name: 'RecipeProvider');
    } catch (e) {
      _setError('Failed to clear all recipes: $e');
      developer.log('Failed to clear all recipes: $e', name: 'RecipeProvider');
    }
  }

  /// 테스트용 에러 설정 (public)
  @visibleForTesting
  void setError(String message) {
    _setError(message);
  }
  
  /// Provider 정리
  @override
  void dispose() {
    developer.log('RecipeProvider disposed', name: 'RecipeProvider');
    super.dispose();
  }
}