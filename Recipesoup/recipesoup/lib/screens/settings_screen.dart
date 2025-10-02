import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/recipe_provider.dart';
import '../providers/burrow_provider.dart';
import '../services/burrow_storage_service.dart';
import '../services/backup_service.dart';
import '../models/backup_data.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: AppTheme.backgroundColor,
              child: Row(
                children: [
                  const Text(
                    '설정',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  // ArchiveScreen과 동일한 높이를 위해 설정 아이콘 추가
                  IconButton(
                    icon: const Icon(
                      Icons.settings,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                    onPressed: null, // 비활성화
                    tooltip: '설정 화면',
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<RecipeProvider>(
                builder: (context, provider, child) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.spacing16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileCard(provider),
                        const SizedBox(height: AppTheme.spacing20),
                        _buildSettingsSection(),
                        const SizedBox(height: AppTheme.spacing20),
                        _buildAboutSection(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(RecipeProvider provider) {
    final totalRecipes = provider.recipes.length;
    final favoriteCount = provider.recipes.where((r) => r.isFavorite).length;
    final averageRating = provider.recipes.isNotEmpty
        ? provider.recipes
            .where((r) => r.rating != null)
            .map((r) => r.rating!)
            .fold(0, (sum, rating) => sum + rating) / 
          provider.recipes.where((r) => r.rating != null).length
        : 0.0;

    return Card(
      elevation: 4,
      color: AppTheme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing20),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(40),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/profile_rabbit.webp', // 사용자가 추가한 토끼 프로필 이미지
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // 이미지 로드 실패시 기본 아이콘 표시
                    return const Icon(
                      Icons.person,
                      size: 40,
                      color: AppTheme.primaryColor,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'Recipesoup',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              '감정과 함께, 나만의 레시피 아카이빙',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn('총 레시피', '$totalRecipes'),
                _buildStatColumn('즐겨찾기', '$favoriteCount'),
                _buildStatColumn(
                  '평균 평점', 
                  averageRating > 0 ? averageRating.toStringAsFixed(1) : '-'
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '설정',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacing16),
        Card(
          elevation: 2,
          color: AppTheme.cardColor,
          child: Column(
            children: [
              _buildSettingsTile(
                icon: Icons.backup,
                title: '백업하기',
                subtitle: '레시피 데이터를 이메일로 공유',
                onTap: () => _showBackupDialog(),
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.restore,
                title: '복원하기',
                subtitle: '백업 파일로 데이터 복원',
                onTap: () => _showRestoreDialog(),
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.refresh,
                title: '토끼굴 데이터 초기화',
                subtitle: '성장 여정 마일스톤 리셋',
                onTap: () => _showClearBurrowDataDialog(context),
                isDestructive: false,
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.delete_sweep,
                title: '데이터 초기화',
                subtitle: '모든 레시피 데이터 삭제',
                onTap: () => _showClearDataDialog(context),
                isDestructive: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '정보',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacing16),
        Card(
          elevation: 2,
          color: AppTheme.cardColor,
          child: Column(
            children: [
              _buildSettingsTile(
                icon: Icons.info,
                title: '앱 정보',
                subtitle: 'Recipesoup v1.0.0',
                onTap: () => _showAppInfoDialog(),
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.privacy_tip,
                title: '개인정보처리방침',
                subtitle: '개인정보 보호 정책',
                onTap: () => _showPrivacyPolicy(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDestructive 
              ? Colors.red.withValues(alpha: 51) 
              : AppTheme.primaryLight.withValues(alpha: 51),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: AppTheme.textTertiary,
        size: 16,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: AppTheme.dividerColor,
      height: 1,
      indent: 16,
      endIndent: 16,
    );
  }


  void _showBackupDialog() {
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final recipes = recipeProvider.recipes;

    if (recipes.isEmpty) {
      _showEmptyDataDialog();
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('데이터 백업'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('총 ${recipes.length}개의 레시피를 백업합니다.'),
              const SizedBox(height: 16),
              const Text(
                '백업된 파일은 이메일, 드라이브 등으로 공유할 수 있으며, '
                '나중에 복원 기능을 통해 데이터를 불러올 수 있습니다.',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performBackup();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('백업 시작'),
            ),
          ],
        );
      },
    );
  }

  void _showRestoreDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('데이터 복원'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('백업 파일로 레시피를 복원합니다.'),
              const SizedBox(height: 16),
              const Text(
                '복원 방식을 선택해주세요.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              // 주요 액션 버튼들 (병합 | 덮어쓰기)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _performRestore(RestoreOption.merge);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('병합'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _performRestore(RestoreOption.overwrite);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('덮어쓰기'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 취소 버튼 (하단 중앙)
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEmptyDataDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('데이터 없음'),
          content: const Text(
            '백업할 레시피가 없습니다.\n\n'
            '레시피를 작성한 후 백업해주세요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performBackup() async {
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final recipes = recipeProvider.recipes;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final backupService = BackupService();

    // 진행상황 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('백업 파일을 생성하는 중...'),
            ],
          ),
        );
      },
    );

    try {
      // 백업 파일 생성
      final backupFilePath = await backupService.createBackup(
        recipes: recipes,
        onProgress: (message, progress) {
          // 진행상황 업데이트는 현재 다이얼로그에서 처리하지 않음
        },
      );

      if (mounted) {
        Navigator.of(context).pop(); // 진행상황 다이얼로그 닫기

        // 공유 확인 다이얼로그
        _showShareBackupDialog(backupService, backupFilePath);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 진행상황 다이얼로그 닫기

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('백업 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showShareBackupDialog(BackupService backupService, String backupFilePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('백업 완료'),
          content: const Text(
            '백업 파일이 생성되었습니다.\n\n'
            '이메일, 클라우드 드라이브 등으로 공유하시겠습니까?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('나중에'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _shareBackupFile(backupService, backupFilePath);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('공유하기'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareBackupFile(BackupService backupService, String backupFilePath) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    bool dialogShown = false;

    try {
      // 공유 진행상황 다이얼로그
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          dialogShown = true;
          return PopScope(
            canPop: false, // 뒤로가기 방지
            child: AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('공유 앱을 여는 중...'),
                  const SizedBox(height: 8),
                  const Text(
                    '잠시만 기다려주세요',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // 전체 타임아웃 20초 설정 (백업 서비스 타임아웃 15초 + 여유 5초)
      final success = await Future.any([
        backupService.shareBackup(
          backupFilePath: backupFilePath,
          onProgress: (message, progress) {
            // 진행상황 업데이트 (다이얼로그가 열려있을 때만)
            if (kDebugMode) {
              print('Backup progress: $message ($progress)');
            }
          },
        ),
        Future.delayed(const Duration(seconds: 20)).then((_) => false),
      ]);

      // 다이얼로그 안전하게 닫기
      if (dialogShown && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogShown = false;
      }

      if (mounted) {
        if (success == true) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('백업 파일이 공유되었습니다! 🎉'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('공유가 취소되었거나 시간이 초과되었습니다.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }

    } catch (e) {
      // 다이얼로그 안전하게 닫기
      if (dialogShown && mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (navError) {
          if (kDebugMode) {
            print('Navigation error while closing dialog: $navError');
          }
        }
        dialogShown = false;
      }

      if (mounted) {
        // 사용자 친화적인 에러 메시지
        String userMessage;
        if (e.toString().contains('timeout') || e.toString().contains('응답하지 않습니다')) {
          userMessage = '공유 기능이 응답하지 않습니다.\n앱을 재시작하고 다시 시도해주세요.';
        } else if (e.toString().contains('파일을 찾을 수 없습니다')) {
          userMessage = '백업 파일을 찾을 수 없습니다.\n백업을 다시 생성해주세요.';
        } else if (e.toString().contains('MissingPluginException')) {
          userMessage = '파일 공유 기능에 문제가 있습니다.\n앱을 재시작해주세요.';
        } else {
          userMessage = '공유 중 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.';
        }

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(userMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: '확인',
              textColor: Colors.white,
              onPressed: () {
                scaffoldMessenger.hideCurrentSnackBar();
              },
            ),
          ),
        );
      }

      // 개발 모드에서만 상세 에러 로그
      if (kDebugMode) {
        print('Backup share error: $e');
      }
    }
  }

  Future<void> _performRestore(RestoreOption option) async {
    // final recipeProvider = Provider.of<RecipeProvider>(context, listen: false); // Unused variable
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final backupService = BackupService();

    // 파일 선택 및 복원 진행상황 다이얼로그
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('백업 파일을 선택해주세요...'),
            ],
          ),
        );
      },
    );

    try {
      // 백업 파일에서 데이터 복원
      final backupData = await backupService.restoreFromFile(
        option: option,
        onProgress: (message, progress) {
          // 진행상황 업데이트
        },
      );

      if (mounted) {
        Navigator.of(context).pop(); // 진행상황 다이얼로그 닫기

        // 복원 확인 다이얼로그 표시
        _showRestoreConfirmDialog(backupData, option);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 진행상황 다이얼로그 닫기

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('복원 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRestoreConfirmDialog(BackupData backupData, RestoreOption option) {
    final optionText = option == RestoreOption.merge ? '병합' : '덮어쓰기';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('복원 확인'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('백업: ${backupData.summary}'),
              const SizedBox(height: 8),
              Text('복원 방식: $optionText'),
              const SizedBox(height: 16),
              Text(
                option == RestoreOption.overwrite
                  ? '기존 데이터가 모두 삭제되고 백업 데이터로 대체됩니다.'
                  : '기존 데이터와 백업 데이터가 병합됩니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: option == RestoreOption.overwrite ? Colors.red : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _applyRestore(backupData, option);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: option == RestoreOption.overwrite ? Colors.red : AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text('$optionText 실행'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _applyRestore(BackupData backupData, RestoreOption option) async {
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // 복원 진행상황 다이얼로그
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('데이터를 복원하는 중... (${backupData.totalRecipes}개)'),
            ],
          ),
        );
      },
    );

    try {
      if (option == RestoreOption.overwrite) {
        // 기존 데이터 모두 삭제
        await recipeProvider.clearAllRecipes();
      }

      // 백업 데이터의 레시피들을 추가
      int restoredCount = 0;
      for (final recipe in backupData.recipes) {
        if (option == RestoreOption.merge) {
          // 병합 모드: ID 충돌 체크
          final existingIds = recipeProvider.recipes.map((r) => r.id).toSet();

          if (existingIds.contains(recipe.id)) {
            // ID 충돌 발생 - 새로운 숫자 ID 생성하여 복원
            // 기존 ID가 숫자형이므로 새 ID도 숫자형으로 생성 (타입 일관성)
            final newId = DateTime.now().millisecondsSinceEpoch.toString();
            final newRecipe = recipe.copyWith(id: newId);
            await recipeProvider.addRecipe(newRecipe);
            restoredCount++;

            debugPrint('🔄 ID 충돌 해결: ${recipe.id} → $newId');
          } else {
            // ID 충돌 없음 - 원본 그대로 저장
            await recipeProvider.addRecipe(recipe);
            restoredCount++;
          }
        } else {
          // 덮어쓰기 모드: 그대로 추가
          await recipeProvider.addRecipe(recipe);
          restoredCount++;
        }
      }

      if (mounted) {
        Navigator.of(context).pop(); // 진행상황 다이얼로그 닫기

        final optionText = option == RestoreOption.merge ? '병합' : '덮어쓰기';
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('복원 완료: $restoredCount개 레시피 ($optionText)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 진행상황 다이얼로그 닫기

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('복원 적용 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAppInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('앱 정보'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                const Text('버전: 1.0.0'),
                const SizedBox(height: AppTheme.spacing8),
                const Text(
                  '감정과 함께하는 레시피 아카이빙 앱입니다. '
                  '단순한 요리법을 넘어 그 순간의 감정과 이야기까지 함께 기록하세요.',
                ),
                const SizedBox(height: AppTheme.spacing16),
                Row(
                  children: [
                    const Icon(
                      Icons.favorite,
                      color: AppTheme.errorColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '감정 기반 요리 일기',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing20),
                const Divider(color: AppTheme.dividerColor),
                const SizedBox(height: AppTheme.spacing16),
                Text(
                  '개발자 정보',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing12),
                const Text(
                  'Recipesoup Team\n'
                  '감정이 담긴 요리 이야기를 소중히 여기는 개발팀입니다.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: AppTheme.spacing16),
                Row(
                  children: [
                    const Icon(
                      Icons.email,
                      color: AppTheme.primaryColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _contactDeveloper(),
                        child: const Text(
                          'recipesoup.team@gmail.com',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing12),
                const Text(
                  '버그 신고, 기능 요청, 앱 사용 중 문제가 있으시면 언제든 연락주세요.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => _contactDeveloper(),
              child: const Text('문의하기'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _contactDeveloper() async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: 'flow.planet.io@gmail.com',
      query: Uri.encodeComponent(
        'subject=Recipesoup 앱 문의&'
        'body=안녕하세요, Recipesoup 팀입니다.\n\n'
        '문의사항을 자세히 작성해주세요:\n\n'
        '앱 버전: 1.0.0\n'
        '기기 정보: ${_getDeviceInfo()}\n\n'
        '문의 내용:\n'
      ),
    );

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        // 이메일 앱을 열 수 없는 경우
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text(
              '이메일 앱을 열 수 없습니다.\n'
              'flow.planet.io@gmail.com으로 직접 연락주세요.',
            ),
            backgroundColor: AppTheme.primaryColor,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('이메일 실행 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showPrivacyPolicy() async {
    const privacyPolicyUrl = 'https://hanabikwon.github.io/recipesoup-privacy/';
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final uri = Uri.parse(privacyPolicyUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.inAppWebView,
          webViewConfiguration: const WebViewConfiguration(
            enableJavaScript: true,
            enableDomStorage: true,
          ),
        );
      } else {
        // 인앱 브라우저를 열 수 없는 경우 외부 브라우저로 fallback
        await launchUrl(uri);
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('개인정보처리방침을 열 수 없습니다: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  String _getDeviceInfo() {
    // 기본적인 플랫폼 정보만 포함
    // 추후 device_info_plus 패키지 추가 시 더 상세한 정보 포함 가능
    return 'Flutter App';
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('데이터 초기화'),
          content: const Text(
            '모든 레시피 데이터가 영구적으로 삭제됩니다. 이 작업은 되돌릴 수 없습니다.\n\n정말 진행하시겠습니까?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _clearAllData(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearAllData(BuildContext context) async {
    final provider = Provider.of<RecipeProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('데이터를 삭제하는 중...'),
            ],
          ),
        );
      },
    );

    try {
      await provider.clearAllRecipes();
      
      if (mounted) {
        navigator.pop(); // 로딩 다이얼로그 닫기
        
        // 성공 메시지
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('모든 데이터가 삭제되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        navigator.pop(); // 로딩 다이얼로그 닫기
        
        // 에러 메시지
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('삭제 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showClearBurrowDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('토끼굴 데이터 초기화'),
          content: const Text(
            '토끼굴 마일스톤 데이터를 초기화하여\n'
            '새로운 32레벨 시스템을 적용합니다.\n\n'
            '기존 토끼굴 진행상황은 사라지지만\n'
            '레시피 데이터는 그대로 유지됩니다.\n\n'
            '진행하시겠습니까?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _clearBurrowData(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('초기화'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearBurrowData(BuildContext context) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('토끼굴 데이터 초기화 중...'),
            ],
          ),
        );
      },
    );

    try {
      // BurrowProvider에서 토끼굴 데이터만 초기화
      final burrowProvider = Provider.of<BurrowProvider>(context, listen: false);
      
      // 토끼굴 스토리지 서비스를 통해 마일스톤과 진행상황만 초기화
      final burrowStorageService = BurrowStorageService();
      await burrowStorageService.resetAllData(); // 토끼굴 데이터만 삭제
      
      // BurrowProvider 재초기화하여 새로운 32레벨 시스템 적용
      await burrowProvider.initialize();

      if (mounted) {
        navigator.pop(); // 로딩 다이얼로그 닫기
        
        // 성공 메시지
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('토끼굴 데이터가 초기화되었습니다! 새로운 32레벨 시스템이 적용되었습니다.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        navigator.pop(); // 로딩 다이얼로그 닫기
        
        // 에러 메시지
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('초기화 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}