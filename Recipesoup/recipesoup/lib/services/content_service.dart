import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

/// 콘텐츠 로드 서비스
/// 에러 핸들링과 메모리 최적화를 고려한 구현
class ContentService {
  // 싱글톤 패턴으로 메모리 최적화
  static final ContentService _instance = ContentService._internal();
  factory ContentService() => _instance;
  ContentService._internal();

  // 캐싱을 위한 변수들
  static Map<String, dynamic>? _cachedRecipes;
  static Map<String, dynamic>? _cachedKnowledge;
  static Map<String, dynamic>? _cachedRecommended;
  static DateTime? _lastLoadTime;
  
  // 캐시 유효 시간 (1시간)
  static const Duration _cacheValidDuration = Duration(hours: 1);

  /// 메인 로드 함수 - 모든 콘텐츠를 안전하게 로드
  static Future<Map<String, dynamic>> loadContent() async {
    try {
      // 캐시가 유효한지 확인
      if (_isCacheValid()) {
        return {
          'todayRecipe': getTodayRecipe(_cachedRecipes?['recipes'] ?? []),
          'todayKnowledge': getTodayKnowledge(_cachedKnowledge?['knowledge'] ?? []),
          'recommendedContent': getRandomRecommendedContent(_cachedRecommended?['content'] ?? []),
          'isFromCache': true,
        };
      }

      // 새로 로드
      final results = await Future.wait([
        _loadRecipes(),
        _loadKnowledge(),
        _loadRecommendedContent(),
      ]);

      final recipesData = results[0];
      final knowledgeData = results[1];
      final recommendedData = results[2];

      // 캐싱 업데이트
      _cachedRecipes = recipesData;
      _cachedKnowledge = knowledgeData;
      _cachedRecommended = recommendedData;
      _lastLoadTime = DateTime.now();

      return {
        'todayRecipe': getTodayRecipe(recipesData['recipes'] ?? []),
        'todayKnowledge': getTodayKnowledge(knowledgeData['knowledge'] ?? []),
        'recommendedContent': getRandomRecommendedContent(recommendedData['content'] ?? []),
        'isFromCache': false,
      };
    } catch (e) {
      // 에러 로깅 (프로덕션에서는 별도 로깅 서비스 사용)
      debugPrint('콘텐츠 로드 실패: $e');
      
      // 캐시가 있으면 캐시 반환, 없으면 기본값 반환
      return _getFailsafeContent();
    }
  }

  /// 캐시 유효성 검사
  static bool _isCacheValid() {
    if (_lastLoadTime == null || 
        _cachedRecipes == null || 
        _cachedKnowledge == null ||
        _cachedRecommended == null) {
      return false;
    }
    
    final timeDiff = DateTime.now().difference(_lastLoadTime!);
    return timeDiff < _cacheValidDuration;
  }

  /// 제철 레시피 JSON 로드
  static Future<Map<String, dynamic>> _loadRecipes() async {
    try {
      final jsonString = await rootBundle.loadString(
        'lib/data/content/seasonal_recipes.json',
      );
      
      if (jsonString.isEmpty) {
        throw Exception('제철 레시피 파일이 비어있습니다');
      }

      final decoded = json.decode(jsonString);
      
      // JSON 구조 검증
      if (decoded is! Map<String, dynamic> || decoded['recipes'] is! List) {
        throw Exception('제철 레시피 JSON 구조가 올바르지 않습니다');
      }

      return decoded;
    } catch (e) {
      debugPrint('제철 레시피 로드 실패: $e');
      return _getDefaultRecipes();
    }
  }

  /// 요리 지식 JSON 로드
  static Future<Map<String, dynamic>> _loadKnowledge() async {
    try {
      final jsonString = await rootBundle.loadString(
        'lib/data/content/cooking_knowledge.json',
      );
      
      if (jsonString.isEmpty) {
        throw Exception('요리 지식 파일이 비어있습니다');
      }

      final decoded = json.decode(jsonString);
      
      // JSON 구조 검증
      if (decoded is! Map<String, dynamic> || decoded['knowledge'] is! List) {
        throw Exception('요리 지식 JSON 구조가 올바르지 않습니다');
      }

      return decoded;
    } catch (e) {
      debugPrint('요리 지식 로드 실패: $e');
      return _getDefaultKnowledge();
    }
  }

