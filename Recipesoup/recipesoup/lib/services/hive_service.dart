import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'dart:async';
import 'dart:convert'; // 🔥 ULTRA THINK: JSON 직렬화로 100% 안전한 타입 변환
import 'package:hive/hive.dart';
import '../models/recipe.dart';
import '../models/mood.dart';

/// Hive JSON-based local storage service (싱글톤)
class HiveService {

  /// 🔥 CRITICAL FIX: 재귀적으로 Map<dynamic, dynamic>를 Map<String, dynamic>로 변환
  /// Test 16: 완전한 타입 안전성 보장
  static Map<String, dynamic> _convertMapRecursively(dynamic data) {
    if (data is Map) {
      return data.map((key, value) {
        // 키는 항상 String으로 변환
        final stringKey = key.toString();

        // 값이 Map이면 재귀적으로 변환
        if (value is Map) {
          return MapEntry(stringKey, _convertMapRecursively(value));
        }
        // 값이 List이면 각 요소 변환
        else if (value is List) {
          return MapEntry(stringKey, value.map((item) {
            if (item is Map) {
              return _convertMapRecursively(item);
            }
            return item;
          }).toList());
        }
        // 기본 타입은 그대로
        return MapEntry(stringKey, value);
      });
    }
    return {};
  }
  static final HiveService _instance = HiveService._internal();
  factory HiveService({String? boxName}) => _instance;
  
  HiveService._internal() : _recipeBoxName = 'recipes';
  
  final String _recipeBoxName;

  // 🔥 TEST 17: Box 타입을 dynamic으로 변경
  Box<dynamic>? _recipeBox;
  
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

    // ✅ DATA PERSISTENCE FIX: 박스가 이미 열려있으면 절대 닫지 않고 재사용
    if (_isInitialized && _recipeBox != null && _recipeBox!.isOpen) {
      developer.log('📦 SINGLETON: Box already initialized and open - reusing existing box (${_instance.hashCode})', name: 'Hive Service');
      return;
    }

    _isInitializing = true;

