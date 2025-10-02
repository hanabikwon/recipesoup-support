import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/burrow_milestone.dart';

/// Ultra-robust 이미지 핸들러 
/// burrow-fix-ver2.txt에서 계획된 다중 계층 로딩 전략 구현
class UltraBurrowImageHandler {
  static final Map<String, ImageProvider> _cache = {};
  static final Map<String, bool> _verifiedPaths = {};

  /// 이미지 경로 변형 생성 (Ultra Think 전략)
  static List<String> _generatePathVariations(String originalPath) {
    final variations = <String>[];
    
    // 파일명만 추출
    String fileName = originalPath;
    if (originalPath.contains('/')) {
      fileName = originalPath.split('/').last;
    }
    
    // 1차: 원본 경로들 (새로운 폴더 구조 포함)
    variations.addAll([
      originalPath,
      'assets/images/burrow/milestones/$fileName',
      'assets/images/burrow/special_rooms/$fileName', 
      'assets/images/burrow/$fileName',
      'assets/burrow/milestones/$fileName',
      'assets/burrow/special_rooms/$fileName',
      'assets/burrow/$fileName',
      'assets/images/$fileName',
      'assets/$fileName',
      fileName,
    ]);
    
    // 2차: 확장자 없는 경우 추가
    if (!fileName.contains('.')) {
      final baseVariations = [
        'assets/images/burrow/milestones/$fileName',
        'assets/images/burrow/special_rooms/$fileName',
        'assets/images/burrow/$fileName',
        'assets/burrow/milestones/$fileName',
        'assets/burrow/special_rooms/$fileName', 
        'assets/burrow/$fileName',
        fileName
      ];
      
      for (final base in baseVariations) {
        variations.addAll([
          '$base.webp',
          '$base.webp',
          '$base.webp',
        ]);
      }
    }
    
    // 3차: 언더스코어/하이픈 변형
    if (fileName.contains('_')) {
      final hyphenVersion = fileName.replaceAll('_', '-');
      variations.addAll([
        'assets/images/burrow/$hyphenVersion',
        'assets/burrow/$hyphenVersion',
        hyphenVersion,
      ]);
    }
    
    if (fileName.contains('-')) {
      final underscoreVersion = fileName.replaceAll('-', '_');
      variations.addAll([
        'assets/images/burrow/$underscoreVersion',
        'assets/burrow/$underscoreVersion',
        underscoreVersion,
      ]);
    }
    
    // 4차: 대소문자 변형
    final lowerCase = fileName.toLowerCase();
    if (lowerCase != fileName) {
      variations.addAll([
        'assets/images/burrow/$lowerCase',
        'assets/burrow/$lowerCase',
        lowerCase,
      ]);
    }
    
    // 중복 제거
    return variations.toSet().toList();
  }

  /// 애셋 존재 여부 확인 (캐시된 결과 사용)
  static Future<bool> _assetExists(String path) async {
    if (_verifiedPaths.containsKey(path)) {
      return _verifiedPaths[path]!;
    }
    
    try {
      final ByteData data = await rootBundle.load(path);
      final exists = data.lengthInBytes > 0;
      _verifiedPaths[path] = exists;
      return exists;
    } catch (e) {
      _verifiedPaths[path] = false;
      return false;
    }
  }

  /// Hot Reload 대응 - 임시로 비활성화하여 이미지 로딩 문제 해결
  static String _getCacheBustedPath(String path) {
    // Debug 모드에서 cache busting이 이미지 로딩을 방해하므로 임시 비활성화
    // if (kDebugMode) {
    //   return '$path?v=$_reloadCounter';
    // }
    return path;
  }

  /// 캐시 무효화
  static void invalidateCache() {
    _cache.clear();
    _verifiedPaths.clear();
  }

  /// 다중 계층 이미지 로딩 (Ultra Think)
  static Widget ultraSafeImage({
    required String imagePath,
    required BurrowMilestone? milestone,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return FutureBuilder<Widget>(
      future: _loadWithMultipleFallbacks(
        imagePath, 
        milestone, 
        fit, 
        width, 
        height,
        placeholder,
        errorWidget,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return placeholder ?? _buildLoadingPlaceholder(width, height);
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          return snapshot.data!;
        }
        
        // 최종 에러 상태
        return errorWidget ?? _buildFinalErrorPlaceholder(width, height, milestone);
      },
    );
  }

