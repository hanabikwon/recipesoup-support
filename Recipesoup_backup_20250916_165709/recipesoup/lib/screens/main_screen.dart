import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../providers/burrow_provider.dart';
import '../models/burrow_milestone.dart';
import '../widgets/burrow/achievement_dialog.dart';
import 'home_screen.dart';
// 🔥 ULTRA FIX: SearchScreen import 제거 (보관함으로 통합)
import 'burrow/burrow_screen.dart';
import 'stats_screen.dart';
import 'archive_screen.dart';
import 'settings_screen.dart';
import 'create_screen.dart';
import 'url_import_screen.dart';
import 'photo_import_screen.dart';
import 'keyword_import_screen.dart';
import 'fridge_ingredients_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isExpandedFabOpen = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  // 🔥 ULTRA FIX: 설정을 바텀바로 이동, 5개 탭으로 확장
  final List<Widget> _screens = [
    const HomeScreen(),    // 0 - 홈
    const BurrowScreen(),  // 1 - 토끼굴 
    const StatsScreen(),   // 2 - 통계 
    const ArchiveScreen(), // 3 - 보관함 (검색 기능 포함)
    const SettingsScreen(), // 4 - 설정 (바텀바로 이동)
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    // 🔥 ULTRA FIX: 인덱스 안전 매핑 (설정 바텀바 이동, 5개 탭 구조)
    _currentIndex = _migrateCurrentIndex(_currentIndex);
    
    // 앱 시작 후 대기 중인 마일스톤 알림 체크
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkGlobalNotifications();
    });
  }

  /// 🔥 ULTRA THINK: 기존 인덱스를 새로운 5개 인덱스로 안전 매핑 (설정 바텀바 이동)
  int _migrateCurrentIndex(int oldIndex) {
    switch (oldIndex) {
      case 0: return 0; // 홈 → 홈 (변경 없음)
      case 1: return 3; // 검색 → 보관함 (검색이 보관함으로 통합됨)
      case 2: return 1; // 토끼굴 → 토끼굴 (변경 없음)
      case 3: return 2; // 통계 → 통계 (변경 없음)
      case 4: return 3; // 보관함 → 보관함 (변경 없음)
      case 5: return 4; // 설정 → 설정 (바텀바로 이동)
      default: return 0; // 안전한 기본값
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 🔥 ULTRA FIX: 바텀바 탭 선택 (5개 인덱스 범위 체크)
  void _onTabTapped(int index) {
    // 안전한 인덱스 범위 체크 (0~4)
    if (index >= 0 && index < _screens.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _toggleExpandedFab() {
    setState(() {
      _isExpandedFabOpen = !_isExpandedFabOpen;
      if (_isExpandedFabOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _navigateToCreate() {
    _closeExpandedFab();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateScreen(),
      ),
    );
  }

  void _navigateToPhotoCreate() {
    _closeExpandedFab();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PhotoImportScreen(),
      ),
    );
  }

  void _navigateToUrlImport() {
    _closeExpandedFab();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UrlImportScreen(),
      ),
    );
  }

  void _navigateToQuickRecipe() {
    _closeExpandedFab();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const KeywordImportScreen(),
      ),
    );
  }

  void _navigateToFridgeIngredients() {
    _closeExpandedFab();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FridgeIngredientsScreen(),
      ),
    );
  }

  void _closeExpandedFab() {
    if (_isExpandedFabOpen) {
      setState(() {
        _isExpandedFabOpen = false;
        _animationController.reverse();
      });
    }
  }

  // 🔥 ULTRA FIX: 설정 화면이 바텀바로 이동되어 별도 네비게이션 불필요

  /// 글로벌 마일스톤 알림 체크 (앱 전역에서 팝업 표시)
  Future<void> _checkGlobalNotifications() async {
    if (!mounted) return;
    
    final burrowProvider = context.read<BurrowProvider>();
    
    while (burrowProvider.pendingNotificationCount > 0) {
      final notification = burrowProvider.getNextNotification();
      if (notification != null && mounted) {
        await _showGlobalAchievementDialog(notification);
      } else {
        break;
      }
    }
  }

  /// 글로벌 성취 팝업 표시
  Future<void> _showGlobalAchievementDialog(UnlockQueueItem item) async {
    if (!mounted) return;
    
    final burrowProvider = context.read<BurrowProvider>();
    burrowProvider.setNotificationShowing(true);
    
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AchievementDialog(
          milestone: item.milestone,
          unlockedAt: item.unlockedAt,
          triggerRecipeId: item.triggerRecipeId,
        ),
      );
    } finally {
      if (mounted) {
        burrowProvider.setNotificationShowing(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BurrowProvider>(
      builder: (context, burrowProvider, child) {
        // 마일스톤 언락 알림이 있으면 즉시 처리
        if (burrowProvider.pendingNotificationCount > 0 && !burrowProvider.isShowingNotification) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkGlobalNotifications();
          });
        }
        
        return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      // 🔥 ULTRA FIX: 전체 상단바 제거 (UI 단순화)
      body: Stack(
        children: [
          // 메인 콘텐츠
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          
          // Speed Dial 오버레이 (보관함 검색 패턴과 동일)
          if (_isExpandedFabOpen)
            GestureDetector(
              onTap: _closeExpandedFab,
              child: Container(
                color: Colors.black.withValues(alpha: 0.3), // 자연스러운 dim 처리 (30% 불투명도)
                child: Stack(
                  children: [
                    // 딤드 배경 (전체 화면)
                    const SizedBox.expand(),
                    
                    // Speed Dial 메뉴 (오른쪽 하단 배치)
                    Positioned(
                      bottom: 80,
                      right: 16,
                      child: _buildSpeedDialMenu(),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _buildExpandableFab(),
      // 🔥 ULTRA FIX: FAB를 바텀바 위에 떠있도록 변경
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // 🔥 ULTRA FIX: Container 래퍼로 복원 (BottomAppBar 제거)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowColor,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.surfaceColor,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.textTertiary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          // 🔥 ULTRA FIX: 설정을 바텀바로 이동 (5개 탭)
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              activeIcon: Icon(Icons.home),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pets),
              activeIcon: Icon(Icons.pets),
              label: '토끼굴',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              activeIcon: Icon(Icons.bar_chart),
              label: '통계',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_open),
              activeIcon: Icon(Icons.folder_open),
              label: '보관함',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              activeIcon: Icon(Icons.settings),
              label: '설정',
            ),
          ],
        ),
      ),
        ); // Scaffold 끝
      }, // Consumer builder 끝
    ); // Consumer 끝
  }

  Widget _buildExpandableFab() {
    // 메인 FAB만 표시 (메뉴는 오버레이에서 처리)
    return FloatingActionButton(
      onPressed: _toggleExpandedFab,
      backgroundColor: AppTheme.fabColor,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: AnimatedRotation(
        turns: _isExpandedFabOpen ? 0.125 : 0, // 45도 회전 (1/8)
        duration: const Duration(milliseconds: 250),
        child: const Icon(
          Icons.add,
          size: 28,
        ),
      ),
    );
  }

  // Speed Dial 메뉴 (오버레이에서 사용)
  Widget _buildSpeedDialMenu() {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _expandAnimation.value) * 20),
          child: Opacity(
            opacity: _expandAnimation.value,
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 280,
                minWidth: 250,
              ),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.vintageShadow,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 퀵레시피 작성하기
                    _buildFabMenuItem(
                      onPressed: _navigateToQuickRecipe,
                      icon: Icons.flash_on,
                      label: '퀵레시피 작성하기',
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 12),

                    // 냉장고 재료 입력하기 (새로운 기능!)
                    _buildFabMenuItem(
                      onPressed: _navigateToFridgeIngredients,
                      icon: Icons.kitchen,
                      label: '냉장고 재료 입력하기',
                      backgroundColor: AppTheme.successColor,
                    ),
                    const SizedBox(height: 12),

                    // 링크로 가져오기
                    _buildFabMenuItem(
                      onPressed: _navigateToUrlImport,
                      icon: Icons.link,
                      label: '링크로 가져오기',
                      backgroundColor: AppTheme.primaryLight,
                    ),
                    const SizedBox(height: 12),
                    
                    // 사진으로 가져오기
                    _buildFabMenuItem(
                      onPressed: _navigateToPhotoCreate,
                      icon: Icons.camera_alt,
                      label: '사진으로 가져오기',
                      backgroundColor: AppTheme.secondaryLight,
                    ),
                    const SizedBox(height: 12),
                    
                    // 나만의 레시피 작성하기
                    _buildFabMenuItem(
                      onPressed: _navigateToCreate,
                      icon: Icons.edit,
                      label: '나만의 레시피 작성하기',
                      backgroundColor: AppTheme.accentOrange,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFabMenuItem({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color backgroundColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 라벨
        Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.vintageShadow,
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        // FAB 버튼
        FloatingActionButton.small(
          onPressed: onPressed,
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          elevation: 4,
          heroTag: label, // 각 FAB에 고유한 heroTag
          child: Icon(icon, size: 20),
        ),
      ],
    );
  }

}