    try {
      // ✅ DATA PERSISTENCE FIX: 박스가 이미 열려있으면 재사용 (절대 닫지 않음)
      if (_recipeBox != null && _recipeBox!.isOpen) {
        developer.log('📦 Box already open - reusing existing instance', name: 'Hive Service');
        _isInitialized = true;
        _isInitializing = false;
        if (!_initCompleter.isCompleted) {
          _initCompleter.complete();
        }
        return;
      }

      // 박스가 닫혀있거나 없을 때만 새로 열기
      // 🔥 TEST 17: Box 타입을 dynamic으로 변경하여 자동 타입 캐스팅 방지
      _recipeBox = await Hive.openBox<dynamic>(_recipeBoxName);
      
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

  Future<Box<dynamic>> get _box async {
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
      
      // 🔥 ULTRA DEBUG: Box 상태 상세 로깅 (RELEASE 모드에서도 출력)
      print('🔥 SAVE DEBUG: HiveService instance: ${_instance.hashCode}');
      print('🔥 SAVE DEBUG: Box hashCode: ${box.hashCode}');
      print('🔥 SAVE DEBUG: Box isOpen: ${box.isOpen}');
      print('🔥 SAVE DEBUG: Box length BEFORE save: ${box.length}');
      print('🔥 SAVE DEBUG: Box name: ${box.name}');
      print('🔥 SAVE DEBUG: Box path: ${box.path}');
      
      // 🔥 CRITICAL FIX: 데이터 저장
      await box.put(recipe.id, recipe.toJson());

      print('🔥 SAVE DEBUG: Box length AFTER save: ${box.length}');

      // 🔥 CRITICAL FIX: 명시적 디스크 동기화 (이것이 핵심!)
      await box.flush(); // 메모리에서 디스크로 강제 쓰기
      print('✅ FLUSH #1 completed');

      // ✅ DATA PERSISTENCE FIX: compact() 제거 - 매번 호출 시 데이터 손상 위험
      // await box.compact(); // 제거됨 - iOS 백그라운드 전환 시 중단되어 데이터 손상 유발

      // 🔥 ULTRA FIX: OS 파일 시스템 캐시가 디스크에 쓸 시간 확보
      await Future.delayed(Duration(milliseconds: 100));
      print('✅ OS cache delay (100ms) completed');

      print('🔥 SAVE DEBUG: Box length AFTER flush/compact: ${box.length}');

      // 🔥 CRITICAL FIX: 저장 후 데이터 존재 확인
      final savedData = box.get(recipe.id);
      if (savedData == null) {
        throw Exception('Recipe was not saved properly to Hive');
      }
      print('✅ Data verification passed');

      // 🔥 ULTRA FIX: 한 번 더 flush (2중 안전장치)
      await box.flush();
      print('✅ FLUSH #2 (double safety) completed');

      // 🔥🔥 TEST 13: Box close/reopen으로 디스크 쓰기 강제
      print('🔥 TEST 13: Closing box to force disk write...');
      await box.close();
      print('✅ Box closed successfully');

      // 박스 재오픈 - 🔥 TEST 17: dynamic 타입으로 변경
      _recipeBox = await Hive.openBox<dynamic>(_recipeBoxName);
      print('✅ Box reopened successfully');
      print('🔥 VERIFY: Box length after reopen: ${_recipeBox!.length}');

      // 재오픈 후 데이터 재확인
      final verifyData = _recipeBox!.get(recipe.id);
      if (verifyData == null) {
        throw Exception('Recipe lost after box reopen!');
      }

      // 🔥 FIX: Map<dynamic, dynamic>을 Map<String, dynamic>으로 안전하게 변환
      final Map<String, dynamic> safeData = Map<String, dynamic>.from(verifyData);

      // 변환된 데이터로 Recipe 객체 생성 가능한지 검증
      try {
        Recipe.fromJson(safeData);
        print('✅ VERIFY: Recipe ${recipe.id} exists after reopen and is valid');
      } catch (parseError) {
        throw Exception('Recipe data corrupted: $parseError');
      }

      print('🔥 SAVE SUCCESS: Recipe ${recipe.id} saved to box ${box.hashCode}');
      developer.log('📦 SINGLETON: Recipe saved and verified: ${recipe.id} (instance: ${_instance.hashCode}, box: ${_recipeBox.hashCode}, size: ${_recipeBox!.length})', name: 'Hive Service');
      
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

      // 🔥 FIX: Map<dynamic, dynamic>을 Map<String, dynamic>으로 안전하게 변환
      final Map<String, dynamic> safeData = Map<String, dynamic>.from(jsonData);
      return Recipe.fromJson(safeData);
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
      // ✅ DATA PERSISTENCE FIX: compact() 제거
      
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
      
      if (kDebugMode) {
        debugPrint('🔥 READ DEBUG: HiveService instance: ${hashCode}');
        debugPrint('🔥 READ DEBUG: Box hashCode: ${box.hashCode}');
        debugPrint('🔥 READ DEBUG: Box isOpen: ${box.isOpen}');
        debugPrint('🔥 READ DEBUG: Box length: ${box.length}');
        debugPrint('🔥 READ DEBUG: Box name: ${box.name}');
        debugPrint('🔥 READ DEBUG: Box path: ${box.path}');
        debugPrint('🔥 READ DEBUG: Box keys: ${box.keys.take(20).toList()}');
        debugPrint('🔥 READ DEBUG: First few keys: ${box.keys.take(3).toList()}');
      }

      List<Recipe> recipes = [];
      int parseErrors = 0;
      int successfulParsing = 0;
      List<dynamic> corruptedKeys = [];

      if (kDebugMode) {
        debugPrint('🔥 CRITICAL DEBUG: About to start processing entries');
        debugPrint('🔥 CRITICAL DEBUG: Got ${box.keys.length} keys from box');
        debugPrint('🔥 CRITICAL DEBUG: About to iterate keys directly');
      }

      // 🔥 ULTRA THINK: Ultra defensive processing with legacy data handling
      for (final key in box.keys) {
        try {
          if (kDebugMode) {
            debugPrint('🔥 ENTRY DEBUG: Processing key $key');
          }
          
          final rawData = box.get(key);
          if (rawData == null) {
            if (kDebugMode) {
              debugPrint('⚠️ SKIP DEBUG: Key $key has null data');
            }
            continue;
          }

          // 🔥 TEST 16: 재귀적 타입 변환으로 완전한 안전성 보장
          Map<String, dynamic> safeJsonData;
          try {
            // 🔥 NEW APPROACH: 재귀적으로 모든 nested Map 변환
            safeJsonData = _convertMapRecursively(rawData);
            if (kDebugMode) {
              debugPrint('✅ RECURSIVE CONVERSION SUCCESS for key $key');
            }
          } catch (conversionError) {
            if (kDebugMode) {
              debugPrint('❌ RECURSIVE CONVERSION ERROR for key $key: $conversionError');
            }

            // 🔥 ULTRA THINK: If conversion fails, mark as corrupted
            if (kDebugMode) {
              debugPrint('🚨 MARKING AS CORRUPTED: Key $key (type: ${rawData.runtimeType})');
            }
            corruptedKeys.add(key);
            parseErrors++;
            continue;
          }

          // 🔥 ULTRA THINK: Try to create Recipe from processed data
          try {
            final recipe = Recipe.fromJson(safeJsonData);
            recipes.add(recipe);
            successfulParsing++;
            if (kDebugMode) {
              debugPrint('✅ SUCCESS: Parsed recipe for key $key: ${recipe.title}');
            }
          } catch (recipeError) {
            if (kDebugMode) {
              debugPrint('❌ RECIPE PARSE ERROR for key $key: $recipeError');
            }
            corruptedKeys.add(key);
            parseErrors++;
          }
          
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ GENERAL PARSE ERROR: Failed to parse key $key: $e');
          }
          corruptedKeys.add(key);
          parseErrors++;
        }
      }

      if (kDebugMode) {
        debugPrint('🔥 PARSING SUMMARY: Success: $successfulParsing, Errors: $parseErrors, Corrupted Keys: ${corruptedKeys.length}');
      }

      // 🔥 ULTRA THINK: Enhanced surgical emergency recovery
      if (corruptedKeys.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('🚨 ENHANCED SURGICAL RECOVERY: Found ${corruptedKeys.length} corrupted entries to remove');
          debugPrint('🚨 CORRUPTED KEYS: ${corruptedKeys.take(10).join(", ")}${corruptedKeys.length > 10 ? "..." : ""}');
        }
        
        try {
          int deletedCount = 0;
          int boxLengthBefore = box.length;
          
          for (final corruptedKey in corruptedKeys) {
            try {
              if (box.containsKey(corruptedKey)) {
                await box.delete(corruptedKey);
                deletedCount++;
                if (kDebugMode) {
                  debugPrint('🔥 DELETED: Successfully removed corrupted key: $corruptedKey');
                }
              } else {
                if (kDebugMode) {
                  debugPrint('⚠️ SKIP DELETE: Key $corruptedKey not found in box');
                }
              }
            } catch (deleteError) {
              if (kDebugMode) {
                debugPrint('❌ DELETE ERROR: Failed to delete key $corruptedKey: $deleteError');
              }
            }
          }
          
          await box.flush();
          // ✅ DATA PERSISTENCE FIX: compact() 제거
          
          int boxLengthAfter = box.length;
          if (kDebugMode) {
            debugPrint('✅ ENHANCED SURGICAL RECOVERY: Deleted $deletedCount corrupted entries');
            debugPrint('✅ BOX SIZE CHANGE: Before: $boxLengthBefore → After: $boxLengthAfter');
            debugPrint('✅ CLEAN RECIPES: Returning ${recipes.length} successfully parsed recipes');
          }
          
          return recipes;
          
        } catch (surgicalError) {
          if (kDebugMode) {
            debugPrint('❌ ENHANCED SURGICAL RECOVERY FAILED: $surgicalError');
          }
        }
      }