  /// 오늘 날짜에 맞는 제철 레시피 선택
  static Map<String, dynamic>? getTodayRecipe(List recipes) {
    if (recipes.isEmpty) return null;

    try {
      final today = DateTime.now();
      
      // 오늘 날짜 이전의 가장 최근 레시피 찾기
      final validRecipes = recipes.where((recipe) {
        try {
          if (recipe is! Map<String, dynamic> || recipe['displayDate'] == null) {
            return false;
          }
          
          final displayDate = DateTime.parse(recipe['displayDate']);
          return displayDate.isBefore(today) || displayDate.isAtSameMomentAs(today);
        } catch (e) {
          debugPrint('레시피 날짜 파싱 오류: $e');
          return false;
        }
      }).toList();

      if (validRecipes.isEmpty) {
        // 유효한 레시피가 없으면 첫 번째 레시피 반환
        return recipes.first is Map<String, dynamic> ? recipes.first : null;
      }

      // 가장 최근 날짜의 레시피 반환
      validRecipes.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['displayDate']);
          final dateB = DateTime.parse(b['displayDate']);
          return dateB.compareTo(dateA);
        } catch (e) {
          debugPrint('레시피 정렬 오류: $e');
          return 0;
        }
      });

      return validRecipes.first;
    } catch (e) {
      debugPrint('오늘의 레시피 선택 오류: $e');
      return recipes.isNotEmpty && recipes.first is Map<String, dynamic> 
        ? recipes.first 
        : null;
    }
  }

  /// 오늘 날짜에 맞는 요리 지식 선택
  static Map<String, dynamic>? getTodayKnowledge(List knowledge) {
    if (knowledge.isEmpty) return null;

    try {
      final today = DateTime.now();
      
      // 오늘 날짜 이전의 가장 최근 지식 찾기
      final validKnowledge = knowledge.where((item) {
        try {
          if (item is! Map<String, dynamic> || item['displayDate'] == null) {
            return false;
          }
          
          final displayDate = DateTime.parse(item['displayDate']);
          return displayDate.isBefore(today) || displayDate.isAtSameMomentAs(today);
        } catch (e) {
          debugPrint('지식 날짜 파싱 오류: $e');
          return false;
        }
      }).toList();

      if (validKnowledge.isEmpty) {
        return knowledge.first is Map<String, dynamic> ? knowledge.first : null;
      }

      // 가장 최근 날짜의 지식 반환
      validKnowledge.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['displayDate']);
          final dateB = DateTime.parse(b['displayDate']);
          return dateB.compareTo(dateA);
        } catch (e) {
          debugPrint('지식 정렬 오류: $e');
          return 0;
        }
      });

      return validKnowledge.first;
    } catch (e) {
      debugPrint('오늘의 지식 선택 오류: $e');
      return knowledge.isNotEmpty && knowledge.first is Map<String, dynamic>
        ? knowledge.first
        : null;
    }
  }

  /// 실패 시 기본 콘텐츠 반환
  static Map<String, dynamic> _getFailsafeContent() {
    return {
      'todayRecipe': _cachedRecipes != null 
        ? getTodayRecipe(_cachedRecipes?['recipes'] ?? [])
        : _getDefaultRecipe(),
      'todayKnowledge': _cachedKnowledge != null 
        ? getTodayKnowledge(_cachedKnowledge?['knowledge'] ?? [])
        : _getDefaultKnowledge(),
      'recommendedContent': _cachedRecommended != null 
        ? getRandomRecommendedContent(_cachedRecommended?['content'] ?? [])
        : _getDefaultRecommendedContent(),
      'isFromCache': true,
      'hasError': true,
    };
  }

  /// 기본 제철 레시피 데이터
  static Map<String, dynamic> _getDefaultRecipes() {
    return {
      'recipes': [_getDefaultRecipe()]
    };
  }

  static Map<String, dynamic> _getDefaultRecipe() {
    return {
      'id': 'default_recipe',
      'displayDate': DateTime.now().toIso8601String().split('T')[0],
      'badge': '기본',
      'title': '간단한 요리',
      'shortDescription': '요리 데이터를 불러올 수 없습니다\n기본 레시피를 보여드립니다',
      'fullDescription': '현재 제철 레시피 정보를 불러올 수 없는 상황입니다. 네트워크 연결을 확인하거나 앱을 다시 시작해 보세요. 그래도 문제가 지속된다면 고객 지원팀에 문의해 주세요.',
    };
  }

  /// 기본 요리 지식 데이터
  static Map<String, dynamic> _getDefaultKnowledge() {
    return {
      'knowledge': [_getDefaultKnowledgeItem()]
    };
  }

  static Map<String, dynamic> _getDefaultKnowledgeItem() {
    return {
      'id': 'default_knowledge',
      'displayDate': DateTime.now().toIso8601String().split('T')[0],
      'title': '요리 기본 상식',
      'content': '요리 지식 데이터를 불러올 수 없습니다. 네트워크 연결을 확인해 주세요.',
      'category': '기본 정보',
    };
  }

  /// 캐시 초기화 (메모리 관리)
  static void clearCache() {
    _cachedRecipes = null;
    _cachedKnowledge = null;
    _cachedRecommended = null;
    _lastLoadTime = null;
  }

  /// 특정 날짜의 레시피 가져오기 (테스트용)
  static Map<String, dynamic>? getRecipeForDate(List recipes, String targetDate) {
    if (recipes.isEmpty) return null;

    try {
      final target = DateTime.parse(targetDate);
      
      final matchingRecipes = recipes.where((recipe) {
        try {
          if (recipe is! Map<String, dynamic>) return false;
          final displayDate = DateTime.parse(recipe['displayDate']);
          return displayDate.isAtSameMomentAs(target) || displayDate.isBefore(target);
        } catch (e) {
          return false;
        }
      }).toList();

      if (matchingRecipes.isEmpty) return null;

      // 가장 가까운 날짜의 레시피 반환
      matchingRecipes.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['displayDate']);
          final dateB = DateTime.parse(b['displayDate']);
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });

      return matchingRecipes.first;
    } catch (e) {
      debugPrint('특정 날짜 레시피 검색 오류: $e');
      return null;
    }
  }

  /// 추천 콘텐츠 JSON 로드
  static Future<Map<String, dynamic>> _loadRecommendedContent() async {
    try {
      final jsonString = await rootBundle.loadString(
        'lib/data/content/recommended_content.json',
      );
      
      if (jsonString.isEmpty) {
        throw Exception('추천 콘텐츠 파일이 비어있습니다');
      }

      final decoded = json.decode(jsonString);
      
      // JSON 구조 검증
      if (decoded is! Map<String, dynamic> || decoded['content'] is! List) {
        throw Exception('추천 콘텐츠 JSON 구조가 올바르지 않습니다');
      }

      return decoded;
    } catch (e) {
      debugPrint('추천 콘텐츠 로드 실패: $e');
      return _getDefaultRecommendedData();
    }
  }

  /// 랜덤 추천 콘텐츠 선택
  static Map<String, dynamic>? getRandomRecommendedContent(List content) {
    if (content.isEmpty) return null;

    try {
      final today = DateTime.now();
      
      // 오늘 날짜 이전의 유효한 콘텐츠들 찾기
      final validContent = content.where((item) {
        try {
          if (item is! Map<String, dynamic> || item['displayDate'] == null) {
            return false;
          }
          
          final displayDate = DateTime.parse(item['displayDate']);
          return displayDate.isBefore(today) || displayDate.isAtSameMomentAs(today);
        } catch (e) {
          debugPrint('추천 콘텐츠 날짜 파싱 오류: $e');
          return false;
        }
      }).toList();

      if (validContent.isEmpty) {
        // 유효한 콘텐츠가 없으면 첫 번째 콘텐츠 반환
        return content.first is Map<String, dynamic> ? content.first : null;
      }

      // 랜덤 선택
      final random = Random();
      return validContent[random.nextInt(validContent.length)];
    } catch (e) {
      debugPrint('추천 콘텐츠 선택 오류: $e');
      return content.isNotEmpty && content.first is Map<String, dynamic> 
        ? content.first 
        : null;
    }
  }

  /// 캐러셀용: 전체 요리 지식 가져오기 (displayDate 필터 없음)
  static Future<List<Map<String, dynamic>>> getAllCookingKnowledge() async {
    try {
      final knowledgeData = await _loadKnowledge();
      final knowledgeList = knowledgeData['knowledge'] as List?;

      if (knowledgeList == null || knowledgeList.isEmpty) {
        return [];
      }

      return knowledgeList
          .where((item) => item is Map<String, dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('전체 요리 지식 로드 오류: $e');
      return [];
    }
  }

  /// 캐러셀용: 전체 추천 콘텐츠 가져오기 (displayDate 필터 없음)
  static Future<List<Map<String, dynamic>>> getAllRecommendedContent() async {
    try {
      final contentData = await _loadRecommendedContent();
      final contentList = contentData['content'] as List?;

      if (contentList == null || contentList.isEmpty) {
        return [];
      }

      return contentList
          .where((item) => item is Map<String, dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('전체 추천 콘텐츠 로드 오류: $e');
      return [];
    }
  }

  /// 기본 추천 콘텐츠 데이터
  static Map<String, dynamic> _getDefaultRecommendedData() {
    return {
      'content': [_getDefaultRecommendedContent()]
    };
  }

  static Map<String, dynamic> _getDefaultRecommendedContent() {
    return {
      'id': 'default_recommended',
      'displayDate': DateTime.now().toIso8601String().split('T')[0],
      'type': 'movie',
      'title': '추천 콘텐츠를 불러올 수 없습니다',
      'subtitle': '네트워크 연결을 확인해주세요',
      'director': '레시피수프',
      'description': '현재 추천 콘텐츠 정보를 불러올 수 없는 상황입니다. 네트워크 연결을 확인하거나 앱을 다시 시작해 보세요.',
      'category': '영화',
    };
  }
}