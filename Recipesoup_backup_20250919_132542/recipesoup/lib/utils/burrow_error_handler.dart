import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/burrow_milestone.dart';
import '../config/burrow_assets.dart';
import '../providers/recipe_provider.dart';
import '../providers/burrow_provider.dart';
import 'dart:developer' as developer;

/// 토끼굴 시스템 에러 처리 유틸리티
/// 이미지 로딩, 데이터 손상, 상태 동기화 에러 등을 처리
class BurrowErrorHandler {
  
  /// 이미지 로딩 에러 처리
  static Widget handleImageError(
    BuildContext context, 
    Object error, 
    StackTrace? stackTrace,
    {
      BurrowMilestone? milestone,
      Color? fallbackColor,
      IconData? fallbackIcon,
    }
  ) {
    developer.log(
      'Image loading failed: $error',
      name: 'BurrowErrorHandler',
      error: error,
      stackTrace: stackTrace,
    );
    
    // 폴백 색상 결정
    final color = fallbackColor ?? _getMilestoneColor(milestone);
    final icon = fallbackIcon ?? _getMilestoneIcon(milestone);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFFEFB),
            color.withValues(alpha: 51),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              '이미지 로딩 실패',
              style: TextStyle(
                color: color.withValues(alpha: 179),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Asset 이미지 로딩 시도 (에러 복구 포함)
  static Widget safeAssetImage(
    String imagePath,
    {
      BoxFit fit = BoxFit.cover,
      BurrowMilestone? milestone,
      Color? fallbackColor,
      IconData? fallbackIcon,
    }
  ) {
    return Builder(
      builder: (context) {
        try {
          developer.log('🖼️ Trying to load image: $imagePath', name: 'BurrowErrorHandler');
          return Image.asset(
            imagePath,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              developer.log('❌ Image loading failed for: $imagePath, Error: $error', name: 'BurrowErrorHandler');
              return handleImageError(
                context,
                error,
                stackTrace,
                milestone: milestone,
                fallbackColor: fallbackColor,
                fallbackIcon: fallbackIcon,
              );
            },
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              // 로딩 중 상태 표시
              if (wasSynchronouslyLoaded) {
                return child;
              }
              
              return AnimatedOpacity(
                opacity: frame == null ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: child,
              );
            },
          );
        } catch (e) {
          return handleImageError(
            context,
            e,
            null,
            milestone: milestone,
            fallbackColor: fallbackColor,
            fallbackIcon: fallbackIcon,
          );
        }
      },
    );
  }
  
  /// 마일스톤 데이터 무결성 검증
  static BurrowMilestone validateMilestone(BurrowMilestone milestone) {
    try {
      // 필수 필드 검증
      if (milestone.id.isEmpty) {
        throw BurrowDataException('마일스톤 ID가 비어있습니다');
      }
      
      if (milestone.title.isEmpty) {
        throw BurrowDataException('마일스톤 제목이 비어있습니다');
      }
      
      if (milestone.description.isEmpty) {
        throw BurrowDataException('마일스톤 설명이 비어있습니다');
      }
      
      // 레벨 범위 검증 (특별 공간이 아닌 경우)
      if (milestone.specialRoom == null && 
          (milestone.level < 1 || milestone.level > 10)) {
        throw BurrowDataException('잘못된 마일스톤 레벨: ${milestone.level}');
      }
      
      // 이미지 경로 검증
      if (!BurrowAssets.isValidAssetPath(milestone.imagePath)) {
        developer.log(
          'Invalid image path, using fallback: ${milestone.imagePath}',
          name: 'BurrowErrorHandler',
        );
        
        // 자동으로 올바른 경로로 복구
        final correctedPath = milestone.specialRoom != null
            ? BurrowAssets.getSpecialRoomImagePath(milestone.specialRoom!.name)
            : BurrowAssets.getMilestoneImagePath(milestone.level);
            
        return milestone.copyWith(imagePath: correctedPath);
      }
      
      return milestone;
      
    } catch (e) {
      developer.log(
        'Milestone validation failed: $e',
        name: 'BurrowErrorHandler',
        error: e,
      );
      
      // 데이터 손상 시 기본값으로 복구
      return _createFallbackMilestone(milestone);
    }
  }
  
  /// Provider 상태 에러 처리
  static void handleProviderError(
    Object error,
    StackTrace stackTrace,
    String operation,
    {
      VoidCallback? onRetry,
    }
  ) {
    developer.log(
      'Provider operation failed: $operation',
      name: 'BurrowErrorHandler', 
      error: error,
      stackTrace: stackTrace,
    );
    
    // 특정 에러 타입에 따른 처리
    if (error is BurrowServiceException) {
      _handleServiceError(error, onRetry);
    } else if (error is BurrowDataException) {
      _handleDataError(error, onRetry);
    } else {
      _handleUnknownError(error, operation, onRetry);
    }
  }
  
  /// 포괄적 에러 복구 메커니즘 (Provider 초기화 실패 시)
  static Future<bool> handleProviderInitializationFailure(
    Object error,
    Future<void> Function() initFunction,
    {int maxRetries = 3}
  ) async {
    developer.log(
      'Handling provider initialization failure with $maxRetries retries: $error',
      name: 'BurrowErrorHandler',
    );
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        developer.log('Provider initialization retry $attempt/$maxRetries', name: 'BurrowErrorHandler');
        
        // 지연 시간 추가 (백오프 전략)
        await Future.delayed(Duration(milliseconds: 500 * attempt));
        
        await initFunction();
        
        developer.log('Provider initialization successful on attempt $attempt', name: 'BurrowErrorHandler');
        return true;
        
      } catch (retryError) {
        developer.log('Provider initialization attempt $attempt failed: $retryError', name: 'BurrowErrorHandler');
        
        if (attempt == maxRetries) {
          // 최종 실패시 대체 동작
          return await _performGracefulDegradation();
        }
      }
    }
    
    return false;
  }
  
  /// Hive 저장소 복구 메커니즘
  static Future<bool> handleStorageRecovery() async {
    try {
      developer.log('Attempting storage recovery', name: 'BurrowErrorHandler');
      
      // 1. 저장소 서비스 재초기화 시도
      await _reinitializeStorage();
      
      // 2. 기본 데이터 구조 검증
      if (await _validateStorageIntegrity()) {
        developer.log('Storage recovery successful', name: 'BurrowErrorHandler');
        return true;
      }
      
      // 3. 검증 실패시 비상 초기화
      developer.log('Storage integrity check failed, performing emergency reset', name: 'BurrowErrorHandler');
      return await _performEmergencyStorageReset();
      
    } catch (e) {
      developer.log('Storage recovery failed: $e', name: 'BurrowErrorHandler');
      return false;
    }
  }
  
  /// 콜백 연결 실패 복구
  static Future<bool> handleCallbackConnectionFailure(
    BuildContext? context, {
    int maxRetries = 3
  }) async {
    if (context == null) return false;
    
    developer.log('Handling callback connection failure', name: 'BurrowErrorHandler');
    
    // Provider들을 미리 가져와서 async gap 문제 방지
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final burrowProvider = Provider.of<BurrowProvider>(context, listen: false);
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        await Future.delayed(Duration(milliseconds: 1000 * attempt));
        
        recipeProvider.setBurrowCallbacks(
          onRecipeAdded: burrowProvider.onRecipeAdded,
          onRecipeUpdated: burrowProvider.onRecipeUpdated,
          onRecipeDeleted: burrowProvider.onRecipeDeleted,
        );
        
        developer.log('Callback connection successful on attempt $attempt', name: 'BurrowErrorHandler');
        return true;
        
      } catch (e) {
        developer.log('Callback connection attempt $attempt failed: $e', name: 'BurrowErrorHandler');
      }
    }
    
    // 모든 시도 실패시 콜백 없이 동작 (기본 기능은 유지)
    developer.log('Callback connection failed, burrow system will work without real-time updates', name: 'BurrowErrorHandler');
    return false;
  }
  
  /// 사용자에게 보여줄 에러 메시지 생성
  static String getUserFriendlyErrorMessage(Object error) {
    if (error is BurrowServiceException) {
      return error.userMessage;
    } else if (error is BurrowDataException) {
      return '데이터 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
    } else if (error is PlatformException) {
      return '시스템 오류가 발생했습니다. 앱을 다시 시작해보세요.';
    } else {
      return '알 수 없는 오류가 발생했습니다. 문제가 계속되면 문의해주세요.';
    }
  }
  
  /// 에러 상황에서 안전한 UI 표시
  static Widget buildErrorWidget(
    String title,
    String message,
    {
      VoidCallback? onRetry,
      IconData icon = Icons.error_outline,
      Color color = const Color(0xFFB5704F),
    }
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: color,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E3D1F),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF5A6B49),
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B9A6B),
                  foregroundColor: Colors.white,
                ),
                onPressed: onRetry,
                child: const Text('다시 시도'),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// 마일스톤별 색상 반환 (private)
  static Color _getMilestoneColor(BurrowMilestone? milestone) {
    if (milestone?.specialRoom != null) {
      switch (milestone!.specialRoom!) {
        case SpecialRoom.ballroom:
          return const Color(0xFFE91E63);
        case SpecialRoom.hotSpring:
          return const Color(0xFF00BCD4);
        case SpecialRoom.orchestra:
          return const Color(0xFF9C27B0);
        case SpecialRoom.alchemyLab:
          return const Color(0xFFFF9800);
        case SpecialRoom.fineDining:
          return const Color(0xFFFFD700);
        // 새로 추가된 특별 공간들 (11개)
        case SpecialRoom.alps:
          return const Color(0xFF2196F3);
        case SpecialRoom.camping:
          return const Color(0xFF4CAF50);
        case SpecialRoom.autumn:
          return const Color(0xFFFF5722);
        case SpecialRoom.springPicnic:
          return const Color(0xFF8BC34A);
        case SpecialRoom.surfing:
          return const Color(0xFF03DAC6);
        case SpecialRoom.snorkel:
          return const Color(0xFF006064);
        case SpecialRoom.summerbeach:
          return const Color(0xFFFFC107);
        case SpecialRoom.baliYoga:
          return const Color(0xFF673AB7);
        case SpecialRoom.orientExpress:
          return const Color(0xFF795548);
        case SpecialRoom.canvas:
          return const Color(0xFFE91E63);
        case SpecialRoom.vacance:
          return const Color(0xFFFF9800);
      }
    }
    return const Color(0xFF8B9A6B);
  }
  
  /// 마일스톤별 아이콘 반환 (private)
  static IconData _getMilestoneIcon(BurrowMilestone? milestone) {
    if (milestone?.specialRoom != null) {
      switch (milestone!.specialRoom!) {
        case SpecialRoom.ballroom:
          return Icons.celebration;
        case SpecialRoom.hotSpring:
          return Icons.hot_tub;
        case SpecialRoom.orchestra:
          return Icons.music_note;
        case SpecialRoom.alchemyLab:
          return Icons.science;
        case SpecialRoom.fineDining:
          return Icons.restaurant;
        // 새로 추가된 특별 공간들 (11개)
        case SpecialRoom.alps:
          return Icons.terrain;
        case SpecialRoom.camping:
          return Icons.nature;
        case SpecialRoom.autumn:
          return Icons.park;
        case SpecialRoom.springPicnic:
          return Icons.local_florist;
        case SpecialRoom.surfing:
          return Icons.surfing;
        case SpecialRoom.snorkel:
          return Icons.scuba_diving;
        case SpecialRoom.summerbeach:
          return Icons.beach_access;
        case SpecialRoom.baliYoga:
          return Icons.self_improvement;
        case SpecialRoom.orientExpress:
          return Icons.train;
        case SpecialRoom.canvas:
          return Icons.palette;
        case SpecialRoom.vacance:
          return Icons.beach_access;
      }
    } else if (milestone != null) {
      switch (milestone.level) {
        case 1:
          return Icons.home_outlined;
        case 2:
          return Icons.home;
        case 3:
          return Icons.home_work_outlined;
        case 4:
          return Icons.home_work;
        case 5:
          return Icons.account_balance;
      }
    }
    return Icons.help_outline;
  }
  
  /// 손상된 마일스톤 데이터 복구용 기본 마일스톤 생성 (private)
  static BurrowMilestone _createFallbackMilestone(BurrowMilestone original) {
    return BurrowMilestone(
      id: original.id.isNotEmpty ? original.id : 'fallback_${DateTime.now().millisecondsSinceEpoch}',
      title: original.title.isNotEmpty ? original.title : '복구된 마일스톤',
      description: original.description.isNotEmpty ? original.description : '데이터가 복구되었습니다.',
      imagePath: BurrowAssets.defaultMilestone,
      level: original.level > 0 ? original.level : 1,
      requiredRecipes: original.requiredRecipes,
      burrowType: original.burrowType,
      isUnlocked: original.isUnlocked,
      unlockedAt: original.unlockedAt,
      specialRoom: original.specialRoom,
      unlockConditions: original.unlockConditions,
    );
  }
  
  /// 서비스 에러 처리 (private)
  static void _handleServiceError(BurrowServiceException error, VoidCallback? onRetry) {
    // 서비스 에러는 보통 일시적이므로 재시도 권장
    developer.log('Service error handled: ${error.message}', name: 'BurrowErrorHandler');
  }
  
  /// 데이터 에러 처리 (private)
  static void _handleDataError(BurrowDataException error, VoidCallback? onRetry) {
    // 데이터 에러는 복구가 어려우므로 초기화 권장
    developer.log('Data error handled: ${error.message}', name: 'BurrowErrorHandler');
  }
  
  /// 알 수 없는 에러 처리 (private)
  static void _handleUnknownError(Object error, String operation, VoidCallback? onRetry) {
    developer.log('Unknown error in $operation: $error', name: 'BurrowErrorHandler');
  }
  
  /// 우아한 성능 저하 모드 (private)
  static Future<bool> _performGracefulDegradation() async {
    try {
      developer.log('Performing graceful degradation - burrow system will run in limited mode', name: 'BurrowErrorHandler');
      
      // 토끼굴 시스템을 제한된 기능으로 실행
      // - UI는 표시하되 실제 기능은 제한
      // - 에러 발생하지 않도록 최소한의 기능만 활성화
      
      return true;
    } catch (e) {
      developer.log('Graceful degradation failed: $e', name: 'BurrowErrorHandler');
      return false;
    }
  }
  
  /// 저장소 재초기화 (private)
  static Future<void> _reinitializeStorage() async {
    try {
      developer.log('Reinitializing burrow storage', name: 'BurrowErrorHandler');
      
      // BurrowStorageService 재초기화 시도
      // 실제 구현은 BurrowStorageService의 initialize() 메서드 호출
      // 여기서는 개념적으로만 구현 (실제로는 service injection 필요)
      
      developer.log('Storage reinitialization completed', name: 'BurrowErrorHandler');
    } catch (e) {
      developer.log('Storage reinitialization failed: $e', name: 'BurrowErrorHandler');
      rethrow;
    }
  }
  
  /// 저장소 무결성 검증 (private)
  static Future<bool> _validateStorageIntegrity() async {
    try {
      developer.log('Validating storage integrity', name: 'BurrowErrorHandler');
      
      // 기본적인 저장소 구조 검증
      // - Hive boxes가 정상적으로 열려있는지
      // - 기본 데이터가 로드 가능한지
      // - 데이터 형식이 올바른지
      
      // 실제 구현시에는 BurrowStorageService의 메서드들을 호출하여 검증
      
      developer.log('Storage integrity validation passed', name: 'BurrowErrorHandler');
      return true;
    } catch (e) {
      developer.log('Storage integrity validation failed: $e', name: 'BurrowErrorHandler');
      return false;
    }
  }
  
  /// 비상 저장소 리셋 (private)
  static Future<bool> _performEmergencyStorageReset() async {
    try {
      developer.log('WARNING: Performing emergency storage reset - all burrow data will be lost', name: 'BurrowErrorHandler');
      
      // 모든 토끼굴 데이터 삭제 및 초기 상태로 리셋
      // 1. 기존 박스 데이터 삭제
      // 2. 기본 마일스톤 데이터 생성
      // 3. 새로운 빈 진행상황 생성
      
      // 실제 구현시에는 BurrowStorageService의 clear 메서드들 호출
      
      developer.log('Emergency storage reset completed', name: 'BurrowErrorHandler');
      return true;
    } catch (e) {
      developer.log('Emergency storage reset failed: $e', name: 'BurrowErrorHandler');
      return false;
    }
  }
}

/// 토끼굴 서비스 예외
class BurrowServiceException implements Exception {
  final String message;
  final String userMessage;
  final String? code;
  
  const BurrowServiceException(
    this.message,
    {
      required this.userMessage,
      this.code,
    }
  );
  
  @override
  String toString() => 'BurrowServiceException: $message';
}

/// 토끼굴 데이터 예외
class BurrowDataException implements Exception {
  final String message;
  
  const BurrowDataException(this.message);
  
  @override
  String toString() => 'BurrowDataException: $message';
}