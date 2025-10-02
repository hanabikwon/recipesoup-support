import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/burrow_milestone.dart';
import '../../providers/recipe_provider.dart';
import '../../utils/ultra_burrow_image_handler.dart';

/// Ultra 개선된 성장 트랙 마일스톤 카드
/// burrow-fix-ver2.txt에서 계획된 세련된 디자인 구현
class UltraBurrowMilestoneCard extends StatelessWidget {
  final BurrowMilestone milestone;
  final VoidCallback? onTap;

  const UltraBurrowMilestoneCard({
    super.key,
    required this.milestone,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: milestone.isUnlocked ? 6 : 2,
        shadowColor: milestone.isUnlocked 
            ? const Color(0xFFD2A45B).withValues(alpha: 77)
            : Colors.black.withValues(alpha: 26),
        color: milestone.isUnlocked 
            ? const Color(0xFFFFFEFB) 
            : const Color(0xFFF8F6F1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: milestone.isUnlocked 
                ? const Color(0xFFD2A45B) 
                : const Color(0xFFE8E3D8),
            width: milestone.isUnlocked ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: milestone.isUnlocked ? onTap : () => _showLockedBurrowDialog(context),
          borderRadius: BorderRadius.circular(20),
          splashColor: const Color(0xFFD2A45B).withValues(alpha: 26),
          highlightColor: const Color(0xFF8B9A6B).withValues(alpha: 13),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // 썸네일 이미지 (Ultra 핸들러 사용)
                _buildThumbnail(),
                
                const SizedBox(width: 16),
                
                // 메인 콘텐츠
                Expanded(
                  child: _buildContent(context),
                ),
                
                // 우측 상태 표시
                _buildStatusIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 썸네일 이미지 (Ultra 핸들러 적용) + 잠금 상태 딤드 처리
  Widget _buildThumbnail() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: milestone.isUnlocked 
                ? const Color(0xFFD2A45B).withValues(alpha: 51)
                : Colors.black.withValues(alpha: 26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // 기본 이미지
            UltraBurrowImageHandler.ultraSafeImage(
              imagePath: milestone.imagePath,
              milestone: milestone,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
            // 특별한 공간에서 잠금 상태일 때만 burrow_locked.png 이미지로 교체
            if (!milestone.isUnlocked && milestone.burrowType == BurrowType.special)
              UltraBurrowImageHandler.ultraSafeImage(
                imagePath: 'assets/images/burrow/special_rooms/burrow_locked.webp',
                milestone: milestone,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
          ],
        ),
      ),
    );
  }

  /// 메인 콘텐츠 (제목 + 설명)
  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 레벨 배지 + 달성 시간
        Row(
          children: [
            // 레벨 배지
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: milestone.isUnlocked 
                    ? const Color(0xFFD2A45B)
                    : const Color(0xFFBDBDBD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Lv.${milestone.level}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // 언락된 경우 달성 시간 표시
            if (milestone.isUnlocked) ...[
              const SizedBox(width: 8),
              Text(
                _getAchievementTime(),
                style: TextStyle(
                  color: const Color(0xFF8B9A6B),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        
        const SizedBox(height: 8),
        
        // 제목
        Text(
          milestone.title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: milestone.isUnlocked 
                ? const Color(0xFF2E3D1F)
                : const Color(0xFF757575),
          ),
        ),
        
        const SizedBox(height: 4),
        
        // 설명 (상태에 따라 다른 텍스트)
        _buildDescription(context),
      ],
    );
  }

  /// 상태별 설명 텍스트
  Widget _buildDescription(BuildContext context) {
    if (milestone.isUnlocked) {
      // 언락된 상태: 달성 정보
      return Text(
        _getUnlockedDescription(),
        style: TextStyle(
          color: const Color(0xFF7A9B5C),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      );
    } else {
      // 잠긴 상태: 필요 조건 (0/5 형식으로 표시)
      return Consumer<RecipeProvider>(
        builder: (context, recipeProvider, child) {
          final currentCount = recipeProvider.recipes.length;
          final required = milestone.requiredRecipes ?? 0;
          
          return Text(
            '$currentCount/$required',
            style: TextStyle(
              color: const Color(0xFF757575),
              fontSize: 14,
            ),
          );
        },
      );
    }
  }

  /// 우측 상태 표시 아이콘 (주황색 동그라미 제거, 체크 아이콘으로 변경)
  Widget _buildStatusIndicator() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFE8E3D8), // 언락/잠김 모두 동일한 베이지 배경
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        milestone.isUnlocked 
            ? Icons.check_circle // chevron_right → check_circle로 변경
            : Icons.lock_outline,
        color: milestone.isUnlocked 
            ? const Color(0xFF7A9B5C) // 주황색 → 올리브 그린으로 변경
            : const Color(0xFF9E9E9E),
        size: 20,
      ),
    );
  }

