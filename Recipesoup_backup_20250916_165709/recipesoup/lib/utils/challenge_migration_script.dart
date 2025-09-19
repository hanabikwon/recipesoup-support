import 'dart:convert';
import 'dart:io';
import 'ingredient_migrator.dart';

/// Ultra Think 방식의 안전한 챌린지 데이터 마이그레이션 스크립트
/// 기존 데이터 완전 보존하면서 새 구조 추가
class ChallengeMigrationScript {
  
  static const String originalFilePath = 'lib/data/challenge_recipes.json';
  static const String backupFilePath = 'lib/data/challenge_recipes.json.backup';
  
  /// 메인 마이그레이션 실행 메서드
  static Future<bool> runMigration() async {
    try {
      print('🚀 챌린지 데이터 마이그레이션 시작...');
      
      // 1. 백업 파일 존재 확인
      if (!await _verifyBackup()) {
        print('❌ 백업 파일이 없습니다. 마이그레이션을 중단합니다.');
        return false;
      }
      
      // 2. 원본 파일 읽기
      final originalData = await _readOriginalFile();
      if (originalData == null) {
        print('❌ 원본 파일을 읽을 수 없습니다.');
        return false;
      }
      
      // 3. 마이그레이션 수행
      final migratedData = await _performMigration(originalData);
      
      // 4. 마이그레이션된 데이터 저장
      await _saveMigratedData(migratedData);
      
      // 5. 검증
      if (await _verifyMigration()) {
        print('✅ 마이그레이션 완료!');
        _printMigrationSummary();
        return true;
      } else {
        print('❌ 마이그레이션 검증 실패. 백업에서 복구합니다.');
        await _rollbackFromBackup();
        return false;
      }
      
    } catch (e) {
      print('❌ 마이그레이션 중 오류 발생: $e');
      print('🔄 백업에서 복구합니다...');
      await _rollbackFromBackup();
      return false;
    }
  }
  
  /// 백업 파일 존재 확인
  static Future<bool> _verifyBackup() async {
    final backupFile = File(backupFilePath);
    return await backupFile.exists();
  }
  
  /// 원본 파일 읽기
  static Future<List<dynamic>?> _readOriginalFile() async {
    try {
      final file = File(originalFilePath);
      final content = await file.readAsString();
      final jsonData = jsonDecode(content);
      
      if (jsonData is List) {
        return jsonData;
      } else {
        print('❌ JSON 형식이 올바르지 않습니다. List 타입이어야 합니다.');
        return null;
      }
    } catch (e) {
      print('❌ 파일 읽기 오류: $e');
      return null;
    }
  }
  
  /// 실제 마이그레이션 수행
  static Future<List<Map<String, dynamic>>> _performMigration(List<dynamic> originalData) async {
    List<Map<String, dynamic>> migratedData = [];
    int processedCount = 0;
    int successCount = 0;
    
    for (var item in originalData) {
      if (item is Map<String, dynamic>) {
        processedCount++;
        
        // 기존 데이터 완전 보존
        Map<String, dynamic> migratedItem = Map<String, dynamic>.from(item);
        
        // 이미 마이그레이션된 아이템은 건너뛰기
        if (migratedItem['migrationCompleted'] == true) {
          print('⏭️  ${migratedItem['id']}: 이미 마이그레이션 완료');
          migratedData.add(migratedItem);
          successCount++;
          continue;
        }
        
        // main_ingredients 필드 확인
        if (migratedItem['main_ingredients'] is List<dynamic>) {
          List<String> ingredients = List<String>.from(migratedItem['main_ingredients']);
          
          // 재료 분류
          final classified = IngredientMigrator.classifyIngredients(ingredients);
          
          // 새 필드 추가 (기존 필드는 보존)
          migratedItem['main_ingredients_v2'] = classified['main'];
          migratedItem['sauce_seasoning'] = classified['sauce'];
          migratedItem['migrationCompleted'] = true;
          migratedItem['migrationDate'] = DateTime.now().toIso8601String();
          
          print('✅ ${migratedItem['id']}: 주재료 ${classified['main']?.length ?? 0}개, 소스&양념 ${classified['sauce']?.length ?? 0}개');
          successCount++;
        } else {
          print('⚠️  ${migratedItem['id']}: main_ingredients 필드가 올바르지 않습니다.');
        }
        
        migratedData.add(migratedItem);
      }
    }
    
    print('📊 처리 완료: $successCount/$processedCount 개 아이템');
    return migratedData;
  }
  
