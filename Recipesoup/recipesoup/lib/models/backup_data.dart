import 'recipe.dart';

/// 백업 파일 포맷 버전
class BackupVersion {
  static const String current = '1.0.0';
  static const String appVersion = '1.0.0';
}

/// 백업 데이터 모델
/// ZIP 파일 내 JSON 구조를 정의
class BackupData {
  /// 백업 파일 포맷 버전
  final String version;

  /// 백업 생성 시 앱 버전
  final String appVersion;

  /// 백업 생성 시각
  final DateTime createdAt;

  /// 총 레시피 수
  final int totalRecipes;

  /// 실제 레시피 데이터 리스트
  final List<Recipe> recipes;

  /// 백업 파일 설명 (옵션)
  final String? description;

  const BackupData({
    required this.version,
    required this.appVersion,
    required this.createdAt,
    required this.totalRecipes,
    required this.recipes,
    this.description,
  });

  /// 현재 버전으로 백업 데이터 생성
  factory BackupData.create({
    required List<Recipe> recipes,
    String? description,
  }) {
    return BackupData(
      version: BackupVersion.current,
      appVersion: BackupVersion.appVersion,
      createdAt: DateTime.now(),
      totalRecipes: recipes.length,
      recipes: recipes,
      description: description,
    );
  }

  /// JSON으로 변환 (ZIP 파일 내 저장용)
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'appVersion': appVersion,
      'createdAt': createdAt.toIso8601String(),
      'totalRecipes': totalRecipes,
      'description': description,
      'recipes': recipes.map((recipe) => recipe.toJson()).toList(),
    };
  }

  /// JSON에서 복원
  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      version: json['version'] as String? ?? '1.0.0',
      appVersion: json['appVersion'] as String? ?? '1.0.0',
      createdAt: DateTime.parse(json['createdAt'] as String),
      totalRecipes: json['totalRecipes'] as int,
      description: json['description'] as String?,
      recipes: (json['recipes'] as List<dynamic>)
          .map((recipeJson) {
            if (recipeJson is Map<String, dynamic>) {
              return Recipe.fromJson(recipeJson);
            } else if (recipeJson is Map) {
              // 안전한 변환
              return Recipe.fromJson(Map<String, dynamic>.from(recipeJson));
            } else {
              throw ArgumentError('Invalid recipe data type: ${recipeJson.runtimeType}');
            }
          })
          .toList(),
    );
  }

  /// 백업 파일 호환성 체크
  bool get isCompatible {
    // 메이저 버전이 같으면 호환성 있음
    try {
      final backupMajor = int.parse(version.split('.')[0]);
      final currentMajor = int.parse(BackupVersion.current.split('.')[0]);
      return backupMajor == currentMajor;
    } catch (e) {
      // 파싱 실패시 호환성 없음으로 간주
      return false;
    }
  }

  /// 백업 파일 유효성 검증
  bool get isValid {
    return version.isNotEmpty &&
           appVersion.isNotEmpty &&
           totalRecipes >= 0 &&
           recipes.length == totalRecipes &&
           recipes.every((recipe) => recipe.isValid);
  }

  /// 백업 파일 요약 정보
  String get summary {
    final dateStr = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
    return '레시피 ${totalRecipes}개 ($dateStr 백업)';
  }

  /// 상세 정보
  Map<String, dynamic> get details {
    return {
      'version': version,
      'appVersion': appVersion,
      'createdAt': createdAt,
      'totalRecipes': totalRecipes,
      'description': description,
      'isCompatible': isCompatible,
      'isValid': isValid,
    };
  }

  @override
  String toString() => 'BackupData(version: $version, recipes: ${recipes.length})';
}

/// 백업 복원 옵션
enum RestoreOption {
  merge,      // 기존 데이터와 병합
  overwrite,  // 기존 데이터 덮어쓰기
}

/// 백업 복원 결과
class RestoreResult {
  /// 복원 성공 여부
  final bool success;

  /// 복원된 레시피 수
  final int restoredCount;

  /// 건너뛴 레시피 수 (중복 등)
  final int skippedCount;

  /// 에러 메시지 (실패시)
  final String? error;

  /// 복원 옵션
  final RestoreOption option;

  const RestoreResult({
    required this.success,
    required this.restoredCount,
    required this.skippedCount,
    this.error,
    required this.option,
  });

  /// 성공 결과 생성
  factory RestoreResult.success({
    required int restoredCount,
    required int skippedCount,
    required RestoreOption option,
  }) {
    return RestoreResult(
      success: true,
      restoredCount: restoredCount,
      skippedCount: skippedCount,
      option: option,
    );
  }

  /// 실패 결과 생성
  factory RestoreResult.failure({
    required String error,
    required RestoreOption option,
  }) {
    return RestoreResult(
      success: false,
      restoredCount: 0,
      skippedCount: 0,
      error: error,
      option: option,
    );
  }

  /// 결과 요약 문자열
  String get summary {
    if (!success) {
      return '복원 실패: $error';
    }

    final optionText = option == RestoreOption.merge ? '병합' : '덮어쓰기';
    return '복원 완료: ${restoredCount}개 추가 (${skippedCount}개 건너뜀, $optionText 모드)';
  }

  @override
  String toString() => summary;
}