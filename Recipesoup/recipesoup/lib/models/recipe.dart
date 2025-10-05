import 'ingredient.dart';
import 'mood.dart';

/// 감정 기반 레시피 모델
/// Recipesoup의 핵심 데이터 모델로 요리와 감정을 연결
class Recipe {
  /// 고유 식별자
  final String id;
  
  /// 레시피 제목
  final String title;
  
  /// 감정 메모 (핵심 기능!) - 왜 이 요리를 만들었는지, 누구를 위해 만들었는지
  final String emotionalStory;
  
  /// 구조화된 재료 리스트
  final List<Ingredient> ingredients;
  
  /// 소스 및 양념 (옵션)
  final String? sauce;
  
  /// 단계별 조리법
  final List<String> instructions;

  /// 해시태그 리스트
  final List<String> tags;

  /// 생성 날짜
  final DateTime createdAt;
  
  /// 감정 상태 (8가지 중 하나)
  final Mood mood;
  
  /// 만족도 점수 (1-5점, 옵션)
  final int? rating;

  /// 즐겨찾기 여부
  final bool isFavorite;
  
  /// 출처 URL (레시피 링크, 옵션)
  final String? sourceUrl;
  
  /// 스크린샷에서 생성된 레시피인지 여부 (OCR 기능)
  final bool isScreenshot;
  
  /// OCR로 추출된 텍스트 (스크린샷인 경우, 옵션)
  final String? extractedText;

  const Recipe({
    required this.id,
    required this.title,
    required this.emotionalStory,
    required this.ingredients,
    this.sauce,
    required this.instructions,
    required this.tags,
    required this.createdAt,
    required this.mood,
    this.rating,
    this.isFavorite = false,
    this.sourceUrl,
    this.isScreenshot = false, // 기본값: 일반 음식 사진
    this.extractedText, // 기본값: null (일반 음식 사진)
  });

  /// 새 레시피 생성 (ID 자동 생성)
  factory Recipe.generateNew({
    required String title,
    required String emotionalStory,
    required Mood mood,
    List<Ingredient>? ingredients,
    String? sauce,
    List<String>? instructions,
    List<String>? tags,
    DateTime? createdAt,
    int? rating,
    bool isFavorite = false,
    String? sourceUrl,
    bool isScreenshot = false, // 기본값: 일반 음식 사진
    String? extractedText, // OCR 텍스트 (스크린샷인 경우)
  }) {
    // 더 고유한 ID 생성 (microseconds + random 추가)
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final randomPart = (timestamp % 1000000).toString().padLeft(6, '0');
    
    return Recipe(
      id: 'recipe_${timestamp}_$randomPart',
      title: title,
      emotionalStory: emotionalStory,
      ingredients: ingredients ?? [],
      sauce: sauce,
      instructions: instructions ?? [],
      tags: tags ?? [],
      createdAt: createdAt ?? DateTime.now(),
      mood: mood,
      rating: rating,
      isFavorite: isFavorite,
      sourceUrl: sourceUrl,
      isScreenshot: isScreenshot,
      extractedText: extractedText,
    );
  }

