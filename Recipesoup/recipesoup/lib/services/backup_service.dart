import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:archive/archive.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../models/backup_data.dart';
import '../models/recipe.dart';

/// 백업 진행상황 콜백 타입
typedef BackupProgressCallback = void Function(String message, double progress);

/// 레시피 백업/복원 서비스
/// 안전하고 호환성 있는 데이터 백업/복원 기능 제공
class BackupService {
  static const String _backupFileName = 'recipes_backup.json';
  static const String _zipExtension = '.zip';

  /// 레시피 데이터를 ZIP 백업 파일로 생성
  ///
  /// [recipes]: 백업할 레시피 리스트
  /// [onProgress]: 진행상황 콜백 (옵션)
  ///
  /// Returns: 생성된 ZIP 파일 경로
  /// Throws: [BackupException] 백업 실패시
  Future<String> createBackup({
    required List<Recipe> recipes,
    BackupProgressCallback? onProgress,
  }) async {
    try {
      onProgress?.call('백업 데이터 준비중...', 0.1);

      // 백업 데이터 생성
      final backupData = BackupData.create(
        recipes: recipes,
        description: '${recipes.length}개 레시피 백업',
      );

      onProgress?.call('JSON 변환중...', 0.3);

      // JSON으로 직렬화
      final jsonString = json.encode(backupData.toJson());
      final jsonBytes = utf8.encode(jsonString);

      onProgress?.call('ZIP 파일 생성중...', 0.6);

      // ZIP 아카이브 생성
      final archive = Archive();
      final file = ArchiveFile(_backupFileName, jsonBytes.length, jsonBytes);
      archive.addFile(file);

      // ZIP 압축
      final zipData = ZipEncoder().encode(archive);
      if (zipData == null) {
        throw BackupException('ZIP 압축에 실패했습니다');
      }

      onProgress?.call('파일 저장중...', 0.8);

      // 임시 디렉토리에 ZIP 파일 저장
      final tempDir = await getTemporaryDirectory();
      final fileName = _generateBackupFileName();
      final zipFile = File(path.join(tempDir.path, fileName));

      await zipFile.writeAsBytes(zipData);

      onProgress?.call('백업 완료!', 1.0);

      if (kDebugMode) {
        print('✅ Backup created: ${zipFile.path} (${recipes.length} recipes)');
      }

      return zipFile.path;

    } catch (e) {
      if (e is BackupException) rethrow;
      throw BackupException('백업 생성 실패: $e');
    }
  }

  /// 백업 파일을 공유 (이메일, 드라이브 등)
  ///
  /// [backupFilePath]: 백업 ZIP 파일 경로
  /// [onProgress]: 진행상황 콜백 (옵션)
  ///
  /// Returns: 공유 성공 여부
  /// Throws: [BackupException] 공유 실패시
  Future<bool> shareBackup({
    required String backupFilePath,
    BackupProgressCallback? onProgress,
  }) async {
    try {
      onProgress?.call('공유 준비중...', 0.5);

      final file = File(backupFilePath);
      if (!await file.exists()) {
        throw BackupException('백업 파일을 찾을 수 없습니다');
      }

      onProgress?.call('공유 앱 열기...', 0.8);

      // 파일 공유 (이메일, 드라이브, 메신저 등) - 타임아웃 처리 추가
      final xFile = XFile(
        backupFilePath,
        name: path.basename(backupFilePath),
        mimeType: 'application/zip',
      );

      // 타임아웃 15초 설정 (더 짧게)
      final result = await Future.any([
        Share.shareXFiles(
          [xFile],
          subject: 'Recipesoup 레시피 백업',
          text: '감정 기반 레시피 백업 파일입니다.\n\nRecipesoup 앱에서 복원하여 사용하세요.',
        ),
        Future.delayed(const Duration(seconds: 15)).then((_) =>
          const ShareResult('timeout', ShareResultStatus.unavailable)
        ),
      ]);

      // 타임아웃 체크
      if (result.status == ShareResultStatus.unavailable) {
        throw BackupException('공유 기능이 응답하지 않습니다. 잠시 후 다시 시도해주세요.');
      }

      onProgress?.call('공유 완료!', 1.0);

      if (kDebugMode) {
        print('✅ Backup shared: $result');
      }

      return result.status == ShareResultStatus.success;

    } catch (e) {
      if (e is BackupException) rethrow;

      // iOS 특화 에러 처리
      if (e.toString().contains('MissingPluginException')) {
        throw BackupException('파일 공유 기능을 사용할 수 없습니다. 앱을 재시작해주세요.');
      } else if (e.toString().contains('PlatformException')) {
        throw BackupException('시스템 에러로 공유할 수 없습니다. 잠시 후 다시 시도해주세요.');
      }

      throw BackupException('백업 공유 실패: ${e.toString().length > 100 ? '시스템 오류가 발생했습니다' : e}');
    }
  }

