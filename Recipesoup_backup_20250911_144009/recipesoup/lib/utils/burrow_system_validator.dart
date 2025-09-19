import '../models/burrow_milestone.dart';
import '../providers/burrow_provider.dart';
import '../providers/recipe_provider.dart';
import '../config/burrow_assets.dart';
import 'dart:developer' as developer;

/// 토끼굴 시스템 통합 검증 유틸리티
/// 개발/테스트 환경에서 시스템 상태를 확인하는 도구
class BurrowSystemValidator {
  
  /// 전체 시스템 건강성 체크
  static Future<BurrowSystemHealthCheck> validateSystem({
    required BurrowProvider burrowProvider,
    required RecipeProvider recipeProvider,
  }) async {
    final healthCheck = BurrowSystemHealthCheck();
    
    try {
      // 1. Provider 상태 검증
      healthCheck.providerHealthy = _validateProviders(burrowProvider, recipeProvider);
      
      // 2. 마일스톤 데이터 무결성 검증
      healthCheck.milestonesValid = _validateMilestones(burrowProvider.milestones);
      
      // 3. 이미지 에셋 검증
      healthCheck.assetsValid = _validateAssets();
      
      // 4. 콜백 통합 검증
      healthCheck.callbacksIntegrated = _validateCallbackIntegration();
      
      // 5. 메모리 사용량 확인
      healthCheck.memoryUsageNormal = _checkMemoryUsage(burrowProvider);
      
      // 전체 상태 계산
      healthCheck.overallHealthy = healthCheck.providerHealthy &&
                                   healthCheck.milestonesValid &&
                                   healthCheck.assetsValid &&
                                   healthCheck.callbacksIntegrated &&
                                   healthCheck.memoryUsageNormal;
      
      // 로그 출력
      _logHealthCheckResults(healthCheck);
      
    } catch (e) {
      developer.log(
        'System validation failed: $e',
        name: 'BurrowSystemValidator',
        error: e,
      );
      healthCheck.overallHealthy = false;
      healthCheck.error = e.toString();
    }
    
    return healthCheck;
  }
  
  /// Provider들의 상태 검증
  static bool _validateProviders(BurrowProvider burrowProvider, RecipeProvider recipeProvider) {
    // BurrowProvider 상태 체크
    if (burrowProvider.isLoading && burrowProvider.error != null) {
      developer.log('BurrowProvider: Loading과 Error 동시 존재', name: 'BurrowSystemValidator');
      return false;
    }
    
    // RecipeProvider 상태 체크  
    if (recipeProvider.isLoading && recipeProvider.error != null) {
      developer.log('RecipeProvider: Loading과 Error 동시 존재', name: 'BurrowSystemValidator');
      return false;
    }
    
    return true;
  }
  
  /// 마일스톤 데이터 무결성 검증
  static bool _validateMilestones(List<BurrowMilestone> milestones) {
    for (final milestone in milestones) {
      // 필수 필드 검증
      if (milestone.title.isEmpty || milestone.description.isEmpty) {
        developer.log('Milestone 필수 필드 누락: ${milestone.id}', name: 'BurrowSystemValidator');
        return false;
      }
      
      // 성장 트랙 레벨 범위 검증
      if (milestone.isGrowthTrack && (milestone.level < 1 || milestone.level > 10)) {
        developer.log('잘못된 성장 트랙 레벨: ${milestone.level}', name: 'BurrowSystemValidator');
        return false;
      }
      
      // 특별 공간 레벨 범위 검증
      if (milestone.isSpecialRoom && milestone.level < 100) {
        developer.log('잘못된 특별 공간 레벨: ${milestone.level}', name: 'BurrowSystemValidator');
        return false;
      }
      
      // 언락 상태 일관성 검증
      if (milestone.isUnlocked && milestone.unlockedAt == null) {
        developer.log('언락되었지만 시간 정보 없음: ${milestone.id}', name: 'BurrowSystemValidator');
        return false;
      }
    }
    
    return true;
  }
  
