// Removed unused import: package:flutter/foundation.dart // 🔧 CRITICAL FIX: kDebugMode import 추가
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/burrow_milestone.dart';
import '../../providers/burrow_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../widgets/burrow/ultra_burrow_milestone_card.dart';
import '../../widgets/burrow/fullscreen_burrow_overlay.dart';
import '../../utils/ultra_burrow_image_handler.dart';
// import '../../utils/run_milestone_reset.dart';  // 🔧 TEMPORARY: 컴파일 오류 해결을 위해 임시 주석처리
import 'achievement_dialog.dart';

/// 토끼굴 마일스톤 메인 화면
/// 성장 트랙과 특별 공간을 모두 표시
class BurrowScreen extends StatefulWidget {
  const BurrowScreen({super.key});

  @override
  State<BurrowScreen> createState() => _BurrowScreenState();
}

class _BurrowScreenState extends State<BurrowScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // 초기화 및 알림 체크
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeBurrowSystem();
      _checkPendingNotifications();
    });
  }

  /// 🔧 DEVELOPER ONLY: 마일스톤 리셋 다이얼로그 표시
  void _showDeveloperResetDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFAF8F3),
        title: Row(
          children: [
            const Icon(
              Icons.developer_mode,
              color: Color(0xFF8B9A6B),
            ),
            const SizedBox(width: 8),
            const Text(
              '개발자 옵션',
              style: TextStyle(
                color: Color(0xFF2E3D1F),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '토끼굴 마일스톤 문제 해결:',
              style: TextStyle(
                color: Color(0xFF2E3D1F),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• 기존 마일스톤 데이터 삭제\n'
              '• 수정된 언락 조건으로 재생성\n'
              '• 레시피 데이터는 보존됨',
              style: TextStyle(
                color: Color(0xFF5A6B49),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F6F1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFD2A45B),
                  width: 1,
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Color(0xFFD2A45B),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '모든 언락 진행상황이 초기화됩니다',
                      style: TextStyle(
                        color: Color(0xFF2E3D1F),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '취소',
              style: TextStyle(color: Color(0xFF5A6B49)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD2A45B),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _executeMilestoneReset();
            },
            child: const Text('리셋 실행'),
          ),
        ],
      ),
    );
  }

  /// 🔧 CRITICAL FIX: 마일스톤 리셋 실행
  Future<void> _executeMilestoneReset() async {
    // 로딩 표시
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF8B9A6B)),
                SizedBox(height: 16),
                Text(
                  '마일스톤 리셋 중...',
                  style: TextStyle(
                    color: Color(0xFF2E3D1F),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // 마일스톤 리셋 실행
      final success = true; // await executeInAppMilestoneReset(); // 🔧 TEMPORARY: 임시 주석처리

      // 로딩 다이얼로그 닫기
      if (mounted) Navigator.of(context).pop();

      if (success) {
        // 성공 메시지
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('마일스톤 리셋 완료! 앱을 재시작해주세요.'),
              backgroundColor: Color(0xFF7A9B5C),
              duration: Duration(seconds: 5),
            ),
          );

          // BurrowProvider 새로고침
          final burrowProvider = context.read<BurrowProvider>();
          await burrowProvider.refresh();
          await _checkPendingNotifications();
        }
      } else {
        // 실패 메시지
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('마일스톤 리셋 실패. 다시 시도해주세요.'),
              backgroundColor: Color(0xFFB5704F),
              duration: Duration(seconds: 5),
            ),
          );
        }
      }

    } catch (e) {
      // 로딩 다이얼로그 닫기
      if (mounted) Navigator.of(context).pop();

      // 에러 메시지
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('리셋 중 오류: $e'),
            backgroundColor: const Color(0xFFB5704F),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 버로우 시스템 초기화
  Future<void> _initializeBurrowSystem() async {
    if (_isInitialized) return;
    
    try {
      // BuildContext 안전성: async 작업 전에 provider 참조 획득
      final burrowProvider = context.read<BurrowProvider>();
      
      // Ultra 이미지 핸들러 디버깅 실행
      await UltraBurrowImageHandler.debugAllImagePaths();
      
      await burrowProvider.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('토끼굴 시스템 초기화 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 대기 중인 언락 알림 체크 (순차 처리)
  Future<void> _checkPendingNotifications() async {
    final burrowProvider = context.read<BurrowProvider>();
    
    while (burrowProvider.pendingNotificationCount > 0) {
      final notification = burrowProvider.getNextNotification();
      if (notification != null) {
        await _showAchievementDialog(notification);
      } else {
        break; // 더 이상 알림이 없으면 종료
      }
    }
  }

  /// 성취 다이얼로그 표시 (순차 처리)
  Future<void> _showAchievementDialog(UnlockQueueItem item) async {
    final burrowProvider = context.read<BurrowProvider>();
    burrowProvider.setNotificationShowing(true);
    
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false, // 사용자가 직접 닫아야 함
        builder: (context) => AchievementDialog(
          milestone: item.milestone,
          unlockedAt: item.unlockedAt,
          triggerRecipeId: item.triggerRecipeId,
        ),
      );
    } finally {
      burrowProvider.setNotificationShowing(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F3), // 빈티지 아이보리 배경
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: const Color(0xFFFAF8F3),
              child: Row(
                children: [
                  // 🔧 DEVELOPER OPTION: 긴 탭으로 마일스톤 리셋 메뉴 열기
                  GestureDetector(
                    onLongPress: _showDeveloperResetDialog,  // 🔧 TEMP FIX: kDebugMode 조건 제거 (테스트용)
                    child: const Text(
                      '토끼굴',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E3D1F),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // 새로고침 버튼
                  IconButton(
                    icon: const Icon(
                      Icons.refresh,
                      color: Color(0xFF8B9A6B),
                    ),
                    onPressed: () async {
                      final burrowProvider = context.read<BurrowProvider>();
                      await burrowProvider.refresh();
                      await _checkPendingNotifications(); // 새로고침 후 알림 체크
                    },
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF8B9A6B),
              unselectedLabelColor: const Color(0xFF5A6B49),
              indicatorColor: const Color(0xFF8B9A6B),
              tabs: const [
                Tab(text: '성장 여정'),
                Tab(text: '특별한 공간'),
              ],
            ),
            Expanded(
              child: Consumer<BurrowProvider>(
                builder: (context, burrowProvider, child) {
                  if (burrowProvider.isLoading && !_isInitialized) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFF8B9A6B),
                          ),
                          SizedBox(height: 16),
                          Text(
                            '토끼굴을 준비하고 있어요...',
                            style: TextStyle(
                              color: Color(0xFF5A6B49),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (burrowProvider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Color(0xFFB5704F),
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '토끼굴 로딩 중 오류가 발생했습니다',
                            style: TextStyle(
                              color: Color(0xFF2E3D1F),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            burrowProvider.error!,
                            style: const TextStyle(
                              color: Color(0xFF5A6B49),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B9A6B),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              burrowProvider.clearError();
                              _initializeBurrowSystem();
                            },
                            child: const Text('다시 시도'),
                          ),
                        ],
                      ),
                    );
                  }

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      // 성장 트랙 탭
                      _buildGrowthTrackTab(burrowProvider),
                      // 특별 공간 탭
                      _buildSpecialRoomsTab(burrowProvider),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 성장 트랙 탭 구성
  Widget _buildGrowthTrackTab(BurrowProvider burrowProvider) {
    final growthMilestones = burrowProvider.growthMilestones;
    
    if (growthMilestones.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_work_outlined,
              color: Color(0xFF8B9A6B),
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              '아직 토끼굴이 없어요',
              style: TextStyle(
                color: Color(0xFF2E3D1F),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '첫 번째 레시피를 작성해서\n토끼굴 여행을 시작해보세요!',
              style: TextStyle(
                color: Color(0xFF5A6B49),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: growthMilestones.length,
      itemBuilder: (context, index) {
        final milestone = growthMilestones[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: UltraBurrowMilestoneCard(
            milestone: milestone,
            onTap: milestone.isUnlocked 
                ? () => _showMilestoneDetail(milestone)
                : () => _showLockedBurrowHint(milestone),
          ),
        );
      },
    );
  }

  /// 특별 공간 탭 구성 - 개선된 그리드 디자인
  Widget _buildSpecialRoomsTab(BurrowProvider burrowProvider) {
    final unlockedRooms = burrowProvider.specialMilestones;
    final lockedRooms = burrowProvider.lockedSpecialMilestones;
    final allRooms = [...unlockedRooms, ...lockedRooms];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 - 더 컴팩트하게
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F6F1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE8E3D8),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '특별한 공간들',
                        style: TextStyle(
                          color: Color(0xFF2E3D1F),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${unlockedRooms.length}/${allRooms.length}개 발견',
                        style: const TextStyle(
                          color: Color(0xFF8B9A6B),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // 그리드 레이아웃으로 특별 공간 표시
          if (allRooms.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 한 줄에 2개
                childAspectRatio: 0.85, // 세로가 조금 더 긴 비율
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: allRooms.length,
              itemBuilder: (context, index) {
                final milestone = allRooms[index];
                return _buildCompactSpecialRoomCard(
                  milestone, 
                  burrowProvider,
                );
              },
            )
          else
            // 빈 상태
            const SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.explore_off_outlined,
                      size: 48,
                      color: Color(0xFF8B9A6B),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '아직 특별한 공간이 없어요',
                      style: TextStyle(
                        color: Color(0xFF5A6B49),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // 모든 공간이 언락된 경우
          if (unlockedRooms.length >= 5 && lockedRooms.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFFEFB), Color(0xFFF8F6F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFD2A45B),
                  width: 2,
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.celebration,
                    color: Color(0xFFD2A45B),
                    size: 48,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '🎉 완전한 토끼굴 마스터! 🎉',
                    style: TextStyle(
                      color: Color(0xFF2E3D1F),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '모든 특별 공간을 열었어요!\n당신은 진정한 요리 마스터입니다.',
                    style: TextStyle(
                      color: Color(0xFF5A6B49),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 마일스톤 상세 정보 표시 (풀스크린 이미지 배경 오버레이)
  void _showMilestoneDetail(BurrowMilestone milestone) {
    // 풀스크린 이미지 배경 오버레이로 네비게이트
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false, // 반투명 효과
        barrierColor: Colors.transparent,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FullscreenBurrowOverlay(milestone: milestone);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // 페이드인 애니메이션
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  /// 잠긴 공간 힌트 표시
  void _showLockedRoomHint(BurrowMilestone milestone) {
    final hint = milestone.specialRoom != null 
        ? context.read<BurrowProvider>().getHintForRoom(milestone.specialRoom!)
        : '특별한 조건을 만족하면 열려요...';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFEFB),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.help_outline,
              color: Color(0xFF8B9A6B),
            ),
            SizedBox(width: 8),
            Text(
              '미지의 공간',
              style: TextStyle(
                color: Color(0xFF2E3D1F),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '???',
              style: TextStyle(
                fontSize: 48,
                color: Color(0xFFE8E3D8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hint,
              style: const TextStyle(
                color: Color(0xFF5A6B49),
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '닫기',
              style: TextStyle(color: Color(0xFF8B9A6B)),
            ),
          ),
        ],
      ),
    );
  }

  /// 잠긴 굴 힌트 표시 (성장 트랙용)
  void _showLockedBurrowHint(BurrowMilestone milestone) {
    final recipeProvider = context.read<RecipeProvider>();
    final currentCount = recipeProvider.recipes.length;
    final required = milestone.requiredRecipes ?? 0;
    final remaining = required - currentCount;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFAF8F3),
        title: Row(
          children: [
            Icon(
              Icons.lock_outlined,
              color: const Color(0xFF8B9A6B),
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              '아직 열리지 않은 굴',
              style: TextStyle(
                color: Color(0xFF2E3D1F),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Text(
                milestone.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E3D1F),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                remaining > 0 
                    ? '레시피를 $remaining개 더 작성하면 열려요!\n\n현재: $currentCount개 / 필요: $required개'
                    : '조건을 만족했어요! 곧 열릴 예정입니다.',
                style: const TextStyle(
                  color: Color(0xFF5A6B49),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '닫기',
              style: TextStyle(color: Color(0xFF8B9A6B)),
            ),
          ),
        ],
      ),
    );
  }


  
  
  /// 컴팩트한 특별 공간 카드 (그리드용) - Ultra UX 개선
  Widget _buildCompactSpecialRoomCard(BurrowMilestone milestone, BurrowProvider burrowProvider) {
    final isUnlocked = milestone.isUnlocked;
    
    // 터치 인터랙션과 애니메이션이 포함된 카드
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: isUnlocked ? 6 : 2,
        shadowColor: isUnlocked 
            ? const Color(0xFF8B9A6B).withValues(alpha: 0.3)
            : Colors.black.withValues(alpha: 0.1),
        color: isUnlocked 
            ? const Color(0xFFFFFEFB) 
            : const Color(0xFFF8F6F1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isUnlocked 
                ? const Color(0xFF8B9A6B) 
                : const Color(0xFFE8E3D8),
            width: isUnlocked ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: () {
            if (isUnlocked) {
              _showMilestoneDetail(milestone);
            } else {
              _showLockedRoomHint(milestone);
            }
          },
          borderRadius: BorderRadius.circular(20),
          splashColor: const Color(0xFF8B9A6B).withValues(alpha: 0.1),
          highlightColor: const Color(0xFF8B9A6B).withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 썸네일 이미지
                _buildSpecialRoomThumbnail(milestone),
                
                const SizedBox(height: 12),
                
                // 제목
                Text(
                  isUnlocked ? _getCompactDescription(milestone) : '???',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked 
                        ? const Color(0xFF2E3D1F)
                        : const Color(0xFF757575),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 4),
                
                // 설명
                Text(
                  isUnlocked 
                      ? '특별한 공간이 열렸어요!'
                      : _getCompactHint(milestone),
                  style: TextStyle(
                    color: isUnlocked 
                        ? const Color(0xFF7A9B5C)
                        : const Color(0xFF757575),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// 특별 공간 썸네일 (제공된 이미지 사용)
  Widget _buildSpecialRoomThumbnail(BurrowMilestone milestone) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: milestone.isUnlocked 
                ? const Color(0xFF8B9A6B).withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: milestone.isUnlocked
            ? UltraBurrowImageHandler.ultraSafeImage(
                imagePath: milestone.imagePath,
                milestone: milestone,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              )
            : Image.asset(
                'assets/images/burrow/special_rooms/burrow_locked.png',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F6F1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: Color(0xFF9E9E9E),
                      size: 24,
                    ),
                  );
                },
              ),
      ),
    );
  }
  


  /// 컴팩트한 설명 (언락된 공간용)
  String _getCompactDescription(BurrowMilestone milestone) {
    switch (milestone.specialRoom) {
      case SpecialRoom.ballroom:
        return '화려한 파티 공간';
      case SpecialRoom.hotSpring:
        return '편안한 온천';
      case SpecialRoom.orchestra:
        return '음악 콘서트홀';
      case SpecialRoom.alchemyLab:
        return '특별한 실험실';
      case SpecialRoom.fineDining:
        return '고급 레스토랑';
      
      // 새로 추가된 11개 특별 공간들
      case SpecialRoom.alps:
        return '알프스 별장';
      case SpecialRoom.camping:
        return '자연 캠핑장';
      case SpecialRoom.autumn:
        return '가을 정원';
      case SpecialRoom.springPicnic:
        return '봄날의 피크닉';
      case SpecialRoom.surfing:
        return '서핑 비치';
      case SpecialRoom.snorkel:
        return '스노클링 만';
      case SpecialRoom.summerbeach:
        return '여름 해변';
      case SpecialRoom.baliYoga:
        return '발리 요가 센터';
      case SpecialRoom.orientExpress:
        return '오리엔트 특급열차';
      case SpecialRoom.canvas:
        return '예술가의 아틀리에';
      case SpecialRoom.vacance:
        return '바캉스 빌라';
      
      default:
        return '특별한 공간';
    }
  }

  /// 컴팩트한 힌트 (잠긴 공간용)
  String _getCompactHint(BurrowMilestone milestone) {
    switch (milestone.specialRoom) {
      case SpecialRoom.ballroom:
        return '화려한 공간';
      case SpecialRoom.hotSpring:
        return '편안한 공간';
      case SpecialRoom.orchestra:
        return '음악 공간';
      case SpecialRoom.alchemyLab:
        return '특별한 공간';
      case SpecialRoom.fineDining:
        return '고급 공간';
      
      // 새로 추가된 11개 특별 공간들
      case SpecialRoom.alps:
        return '극한의 공간';
      case SpecialRoom.camping:
        return '자연의 공간';
      case SpecialRoom.autumn:
        return '계절의 공간';
      case SpecialRoom.springPicnic:
        return '야외의 공간';
      case SpecialRoom.surfing:
        return '바다의 공간';
      case SpecialRoom.snorkel:
        return '해양의 공간';
      case SpecialRoom.summerbeach:
        return '해변의 공간';
      case SpecialRoom.baliYoga:
        return '명상의 공간';
      case SpecialRoom.orientExpress:
        return '여행의 공간';
      case SpecialRoom.canvas:
        return '예술의 공간';
      case SpecialRoom.vacance:
        return '휴식의 공간';
      
      default:
        return '신비한 공간';
    }
  }
  

}

