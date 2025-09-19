import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'dart:async';
import 'dart:convert'; // 🔥 ULTRA THINK: JSON 직렬화로 100% 안전한 타입 변환
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
      
      debugPrint('🔥 READ DEBUG: HiveService instance: ${hashCode}');
      debugPrint('🔥 READ DEBUG: Box hashCode: ${box.hashCode}');
      debugPrint('🔥 READ DEBUG: Box isOpen: ${box.isOpen}');
      debugPrint('🔥 READ DEBUG: Box length: ${box.length}');
      debugPrint('🔥 READ DEBUG: Box name: ${box.name}');
      debugPrint('🔥 READ DEBUG: Box path: ${box.path}');
      debugPrint('🔥 READ DEBUG: Box keys: ${box.keys.take(20).toList()}');
      debugPrint('🔥 READ DEBUG: First few keys: ${box.keys.take(3).toList()}');

      List<Recipe> recipes = [];
      int parseErrors = 0;
      int successfulParsing = 0;
      List<dynamic> corruptedKeys = [];

      debugPrint('🔥 CRITICAL DEBUG: About to start processing entries');
      debugPrint('🔥 CRITICAL DEBUG: Got ${box.keys.length} keys from box');
      debugPrint('🔥 CRITICAL DEBUG: About to iterate keys directly');

      // 🔥 ULTRA THINK: Ultra defensive processing with legacy data handling
      for (final key in box.keys) {
        try {
          debugPrint('🔥 ENTRY DEBUG: Processing key $key');
          
          final rawData = box.get(key);
          if (rawData == null) {
            debugPrint('⚠️ SKIP DEBUG: Key $key has null data');
            continue;
          }

          // 🔥 ULTRA THINK: Ultra defensive JSON handling with multiple fallbacks
          Map<String, dynamic> safeJsonData;
          try {
            // First attempt: Standard JSON approach
            safeJsonData = Map<String, dynamic>.from(
              json.decode(json.encode(rawData))
            );
            debugPrint('✅ JSON SUCCESS: Standard JSON conversion for key $key');
          } catch (jsonError) {
            debugPrint('❌ JSON SERIALIZATION ERROR for key $key: $jsonError');
            try {
              // Second attempt: Direct casting if it's already a map
              if (rawData is Map) {
                safeJsonData = Map<String, dynamic>.from(rawData);
                debugPrint('✅ DIRECT CAST SUCCESS: Direct map conversion for key $key');
              } else {
                throw Exception('Data is not a Map: ${rawData.runtimeType}');
              }
            } catch (castError) {
              debugPrint('❌ DIRECT CAST ERROR for key $key: $castError');
              
              // 🔥 ULTRA THINK: If all conversion attempts fail, mark as corrupted
              debugPrint('🚨 MARKING AS CORRUPTED: Key $key (type: ${rawData.runtimeType})');
              corruptedKeys.add(key);
              parseErrors++;
              continue;
            }
          }

          // 🔥 ULTRA THINK: Try to create Recipe from processed data
          try {
            final recipe = Recipe.fromJson(safeJsonData);
            recipes.add(recipe);
            successfulParsing++;
            debugPrint('✅ SUCCESS: Parsed recipe for key $key: ${recipe.title}');
          } catch (recipeError) {
            debugPrint('❌ RECIPE PARSE ERROR for key $key: $recipeError');
            corruptedKeys.add(key);
            parseErrors++;
          }
          
        } catch (e) {
          debugPrint('❌ GENERAL PARSE ERROR: Failed to parse key $key: $e');
          corruptedKeys.add(key);
          parseErrors++;
        }
      }

      debugPrint('🔥 PARSING SUMMARY: Success: $successfulParsing, Errors: $parseErrors, Corrupted Keys: ${corruptedKeys.length}');

      // 🔥 ULTRA THINK: Enhanced surgical emergency recovery
      if (corruptedKeys.isNotEmpty) {
        debugPrint('🚨 ENHANCED SURGICAL RECOVERY: Found ${corruptedKeys.length} corrupted entries to remove');
        debugPrint('🚨 CORRUPTED KEYS: ${corruptedKeys.take(10).join(", ")}${corruptedKeys.length > 10 ? "..." : ""}');
        
        try {
          int deletedCount = 0;
          int boxLengthBefore = box.length;
          
          for (final corruptedKey in corruptedKeys) {
            try {
              if (box.containsKey(corruptedKey)) {
                await box.delete(corruptedKey);
                deletedCount++;
                debugPrint('🔥 DELETED: Successfully removed corrupted key: $corruptedKey');
              } else {
                debugPrint('⚠️ SKIP DELETE: Key $corruptedKey not found in box');
              }
            } catch (deleteError) {
              debugPrint('❌ DELETE ERROR: Failed to delete key $corruptedKey: $deleteError');
            }
          }
          
          await box.flush();
          await box.compact();
          
          int boxLengthAfter = box.length;
          debugPrint('✅ ENHANCED SURGICAL RECOVERY: Deleted $deletedCount corrupted entries');
          debugPrint('✅ BOX SIZE CHANGE: Before: $boxLengthBefore → After: $boxLengthAfter');
          debugPrint('✅ CLEAN RECIPES: Returning ${recipes.length} successfully parsed recipes');
          
          return recipes;
          
        } catch (surgicalError) {
          debugPrint('❌ ENHANCED SURGICAL RECOVERY FAILED: $surgicalError');
        }
      }

      // 🔥 ULTRA THINK: Ultimate fallback - if too many errors and no good data, clear everything
      if (recipes.isEmpty && parseErrors > 0 && box.length > 0) {
        debugPrint('🚨 ULTIMATE RECOVERY: ALL ${box.length} entries failed to parse! Clearing entire box...');
        try {
          int boxLengthBefore = box.length;
          await box.clear();
          await box.flush();
          await box.compact();
          debugPrint('✅ ULTIMATE RECOVERY: Successfully cleared all $boxLengthBefore corrupted entries');
        } catch (e) {
          debugPrint('❌ ULTIMATE RECOVERY FAILED: $e');
        }
      }

      debugPrint('🎯 FINAL RESULT: Returning ${recipes.length} recipes');
      return recipes;

    } catch (e) {
      debugPrint('❌ CRITICAL ERROR in getAllRecipes: $e');
      
      // 🔥 ULTRA THINK: Emergency data recovery in catch block
      try {
        final box = await _box;
        if (box.length > 0) {
          debugPrint('🚨 EMERGENCY RECOVERY (CATCH): Critical error with ${box.length} entries! Clearing corrupted data...');
          await box.clear();
          await box.flush();
          await box.compact();
          debugPrint('✅ EMERGENCY RECOVERY (CATCH): Successfully cleared all corrupted entries');
        }
      } catch (recoveryError) {
        debugPrint('❌ EMERGENCY RECOVERY (CATCH) FAILED: $recoveryError');
      }
      
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

  // Burrow milestone management
  Future<List<dynamic>?> getBurrowMilestones() async {
    try {
      final box = await _box;
      final data = box.get('burrow_milestones');
      if (data is Map<String, dynamic>) {
        // 만약 Map 형태로 저장되어 있다면 List로 변환
        if (data.containsKey('milestones') && data['milestones'] is List) {
          return data['milestones'] as List<dynamic>;
        }
      } else if (data is List) {
        return data;
      }
      return null;
    } catch (e) {
      developer.log('Failed to get burrow milestones: $e', name: 'Hive Service');
      return null;
    }
  }

  Future<void> saveBurrowMilestones(List<dynamic> milestones) async {
    try {
      final box = await _box;
      final jsonList = milestones.map((m) => m.toJson()).toList();
      // List를 Map으로 감싸서 저장
      final dataToStore = {
        'milestones': jsonList,
        'version': 1,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      await box.put('burrow_milestones', dataToStore);
      await box.flush();
      await box.compact();
      developer.log('Burrow milestones saved: ${milestones.length}', name: 'Hive Service');
    } catch (e) {
      developer.log('Failed to save burrow milestones: $e', name: 'Hive Service');
      throw Exception('Failed to save burrow milestones: $e');
    }
  }

  // Generic key-value storage for backward compatibility
  Future<dynamic> getValue(String key) async {
    try {
      final box = await _box;
      return box.get(key);
    } catch (e) {
      developer.log('Failed to get value for key $key: $e', name: 'Hive Service');
      return null;
    }
  }

  Future<void> setValue(String key, dynamic value) async {
    try {
      final box = await _box;
      await box.put(key, value);
      await box.flush();
      await box.compact();
      developer.log('Value saved for key $key', name: 'Hive Service');
    } catch (e) {
      developer.log('Failed to save value for key $key: $e', name: 'Hive Service');
      throw Exception('Failed to save value for key $key: $e');
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