  /// JSON으로 변환 (Hive 저장용)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'emotionalStory': emotionalStory,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'sauce': sauce,
      'instructions': instructions,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'mood': mood.name, // enum name으로 저장
      'rating': rating,
      'isFavorite': isFavorite,
      'sourceUrl': sourceUrl,
      'isScreenshot': isScreenshot,
      'extractedText': extractedText,
    };
  }

  /// JSON에서 생성 (Hive 로드용)
  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      title: json['title'] as String,
      emotionalStory: json['emotionalStory'] as String,
      ingredients: (json['ingredients'] as List<dynamic>)
          .map((i) {
            if (i is Map<String, dynamic>) {
              return Ingredient.fromJson(i);
            } else if (i is Map) {
              // 안전한 변환: _Map<dynamic, dynamic>을 Map<String, dynamic>으로 변환
              return Ingredient.fromJson(Map<String, dynamic>.from(i));
            } else {
              throw ArgumentError('Invalid ingredient data type: ${i.runtimeType}');
            }
          })
          .toList(),
      sauce: json['sauce'] as String?,
      instructions: List<String>.from(json['instructions'] as List<dynamic>),
      tags: List<String>.from(json['tags'] as List<dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      mood: Mood.values.firstWhere((m) => m.name == json['mood']),
      rating: json['rating'] as int?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      sourceUrl: json['sourceUrl'] as String?,
      // 호환성을 위한 기본값 제공 (기존 데이터에는 이 필드들이 없을 수 있음)
      isScreenshot: json['isScreenshot'] as bool? ?? false,
      extractedText: json['extractedText'] as String?,
    );
  }

  /// 복사본 생성 (일부 필드 변경)
  Recipe copyWith({
    String? id,
    String? title,
    String? emotionalStory,
    List<Ingredient>? ingredients,
    String? sauce,
    List<String>? instructions,
    List<String>? tags,
    DateTime? createdAt,
    Mood? mood,
    int? rating,
    bool? isFavorite,
    String? sourceUrl,
    bool? isScreenshot,
    String? extractedText,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      emotionalStory: emotionalStory ?? this.emotionalStory,
      ingredients: ingredients ?? this.ingredients,
      sauce: sauce ?? this.sauce,
      instructions: instructions ?? this.instructions,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      mood: mood ?? this.mood,
      rating: rating ?? this.rating,
      isFavorite: isFavorite ?? this.isFavorite,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      isScreenshot: isScreenshot ?? this.isScreenshot,
      extractedText: extractedText ?? this.extractedText,
    );
  }

  /// 레시피 유효성 검증 (감정 메모 필수!)
  bool get isValid {
    return id.isNotEmpty &&
           title.isNotEmpty &&
           emotionalStory.isNotEmpty && // 감정 기반 앱의 핵심!
           (rating == null || (rating! >= 1 && rating! <= 5));
  }

  /// 태그 검색 매칭
  bool matchesTag(String searchTag) {
    final normalizedSearch = searchTag.toLowerCase().replaceAll('#', '');
    return tags.any((tag) => 
        tag.toLowerCase().replaceAll('#', '').contains(normalizedSearch));
  }

  /// 제목 검색 매칭
  bool matchesTitle(String searchTitle) {
    return title.toLowerCase().contains(searchTitle.toLowerCase());
  }

  /// 감정 이야기 검색 매칭
  bool matchesEmotionalStory(String searchText) {
    return emotionalStory.toLowerCase().contains(searchText.toLowerCase());
  }

  /// 전체 텍스트 검색 (제목 + 감정 이야기 + 태그)
  bool matchesSearch(String searchText) {
    return matchesTitle(searchText) ||
           matchesEmotionalStory(searchText) ||
           matchesTag(searchText);
  }

  /// 조리 시간 추정 (지시사항 수 기반)
  int get estimatedTimeMinutes {
    if (instructions.isEmpty) return 30; // 기본값
    return (instructions.length * 5).clamp(15, 120); // 단계당 5분, 15-120분 범위
  }

  /// 난이도 추정 (재료 수 + 지시사항 수 기반)
  String get estimatedDifficulty {
    final complexity = ingredients.length + instructions.length;
    if (complexity <= 8) return '쉬움';
    if (complexity <= 15) return '보통';
    return '어려움';
  }
  
  /// URL 타입 판별 (내부 로직용)
  String? get urlType {
    if (sourceUrl == null || sourceUrl!.isEmpty) return null;
    if (sourceUrl!.contains('youtube.com') || sourceUrl!.contains('youtu.be')) {
      return 'video';
    }
    if (sourceUrl!.contains('instagram.com')) {
      return 'instagram';
    }
    return 'blog';
  }
  
  /// URL 유효성 체크
  bool get hasValidUrl {
    return sourceUrl != null && 
           sourceUrl!.isNotEmpty && 
           (sourceUrl!.startsWith('http://') || sourceUrl!.startsWith('https://'));
  }
  
  /// OCR 텍스트가 있는지 확인
  bool get hasExtractedText {
    return extractedText != null && extractedText!.trim().isNotEmpty;
  }
  
  /// 스크린샷 레시피인지 확인
  bool get isFromScreenshot {
    return isScreenshot;
  }
  
  /// OCR 요약 정보 (UI 표시용)
  String get ocrSummary {
    if (!isScreenshot) return '';
    if (!hasExtractedText) return '스크린샷 레시피 (텍스트 추출 실패)';
    
    final textLength = extractedText!.length;
    if (textLength > 100) {
      return '스크린샷 레시피 ($textLength자 텍스트 추출됨)';
    }
    return '스크린샷 레시피: ${extractedText!.substring(0, textLength.clamp(0, 50))}${textLength > 50 ? '...' : ''}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Recipe &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Recipe(id: $id, title: $title, mood: ${mood.korean}, isScreenshot: $isScreenshot, hasOCR: $hasExtractedText)';
}