  /// 사용자가 선택한 파일에서 백업 복원
  ///
  /// [option]: 복원 옵션 (병합/덮어쓰기)
  /// [onProgress]: 진행상황 콜백 (옵션)
  ///
  /// Returns: [BackupData] 복원된 백업 데이터
  /// Throws: [BackupException] 복원 실패시
  Future<BackupData> restoreFromFile({
    required RestoreOption option,
    BackupProgressCallback? onProgress,
  }) async {
    try {
      onProgress?.call('파일 선택 대기중...', 0.1);

      // 파일 선택기로 ZIP 파일 선택
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        throw BackupException('파일이 선택되지 않았습니다');
      }

      final filePath = result.files.first.path;
      if (filePath == null) {
        throw BackupException('선택한 파일 경로를 확인할 수 없습니다');
      }

      onProgress?.call('백업 파일 검증중...', 0.3);

      // 백업 파일 복원
      final backupData = await _extractBackupFromZip(filePath);

      onProgress?.call('데이터 유효성 검증중...', 0.6);

      // 유효성 검증
      if (!backupData.isValid) {
        throw BackupException('백업 파일이 손상되었거나 올바르지 않습니다');
      }

      // 호환성 체크
      if (!backupData.isCompatible) {
        throw BackupException(
          '호환되지 않는 백업 파일입니다.\n'
          '백업 버전: ${backupData.version}\n'
          '현재 지원 버전: ${BackupVersion.current}'
        );
      }

      onProgress?.call('복원 준비 완료!', 1.0);

      if (kDebugMode) {
        print('✅ Backup restored: ${backupData.totalRecipes} recipes');
      }

      return backupData;

    } catch (e) {
      if (e is BackupException) rethrow;
      throw BackupException('백업 복원 실패: $e');
    }
  }

  /// 백업 파일 유효성 검증 (선택만, 복원 안함)
  ///
  /// [filePath]: 검증할 ZIP 파일 경로 (옵션, null이면 파일 선택기 사용)
  ///
  /// Returns: [BackupData] 검증된 백업 데이터
  /// Throws: [BackupException] 검증 실패시
  Future<BackupData> validateBackupFile([String? filePath]) async {
    try {
      String targetPath;

      if (filePath != null) {
        targetPath = filePath;
      } else {
        // 파일 선택기 사용
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['zip'],
          allowMultiple: false,
        );

        if (result == null || result.files.isEmpty) {
          throw BackupException('파일이 선택되지 않았습니다');
        }

        final selectedPath = result.files.first.path;
        if (selectedPath == null) {
          throw BackupException('선택한 파일 경로를 확인할 수 없습니다');
        }
        targetPath = selectedPath;
      }

      // 백업 데이터 추출 및 검증
      final backupData = await _extractBackupFromZip(targetPath);

      if (!backupData.isValid) {
        throw BackupException('백업 파일이 손상되었거나 올바르지 않습니다');
      }

      return backupData;

    } catch (e) {
      if (e is BackupException) rethrow;
      throw BackupException('백업 파일 검증 실패: $e');
    }
  }

  /// ZIP 파일에서 백업 데이터 추출 (내부 메서드)
  Future<BackupData> _extractBackupFromZip(String zipFilePath) async {
    final zipFile = File(zipFilePath);
    if (!await zipFile.exists()) {
      throw BackupException('백업 파일을 찾을 수 없습니다: $zipFilePath');
    }

    // ZIP 파일 읽기
    final zipBytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(zipBytes);

    // recipes_backup.json 파일 찾기
    ArchiveFile? jsonFile;
    for (final file in archive) {
      if (file.name == _backupFileName && file.isFile) {
        jsonFile = file;
        break;
      }
    }

    if (jsonFile == null) {
      throw BackupException('백업 파일에서 레시피 데이터를 찾을 수 없습니다');
    }

    // JSON 데이터 추출
    final jsonBytes = jsonFile.content as Uint8List;
    final jsonString = utf8.decode(jsonBytes);

    try {
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      return BackupData.fromJson(jsonData);
    } catch (e) {
      throw BackupException('백업 데이터 형식이 올바르지 않습니다: $e');
    }
  }

  /// 백업 파일명 생성
  String _generateBackupFileName() {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    return 'recipesoup_backup_$dateStr$_zipExtension';
  }

  /// 백업 파일 정리 (임시 파일 삭제)
  Future<void> cleanupBackupFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();

      for (final file in files) {
        if (file is File &&
            file.path.contains('recipesoup_backup_') &&
            file.path.endsWith(_zipExtension)) {
          await file.delete();
          if (kDebugMode) {
            print('🗑️ Cleaned up backup file: ${file.path}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to cleanup backup files: $e');
      }
      // 정리 실패는 치명적이지 않으므로 예외를 다시 던지지 않음
    }
  }
}

/// 백업 서비스 전용 예외 클래스
class BackupException implements Exception {
  final String message;

  const BackupException(this.message);

  @override
  String toString() => 'BackupException: $message';
}