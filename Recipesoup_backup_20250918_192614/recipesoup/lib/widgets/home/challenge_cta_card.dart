import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/challenge_provider.dart';
import '../../screens/challenge_hub_screen.dart';

/// 홈 화면에 표시되는 깡총 챌린지 CTA 카드
/// 사용자에게 챌린지 시스템을 소개하고 참여를 유도하는 핵심 UI
class ChallengeCTACard extends StatelessWidget {
  const ChallengeCTACard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Consumer<ChallengeProvider>(
        builder: (context, challengeProvider, child) {
          // 데이터 로딩 중일 때
          if (challengeProvider.isLoading) {
            return _buildLoadingStateWithHeader(context);
          }

          // 에러 상태일 때
          if (challengeProvider.error != null) {
            return _buildErrorStateWithHeader(context, challengeProvider.error!);
          }

          // 정상 상태일 때
          return _buildNormalStateWithHeader(context, challengeProvider);
        },
      ),
    );
  }

  /// 헤더가 분리된 로딩 상태 UI
  Widget _buildLoadingStateWithHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더: 제목과 뱃지를 박스 밖으로 (로딩 중이므로 기본값)
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              // 깡총 챌린지 제목
              Row(
                children: [
                  Text(
                    '🐰',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '깡총 챌린지',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // 로딩 중 뱃지
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '...',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // 메인 콘텐츠 박스 (로딩 상태)
        Container(
          width: double.infinity,
          height: 120,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: AppTheme.primaryLight.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '깡총 챌린지 로딩 중...',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 헤더가 분리된 에러 상태 UI
  Widget _buildErrorStateWithHeader(BuildContext context, String error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더: 제목과 뱃지를 박스 밖으로 (에러 상태)
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              // 깡총 챌린지 제목
              Row(
                children: [
                  Text(
                    '🐰',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '깡총 챌린지',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // 에러 뱃지
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '오류',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // 메인 콘텐츠 박스 (에러 상태)
        Container(
          width: double.infinity,
          height: 120,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: AppTheme.primaryLight.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppTheme.textSecondary.withValues(alpha: 0.7),
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  '챌린지 로드 실패',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Removed unused _buildLoadingState method

  // Removed unused _buildErrorState method

  /// 헤더가 분리된 정상 상태 UI
  Widget _buildNormalStateWithHeader(BuildContext context, ChallengeProvider provider) {
    final totalChallenges = provider.allChallenges.length;
    // final completedCount = provider.userProgress.values
    //     .where((progress) => progress.isCompleted)
    //     .length;
    // completionRate calculation and completedCount removed - were unused

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더: 제목과 뱃지를 박스 밖으로
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              // 깡총 챌린지 제목
              Row(
                children: [
                  Text(
                    '🐰',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '깡총 챌린지',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // 챌린지 개수 뱃지
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$totalChallenges개',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 메인 콘텐츠 박스
        InkWell(
          onTap: () => _navigateToChallengePage(context),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor, // 다른 섹션과 통일된 베이지 아이보리 배경
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: const Color(0xFFD2A45B), // 빈티지 당근색 border
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // 왼쪽 텍스트 영역
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 메인 메시지
                      Text(
                        '새로운 요리 모험',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // 서브 텍스트
                      Text(
                        '감정별·세계·건강 $totalChallenges개의 다양한 요리 챌린지',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 좌측 하단 CTA
                      Row(
                        children: [
                          Text(
                            '시작하기',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // 우측 이미지 영역
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 80,
                    child: Image.asset(
                      'assets/images/main_challenge.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Removed unused _buildNormalState method - was never called
  /*
  Widget _removedBuildNormalState(BuildContext context, ChallengeProvider provider) {
    final totalChallenges = provider.allChallenges.length;
    final completedCount = provider.userProgress.values
        .where((progress) => progress.isCompleted)
        .length;
    final completionRate = totalChallenges > 0 
        ? (completedCount * 100 / totalChallenges).round() 
        : 0;

    return InkWell(
      onTap: () => _navigateToChallengePage(context),
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더: 브랜딩 + 통계
            Row(
              children: [
                // 깡총 챌린지 브랜딩
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '🐰',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '깡총 챌린지',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // 완료율 표시
                if (totalChallenges > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$completionRate%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // 메인 메시지
            Text(
              '새로운 요리 모험을 시작해보세요!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            
            const SizedBox(height: 6),
            
            Text(
              '감정별·세계·건강 $totalChallenges개의 다양한 요리 챌린지',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            
            const SizedBox(height: 10),
            
            // CTA 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _navigateToChallengePage(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '챌린지 시작하기',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  */



  /// 챌린지 페이지로 네비게이션
  void _navigateToChallengePage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ChallengeHubScreen(),
      ),
    );
  }
}