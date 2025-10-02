import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../providers/challenge_provider.dart';
import '../models/challenge_models.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../models/mood.dart';
import '../utils/cooking_steps_analyzer.dart';
import 'challenge_progress_screen.dart';
import 'create_screen.dart';

/// 챌린지 상세보기 화면
/// 챌린지의 상세 정보를 표시하고 시작/진행/완료 액션을 제공하는 화면
class ChallengeDetailScreen extends StatefulWidget {
  final Challenge challenge;

  const ChallengeDetailScreen({
    super.key,
    required this.challenge,
  });

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> 
    with SingleTickerProviderStateMixin {
  
  late ScrollController _scrollController;
  late TabController _tabController;
  bool _isChallengeStarted = false;

  /// Ultra Think Feature Flag: 새로운 3탭 구조 사용 여부 확인
  /// 마이그레이션된 챌린지만 3탭 구조 사용
  bool get _useNewTabStructure {
    // migrationCompleted 필드가 true인 경우에만 3탭 구조 사용
    final migrationCompleted = widget.challenge.toJson()['migrationCompleted'] as bool?;
    return migrationCompleted == true;
  }

  /// 동적 탭 목록 생성 (2탭 또는 3탭)
  List<Tab> get _tabs {
    if (_useNewTabStructure) {
      return [
        Tab(text: '주요 재료'),
        Tab(text: '소스&양념'),  // 새로운 탭
        Tab(text: '상세 요리법'),
      ];
    } else {
      return [
        Tab(text: '주요 재료'),
        Tab(text: '상세 요리법'),
      ];
    }
  }

  /// 동적 탭 콘텐츠 생성 (2탭 또는 3탭)
  List<Widget> get _tabViews {
    if (_useNewTabStructure) {
      return [
        _buildMainIngredientsTabContent(),     // 주재료만
        _buildSauceSeasoningTabContent(),      // 소스&양념만 (새로운 탭)
        _buildCookingMethodTabContent(),       // 상세 요리법
      ];
    } else {
      return [
        _buildIngredientsTabContent(),         // 기존 로직 (모든 재료)
        _buildCookingMethodTabContent(),       // 상세 요리법
      ];
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Ultra Think: 동적 탭 길이 결정 (마이그레이션된 챌린지는 3탭, 아니면 2탭)
    int tabLength = _useNewTabStructure ? 3 : 2;
    _tabController = TabController(length: tabLength, vsync: this);
    
    // 챌린지 시작 상태 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ChallengeProvider>(context, listen: false);
      final progress = provider.getProgressById(widget.challenge.id);
      final isStartedOrCompleted = (progress?.isStarted ?? false) || (progress?.isCompleted ?? false);
      
      if (isStartedOrCompleted != _isChallengeStarted) {
        setState(() {
          _isChallengeStarted = isStartedOrCompleted;
        });
        
        // 챌린지가 이미 시작되었다면 상세 요리법 탭으로 전환
        if (_isChallengeStarted) {
          _tabController.animateTo(1);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppTheme.textPrimary,
            size: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: 즐겨찾기 기능 구현
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('즐겨찾기 기능 준비 중입니다'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: Icon(
              Icons.favorite_border,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: Consumer<ChallengeProvider>(
        builder: (context, provider, child) {
          final progress = provider.getProgressById(widget.challenge.id);
          
          return SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildChallengeHeader(),
                _buildStatusCard(progress, provider),
                SizedBox(height: 24), // 상태 박스와 설명 섹션 간격 추가
                _buildAllContent(),
                SizedBox(height: 40), // 하단 여백
              ],
            ),
          );
        },
      ),
    );
  }


  /// 챌린지 헤더
  Widget _buildChallengeHeader() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카테고리 태그
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              _getCategoryDisplayName(widget.challenge.category),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          
          SizedBox(height: 12),
          
          // 제목
          Text(
            widget.challenge.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              height: 1.3,
            ),
          ),
          
          SizedBox(height: 12),
          
          // 기본 정보 (난이도, 시간, 서빙, 포인트)
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.star,
                label: _getDifficultyText(widget.challenge.difficulty),
                color: _getDifficultyColor(widget.challenge.difficulty),
              ),
              SizedBox(width: 12),
              _buildInfoChip(
                icon: Icons.access_time,
                label: '${widget.challenge.estimatedMinutes}분',
                color: AppTheme.textSecondary,
              ),
              SizedBox(width: 12),
              _buildInfoChip(
                icon: Icons.restaurant,
                label: widget.challenge.servings,
                color: AppTheme.textSecondary,
              ),
              // 포인트 시스템이 제거됨
            ],
          ),
        ],
      ),
    );
  }

  /// 정보 칩
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 상태 카드
  Widget _buildStatusCard(ChallengeProgress? progress, ChallengeProvider provider) {
    final isCompleted = progress?.isCompleted ?? false;
    final isInProgress = progress?.isStarted ?? false;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.dividerColor.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: AppTheme.vintageShadow,
      ),
      child: Column(
        children: [
          if (isCompleted) ...[
            _buildCompletedStatus(progress!),
          ] else if (isInProgress) ...[
            _buildInProgressStatus(progress!, provider),
          ] else ...[
            _buildNotStartedStatus(provider),
          ],
        ],
      ),
    );
  }

  /// 완료된 상태
  Widget _buildCompletedStatus(ChallengeProgress progress) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '챌린지 완료!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  if (progress.completedAt != null) ...[
                    Text(
                      '완료일: ${_formatDate(progress.completedAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (progress.userRating != null) ...[
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    Icons.star,
                    size: 16,
                    color: index < progress.userRating!
                        ? Colors.amber
                        : AppTheme.primaryLight.withValues(alpha: 0.3),
                  );
                }),
              ),
            ],
          ],
        ),
        if (progress.userNote != null && progress.userNote!.isNotEmpty) ...[
          SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '"${progress.userNote}"',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final provider = Provider.of<ChallengeProvider>(context, listen: false);
                  final success = await provider.restartChallenge(widget.challenge.id);
                  
                  if (success) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('챌린지를 다시 시작했습니다! 새로운 도전을 해보세요.'),
                          backgroundColor: AppTheme.primaryColor,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('챌린지 재시작에 실패했습니다. 다시 시도해 주세요.'),
                          backgroundColor: AppTheme.errorColor,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: BorderSide(color: AppTheme.primaryColor),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('다시 도전하기'),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  _showReviewEditDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('리뷰 수정'),
              ),
            ),
          ],
        ),
        // 나만의 레시피 보관 버튼 추가
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _navigateToRecipeCreation(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
              foregroundColor: AppTheme.primaryColor,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(Icons.restaurant_menu, size: 20),
            label: Text(
              '나만의 레시피로 보관하기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 진행 중인 상태
  Widget _buildInProgressStatus(ChallengeProgress progress, ChallengeProvider provider) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow,
                color: AppTheme.textSecondary,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '진행 중인 챌린지',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  if (progress.startedAt != null) ...[
                    Text(
                      '시작일: ${_formatDate(progress.startedAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _showAbandonDialog(provider);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: BorderSide(color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('포기하기'),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChallengeProgressScreen(
                        challenge: widget.challenge,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('이어서 진행하기'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 시작하지 않은 상태
  Widget _buildNotStartedStatus(ChallengeProvider provider) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.flag,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '새로운 챌린지',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Text(
                    '지금 바로 시작해보세요!',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              final success = await provider.startChallenge(widget.challenge.id);
              if (success && mounted) {
                // 챌린지 시작 상태 업데이트
                setState(() {
                  _isChallengeStarted = true;
                });
                
                // 상세 요리법 탭으로 자동 전환
                _tabController.animateTo(1);
                
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChallengeProgressScreen(
                      challenge: widget.challenge,
                    ),
                  ),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('챌린지 시작에 실패했습니다'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow, size: 20),
                SizedBox(width: 8),
                Text(
                  '챌린지 시작하기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 모든 콘텐츠를 단일 스크롤로 통합
  Widget _buildAllContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDescriptionSection(),
        SizedBox(height: 32),
        _buildSpecificTipsSection(),
        SizedBox(height: 32),
        _buildIngredientsAndMethodSection(),
      ],
    );
  }

  /// 주요 재료 | 상세 요리법 탭 섹션
  Widget _buildIngredientsAndMethodSection() {
    return Column(
      children: [
        // 탭 헤더
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textSecondary,
            labelStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
            indicator: BoxDecoration(
              color: AppTheme.primaryLight.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            indicatorPadding: EdgeInsets.all(4),
            dividerColor: Colors.transparent,
            tabs: _tabs,
          ),
        ),
        SizedBox(height: 16),
        // 탭 콘텐츠
        Container(
          height: _isChallengeStarted ? 400 : 300, // 챌린지 시작 후 높이 증가
          child: TabBarView(
            controller: _tabController,
            children: _tabViews,
          ),
        ),
      ],
    );
  }

  /// 설명 섹션
  Widget _buildDescriptionSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '챌린지 설명',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 12),
          Text(
            widget.challenge.description,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  /// 주요 재료 탭 콘텐츠 - 통합된 섹션
  Widget _buildIngredientsTabContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryLight.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...widget.challenge.mainIngredients.asMap().entries.map((entry) {
              final index = entry.key;
              final ingredient = entry.value;
              final isLast = index == widget.challenge.mainIngredients.length - 1;
              
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 6,
                      color: AppTheme.primaryColor,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ingredient,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppTheme.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// 상세 요리법 탭 콘텐츠
  Widget _buildCookingMethodTabContent() {
    return FutureBuilder<List<String>>(
      future: Provider.of<ChallengeProvider>(context, listen: false)
          .getCookingSteps(widget.challenge.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
                SizedBox(height: 16),
                Text(
                  '상세 요리법 로딩 중...',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '조리법을 불러오는 중 오류가 발생했습니다.',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final cookingSteps = snapshot.data ?? [];
        
        if (cookingSteps.isEmpty) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '이 챌린지의 상세 조리법이 준비 중입니다.\n기본 재료와 설명을 참고해주세요.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryLight.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...cookingSteps.asMap().entries.map((entry) {
                  final index = entry.key;
                  final step = entry.value;
                  final isLast = index == cookingSteps.length - 1;
                  
                  return Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 6,
                          color: AppTheme.primaryColor,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            step,
                            style: TextStyle(
                              fontSize: 15,
                              color: AppTheme.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 챌린지별 특화 팁 섹션 (사진 관련 및 전역 팁 제거)
  Widget _buildSpecificTipsSection() {
    // 챌린지별 특화 팁이 있을 경우에만 표시
    if (widget.challenge.cookingTip == null || widget.challenge.cookingTip!.isEmpty) {
      return SizedBox.shrink(); // 팁이 없으면 아무것도 표시하지 않음
    }
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.accentOrange.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.tips_and_updates,
                  color: AppTheme.accentOrange,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.challenge.cookingTip!,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔥 상세 조리법 섹션 (detailed_cooking_methods.json에서 로드)
  Widget _buildCookingMethodSection() {
    return FutureBuilder<List<String>>(
      future: Provider.of<ChallengeProvider>(context, listen: false)
          .getCookingSteps(widget.challenge.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🍳 상세 조리법',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 16),
                Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🍳 상세 조리법',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '조리법을 불러오는 중 오류가 발생했습니다.',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        }

        final cookingSteps = snapshot.data ?? [];
        
        if (cookingSteps.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🍳 상세 조리법',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '이 챌린지의 상세 조리법이 준비 중입니다.\n기본 재료와 설명을 참고해주세요.',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🍳 상세 조리법',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 16),
              ...cookingSteps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                
                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 단계 번호
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      // 단계 설명
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primaryLight.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            step,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  /// 포기 다이얼로그
  void _showAbandonDialog(ChallengeProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('챌린지 포기'),
          content: Text('정말 이 챌린지를 포기하시겠어요?\n진행 상황이 초기화됩니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await provider.abandonChallenge(widget.challenge.id);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('챌린지를 포기했습니다'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  setState(() {}); // UI 업데이트
                }
              },
              style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
              child: Text('포기하기'),
            ),
          ],
        );
      },
    );
  }

  /// 리뷰 수정 다이얼로그
  void _showReviewEditDialog(BuildContext context) {
    final provider = Provider.of<ChallengeProvider>(context, listen: false);
    final progress = provider.getProgressById(widget.challenge.id);
    
    int currentRating = progress?.userRating ?? 0;
    String currentReview = progress?.userNote ?? '';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                '리뷰 수정',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              content: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '평점',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              currentRating = index + 1;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              index < currentRating ? Icons.star : Icons.star_border,
                              color: index < currentRating ? Colors.amber : Colors.grey,
                              size: 32,
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '리뷰',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: TextEditingController(text: currentReview)
                        ..selection = TextSelection.fromPosition(
                          TextPosition(offset: currentReview.length),
                        ),
                      onChanged: (value) {
                        currentReview = value;
                      },
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: '챌린지에 대한 느낌이나 후기를 작성해주세요',
                        hintStyle: TextStyle(color: AppTheme.textTertiary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.primaryColor),
                        ),
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    
                    final success = await provider.updateChallengeProgress(
                      widget.challenge.id,
                      rating: currentRating > 0 ? currentRating : null,
                      review: currentReview.trim().isNotEmpty ? currentReview.trim() : null,
                    );
                    
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('리뷰가 수정되었습니다'),
                          backgroundColor: AppTheme.primaryColor,
                          duration: Duration(seconds: 2),
                        ),
                      );
                      setState(() {}); // UI 업데이트
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('리뷰 수정에 실패했습니다'),
                          backgroundColor: AppTheme.errorColor,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 유틸리티 메서드들
  Color _getCategoryColor(ChallengeCategory category) {
    switch (category) {
      // 메인 카테고리
      case ChallengeCategory.emotional:
        return Color(0xFFE8A5C0); // 핑크 계열 (홈화면과 일치하는 부드러운 핑크)
      case ChallengeCategory.worldCuisine:
        return Color(0xFF4ECDC4); // 청록 계열
      case ChallengeCategory.healthy:
        return Color(0xFF45B7D1); // 파랑 계열
      
      // 감정별 서브카테고리
      case ChallengeCategory.emotionalHappy:
        return Color(0xFFF4D03F); // 기쁨 골드 (홈화면과 일치하는 부드러운 골드)
      case ChallengeCategory.emotionalComfort:
        return Color(0xFFE8A5C0); // 위로 핑크 (홈화면과 일치하는 부드러운 핑크)
      case ChallengeCategory.emotionalNostalgic:
        return Color(0xFF9B7FB3); // 그리움 라벤더
      case ChallengeCategory.emotionalEnergy:
        return Color(0xFFF39C12); // 활력 오렌지 (홈화면과 일치하는 부드러운 오렌지)
      
      // 세계 요리 서브카테고리
      case ChallengeCategory.worldAsian:
        return Color(0xFFE57373); // 아시아 레드 (부드러운 레드)
      case ChallengeCategory.worldEuropean:
        return Color(0xFF3498DB); // 유럽 블루
      case ChallengeCategory.worldAmerican:
        return Color(0xFF27AE60); // 아메리카 그린
      case ChallengeCategory.worldFusion:
        return Color(0xFFE67E22); // 중동 오렌지
      
      // 건강 라이프 서브카테고리
      case ChallengeCategory.healthyNatural:
        return Color(0xFF7BC04A); // 자연 올리브 그린
      case ChallengeCategory.healthyEnergy:
        return Color(0xFFF7DC6F); // 에너지 옐로우 (부드러운 에너지 색상)
      case ChallengeCategory.healthyCare:
        return Color(0xFF3498DB); // 건강 블루
      case ChallengeCategory.healthyHealing:
        return Color(0xFF9B59B6); // 힐링 퍼플
    }
  }

  String _getCategoryIcon(ChallengeCategory category) {
    switch (category) {
      // 메인 카테고리
      case ChallengeCategory.emotional:
        return '💝';
      case ChallengeCategory.worldCuisine:
        return '🌍';
      case ChallengeCategory.healthy:
        return '🥗';
      
      // 감정별 서브카테고리
      case ChallengeCategory.emotionalHappy:
        return '🎉'; // 기쁨
      case ChallengeCategory.emotionalComfort:
        return '🤗'; // 위로
      case ChallengeCategory.emotionalNostalgic:
        return '💭'; // 그리움
      case ChallengeCategory.emotionalEnergy:
        return '💪'; // 활력
      
      // 세계 요리 서브카테고리
      case ChallengeCategory.worldAsian:
        return '🍜'; // 아시아
      case ChallengeCategory.worldEuropean:
        return '🍝'; // 유럽
      case ChallengeCategory.worldAmerican:
        return '🍔'; // 아메리카
      case ChallengeCategory.worldFusion:
        return '🌶️'; // 중동
      
      // 건강 라이프 서브카테고리
      case ChallengeCategory.healthyNatural:
        return '🌱'; // 자연 친화
      case ChallengeCategory.healthyEnergy:
        return '⚡'; // 에너지 충전
      case ChallengeCategory.healthyCare:
        return '🏥'; // 건강 관리
      case ChallengeCategory.healthyHealing:
        return '🧘'; // 몸과 마음 케어
    }
  }

  String _getCategoryDisplayName(ChallengeCategory category) {
    switch (category) {
      // 메인 카테고리
      case ChallengeCategory.emotional:
        return '감정별 챌린지';
      case ChallengeCategory.worldCuisine:
        return '세계 맛 여행';
      case ChallengeCategory.healthy:
        return '건강 라이프';
      
      // 감정별 서브카테고리
      case ChallengeCategory.emotionalHappy:
        return '기쁨과 축하';
      case ChallengeCategory.emotionalComfort:
        return '위로와 치유';
      case ChallengeCategory.emotionalNostalgic:
        return '그리움과 추억';
      case ChallengeCategory.emotionalEnergy:
        return '활력과 동기부여';
      
      // 세계 요리 서브카테고리
      case ChallengeCategory.worldAsian:
        return '아시아 요리';
      case ChallengeCategory.worldEuropean:
        return '유럽 요리';
      case ChallengeCategory.worldAmerican:
        return '아메리카 요리';
      case ChallengeCategory.worldFusion:
        return '중동·아프리카 요리';
      
      // 건강 라이프 서브카테고리
      case ChallengeCategory.healthyNatural:
        return '자연 친화';
      case ChallengeCategory.healthyEnergy:
        return '에너지 충전';
      case ChallengeCategory.healthyCare:
        return '건강 관리';
      case ChallengeCategory.healthyHealing:
        return '몸과 마음 케어';
    }
  }

  String _getDifficultyText(int difficulty) {
    switch (difficulty) {
      case 1:
        return '쉬움';
      case 2:
        return '보통';
      case 3:
        return '어려움';
      default:
        return '보통';
    }
  }

  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  /// Ultra Think: 3탭 구조 - 주재료만 표시하는 탭 콘텐츠
  Widget _buildMainIngredientsTabContent() {
    // 마이그레이션된 데이터에서 주재료만 가져오기
    final challengeData = widget.challenge.toJson();
    final mainIngredientsV2 = challengeData['main_ingredients_v2'] as List<dynamic>?;
    final mainIngredients = mainIngredientsV2?.cast<String>() ?? widget.challenge.mainIngredients;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryLight.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...mainIngredients.asMap().entries.map((entry) {
              final index = entry.key;
              final ingredient = entry.value;
              final isLast = index == mainIngredients.length - 1;
              
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ingredient,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!isLast) SizedBox(height: 12),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Ultra Think: 3탭 구조 - 소스&양념만 표시하는 탭 콘텐츠 (cooking_steps 통합)
  Widget _buildSauceSeasoningTabContent() {
    return FutureBuilder<List<String>>(
      future: _getCombinedSauceIngredients(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondaryColor),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              '소스&양념 정보를 불러오는 중 오류가 발생했습니다.',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        final combinedSauceIngredients = snapshot.data ?? <String>[];
        return _buildSauceSeasoningContent(combinedSauceIngredients);
      },
    );
  }

  /// 기존 sauce_seasoning과 cooking_steps에서 추출한 소스를 통합하여 반환
  Future<List<String>> _getCombinedSauceIngredients() async {
    // 마이그레이션된 데이터에서 소스&양념 가져오기
    final challengeData = widget.challenge.toJson();
    final sauceSeasoning = challengeData['sauce_seasoning'] as List<dynamic>?;
    final existingSauces = sauceSeasoning?.cast<String>() ?? <String>[];

    // cooking_steps에서 소스 추출
    try {
      final provider = Provider.of<ChallengeProvider>(context, listen: false);
      final cookingSteps = await provider.getCookingSteps(widget.challenge.id);

      // 기존 소스와 cooking_steps에서 추출한 소스 통합
      final combinedSauces = CookingStepsAnalyzer.combineSauceData(existingSauces, cookingSteps);

      return combinedSauces;
    } catch (e) {
      // 오류 발생 시 기존 소스만 반환
      if (kDebugMode) {
        print('cooking_steps 소스 추출 오류: $e');
      }
      return existingSauces;
    }
  }

  /// 통합된 소스&양념 리스트로 UI 콘텐츠 빌드
  Widget _buildSauceSeasoningContent(List<String> sauceIngredients) {

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.secondaryColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sauceIngredients.isEmpty) ...[
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.textSecondary,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '이 챌린지는 별도의 소스나 양념이 필요하지 않습니다.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ...sauceIngredients.asMap().entries.map((entry) {
                final index = entry.key;
                final ingredient = entry.value;
                final isLast = index == sauceIngredients.length - 1;
                
                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ingredient,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!isLast) SizedBox(height: 12),
                  ],
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  /// 챌린지 완료 후 나만의 레시피로 작성하기
  void _navigateToRecipeCreation(BuildContext context) async {
    try {
      // 마이그레이션된 데이터 가져오기
      final challengeData = widget.challenge.toJson();

      // 마이그레이션 완료 여부 확인
      if (challengeData['migrationCompleted'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이 챌린지는 아직 새 구조로 업데이트되지 않았습니다.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      // 마이그레이션된 재료 데이터 추출
      final mainIngredientsV2 = challengeData['main_ingredients_v2'] as List<dynamic>?;
      final sauceSeasoningList = challengeData['sauce_seasoning'] as List<dynamic>?;

      // detailed_cooking_methods 필드가 마이그레이션되지 않았으므로,
      // ChallengeProvider를 통해 직접 가져옵니다
      final provider = Provider.of<ChallengeProvider>(context, listen: false);
      final cookingMethods = await provider.getCookingSteps(widget.challenge.id);

      // 디버깅: 실제 챌린지 데이터 확인
      if (kDebugMode) {
        print('🔍 [DEBUG] Challenge data keys: ${challengeData.keys.toList()}');
        print('🔍 [DEBUG] mainIngredientsV2: $mainIngredientsV2');
        print('🔍 [DEBUG] sauceSeasoningList: $sauceSeasoningList');
        print('🔍 [DEBUG] cookingMethods from getCookingSteps: $cookingMethods');
        print('🔍 [DEBUG] cookingMethods length: ${cookingMethods.length}');
      }

      if (mainIngredientsV2 == null || sauceSeasoningList == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('레시피 데이터를 가져올 수 없습니다.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      // 소스&양념 데이터를 문자열로 변환 (CreateScreen의 "소스 비율" 필드용)
      final sauceString = sauceSeasoningList.isNotEmpty
          ? sauceSeasoningList.map((item) => item.toString()).join(',')
          : '';

      // 상세 요리법 데이터를 사용 (getCookingSteps에서 이미 List<String>으로 반환됨)
      final instructionsList = cookingMethods;

      // Recipe 객체 생성 (pre-filled 데이터)
      final prefilledRecipe = Recipe(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}', // 임시 ID
        title: '${widget.challenge.title} 레시피', // 기본 제목
        emotionalStory: '', // 사용자가 입력할 감정 이야기
        ingredients: [
          // 주재료 (기타 카테고리로 분류)
          ...mainIngredientsV2.map((ingredient) => Ingredient(
            name: ingredient.toString(),
            amount: '',
            unit: null,
            category: IngredientCategory.other,
          )).toList(),
          // 소스&양념 (조미료 카테고리로 분류)
          ...sauceSeasoningList.map((seasoning) => Ingredient(
            name: seasoning.toString(),
            amount: '',
            unit: null,
            category: IngredientCategory.seasoning,
          )).toList(),
        ],
        instructions: instructionsList, // 상세 요리법 → "만드는 법" 필드로 전달
        sauce: sauceString, // 소스&양념 → "소스 비율" 필드로 전달
        tags: ['#챌린지완료', '#${widget.challenge.category.name}'],
        createdAt: DateTime.now(),
        mood: Mood.values[0], // 기본 감정 (사용자가 선택)
        rating: null, // 사용자가 평가
        isFavorite: false,
      );

      // CreateScreen으로 이동 (편집 모드가 아닌 pre-filled 모드)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateScreen(
            editingRecipe: prefilledRecipe,
            isEditMode: false, // 생성 모드 (편집 아님)
          ),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('레시피 작성 화면으로 이동하는 중 오류가 발생했습니다.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      if (kDebugMode) {
        print('Recipe creation navigation error: $e');
      }
    }
  }
}