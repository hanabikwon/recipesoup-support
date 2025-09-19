import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/burrow_milestone.dart';
import '../../providers/recipe_provider.dart';
import '../../utils/burrow_image_handler.dart';

/// 성장 트랙 마일스톤 카드 (업데이트됨)
/// 레시피 수량 기반 마일스톤 표시용
class BurrowMilestoneCard extends StatelessWidget {
  final BurrowMilestone milestone;
  final VoidCallback? onTap;

  const BurrowMilestoneCard({
    super.key,
    required this.milestone,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: milestone.isUnlocked ? 4 : 2,
      color: milestone.isUnlocked 
          ? const Color(0xFFFFFEFB) 
          : Colors.red.withValues(alpha: 77), // 테스트: 잠긴 굴을 빨간색으로
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: milestone.isUnlocked 
              ? const Color(0xFFD2A45B) 
              : const Color(0xFFE8E3D8),
          width: milestone.isUnlocked ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: milestone.isUnlocked ? onTap : () => _showLockedBurrowDialog(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 마일스톤 이미지
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFF8F6F1),
                  border: Border.all(
                    color: const Color(0xFFE8E3D8),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildMilestoneImage(),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // 마일스톤 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 레벨과 상태
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: milestone.isUnlocked 
                                ? const Color(0xFFD2A45B) 
                                : const Color(0xFF8B9A6B),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Lv.${milestone.level}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Achievement time moved next to Lv.1
                        if (milestone.isUnlocked && milestone.unlockedAt != null)
                          Text(
                            '달성: ${_formatDate(milestone.unlockedAt!)}',
                            style: const TextStyle(
                              color: Color(0xFF8B9A6B),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        const Spacer(),
                        if (milestone.isUnlocked)
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF7A9B5C),
                            size: 18,
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // 마일스톤 제목 (라운드 테두리 적용)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: milestone.isUnlocked ? 16 : 14,
                        vertical: milestone.isUnlocked ? 8 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: milestone.isUnlocked 
                            ? const Color(0xFFFFF8E5)  // 열린 굴: 따뜻한 노란빛
                            : const Color(0xFFF0F0EC), // 잠긴 굴: 연한 회색
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: milestone.isUnlocked 
                              ? const Color(0xFFD2A45B)  // 열린 굴: 올리브 오렌지
                              : const Color(0xFFE8E3D8), // 잠긴 굴: 베이지 회색
                          width: milestone.isUnlocked ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        milestone.title,
                        style: TextStyle(
                          color: milestone.isUnlocked 
                              ? const Color(0xFF2E3D1F)  // 열린 굴: 진한 올리브
                              : const Color(0xFF8B9A6B), // 잠긴 굴: 연한 올리브
                          fontSize: 18,
                          fontWeight: milestone.isUnlocked 
                              ? FontWeight.bold 
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // 레시피 요구사항과 액션 프롬프트 (높이 통일)
                    Consumer<RecipeProvider>(
                      builder: (context, recipeProvider, child) {
                        final currentRecipes = recipeProvider.recipes.length;
                        
                        if (milestone.requiredRecipes != null) {
                          if (milestone.isUnlocked) {
                            // 열린 카드: 고정 높이 컨테이너로 통일
                            return SizedBox(
                              height: 40, // 잠긴 카드와 동일한 높이 보장
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '레시피 ${milestone.requiredRecipes}개 달성',
                                  style: const TextStyle(
                                    color: Color(0xFF7A9B5C),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          } else {
                            final remaining = milestone.requiredRecipes! - currentRecipes;
                            // 잠긴 카드: 간단한 텍스트로 통일 (진행률 표시 제거)
                            return SizedBox(
                              height: 40, // 열린 카드와 동일한 높이
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  remaining > 0 
                                    ? '레시피 $remaining개 더 필요'
                                    : '레시피 ${milestone.requiredRecipes}개 필요',
                                  style: const TextStyle(
                                    color: Color(0xFF8B9A6B),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }
                        }
                        
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
              
            ],
          ),
        ),
      ),
    );
  }

  /// 마일스톤 이미지 위젯 (BurrowImageHandler 사용)
  Widget _buildMilestoneImage() {
    if (milestone.isUnlocked) {
      return BurrowImageHandler.safeImage(
        imagePath: milestone.imagePath,
        milestone: milestone,
        fit: BoxFit.cover,
        width: 60,
        height: 60,
      );
    } else {
      return Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8E3D8), Color(0xFFB8C2A7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                color: Colors.white.withValues(alpha: 204),
                size: 20,
              ),
              const SizedBox(height: 2),
              Text(
                '???',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 204),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
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

  /// 날짜 포맷팅
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return '오늘 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}