import 'dart:io';
import 'challenge_migration_script.dart';
import 'ingredient_migrator.dart';

/// 마이그레이션 테스트 실행 스크립트
/// Ultra Think 방식: 안전한 단계별 테스트
void main() async {
  print('🧪 === 최종 마이그레이션 상태 확인 ===\n');
  
  // 마이그레이션 완료 상태 확인
  await ChallengeMigrationScript.checkMigrationStatus();
  
  print('\n🧪 === 확인 완료 ===');
}

/// 재료 분류 로직 테스트
Future<void> testIngredientClassifier() async {
  print('🧮 재료 분류 로직 테스트...\n');
  
  // 테스트 케이스 1: 미역국
  List<String> meeokGuk = ["미역", "쇠고기", "참기름", "국간장", "다진마늘"];
  print('테스트 1 - 미역국:');
  IngredientMigrator.printClassification(meeokGuk);
  
  // 테스트 케이스 2: 계란볶음밥
  List<String> eggFriedRice = ["밥", "계란", "파", "간장", "참기름"];
  print('테스트 2 - 계란볶음밥:');
  IngredientMigrator.printClassification(eggFriedRice);
  
  // 테스트 케이스 3: 닭죽
  List<String> chickenPorridge = ["닭", "쌀", "대파", "마늘", "생강"];
  print('테스트 3 - 닭죽:');
  IngredientMigrator.printClassification(chickenPorridge);
  
  print('');
}

/// 전체 마이그레이션 실행 (수동 호출)
Future<void> runFullMigration() async {
  print('\n🚀 === 전체 마이그레이션 실행 ===');
  
  print('⚠️  주의: 전체 챌린지 데이터를 마이그레이션합니다.');
  print('📁 백업 파일: lib/data/challenge_recipes.json.backup');
  print('🔄 롤백 가능: 문제 시 백업에서 자동 복구됩니다.\n');
  
  // 사용자 확인 (실제 환경에서는 stdin.readLineSync() 사용 가능)
  print('계속하시겠습니까? (y/N)');
  
  // 자동으로 진행 (테스트 환경)
  String response = 'y'; // 실제로는 stdin.readLineSync() ?? 'n';
  
  if (response.toLowerCase() == 'y') {
    bool result = await ChallengeMigrationScript.runMigration();
    
    if (result) {
      print('\n🎉 전체 마이그레이션 완료!');
      print('✨ 이제 3탭 구조를 사용할 수 있습니다.');
    } else {
      print('\n❌ 마이그레이션 실패');
      print('🔙 백업에서 복구되었습니다.');
    }
  } else {
    print('❌ 마이그레이션이 취소되었습니다.');
  }
}

/// 긴급 롤백 실행
Future<void> emergencyRollback() async {
  print('🚨 === 긴급 롤백 실행 ===');
  
  final backupFile = File('lib/data/challenge_recipes.json.backup');
  final originalFile = File('lib/data/challenge_recipes.json');
  
  if (await backupFile.exists()) {
    await backupFile.copy('lib/data/challenge_recipes.json');
    print('✅ 백업에서 복구 완료');
  } else {
    print('❌ 백업 파일이 없습니다.');
  }
}