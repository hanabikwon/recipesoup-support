import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/burrow_milestone.dart';

/// Ultra-robust 이미지 핸들러
/// 다중 폴백 전략으로 이미지 로딩 실패 해결
class BurrowImageHandler {
  static final Map<String, ImageProvider> _cache = {};
  static int _reloadCounter = 0;

  /// 경로 변형 생성
  static List<String> _generatePathVariations(String originalPath) {
    final variations = <String>[];
    
    // 원본 경로 (최우선)
    variations.add(originalPath);
    
    // 파일명만 추출
    String fileName = originalPath;
    if (originalPath.contains('/')) {
      fileName = originalPath.split('/').last;
    }
    
    // 다양한 경로 조합 시도
    variations.addAll([
      'assets/images/burrow/$fileName',
      'assets/burrow/$fileName',
      'assets/images/$fileName',
      'assets/$fileName',
      fileName,
    ]);
    
    // 언더스코어/하이픈 변형
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
    
    // 중복 제거하고 반환
    return variations.toSet().toList();
  }

  /// 애셋 존재 여부 확인
  static Future<bool> _assetExists(String path) async {
    try {
      final ByteData data = await rootBundle.load(path);
      return data.lengthInBytes > 0;
    } catch (e) {
      return false;
    }
  }

  /// Hot Reload 대응 경로
  static String _getCacheBustedPath(String path) {
    if (kDebugMode) {
      return '$path?v=$_reloadCounter';
    }
    return path;
  }

  /// 캐시 무효화 (Hot Reload 시 호출)
  static void invalidateCache() {
    _reloadCounter++;
    _cache.clear();
  }

  /// 이미지 프리로딩
  static Future<void> preloadImages(BuildContext context, List<String> paths) async {
    for (final path in paths) {
      try {
        final variations = _generatePathVariations(path);
        for (final variant in variations) {
          if (await _assetExists(variant)) {
            final image = AssetImage(variant);
            // ignore: use_build_context_synchronously
            await precacheImage(image, context);
            _cache[path] = image;
            break;
          }
        }
      } catch (e) {
        debugPrint('Failed to preload: $path - $e');
      }
    }
  }

  /// 안전한 이미지 위젯 생성
  static Widget safeImage({
    required String imagePath,
    required BurrowMilestone? milestone,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return FutureBuilder<Widget?>(
      future: _loadImageWithFallbacks(
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
        
        return errorWidget ?? _buildErrorPlaceholder(width, height, milestone);
      },
    );
  }

  /// 다중 폴백으로 이미지 로딩
  static Future<Widget?> _loadImageWithFallbacks(
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
      return Image(
        image: _cache[imagePath]!,
        fit: fit,
        width: width,
        height: height,
      );
    }

    // 경로 변형들을 시도
    final variations = _generatePathVariations(imagePath);
    debugPrint('🔍 BurrowImageHandler: Trying to load $imagePath');
    debugPrint('🔍 Generated variations: $variations');
    
    for (final path in variations) {
      try {
        debugPrint('🔍 Checking path: $path');
        final exists = await _assetExists(path);
        debugPrint('🔍 Path $path exists: $exists');
        
        if (exists) {
          debugPrint('✅ Found working path: $path');
          final image = AssetImage(_getCacheBustedPath(path));
          _cache[imagePath] = image;
          
          return Image(
            image: image,
            fit: fit,
            width: width,
            height: height,
            errorBuilder: (context, error, stack) {
              debugPrint('❌ Image.asset failed for $path: $error');
              return errorWidget ?? _buildErrorPlaceholder(width, height, milestone);
            },
          );
        }
      } catch (e) {
        debugPrint('❌ Failed to load $path: $e');
        continue;
      }
    }

    // 개발 모드에서 네트워크 플레이스홀더 시도
    if (kDebugMode) {
      try {
        return Image.network(
          'https://via.placeholder.com/${width?.toInt() ?? 400}x${height?.toInt() ?? 400}/E8E3D8/5A6B49?text=Image',
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, error, stack) {
            return errorWidget ?? _buildErrorPlaceholder(width, height, milestone);
          },
        );
      } catch (e) {
        debugPrint('Network placeholder failed: $e');
      }
    }

    // 모든 시도 실패 시 null 반환
    return null;
  }

  /// 로딩 플레이스홀더
  static Widget _buildLoadingPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE8E3D8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B9A6B)),
        ),
      ),
    );
  }

  /// 에러 플레이스홀더
  static Widget _buildErrorPlaceholder(double? width, double? height, BurrowMilestone? milestone) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8E3D8), Color(0xFFB8C2A7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            milestone?.isUnlocked == true ? Icons.image : Icons.lock,
            color: Colors.white.withValues(alpha: 204),
            size: width != null && width < 100 ? 20 : 32,
          ),
          if (width == null || width >= 100) ...[
            const SizedBox(height: 4),
            Text(
              milestone?.isUnlocked == true ? '이미지\n로드 실패' : '???',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 204),
                fontSize: width != null && width < 100 ? 10 : 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 배경 이미지용 Container decoration
  static Future<BoxDecoration?> backgroundDecoration({
    required String imagePath,
    BoxFit fit = BoxFit.cover,
  }) async {
    final variations = _generatePathVariations(imagePath);
    
    for (final path in variations) {
      if (await _assetExists(path)) {
        return BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_getCacheBustedPath(path)),
            fit: fit,
            onError: (error, stackTrace) {
              debugPrint('Background decoration error for $path: $error');
            },
          ),
        );
      }
    }
    
    return null;
  }

  /// 디버그 정보 출력
  static Future<void> debugImagePaths(List<String> paths) async {
    if (!kDebugMode) return;
    
    debugPrint('=== BurrowImageHandler Debug ===');
    for (final path in paths) {
      final variations = _generatePathVariations(path);
      debugPrint('Original: $path');
      
      bool found = false;
      for (final variant in variations) {
        final exists = await _assetExists(variant);
        debugPrint('  ${exists ? "✅" : "❌"} $variant');
        if (exists && !found) found = true;
      }
      
      if (!found) {
        debugPrint('  ⚠️ No valid path found for: $path');
      }
      debugPrint('---');
    }
    debugPrint('================================');
  }
}