  /// 다중 계층 폴백 전략으로 이미지 로딩
  static Future<Widget> _loadWithMultipleFallbacks(
    String imagePath,
    BurrowMilestone? milestone,
    BoxFit fit,
    double? width,
    double? height,
    Widget? placeholder,
    Widget? errorWidget,
  ) async {
    // 캐시에서 먼저 확인
    if (_cache.containsKey(imagePath)) {
      return _buildImageWidget(_cache[imagePath]!, fit, width, height);
    }

    // 경로 변형들 생성
    final variations = _generatePathVariations(imagePath);
    debugPrint('🔥 ULTRA: Trying to load $imagePath');
    debugPrint('🔥 ULTRA: Generated ${variations.length} variations: $variations');
    
    // Level 1: AssetImage with variations
    for (final path in variations) {
      try {
        debugPrint('🔥 ULTRA Level 1: Checking $path');
        final exists = await _assetExists(path);
        debugPrint('🔥 ULTRA Level 1: $path exists: $exists');
        
        if (exists) {
          debugPrint('✅ ULTRA Level 1: SUCCESS with $path');
          final image = AssetImage(_getCacheBustedPath(path));
          _cache[imagePath] = image;
          return _buildImageWidget(image, fit, width, height);
        }
      } catch (e) {
        debugPrint('❌ ULTRA Level 1: Failed $path: $e');
        continue;
      }
    }
    
    // Level 2: Container decoration 시도
    debugPrint('🔥 ULTRA Level 2: Trying Container decoration');
    for (final path in variations.take(3)) { // 상위 3개만 시도
      try {
        final exists = await _assetExists(path);
        if (exists) {
          debugPrint('✅ ULTRA Level 2: SUCCESS with Container decoration: $path');
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(_getCacheBustedPath(path)),
                fit: fit,
                onError: (error, stack) {
                  debugPrint('❌ ULTRA Level 2: Decoration error: $error');
                },
              ),
            ),
          );
        }
      } catch (e) {
        continue;
      }
    }
    
    // Level 3: 하드코딩된 기본 이미지들 시도
    debugPrint('🔥 ULTRA Level 3: Trying hardcoded defaults');
    final hardcodedPaths = [
      'assets/images/burrow/special_rooms/burrow_locked.webp', // 특별 공간 잠김 이미지 우선
      'assets/images/burrow/milestones/burrow_tiny.webp',
      'assets/images/burrow/milestones/burrow_small.webp',
      'assets/images/burrow/milestones/burrow_medium.webp',
      'assets/images/burrow/milestones/burrow_large.webp',
    ];
    
    for (final path in hardcodedPaths) {
      try {
        final exists = await _assetExists(path);
        if (exists) {
          debugPrint('✅ ULTRA Level 3: SUCCESS with hardcoded: $path');
          final image = AssetImage(_getCacheBustedPath(path));
          return _buildImageWidget(image, fit, width, height);
        }
      } catch (e) {
        continue;
      }
    }
    
    // Level 4: 개발 모드에서 네트워크 플레이스홀더
    if (kDebugMode) {
      debugPrint('🔥 ULTRA Level 4: Using network placeholder');
      try {
        return Image.network(
          'https://via.placeholder.com/${width?.toInt() ?? 120}x${height?.toInt() ?? 120}/8B9A6B/FFFFFF?text=🏠',
          fit: fit,
          width: width,
          height: height,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildLoadingPlaceholder(width, height);
          },
          errorBuilder: (context, error, stack) {
            return _buildFinalErrorPlaceholder(width, height, milestone);
          },
        );
      } catch (e) {
        debugPrint('❌ ULTRA Level 4: Network failed: $e');
      }
    }
    
    // Level 5: 최종 폴백 - 항상 성공하는 위젯
    debugPrint('🔥 ULTRA Level 5: Final fallback');
    return _buildFinalErrorPlaceholder(width, height, milestone);
  }

  /// 이미지 위젯 생성 헬퍼
  static Widget _buildImageWidget(ImageProvider image, BoxFit fit, double? width, double? height) {
    return Image(
      image: image,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stack) {
        debugPrint('❌ Image widget error: $error');
        return _buildFinalErrorPlaceholder(width, height, null);
      },
    );
  }

  /// 로딩 플레이스홀더 (향상된 버전)
  static Widget _buildLoadingPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE8E3D8),
            const Color(0xFFB8C2A7).withValues(alpha: 77),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B9A6B)),
            ),
          ),
          if (width == null || width >= 80) ...[
            const SizedBox(height: 8),
            Text(
              '로딩중...',
              style: TextStyle(
                color: Color(0xFF5A6B49),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 최종 에러 플레이스홀더 (더 나은 디자인)
  static Widget _buildFinalErrorPlaceholder(double? width, double? height, BurrowMilestone? milestone) {
    final isLocked = milestone?.isUnlocked != true;
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLocked 
            ? [Color(0xFFE0E0E0), Color(0xFFBDBDBD)]
            : [Color(0xFFE8E3D8), Color(0xFF8B9A6B).withValues(alpha: 77)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLocked ? Color(0xFFBDBDBD) : Color(0xFF8B9A6B).withValues(alpha: 77),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isLocked ? Icons.lock : Icons.image,
            color: isLocked ? Color(0xFF757575) : Color(0xFF8B9A6B),
            size: width != null && width < 80 ? 20 : 32,
          ),
          if (width == null || width >= 80) ...[
            const SizedBox(height: 8),
            Text(
              isLocked ? '???' : '이미지\n준비중',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isLocked ? Color(0xFF757575) : Color(0xFF5A6B49),
                fontSize: width != null && width < 80 ? 8 : 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 디버그 정보 출력 (개발용)
  static Future<void> debugAllImagePaths() async {
    if (!kDebugMode) return;
    
    debugPrint('🔥🔥🔥 ULTRA DEBUG: Checking all image paths');
    
    final testPaths = [
      'assets/images/burrow/burrow_tiny.webp',
      'assets/images/burrow/burrow_small.webp',
      'assets/images/burrow/burrow_medium.webp',
      'assets/images/burrow/burrow_large.webp',
      'assets/images/burrow/burrow_locked.webp',
    ];
    
    for (final path in testPaths) {
      try {
        final data = await rootBundle.load(path);
        debugPrint('✅ ULTRA: $path -> ${data.lengthInBytes} bytes');
      } catch (e) {
        debugPrint('❌ ULTRA: $path -> ERROR: $e');
      }
    }
  }
}