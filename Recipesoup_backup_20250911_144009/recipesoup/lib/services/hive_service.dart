import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'dart:async';
import 'package:hive/hive.dart';
import '../models/recipe.dart';
import '../models/mood.dart';

/// Hive JSON-based local storage service (싱글톤)
class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService({String? boxName}) => _instance;
  
  HiveService._internal() : _recipeBoxName = 'recipes';
  
  final String _recipeBoxName;
  
  Box<Map<String, dynamic>>? _recipeBox;
  
  // 🔥 CRITICAL FIX: 동기화를 위한 뮤텍스
  final Completer<void> _initCompleter = Completer<void>();
  bool _isInitialized = false;
  bool _isInitializing = false;

  Future<void> _initializeBox() async {
    // 🔥 CRITICAL FIX: 이미 초기화 중이면 기다림 (동기화)
    if (_isInitializing) {
      await _initCompleter.future;
      return;
    }
    
    if (_isInitialized && _recipeBox != null && _recipeBox!.isOpen) {
      developer.log('📦 SINGLETON: Box already initialized and open (${_instance.hashCode})', name: 'Hive Service');
      return;
    }
    
    _isInitializing = true;
    
    try {
      // 🔥 CRITICAL FIX: 기존 박스가 있으면 먼저 닫기
      if (_recipeBox != null && _recipeBox!.isOpen) {
        await _recipeBox!.close();
        developer.log('📦 SINGLETON: Closed existing box', name: 'Hive Service');
      }
      
      // 🔥 CRITICAL FIX: 완전히 새로운 박스 인스턴스 생성
      _recipeBox = await Hive.openBox<Map<String, dynamic>>(_recipeBoxName);
      
      developer.log('📦 SINGLETON: Recipe Box initialized successfully (instance: ${_instance.hashCode}, box: ${_recipeBox.hashCode}, length: ${_recipeBox!.length})', name: 'Hive Service');
      
      _isInitialized = true;
      _isInitializing = false;
      
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
      
    } catch (e) {
      _isInitializing = false;
      if (!_initCompleter.isCompleted) {
        _initCompleter.completeError(e);
      }
      developer.log('Failed to initialize Recipe Box: $e', name: 'Hive Service');
      rethrow;
    }
  }

  Future<Box<Map<String, dynamic>>> get _box async {
    // 🔥 CRITICAL FIX: 안전한 박스 접근 보장
    if (!_isInitialized || _recipeBox == null || !_recipeBox!.isOpen) {
      await _initializeBox();
    }
    
    // 🔥 CRITICAL FIX: 박스 상태 재확인
    if (_recipeBox == null || !_recipeBox!.isOpen) {
      throw Exception('Recipe box is not available after initialization');
    }
    
    return _recipeBox!;
  }

  // Basic CRUD operations
  Future<void> saveRecipe(Recipe recipe) async {
    try {
      final box = await _box;
      
      // 🔥 ULTRA DEBUG: Box 상태 상세 로깅
      debugPrint('🔥 SAVE DEBUG: HiveService instance: ${_instance.hashCode}');
      debugPrint('🔥 SAVE DEBUG: Box hashCode: ${box.hashCode}');
      debugPrint('🔥 SAVE DEBUG: Box isOpen: ${box.isOpen}');
      debugPrint('🔥 SAVE DEBUG: Box length BEFORE save: ${box.length}');
      debugPrint('🔥 SAVE DEBUG: Box name: ${box.name}');
      debugPrint('🔥 SAVE DEBUG: Box path: ${box.path}');
      
      // 🔥 CRITICAL FIX: 데이터 저장
      await box.put(recipe.id, recipe.toJson());
      
      debugPrint('🔥 SAVE DEBUG: Box length AFTER save: ${box.length}');
      
      // 🔥 CRITICAL FIX: 명시적 디스크 동기화 (이것이 핵심!)
      await box.flush(); // 메모리에서 디스크로 강제 쓰기
      await box.compact(); // 데이터 압축 및 디스크 반영 보장
      
      debugPrint('🔥 SAVE DEBUG: Box length AFTER flush/compact: ${box.length}');
      
      // 🔥 CRITICAL FIX: 저장 후 데이터 존재 확인
      final savedData = box.get(recipe.id);
      if (savedData == null) {
        throw Exception('Recipe was not saved properly to Hive');
      }
      
      debugPrint('🔥 SAVE SUCCESS: Recipe ${recipe.id} saved to box ${box.hashCode}');
      developer.log('📦 SINGLETON: Recipe saved and verified: ${recipe.id} (instance: ${_instance.hashCode}, box: ${box.hashCode}, size: ${box.length})', name: 'Hive Service');
      
    } catch (e) {
      developer.log('Failed to save recipe: $e', name: 'Hive Service');
      throw Exception('Failed to save recipe: $e');
    }
  }

  Future<Recipe?> getRecipe(String id) async {
    try {
      final box = await _box;
      final jsonData = box.get(id);
      if (jsonData == null) return null;
      return Recipe.fromJson(jsonData);
    } catch (e) {
      developer.log('Failed to get recipe: $e', name: 'Hive Service');
      return null;
    }
  }

  Future<void> updateRecipe(Recipe recipe) async {
    try {
      final box = await _box;
      
      await box.put(recipe.id, recipe.toJson());
      
      // 🔥 CRITICAL FIX: 데이터 동기화
      await box.flush();
      await box.compact();
      
      developer.log('Recipe updated and flushed: ${recipe.id}', name: 'Hive Service');
    } catch (e) {
      developer.log('Failed to update recipe: $e', name: 'Hive Service');
      throw Exception('Failed to update recipe: $e');
    }
  }

  Future<void> deleteRecipe(String id) async {
    try {
      final box = await _box;
      await box.delete(id);
      developer.log('Recipe deleted: $id', name: 'Hive Service');
    } catch (e) {
      developer.log('Failed to delete recipe: $e', name: 'Hive Service');
    }
  }

  // Multiple recipe operations
  Future<List<Recipe>> getAllRecipes() async {
    try {
      final box = await _box;
      
      // 🔥 ULTRA DEBUG: Box 상태 상세 로깅
      debugPrint('🔥 READ DEBUG: HiveService instance: ${_instance.hashCode}');
      debugPrint('🔥 READ DEBUG: Box hashCode: ${box.hashCode}');
      debugPrint('🔥 READ DEBUG: Box isOpen: ${box.isOpen}');
      debugPrint('🔥 READ DEBUG: Box length: ${box.length}');
      debugPrint('🔥 READ DEBUG: Box name: ${box.name}');
      debugPrint('🔥 READ DEBUG: Box path: ${box.path}');
      
      // 🔥 ULTRA DEBUG: Box 내용 직접 확인
      debugPrint('🔥 READ DEBUG: Box keys: ${box.keys.toList()}');
      if (box.length > 0) {
        debugPrint('🔥 READ DEBUG: First few keys: ${box.keys.take(3).toList()}');
      }
      
      // 🔥 CRITICAL FIX: 안전한 레시피 파싱 (개별 에러 처리)
      final recipes = <Recipe>[];
      int parseErrors = 0;
      
      for (final entry in box.toMap().entries) {
        try {
          final jsonData = entry.value;
          debugPrint('🔥 PARSING DEBUG: Processing entry ${entry.key} of type ${jsonData.runtimeType}');
          
          // Map<dynamic, dynamic>을 Map<String, dynamic>으로 안전하게 변환
          final Map<String, dynamic> safeJsonData = Map<String, dynamic>.from(jsonData);
          final recipe = Recipe.fromJson(safeJsonData);
          recipes.add(recipe);
          debugPrint('✅ PARSED: Successfully parsed recipe "${recipe.title}"');
        } catch (e) {
          debugPrint('❌ PARSE ERROR: Failed to parse entry ${entry.key}: $e');
          debugPrint('❌ PARSE ERROR: Data type: ${entry.value.runtimeType}');
          debugPrint('❌ PARSE ERROR: Data preview: ${entry.value.toString().substring(0, 100)}...');
          parseErrors++;
        }
      }
      
      recipes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      debugPrint('🔥 READ RESULT: Found $recipes.length valid recipes in box $box.hashCode ($parseErrors parse errors)');
      developer.log('📦 SINGLETON: getAllRecipes called (instance: $_instance.hashCode, box size: $box.length, valid recipes: $recipes.length, parse errors: $parseErrors)', name: 'Hive Service');
      
      return recipes;
    } catch (e) {
      debugPrint('❌ CRITICAL ERROR in getAllRecipes: $e');
      developer.log('Failed to get all recipes: $e', name: 'Hive Service');
      return [];
    }
  }

  Future<void> saveRecipes(List<Recipe> recipes) async {
    try {
      final box = await _box;
      final recipeMap = {
        for (var recipe in recipes) recipe.id: recipe.toJson()
      };
      await box.putAll(recipeMap);
      
      // 🔥 CRITICAL FIX: 일괄 저장 후 동기화
      await box.flush();
      await box.compact();
      
      developer.log('${recipes.length} recipes saved in batch and flushed', name: 'Hive Service');
    } catch (e) {
      developer.log('Failed to save recipes in batch: $e', name: 'Hive Service');
      throw Exception('Failed to save recipes in batch: $e');
    }
  }

  Future<int> getRecipesCount() async {
    try {
      final box = await _box;
      return box.length;
    } catch (e) {
      developer.log('Failed to get recipes count: $e', name: 'Hive Service');
      return 0;
    }
  }

  // Date-based search
  Future<List<Recipe>> getRecipesByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final allRecipes = await getAllRecipes();
      
      return allRecipes.where((recipe) {
        final recipeDate = recipe.createdAt;
        return recipeDate.isAfter(startDate.subtract(Duration(seconds: 1))) &&
               recipeDate.isBefore(endDate.add(Duration(seconds: 1)));
      }).toList();
    } catch (e) {
      developer.log('Failed to get recipes by date range: $e', name: 'Hive Service');
      return [];
    }
  }

  Future<List<Recipe>> getPastTodayRecipes(DateTime today) async {
    try {
      final allRecipes = await getAllRecipes();
      
      return allRecipes.where((recipe) {
        final recipeDate = recipe.createdAt;
        return recipeDate.month == today.month &&
               recipeDate.day == today.day &&
               recipeDate.year != today.year;
      }).toList();
    } catch (e) {
      developer.log('Failed to get past today recipes: $e', name: 'Hive Service');
      return [];
    }
  }

  // Mood-based functionality
  Future<List<Recipe>> getRecipesByMood(Mood mood) async {
    try {
      final allRecipes = await getAllRecipes();
      return allRecipes.where((recipe) => recipe.mood == mood).toList();
    } catch (e) {
      developer.log('Failed to get recipes by mood: $e', name: 'Hive Service');
      return [];
    }
  }

  Future<Map<Mood, int>> getMoodDistribution() async {
    try {
      final allRecipes = await getAllRecipes();
      final distribution = <Mood, int>{};
      
      for (final recipe in allRecipes) {
        distribution[recipe.mood] = (distribution[recipe.mood] ?? 0) + 1;
      }
      
      return distribution;
    } catch (e) {
      developer.log('Failed to get mood distribution: $e', name: 'Hive Service');
      return {};
    }
  }

  // Tag-based search
  Future<List<Recipe>> searchRecipesByTag(String tag) async {
    try {
      final allRecipes = await getAllRecipes();
      return allRecipes.where((recipe) => recipe.tags.contains(tag)).toList();
    } catch (e) {
      developer.log('Failed to search recipes by tag: $e', name: 'Hive Service');
      return [];
    }
  }

  Future<List<Recipe>> searchRecipesByTags(List<String> tags) async {
    try {
      final allRecipes = await getAllRecipes();
      return allRecipes.where((recipe) {
        return tags.every((tag) => recipe.tags.contains(tag));
      }).toList();
    } catch (e) {
      developer.log('Failed to search recipes by tags: $e', name: 'Hive Service');
      return [];
    }
  }

  Future<Map<String, int>> getTagFrequency() async {
    try {
      final allRecipes = await getAllRecipes();
      final frequency = <String, int>{};
      
      for (final recipe in allRecipes) {
        for (final tag in recipe.tags) {
          frequency[tag] = (frequency[tag] ?? 0) + 1;
        }
      }
      
      return frequency;
    } catch (e) {
      developer.log('Failed to get tag frequency: $e', name: 'Hive Service');
      return {};
    }
  }

  // Search and filtering
  Future<List<Recipe>> searchRecipesByTitle(String keyword) async {
    try {
      final allRecipes = await getAllRecipes();
      return allRecipes.where((recipe) {
        return recipe.title.toLowerCase().contains(keyword.toLowerCase());
      }).toList();
    } catch (e) {
      developer.log('Failed to search recipes by title: $e', name: 'Hive Service');
      return [];
    }
  }

  Future<List<Recipe>> searchRecipesByEmotionalStory(String keyword) async {
    try {
      final allRecipes = await getAllRecipes();
      return allRecipes.where((recipe) {
        return recipe.emotionalStory.toLowerCase().contains(keyword.toLowerCase());
      }).toList();
    } catch (e) {
      developer.log('Failed to search recipes by emotional story: $e', name: 'Hive Service');
      return [];
    }
  }

  Future<List<Recipe>> getFavoriteRecipes() async {
    try {
      final allRecipes = await getAllRecipes();
      return allRecipes.where((recipe) => recipe.isFavorite).toList();
    } catch (e) {
      developer.log('Failed to get favorite recipes: $e', name: 'Hive Service');
      return [];
    }
  }

  // Data management
  Future<void> clearAllRecipes() async {
    try {
      final box = await _box;
      await box.clear();
      developer.log('All recipes cleared', name: 'Hive Service');
    } catch (e) {
      developer.log('Failed to clear all recipes: $e', name: 'Hive Service');
      throw Exception('Failed to clear all recipes: $e');
    }
  }

  Future<void> dispose() async {
    try {
      if (_recipeBox != null && _recipeBox!.isOpen) {
        await _recipeBox!.close();
        developer.log('Recipe Box closed', name: 'Hive Service');
      }
    } catch (e) {
      developer.log('Failed to close Recipe Box: $e', name: 'Hive Service');
    }
  }
}