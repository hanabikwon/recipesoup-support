import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../providers/challenge_provider.dart';
import '../models/challenge_models.dart';
import '../widgets/vintage_loading_widget.dart';
import '../widgets/common/vintage_info_card.dart';
import 'challenge_detail_screen.dart';

/// 카테고리별 챌린지 목록 화면 (간단한 wireframe 기반)
/// 단순한 세로 리스트 형태로 챌린지들을 보여주는 화면
class ChallengeCategoryScreen extends StatefulWidget {
  final ChallengeCategory category;
  
  const ChallengeCategoryScreen({
    super.key,
    required this.category,
  });

  @override
  State<ChallengeCategoryScreen> createState() => _ChallengeCategoryScreenState();
}

class _ChallengeCategoryScreenState extends State<ChallengeCategoryScreen> {
  
  @override
  void initState() {
    super.initState();
    // 현재 카테고리로 필터 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ChallengeProvider>(context, listen: false);
      provider.setCategory(widget.category);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
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
        title: Text(
          _getCategoryTitle(widget.category),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<ChallengeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return VintageLoadingWidget(
              message: '${_getCategoryTitle(widget.category)} 챌린지를 불러오고 있어요...',
            );
          }

          if (provider.error != null) {
            return _buildErrorView(provider.error!);
          }

          final challenges = provider.filteredChallenges
              .where((c) => c.category == widget.category)
              .toList();

          if (challenges.isEmpty) {
            return _buildEmptyView();
          }

          return ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: challenges.length,
            separatorBuilder: (context, index) => SizedBox(height: 12),
            itemBuilder: (context, index) {
              final challenge = challenges[index];
              final progress = provider.getProgressById(challenge.id);
              return _buildSimpleChallengeCard(challenge, progress);
            },
          );
        },
      ),
    );
  }

  /// 간단한 챌린지 카드 (wireframe 기반)
  Widget _buildSimpleChallengeCard(Challenge challenge, ChallengeProgress? progress) {
    final isCompleted = progress?.isCompleted ?? false;
    
    return InkWell(
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
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowColor.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
            BoxShadow(
              color: AppTheme.shadowColor.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
          border: isCompleted 
              ? Border.all(color: AppTheme.successColor.withValues(alpha: 0.7), width: 2)
              : Border.all(color: AppTheme.dividerColor.withValues(alpha: 0.6), width: 1),
        ),
        child: Row(
          children: [
            // 왼쪽: 카테고리 아이콘
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getCategoryIcon(widget.category),
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            
            SizedBox(width: 16),
            
            // 중간: 콘텐츠
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  Text(
                    challenge.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: 4),
                  
                  // 난이도 별점
                  Row(
                    children: List.generate(
                      challenge.difficulty,
                      (index) => Icon(
                        Icons.star,
                        size: 14,
                        color: AppTheme.accentOrange,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 4),
                  
                  // 시간
                  Text(
                    '${challenge.estimatedMinutes}분',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  
                  SizedBox(height: 6),
                  
                  // 설명
                  Text(
                    challenge.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // 오른쪽: 완료 상태 또는 화살표
            if (isCompleted)
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  size: 16,
                  color: AppTheme.successColor,
                ),
              )
            else
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppTheme.textSecondary,
              ),
          ],
        ),
      ),
    );
  }

  /// 간단한 빈 뷰
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getCategoryIcon(widget.category),
              color: AppTheme.primaryColor,
              size: 48,
            ),
          ),
          SizedBox(height: 16),
          Text(
            '챌린지가 없어요',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '새로운 챌린지를 기다려주세요',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 간단한 에러 뷰 (VintageInfoCard 사용)
  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            VintageInfoCard(
              title: '잠시만 기다려주세요 🐰',
              message: '챌린지를 불러오는데 실패했어요.\n잠시 후 다시 시도해주세요.',
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final provider = Provider.of<ChallengeProvider>(context, listen: false);
                provider.refresh();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
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
      ),
    );
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
        return Icons.self_improvement;
    }
  }

  /// 카테고리별 제목
  String _getCategoryTitle(ChallengeCategory category) {
    switch (category) {
      // 메인 카테고리
      case ChallengeCategory.emotional:
        return '감정 요리 챌린지';
      case ChallengeCategory.worldCuisine:
        return '세계 요리 탐험';
      case ChallengeCategory.healthy:
        return '건강한 요리';
      
      // 감정별 서브카테고리
      case ChallengeCategory.emotionalHappy:
        return '기쁨과 축하 요리';
      case ChallengeCategory.emotionalComfort:
        return '위로와 치유 요리';
      case ChallengeCategory.emotionalNostalgic:
        return '그리움과 추억 요리';
      case ChallengeCategory.emotionalEnergy:
        return '활력과 동기부여 요리';
      
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
        return '자연 친화 요리';
      case ChallengeCategory.healthyEnergy:
        return '에너지 충전 요리';
      case ChallengeCategory.healthyCare:
        return '건강 관리 요리';
      case ChallengeCategory.healthyHealing:
        return '몸과 마음 케어 요리';
    }
  }
}