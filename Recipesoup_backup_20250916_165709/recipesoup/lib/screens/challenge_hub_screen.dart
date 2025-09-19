import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../providers/challenge_provider.dart';
import '../models/challenge_models.dart';
import '../widgets/vintage_loading_widget.dart';
import 'challenge_category_screen.dart';
import 'challenge_mood_entry_screen.dart';
import 'challenge_detail_screen.dart';

/// 깡총 챌린지 허브 화면 - 새로운 메인 화면
/// 사용자의 상세 UI 요구사항을 반영한 감정 기반 챌린지 진입점
class ChallengeHubScreen extends StatefulWidget {
  const ChallengeHubScreen({super.key});

  @override
  State<ChallengeHubScreen> createState() => _ChallengeHubScreenState();
}

class _ChallengeHubScreenState extends State<ChallengeHubScreen> {
  bool _isEmotionalExpanded = false;
  bool _isWorldCuisineExpanded = false;
  bool _isHealthyLifeExpanded = false;
  
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  /// 데이터 초기화
  void _initializeData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final challengeProvider = Provider.of<ChallengeProvider>(context, listen: false);
      if (challengeProvider.allChallenges.isEmpty) {
        challengeProvider.loadInitialData();
      }
    });
  }

  /// 완료한 챌린지 보기 화면으로 이동
  void _navigateToCompletedChallenges() {
    final challengeProvider = Provider.of<ChallengeProvider>(context, listen: false);
    final completedChallenges = challengeProvider.allChallenges
        .where((challenge) => challengeProvider.userProgress[challenge.id]?.isCompleted ?? false)
        .toList();
    
    // 완료된 챌린지가 없다면 안내 메시지 표시
    if (completedChallenges.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('아직 완료한 챌린지가 없어요. 챌린지를 완료해보세요!'),
          backgroundColor: AppTheme.primaryColor,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 완료한 챌린지 리스트를 다이얼로그로 표시
    _showCompletedChallengesDialog(completedChallenges);
  }

  /// 완료한 챌린지 리스트 다이얼로그 표시
  void _showCompletedChallengesDialog(List<Challenge> completedChallenges) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppTheme.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 헤더
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '완료한 챌린지',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // 완료한 챌린지 리스트
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: completedChallenges.length,
                    separatorBuilder: (context, index) => SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final challenge = completedChallenges[index];
                      return _buildCompletedChallengeCard(challenge);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 완료한 챌린지 카드
  Widget _buildCompletedChallengeCard(Challenge challenge) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop(); // 다이얼로그 닫기
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChallengeDetailScreen(challenge: challenge),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.successColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.successColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // 체크 아이콘
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.successColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              ),
            ),
            SizedBox(width: 12),
            // 챌린지 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // 화살표 아이콘
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Consumer<ChallengeProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const VintageLoadingWidget(
                message: '깡총 챌린지 준비 중...',
              );
            }

            if (provider.error != null) {
              return _buildErrorView(provider.error!);
            }

            return CustomScrollView(
              slivers: [
                _buildHeader(provider),
                _buildMoodEntry(),
                _buildUserProgress(provider),
                _buildCategoryHubs(provider),
                _buildRecentChallenges(provider),
                _buildFooterSpacing(),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 헤더 섹션 - 미니멀 디자인
  Widget _buildHeader(ChallengeProvider provider) {
    final completedCount = provider.userProgress.values
        .where((progress) => progress.isCompleted)
        .length;
    final totalCount = provider.allChallenges.length;

    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.arrow_back_ios,
                color: AppTheme.textPrimary,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '깡총 챌린지',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '감정으로 시작하는 요리 여행',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                '$completedCount / $totalCount',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 감정 기반 진입점 - "지금 기분이 어떠세요?"
  Widget _buildMoodEntry() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ChallengeMoodEntryScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFF5F3F0), // 따뜻한 베이지 배경
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE8A5C0).withValues(alpha: 0.6), // 빈티지 핑크 border
                width: 2,
              ),
              boxShadow: [BoxShadow(
                color: AppTheme.shadowColor,
                blurRadius: 6,
                offset: Offset(0, 2),
              )],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8A5C0).withValues(alpha: 0.2), // 빈티지 핑크 배경
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.psychology,
                    color: const Color(0xFFE8A5C0), // 빈티지 핑크 아이콘
                    size: 28,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '지금 기분은 어떤가요?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '오늘의 감정에 어울리는 작은 도전을 준비했어요',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: const Color(0xFFE8A5C0), // 빈티지 핑크 화살표
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 사용자 진행률 섹션
  Widget _buildUserProgress(ChallengeProvider provider) {
    final stats = provider.statistics;
    if (stats == null) return SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '나의 챌린지 현황',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                _buildProgressCard(
                  iconData: Icons.restaurant_menu,
                  title: '완료한 레시피',
                  value: '${stats.completedChallenges}개',
                  color: AppTheme.successColor,
                  onTap: _navigateToCompletedChallenges,
                ),
                SizedBox(width: 12),
                _buildProgressCard(
                  iconData: Icons.military_tech,
                  title: '획득한 뱃지',
                  value: '${provider.userBadges.length}개',
                  color: AppTheme.primaryDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 진행률 카드
  Widget _buildProgressCard({
    required IconData iconData,
    required String title,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(iconData, color: color, size: 24),
                  Spacer(),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 카테고리별 챌린지 허브
  Widget _buildCategoryHubs(ChallengeProvider provider) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '챌린지 카테고리',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 16),
            _buildEmotionalExpandedCard(provider),
            SizedBox(height: 12),
            _buildWorldCuisineExpandedCard(provider),
            SizedBox(height: 12),
            _buildHealthyLifeExpandedCard(provider),
          ],
        ),
      ),
    );
  }

  /// 감정 요리 확장 카드
  Widget _buildEmotionalExpandedCard(ChallengeProvider provider) {
    final emotionalSubcategories = [
      ChallengeCategory.emotionalHappy,
      ChallengeCategory.emotionalComfort,
      ChallengeCategory.emotionalNostalgic,
      ChallengeCategory.emotionalEnergy,
    ];

    // 서브카테고리 개수 기반 카운팅 (올바른 로직)
    final totalSubcategoryCount = emotionalSubcategories.length; // 4개
    
    // 완료된 서브카테고리 개수 (각 서브카테고리별로 하나 이상 완료된 개수)
    int completedSubcategoryCount = 0;
    for (final subcategory in emotionalSubcategories) {
      final hasCompletedChallenge = provider.allChallenges
          .where((c) => c.category == subcategory && c.isActive)
          .any((c) => provider.userProgress[c.id]?.isCompleted ?? false);
      if (hasCompletedChallenge) {
        completedSubcategoryCount++;
      }
    }

    return Column(
      children: [
        // 메인 감정 요리 카드
        InkWell(
          onTap: () {
            setState(() {
              _isEmotionalExpanded = !_isEmotionalExpanded;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFFF5F3F0), // 따뜻한 베이지 배경
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color.fromARGB(180, 243, 201, 193).withValues(alpha: 0.6),
                width: 2,
              ),
              boxShadow: [BoxShadow(
                color: AppTheme.shadowColor,
                blurRadius: 8,
                offset: Offset(0, 2),
              )],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(180, 243, 201, 193).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.favorite,
                    color: Color.fromARGB(180, 243, 201, 193),
                    size: 32,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '감정 요리 챌린지',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '마음을 치유하는 따뜻한 요리',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$completedSubcategoryCount / $totalSubcategoryCount',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          Spacer(),
                          Icon(
                            _isEmotionalExpanded ? Icons.expand_less : Icons.expand_more,
                            color: Color.fromARGB(180, 243, 201, 193),
                            size: 24,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // 서브카테고리 전개
        if (_isEmotionalExpanded)
          Container(
            margin: EdgeInsets.only(top: 6),
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 6),
                ...emotionalSubcategories.map((subcategory) => 
                  _buildSubcategoryItem(subcategory, provider)
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// 세계 요리 확장 카드
  Widget _buildWorldCuisineExpandedCard(ChallengeProvider provider) {
    final worldCuisineSubcategories = [
      ChallengeCategory.worldAsian,
      ChallengeCategory.worldEuropean,
      ChallengeCategory.worldAmerican,
      ChallengeCategory.worldFusion,
    ];

    // 서브카테고리 개수 기반 카운팅 (올바른 로직)
    final totalSubcategoryCount = worldCuisineSubcategories.length; // 4개
    
    // 완료된 서브카테고리 개수 (각 서브카테고리별로 하나 이상 완료된 개수)
    int completedSubcategoryCount = 0;
    for (final subcategory in worldCuisineSubcategories) {
      final hasCompletedChallenge = provider.allChallenges
          .where((c) => c.category == subcategory && c.isActive)
          .any((c) => provider.userProgress[c.id]?.isCompleted ?? false);
      if (hasCompletedChallenge) {
        completedSubcategoryCount++;
      }
    }

    return Column(
      children: [
        // 메인 세계 요리 카드
        InkWell(
          onTap: () {
            setState(() {
              _isWorldCuisineExpanded = !_isWorldCuisineExpanded;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFFF2F0ED), // 쿨 그레이 베이지 배경
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color.fromARGB(180, 185, 227, 244).withValues(alpha: 0.6),
                width: 2,
              ),
              boxShadow: [BoxShadow(
                color: AppTheme.shadowColor,
                blurRadius: 8,
                offset: Offset(0, 2),
              )],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(180, 185, 227, 244).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.travel_explore,
                    color: Color.fromARGB(180, 185, 227, 244),
                    size: 32,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '세계 요리 탐험',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '전 세계의 맛있는 여행',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$completedSubcategoryCount / $totalSubcategoryCount',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          Spacer(),
                          Icon(
                            _isWorldCuisineExpanded ? Icons.expand_less : Icons.expand_more,
                            color: Color.fromARGB(180, 185, 227, 244),
                            size: 24,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // 서브카테고리 전개
        if (_isWorldCuisineExpanded)
          Container(
            margin: EdgeInsets.only(top: 6),
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 12),
                ...worldCuisineSubcategories.map((subcategory) => 
                  _buildSubcategoryItem(subcategory, provider)
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// 건강 라이프 확장 카드
  Widget _buildHealthyLifeExpandedCard(ChallengeProvider provider) {
    final healthySubcategories = [
      ChallengeCategory.healthyNatural,
      ChallengeCategory.healthyEnergy,
      ChallengeCategory.healthyCare,
      ChallengeCategory.healthyHealing,
    ];

    // 서브카테고리 개수 기반 카운팅 (올바른 로직)
    final totalSubcategoryCount = healthySubcategories.length; // 4개
    
    // 완료된 서브카테고리 개수 (각 서브카테고리별로 하나 이상 완료된 개수)
    int completedSubcategoryCount = 0;
    for (final subcategory in healthySubcategories) {
      final hasCompletedChallenge = provider.allChallenges
          .where((c) => c.category == subcategory && c.isActive)
          .any((c) => provider.userProgress[c.id]?.isCompleted ?? false);
      if (hasCompletedChallenge) {
        completedSubcategoryCount++;
      }
    }

    return Column(
      children: [
        // 메인 건강 라이프 카드
        InkWell(
          onTap: () {
            setState(() {
              _isHealthyLifeExpanded = !_isHealthyLifeExpanded;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFFF1F2F0), // 내추럴 그레이 베이지 배경
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color.fromARGB(180, 178, 201, 146).withValues(alpha: 0.6),
                width: 2,
              ),
              boxShadow: [BoxShadow(
                color: AppTheme.shadowColor,
                blurRadius: 8,
                offset: Offset(0, 2),
              )],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(180, 178, 201, 146).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.eco,
                    color: Color.fromARGB(180, 178, 201, 146),
                    size: 32,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '건강 라이프 챌린지',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '몸과 마음이 건강해지는 요리',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$completedSubcategoryCount / $totalSubcategoryCount',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          Spacer(),
                          Icon(
                            _isHealthyLifeExpanded ? Icons.expand_less : Icons.expand_more,
                            color: Color.fromARGB(180, 178, 201, 146),
                            size: 24,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // 서브카테고리 전개
        if (_isHealthyLifeExpanded)
          Container(
            margin: EdgeInsets.only(top: 6),
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 12),
                ...healthySubcategories.map((subcategory) => 
                  _buildSubcategoryItem(subcategory, provider)
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// 최근 챌린지 섹션
  Widget _buildRecentChallenges(ChallengeProvider provider) {
    // 진행중이거나 최근 시작할 만한 챌린지들
    final recentChallenges = provider.allChallenges
        .where((c) => c.isActive && 
                     (provider.userProgress[c.id]?.isStarted ?? false) &&
                     !(provider.userProgress[c.id]?.isCompleted ?? false))
        .take(3)
        .toList();

    if (recentChallenges.isEmpty) {
      return SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '진행중인 챌린지',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 16),
            ...recentChallenges.map((challenge) => _buildRecentChallengeCard(challenge, provider)),
          ],
        ),
      ),
    );
  }

  /// 최근 챌린지 카드
  Widget _buildRecentChallengeCard(Challenge challenge, ChallengeProvider provider) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChallengeDetailScreen(challenge: challenge),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppTheme.vintageShadow,
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getCategoryColor(challenge.category).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getCategoryIcon(challenge.category),
                  color: _getCategoryColor(challenge.category),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${challenge.estimatedMinutes}분 • ${challenge.difficultyText}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '계속하기',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 서브카테고리 아이템
  Widget _buildSubcategoryItem(ChallengeCategory subcategory, ChallengeProvider provider) {
    final categoryCount = provider.allChallenges
        .where((c) => c.category == subcategory && c.isActive)
        .length;
    final completedCount = provider.allChallenges
        .where((c) => c.category == subcategory && c.isActive)
        .where((c) => provider.userProgress[c.id]?.isCompleted ?? false)
        .length;

    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;
        
        return Container(
          margin: EdgeInsets.only(bottom: 8),
          child: MouseRegion(
            onEnter: (_) => setState(() => isHovered = true),
            onExit: (_) => setState(() => isHovered = false),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChallengeCategoryScreen(category: subcategory),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isHovered 
                        ? _getCategoryColor(subcategory).withValues(alpha: 0.05)
                        : AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.shadowColor.withValues(alpha: isHovered ? 0.08 : 0.04),
                        blurRadius: isHovered ? 8 : 4,
                        offset: isHovered ? Offset(0, 2) : Offset(0, 1),
                      ),
                    ],
                    border: Border.all(
                      color: AppTheme.dividerColor.withValues(alpha: isHovered ? 1.0 : 0.8),
                      width: isHovered ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(subcategory).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getCategoryIcon(subcategory),
                          color: _getCategoryColor(subcategory).withValues(alpha: 0.9),
                          size: 16,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subcategory.displayName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              subcategory.description,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(subcategory).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$completedCount/$categoryCount',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getCategoryColor(subcategory).withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 하단 여백
  Widget _buildFooterSpacing() {
    return SliverToBoxAdapter(
      child: SizedBox(height: 80),
    );
  }

  /// 에러 뷰
  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.secondaryLight.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restaurant_menu,
              color: AppTheme.secondaryColor,
              size: 64,
            ),
          ),
          SizedBox(height: 16),
          Text(
            '챌린지를 준비하는데 문제가 발생했어요',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              final provider = Provider.of<ChallengeProvider>(context, listen: false);
              provider.refresh();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  /// 카테고리별 색상
  Color _getCategoryColor(ChallengeCategory category) {
    switch (category) {
      // 메인 카테고리
      case ChallengeCategory.emotional:
        return Color(0xFFE8A5C0); // 핑크 계열 (홈화면과 일치하는 부드러운 핑크)
      case ChallengeCategory.worldCuisine:
        return Color(0xFF4ECDC4); // 청록 계열
      case ChallengeCategory.healthy:
        return Color(0xFF45B7D1); // 파랑 계열
      
      // 감정별 서브카테고리 - 빈티지 테마에 맞게 조정
      case ChallengeCategory.emotionalHappy:
        return Color(0xFFD2A45B); // 빈티지 오렌지 (기쁨과 축하)
      case ChallengeCategory.emotionalComfort:
        return Color(0xFFB5704F); // 빈티지 레드 (위로와 치유)
      case ChallengeCategory.emotionalNostalgic:
        return Color(0xFF8B9A6B); // 연한 올리브 (그리움과 추억)
      case ChallengeCategory.emotionalEnergy:
        return Color(0xFF7A9B5C); // 허브 그린 (활력과 동기부여)
      
      // 세계 요리 서브카테고리 - 빈티지 테마에 맞게 조정
      case ChallengeCategory.worldAsian:
        return Color(0xFFB5704F); // 빈티지 레드 (아시아 요리)
      case ChallengeCategory.worldEuropean:
        return Color(0xFF6B8BA5); // 빈티지 블루 (유럽 요리)
      case ChallengeCategory.worldAmerican:
        return Color(0xFF7A9B5C); // 허브 그린 (아메리카 요리)
      case ChallengeCategory.worldFusion:
        return Color(0xFFD2A45B); // 빈티지 오렌지 (퓨전 요리)
      
      // 건강 라이프 서브카테고리 - 빈티지 테마에 맞게 조정
      case ChallengeCategory.healthyNatural:
        return Color(0xFF8B9A6B); // 라이트 올리브 (자연 건강)
      case ChallengeCategory.healthyEnergy:
        return Color(0xFFD2A45B); // 빈티지 오렌지 (에너지)
      case ChallengeCategory.healthyCare:
        return Color(0xFFB5704F); // 빈티지 레드 (케어)
      case ChallengeCategory.healthyHealing:
        return Color(0xFF7A9B5C); // 허브 그린 (힐링)
        
      default:
        return Color(0xFF95A5A6); // 기본 그레이
    }
  }

  /// 카테고리별 아이콘
  IconData _getCategoryIcon(ChallengeCategory category) {
    switch (category) {
      // 메인 카테고리
      case ChallengeCategory.emotional:
        return Icons.favorite;
      case ChallengeCategory.worldCuisine:
        return Icons.travel_explore;
      case ChallengeCategory.healthy:
        return Icons.eco;
      
      // 감정별 서브카테고리
      case ChallengeCategory.emotionalHappy:
        return Icons.celebration;
      case ChallengeCategory.emotionalComfort:
        return Icons.healing;
      case ChallengeCategory.emotionalNostalgic:
        return Icons.history;
      case ChallengeCategory.emotionalEnergy:
        return Icons.battery_charging_full;
      
      // 세계 요리 서브카테고리
      case ChallengeCategory.worldAsian:
        return Icons.ramen_dining;
      case ChallengeCategory.worldEuropean:
        return Icons.local_pizza;
      case ChallengeCategory.worldAmerican:
        return Icons.fastfood;
      case ChallengeCategory.worldFusion:
        return Icons.outdoor_grill;
      
      // 건강 라이프 서브카테고리
      case ChallengeCategory.healthyNatural:
        return Icons.nature;
      case ChallengeCategory.healthyEnergy:
        return Icons.bolt;
      case ChallengeCategory.healthyCare:
        return Icons.local_hospital;
      case ChallengeCategory.healthyHealing:
        return Icons.spa;
        
      default:
        return Icons.help;
    }
  }
}