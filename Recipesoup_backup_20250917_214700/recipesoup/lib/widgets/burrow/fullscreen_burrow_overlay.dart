import 'package:flutter/material.dart';
import '../../models/burrow_milestone.dart';
import '../../utils/ultra_burrow_image_handler.dart';

/// 세로형 이미지를 배경으로 활용한 풀스크린 토끼굴 오버레이
/// 800x1000 세로 이미지를 전체 화면에 표시하며, 상하단에 그라디언트 오버레이 적용
class FullscreenBurrowOverlay extends StatelessWidget {
  final BurrowMilestone milestone;
  
  const FullscreenBurrowOverlay({
    super.key,
    required this.milestone,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // 완전 투명 배경 - 이미지가 자연스럽게 보이도록
      body: Stack(
        children: [
          // 배경 이미지 (세로형 800x1000) - 가장 뒤
          _buildBackgroundImage(),
          
          // 그라디언트 오버레이들
          _buildGradientOverlays(),
          
          // 하단 정보 오버레이
          _buildBottomInfoOverlay(context),
          
          // 상단 컨트롤 (X 버튼, 레벨 뱃지) - 가장 앞
          _buildTopControls(context),
        ],
      ),
    );
  }
  
  /// 배경 이미지 위젯
  Widget _buildBackgroundImage() {
    return Positioned.fill(
      child: UltraBurrowImageHandler.ultraSafeImage(
        imagePath: milestone.imagePath,
        milestone: milestone,
        fit: BoxFit.cover, // 전체 화면에 맞게 크롭
        errorWidget: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF8B9A6B).withValues(alpha: 0.3),
                const Color(0xFF5A6B49).withValues(alpha: 0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.image,
              size: 100,
              color: Colors.white54,
            ),
          ),
        ),
      ),
    );
  }
  
  /// 그라디언트 오버레이들 (상단과 하단)
  Widget _buildGradientOverlays() {
    return Stack(
      children: [
        // 상단 그라디언트
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.5),
                  Colors.black.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  /// 상단 컨트롤 (X 버튼, 레벨 뱃지) - 가장 앞
  Widget _buildTopControls(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEnhancedCloseButton(context),
              _buildEnhancedLevelBadge(),
            ],
          ),
        ),
      ),
    );
  }
  
  /// 간단한 닫기 버튼
  Widget _buildEnhancedCloseButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.close,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
  
  /// 간단한 레벨 뱃지
  Widget _buildEnhancedLevelBadge() {
    return Container(
      height: 40, // X 버튼과 동일한 높이로 맞춤
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF8B9A6B).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20), // 높이에 맞춰 둥근 정도 조정
      ),
      child: Center( // 텍스트를 중앙 정렬
        child: Text(
          milestone.isSpecialRoom 
              ? '특별 공간' 
              : 'Lv.${milestone.level}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13, // 살짝 크게 조정
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
  
  /// 하단 정보 오버레이 (어두운 그라디언트 + 텍스트)
  Widget _buildBottomInfoOverlay(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.8), // 하단 80% 불투명도
              Colors.black.withValues(alpha: 0.5),  // 중간 50% 불투명도
              Colors.black.withValues(alpha: 0.2),  // 상단쪽 약간 투명
              Colors.transparent, // 최상단 완전 투명
            ],
            stops: const [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 제목
            Row(
              children: [
                Icon(
                  milestone.isSpecialRoom 
                      ? Icons.auto_awesome 
                      : Icons.home,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    milestone.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // 구분선
            Container(
              width: 80,
              height: 2,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 설명
            Text(
              milestone.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.bold, // 볼드 처리 추가
                fontStyle: FontStyle.italic,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 달성 정보 또는 조건
            if (milestone.isUnlocked && milestone.unlockedAt != null) ...[
              // 달성된 경우
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B9A6B).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '달성: ${_formatDate(milestone.unlockedAt!)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD2A45B).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.restaurant_menu,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      milestone.isSpecialRoom
                          ? '특별 공간'
                          : '레시피 ${milestone.requiredRecipes ?? 0}개로 오픈',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // 미달성인 경우
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '아직 열리지 않은 공간',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      milestone.isSpecialRoom
                          ? '특별한 조건을 만족하면 열려요!'
                          : '레시피 ${milestone.requiredRecipes ?? 0}개를 작성하면 열려요',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// 날짜 포맷팅
  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}