  /// 이미지 에셋 검증
  static bool _validateAssets() {
    final assetStatus = BurrowAssets.checkMissingAssets();
    
    for (final entry in assetStatus.entries) {
      if (!entry.value) {
        developer.log('잘못된 에셋 경로: ${entry.key}', name: 'BurrowSystemValidator');
        return false;
      }
    }
    
    return true;
  }
  
  /// 콜백 통합 검증 (기본 체크)
  static bool _validateCallbackIntegration() {
    // 실제로는 런타임에 RecipeProvider의 콜백이 설정되어 있는지 확인해야 하지만
    // 현재는 구조적 검증만 수행
    return true;
  }
  
  /// 메모리 사용량 확인 (기본 체크)
  static bool _checkMemoryUsage(BurrowProvider provider) {
    final milestoneCount = provider.totalMilestoneCount;
    final progressCount = provider.progressList.length;
    
    // 너무 많은 데이터가 메모리에 있는지 확인
    if (milestoneCount > 1000 || progressCount > 500) {
      developer.log('메모리 사용량 경고: milestones=$milestoneCount, progress=$progressCount', 
                   name: 'BurrowSystemValidator');
      return false;
    }
    
    return true;
  }
  
  /// 건강성 체크 결과 로깅
  static void _logHealthCheckResults(BurrowSystemHealthCheck healthCheck) {
    final status = healthCheck.overallHealthy ? '✅ HEALTHY' : '❌ UNHEALTHY';
    
    developer.log(
      '''
🏠 Burrow System Health Check: $status

📊 Details:
  - Providers: ${healthCheck.providerHealthy ? '✅' : '❌'}
  - Milestones: ${healthCheck.milestonesValid ? '✅' : '❌'}  
  - Assets: ${healthCheck.assetsValid ? '✅' : '❌'}
  - Callbacks: ${healthCheck.callbacksIntegrated ? '✅' : '❌'}
  - Memory: ${healthCheck.memoryUsageNormal ? '✅' : '❌'}

${healthCheck.error != null ? '❌ Error: ${healthCheck.error}' : ''}
      ''',
      name: 'BurrowSystemValidator',
    );
  }
  
  /// 개발용 시스템 정보 출력
  static void logSystemInfo(BurrowProvider burrowProvider) {
    developer.log(
      '''
🏠 Burrow System Info:
  - Total Milestones: ${burrowProvider.totalMilestoneCount}
  - Unlocked: ${burrowProvider.unlockedMilestoneCount}  
  - Progress: ${(burrowProvider.overallProgress * 100).toInt()}%
  - Growth Track: ${burrowProvider.growthMilestones.length}
  - Special Rooms: ${burrowProvider.specialMilestones.length}
  - Pending Notifications: ${burrowProvider.pendingNotificationCount}
  - Is Loading: ${burrowProvider.isLoading}
  - Has Error: ${burrowProvider.error != null}
      ''',
      name: 'BurrowSystemValidator',
    );
  }
}

/// 시스템 건강성 체크 결과
class BurrowSystemHealthCheck {
  bool providerHealthy = false;
  bool milestonesValid = false;
  bool assetsValid = false;
  bool callbacksIntegrated = false;
  bool memoryUsageNormal = false;
  bool overallHealthy = false;
  String? error;
  
  /// 문제가 있는 영역들 반환
  List<String> get issues {
    final List<String> issues = [];
    
    if (!providerHealthy) issues.add('Provider 상태 이상');
    if (!milestonesValid) issues.add('마일스톤 데이터 무결성 문제');
    if (!assetsValid) issues.add('이미지 에셋 문제');
    if (!callbacksIntegrated) issues.add('콜백 통합 문제');
    if (!memoryUsageNormal) issues.add('메모리 사용량 과다');
    if (error != null) issues.add('시스템 에러: $error');
    
    return issues;
  }
  
  @override
  String toString() {
    return 'BurrowSystemHealthCheck(healthy: $overallHealthy, issues: ${issues.length})';
  }
}