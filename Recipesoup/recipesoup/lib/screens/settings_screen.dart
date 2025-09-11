import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/recipe_provider.dart';
import '../providers/burrow_provider.dart';
import '../services/burrow_storage_service.dart';

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
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(40),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/profile_rabbit.png', // 사용자가 추가한 토끼 프로필 이미지
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
                icon: Icons.notifications,
                title: '알림 설정',
                subtitle: '레시피 리마인더 및 알림',
                onTap: () => _showComingSoonDialog('알림 설정'),
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.cloud_upload,
                title: '백업 및 복원',
                subtitle: '데이터 백업하기',
                onTap: () => _showComingSoonDialog('백업 및 복원'),
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.download,
                title: '내보내기',
                subtitle: '레시피를 파일로 내보내기',
                onTap: () => _showComingSoonDialog('내보내기'),
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.refresh,
                title: '토끼굴 데이터 초기화',
                subtitle: '32레벨 시스템 적용 (마일스톤만 재생성)',
                onTap: () => _showClearBurrowDataDialog(context),
                isDestructive: false,
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.delete_sweep,
                title: '데이터 초기화',
                subtitle: '모든 레시피 데이터 삭제 (테스트용)',
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
                icon: Icons.help,
                title: '도움말',
                subtitle: '앱 사용법 및 FAQ',
                onTap: () => _showComingSoonDialog('도움말'),
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.privacy_tip,
                title: '개인정보처리방침',
                subtitle: '개인정보 보호 정책',
                onTap: () => _showComingSoonDialog('개인정보처리방침'),
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
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('준비 중'),
          content: Text('$feature 기능은 곧 추가될 예정입니다.'),
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

  void _showAppInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('앱 정보'),
          content: Column(
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
            ],
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

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('⚠️ 데이터 초기화'),
          content: const Text(
            '모든 레시피 데이터가 영구적으로 삭제됩니다.\n'
            '이 작업은 되돌릴 수 없습니다.\n\n'
            '정말 진행하시겠습니까?'
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
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        
        // 성공 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 모든 데이터가 삭제되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        
        // 에러 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 삭제 실패: $e'),
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
          title: const Text('🔄 토끼굴 데이터 초기화'),
          content: const Text(
            '토끼굴 마일스톤 데이터를 초기화하여\n'
            '새로운 32레벨 시스템을 적용합니다.\n\n'
            '⚠️ 기존 토끼굴 진행상황은 사라지지만\n'
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
                foregroundColor: AppTheme.primaryColor,
              ),
              child: const Text('초기화'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearBurrowData(BuildContext context) async {
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
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        
        // 성공 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 토끼굴 데이터가 초기화되었습니다! 새로운 32레벨 시스템이 적용되었습니다.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        
        // 에러 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 초기화 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}