  /// 언락된 상태 설명 (계획된 카피 적용)
  String _getUnlockedDescription() {
    // burrow_unlock_service.dart에 정의된 각 레벨별 설명을 그대로 사용
    // Level 1~32까지 모두 정확한 설명이 표시됨
    return milestone.description;
  }

  /// 달성 시간 표시
  String _getAchievementTime() {
    final now = DateTime.now();
    final unlockTime = milestone.unlockedAt ?? now;
    final diff = now.difference(unlockTime);
    
    if (diff.inDays > 0) {
      return '달성: ${diff.inDays}일 전';
    } else if (diff.inHours > 0) {
      return '달성: ${diff.inHours}시간 전';
    } else if (diff.inMinutes > 0) {
      return '달성: ${diff.inMinutes}분 전';
    } else {
      return '달성: 방금 전';
    }
  }

  /// 잠긴 굴 팝업 다이얼로그
  void _showLockedBurrowDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<RecipeProvider>(
          builder: (context, recipeProvider, child) {
            final currentRecipes = recipeProvider.recipes.length;
            final remaining = (milestone.requiredRecipes ?? 0) - currentRecipes;
            final progress = milestone.requiredRecipes != null 
                ? currentRecipes / milestone.requiredRecipes! 
                : 0.0;
            
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 헤더 - 자물쇠 아이콘과 타이틀
                  Row(
                    children: [
                      const Icon(
                        Icons.lock,
                        size: 24,
                        color: Color(0xFF8B9A6B),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "아직 열리지 않은 굴",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF8B9A6B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 굴 이름 (라운드 테두리)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0EC),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFFE8E3D8), width: 1),
                    ),
                    child: Text(
                      milestone.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B9A6B),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 진행 상황 텍스트
                  Text(
                    remaining > 0 
                        ? "레시피를 $remaining개 더 작성하면 열려요!"
                        : "조건을 만족하면 열려요!",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF5A6B49),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 현재/필요 표시
                  if (milestone.requiredRecipes != null) ...[ 
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "현재: ",
                          style: TextStyle(color: Color(0xFF8B9A6B), fontSize: 13),
                        ),
                        Text(
                          "$currentRecipes개",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF2E3D1F),
                          ),
                        ),
                        const Text(
                          " / ",
                          style: TextStyle(color: Color(0xFF8B9A6B), fontSize: 13),
                        ),
                        const Text(
                          "필요: ",
                          style: TextStyle(color: Color(0xFF8B9A6B), fontSize: 13),
                        ),
                        Text(
                          "${milestone.requiredRecipes}개",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF2E3D1F),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 프로그레스 바
                    LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: const Color(0xFFE8E3D8),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF8B9A6B)),
                      minHeight: 6,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // 퍼센트 표시
                    Text(
                      "${(progress * 100).clamp(0, 100).toInt()}%",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B9A6B),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // 닫기 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B9A6B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "닫기",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}