      // 🔥 ULTRA THINK: Ultimate fallback - if too many errors and no good data, clear everything
      if (recipes.isEmpty && parseErrors > 0 && box.length > 0) {
        if (kDebugMode) {
          debugPrint('🚨 ULTIMATE RECOVERY: ALL ${box.length} entries failed to parse! Clearing entire box...');
        }
        try {
          int boxLengthBefore = box.length;
          await box.clear();
          await box.flush();
          // ✅ DATA PERSISTENCE FIX: compact() 제거
          if (kDebugMode) {
            debugPrint('✅ ULTIMATE RECOVERY: Successfully cleared all $boxLengthBefore corrupted entries');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ ULTIMATE RECOVERY FAILED: $e');
          }
        }
      }

      if (kDebugMode) {
        debugPrint('🎯 FINAL RESULT: Returning ${recipes.length} recipes');
      }
      return recipes;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ CRITICAL ERROR in getAllRecipes: $e');
      }
      
      // 🔥 ULTRA THINK: Emergency data recovery in catch block
      try {
        final box = await _box;
        if (box.length > 0) {
          if (kDebugMode) {
            debugPrint('🚨 EMERGENCY RECOVERY (CATCH): Critical error with ${box.length} entries! Clearing corrupted data...');
          }
          await box.clear();
          await box.flush();
          // ✅ DATA PERSISTENCE FIX: compact() 제거
          if (kDebugMode) {
            debugPrint('✅ EMERGENCY RECOVERY (CATCH): Successfully cleared all corrupted entries');
          }
        }
      } catch (recoveryError) {
        if (kDebugMode) {
          debugPrint('❌ EMERGENCY RECOVERY (CATCH) FAILED: $recoveryError');
        }
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
      // ✅ DATA PERSISTENCE FIX: compact() 제거
      
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

  // Note: 감정 분포는 StatsScreen._buildEmotionDistributionCard()에서 RecipeProvider 데이터로 직접 계산합니다.
  // RecipeProvider를 사용하면 async 오버헤드 없이 in-memory 데이터로 더 빠르게 처리할 수 있습니다.

  // Note: 태그 검색은 다음 위치에서 더 유연하게 구현되어 있습니다:
  // - RecipeProvider.searchByTag() (contains 검색 지원)
  // - ArchiveScreen._performSearch() (tags.any 사용으로 부분 일치 지원)
  // RecipeProvider를 사용하면 더 강력한 태그 검색 기능을 제공합니다.

  // Note: 태그 빈도는 다음 위치에서 RecipeProvider 데이터로 직접 계산합니다:
  // - StatsScreen._buildMostUsedTagsCard() (통계 화면)
  // - ArchiveScreen._getRecommendedTags() (보관함 화면)
  // RecipeProvider를 사용하면 async 오버헤드 없이 in-memory 데이터로 더 빠르게 처리할 수 있습니다.

  // Search and filtering
  // Note: 제목/감정 이야기 검색은 RecipeProvider.searchRecipes()를 사용하세요.
  // RecipeProvider가 더 강력한 통합 검색 기능을 제공합니다.

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
      // ✅ DATA PERSISTENCE FIX: compact() 제거
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
      // ✅ DATA PERSISTENCE FIX: compact() 제거
      developer.log('Value saved for key $key', name: 'Hive Service');
    } catch (e) {
      developer.log('Failed to save value for key $key: $e', name: 'Hive Service');
      throw Exception('Failed to save value for key $key: $e');
    }
  }

  Future<void> dispose() async {
    try {
      // 🔥 DATA PERSISTENCE FIX: 박스를 절대 닫지 않음
      // 이유: flush()만으로도 데이터가 디스크에 저장되므로
      // 박스를 열린 채로 두면 앱 재시작 시 데이터 접근이 더 안정적임
      if (_recipeBox != null && _recipeBox!.isOpen) {
        // 마지막 flush로 모든 데이터 디스크 반영
        await _recipeBox!.flush();
        developer.log('Recipe Box flushed (kept open for data persistence)', name: 'Hive Service');
        // await _recipeBox!.close(); // 박스 닫기 제거 - 데이터 지속성 강화
      }
    } catch (e) {
      developer.log('Failed to flush Recipe Box: $e', name: 'Hive Service');
    }
  }
}