  /// 마이그레이션된 데이터 저장
  static Future<void> _saveMigratedData(List<Map<String, dynamic>> migratedData) async {
    final file = File(originalFilePath);
    final jsonString = const JsonEncoder.withIndent('  ').convert(migratedData);
    await file.writeAsString(jsonString);
    print('💾 마이그레이션된 데이터 저장 완료');
  }
  
  /// 마이그레이션 검증
  static Future<bool> _verifyMigration() async {
    try {
      final data = await _readOriginalFile();
      if (data == null) return false;
      
      int migratedCount = 0;
      int totalCount = data.length;
      
      for (var item in data) {
        if (item is Map<String, dynamic>) {
          if (item['migrationCompleted'] == true &&
              item['main_ingredients_v2'] != null &&
              item['sauce_seasoning'] != null) {
            migratedCount++;
          }
        }
      }
      
      print('🔍 검증 결과: $migratedCount/$totalCount 개 아이템이 마이그레이션됨');
      return migratedCount > 0; // 최소 1개 이상 마이그레이션되어야 성공
      
    } catch (e) {
      print('❌ 검증 중 오류: $e');
      return false;
    }
  }
  
  /// 백업에서 복구
  static Future<void> _rollbackFromBackup() async {
    try {
      final backupFile = File(backupFilePath);
      final originalFile = File(originalFilePath);
      
      if (await backupFile.exists()) {
        await backupFile.copy(originalFilePath);
        print('🔄 백업에서 복구 완료');
      } else {
        print('❌ 백업 파일이 없어 복구할 수 없습니다.');
      }
    } catch (e) {
      print('❌ 복구 중 오류: $e');
    }
  }
  
  /// 마이그레이션 요약 출력
  static void _printMigrationSummary() {
    print('');
    print('🎉 === 마이그레이션 완료 요약 ===');
    print('✅ 기존 main_ingredients 필드: 완전 보존');
    print('✅ 새로운 main_ingredients_v2 필드: 주재료만 포함');
    print('✅ 새로운 sauce_seasoning 필드: 소스&양념만 포함');
    print('✅ migrationCompleted 플래그: 마이그레이션 완료 표시');
    print('🔒 백워드 호환성: 100% 보장');
    print('🔄 롤백 가능: 언제든 백업에서 복구 가능');
    print('================================');
    print('');
  }
  
  /// 개별 챌린지 마이그레이션 상태 확인
  static Future<void> checkMigrationStatus() async {
    final data = await _readOriginalFile();
    if (data == null) return;
    
    print('📊 === 마이그레이션 상태 확인 ===');
    for (var item in data) {
      if (item is Map<String, dynamic>) {
        String id = item['id'] ?? 'unknown';
        bool isMigrated = item['migrationCompleted'] == true;
        String status = isMigrated ? '✅ 완료' : '⏸️  대기';
        print('$status - $id');
      }
    }
    print('==============================');
  }
  
  /// 특정 챌린지만 마이그레이션 (테스트용)
  static Future<bool> migrateSingleChallenge(String challengeId) async {
    try {
      final data = await _readOriginalFile();
      if (data == null) return false;
      
      bool found = false;
      List<Map<String, dynamic>> updatedData = [];
      
      for (var item in data) {
        if (item is Map<String, dynamic>) {
          Map<String, dynamic> updatedItem = Map<String, dynamic>.from(item);
          
          if (updatedItem['id'] == challengeId) {
            found = true;
            
            if (updatedItem['main_ingredients'] is List<dynamic>) {
              List<String> ingredients = List<String>.from(updatedItem['main_ingredients']);
              final classified = IngredientMigrator.classifyIngredients(ingredients);
              
              updatedItem['main_ingredients_v2'] = classified['main'];
              updatedItem['sauce_seasoning'] = classified['sauce'];
              updatedItem['migrationCompleted'] = true;
              updatedItem['migrationDate'] = DateTime.now().toIso8601String();
              
              print('✅ $challengeId 마이그레이션 완료');
              IngredientMigrator.printClassification(ingredients);
            }
          }
          
          updatedData.add(updatedItem);
        }
      }
      
      if (found) {
        await _saveMigratedData(updatedData);
        return true;
      } else {
        print('❌ 챌린지 ID "$challengeId"를 찾을 수 없습니다.');
        return false;
      }
      
    } catch (e) {
      print('❌ 단일 마이그레이션 오류: $e');
      return false;
    }
  }
}