import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/recipe_provider.dart';
import '../providers/challenge_provider.dart';
import '../services/content_service.dart';
import '../widgets/home/recent_recipe_card.dart';
import '../widgets/home/seasonal_recipe_card.dart';
import '../widgets/home/cooking_knowledge_card.dart';
import '../widgets/home/recommended_content_card.dart';
import '../widgets/home/challenge_cta_card.dart';
import '../widgets/vintage_loading_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  // 홈 콘텐츠 데이터
  Map<String, dynamic> _contentData = {};
  bool _isContentLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHomeContent();
    _initializeChallengeProvider();
  }

  /// ChallengeProvider 초기화
  void _initializeChallengeProvider() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final challengeProvider = Provider.of<ChallengeProvider>(context, listen: false);
      if (challengeProvider.allChallenges.isEmpty) {
        challengeProvider.loadInitialData();
      }
    });
  }

  /// 홈 화면 콘텐츠 로드 (제철 레시피, 요리 지식)
  Future<void> _loadHomeContent() async {
    if (!mounted) return;
    
    setState(() {
      _isContentLoading = true;
    });

    try {
      final data = await ContentService.loadContent();
      if (mounted) {
        setState(() {
          _contentData = data;
          _isContentLoading = false;
        });
      }
    } catch (e) {
      debugPrint('홈 콘텐츠 로드 실패: $e');
      if (mounted) {
        setState(() {
          _isContentLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: Consumer<RecipeProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && _isContentLoading) {
                    return _buildLoadingView();
                  }

                  return _buildNewContentView(provider);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: AppTheme.backgroundColor,
      child: Row(
        children: [
          Text(
            AppConstants.appName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: AppTheme.spacing8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            ),
            child: Text(
              '감정 기반',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              // 알림 기능 (추후 구현)
            },
            icon: const Icon(
              Icons.notifications_none,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const VintageLoadingWidget(
      message: '레시피를 불러오는 중...',
    );
  }

  /// 새로운 콘텐츠 뷰 (3개 섹션)
  Widget _buildNewContentView(RecipeProvider provider) {
    return RefreshIndicator(
      onRefresh: () async {
        // 🔥 CRITICAL FIX: 안전한 새로고침 (에러 발생시 기존 데이터 유지)
        try {
          final challengeProvider = Provider.of<ChallengeProvider>(context, listen: false);
          await Future.wait([
            provider.loadRecipes(), // 이미 안전하게 수정됨
            _loadHomeContent(),
            challengeProvider.refresh(), // 깡총 챌린지 데이터도 새로고침
          ]);
        } catch (e) {
          debugPrint('새로고침 중 오류 발생 (기존 데이터 유지): $e');
          // 에러가 발생해도 기존 데이터는 유지됨
        }
      },
      color: AppTheme.primaryColor,
      child: CustomScrollView(
        slivers: [
          // 최근 저장한 레시피 섹션
          SliverToBoxAdapter(
            child: RecentRecipeCard(
              recipe: provider.recipes.isNotEmpty ? provider.recipes.first : null,
            ),
          ),

          // 깡총 챌린지 CTA 카드
          const SliverToBoxAdapter(
            child: ChallengeCTACard(),
          ),

          // 섹션 간 추가 여백
          const SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),

          // 요즘 주목받는 레시피 섹션
          if (!_isContentLoading) ...[
            SliverToBoxAdapter(
              child: SeasonalRecipeCard(
                recipeData: _contentData['todayRecipe'],
              ),
            ),
          ] else ...[
            SliverToBoxAdapter(
              child: _buildContentLoadingCard('제철 레시피'),
            ),
          ],

          // 레시피 너머의 이야기 섹션
          if (!_isContentLoading) ...[
            SliverToBoxAdapter(
              child: CookingKnowledgeCard(
                knowledgeData: _contentData['todayKnowledge'],
              ),
            ),
          ] else ...[
            SliverToBoxAdapter(
              child: _buildContentLoadingCard('요리 지식'),
            ),
          ],

          // 콘텐츠 큐레이션 섹션
          if (!_isContentLoading) ...[
            SliverToBoxAdapter(
              child: RecommendedContentCard(
                contentData: _contentData['recommendedContent'],
              ),
            ),
          ] else ...[
            SliverToBoxAdapter(
              child: _buildContentLoadingCard('추천 콘텐츠'),
            ),
          ],


          // 하단 여백
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  /// 콘텐츠 로딩 중 표시하는 카드
  Widget _buildContentLoadingCard(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          boxShadow: AppTheme.vintageShadow,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$title 로딩 중...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }





  @override
  void dispose() {
    // 콘텐츠 서비스 캐시 정리 (메모리 최적화)
    ContentService.clearCache();
    super.dispose();
  }

}