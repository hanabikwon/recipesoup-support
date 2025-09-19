import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 상세 조리 방법 데이터 모델
class DetailedCookingMethod {
  final String title;
  final List<String> cookingSteps;

  DetailedCookingMethod({
    required this.title,
    required this.cookingSteps,
  });

  factory DetailedCookingMethod.fromJson(Map<String, dynamic> json) {
    return DetailedCookingMethod(
      title: json['title'] as String,
      cookingSteps: (json['cooking_steps'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
    );
  }
}

/// 상세 조리 방법 서비스
class CookingMethodService {
  static final CookingMethodService _instance = CookingMethodService._internal();
  factory CookingMethodService() => _instance;
  CookingMethodService._internal();

  static Map<String, DetailedCookingMethod>? _cachedMethods;
  
  /// 모든 상세 조리 방법 로드
  Future<Map<String, DetailedCookingMethod>> loadAllCookingMethods() async {
    try {
      if (_cachedMethods != null) {
        if (kDebugMode) {
          print('🍳 CookingMethod cache hit - returning ${_cachedMethods!.length} methods');
        }
        return _cachedMethods!;
      }

      if (kDebugMode) {
        print('🍳 Loading cooking methods from JSON...');
      }

      // JSON 파일에서 상세 조리 방법 로드
      final jsonString = await rootBundle.loadString('lib/data/detailed_cooking_methods.json');
      final methodsJson = json.decode(jsonString) as Map<String, dynamic>;
      
      final methods = <String, DetailedCookingMethod>{};
      methodsJson.forEach((key, value) {
        methods[key] = DetailedCookingMethod.fromJson(value as Map<String, dynamic>);
      });

      // 캐시 업데이트
      _cachedMethods = methods;

      if (kDebugMode) {
        print('✅ Loaded ${methods.length} detailed cooking methods');
      }

      return methods;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to load cooking methods: $e');
      }
      
      return <String, DetailedCookingMethod>{};
    }
  }

  /// 특정 챌린지의 상세 조리 방법 조회
  Future<DetailedCookingMethod?> getCookingMethodById(String challengeId) async {
    final allMethods = await loadAllCookingMethods();
    return allMethods[challengeId];
  }

  /// 캐시 클리어
  void clearCache() {
    _cachedMethods = null;
  }
}