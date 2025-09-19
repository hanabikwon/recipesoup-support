import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/recipe_suggestion.dart';
import 'create_screen.dart';

/// AI 레시피 추천 결과 화면
/// 3개의 추천 레시피를 카드 형태로 보여주고 사용자가 선택할 수 있는 화면
class RecipeRecommendationScreen extends StatelessWidget {
  final RecipeSuggestionResponse response;

  const RecipeRecommendationScreen({
    super.key,
    required this.response,
  });

  /// 선택된 레시피로 작성하기
  void _navigateToCreateScreen(BuildContext context, RecipeSuggestion suggestion) {
    // 모든 재료 통합 (입력 재료 + 추가 재료)
    final allIngredients = [
      ...response.inputIngredients,
      ...suggestion.additionalIngredients,
    ];

    // 조리법 텍스트 생성
    final cookingMethodText = suggestion.cookingSteps.isNotEmpty
        ? suggestion.cookingSteps.join('\n')
        : '${suggestion.description}\n\n예상 조리시간: ${suggestion.estimatedTime}\n난이도: ${suggestion.difficulty}';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateScreen(
          prefilledTitle: suggestion.dishName,
          prefilledIngredients: allIngredients,
          prefilledCookingMethod: cookingMethodText,
          dataSource: 'fridge_ingredients',
        ),
      ),
    );
  }

  /// 난이도에 따른 색상 반환
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case '쉬움':
        return AppTheme.successColor;
      case '보통':
        return AppTheme.warningColor;
      case '어려움':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  /// 난이도에 따른 아이콘 반환
  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty) {
      case '쉬움':
        return Icons.sentiment_satisfied;
      case '보통':
        return Icons.sentiment_neutral;
      case '어려움':
        return Icons.sentiment_dissatisfied;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 1,
        shadowColor: AppTheme.shadowColor,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppTheme.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'AI 레시피 추천',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 헤더 정보
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowColor,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: AppTheme.fabColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '맞춤 레시피 추천',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 입력한 재료들 표시
                  const Text(
                    '사용한 재료:',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: response.inputIngredients.map((ingredient) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryLight,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          ingredient,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // 추천 레시피 리스트
            Expanded(
              child: response.hasRecipes
                  ? ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: response.suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = response.suggestions[index];
                        return _buildRecipeCard(context, suggestion, index + 1);
                      },
                    )
                  : _buildEmptyState(),
            ),
          ],
        ),
      ),
    );
  }

  /// 레시피 카드 위젯
  Widget _buildRecipeCard(BuildContext context, RecipeSuggestion suggestion, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.vintageShadow,
        border: Border.all(
          color: AppTheme.dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카드 헤더
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    suggestion.dishName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                // 난이도 표시
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(suggestion.difficulty).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getDifficultyColor(suggestion.difficulty),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getDifficultyIcon(suggestion.difficulty),
                        size: 14,
                        color: _getDifficultyColor(suggestion.difficulty),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        suggestion.difficulty,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getDifficultyColor(suggestion.difficulty),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 카드 본문
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 설명
                Text(
                  suggestion.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 12),

                // 조리시간
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppTheme.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      suggestion.estimatedTime,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 추가 재료
                if (suggestion.additionalIngredients.isNotEmpty) ...[
                  const Text(
                    '추가로 필요한 재료:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: suggestion.additionalIngredients.map((ingredient) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.warningColor.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          ingredient,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // 간단한 조리 단계 (처음 2-3단계만 미리보기)
                if (suggestion.cookingSteps.isNotEmpty) ...[
                  const Text(
                    '조리 방법:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...suggestion.cookingSteps.take(3).map((step) {
                    final stepIndex = suggestion.cookingSteps.indexOf(step) + 1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Center(
                              child: Text(
                                '$stepIndex',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              step,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  if (suggestion.cookingSteps.length > 3)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        '... 더 많은 단계가 있습니다',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textTertiary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],

                const SizedBox(height: 16),

                // 선택 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _navigateToCreateScreen(context, suggestion),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.fabColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      shadowColor: AppTheme.shadowColor,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.restaurant_menu,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '이 요리로 레시피 작성하기',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

  /// 빈 상태 위젯 (추천 결과가 없을 때)
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppTheme.textTertiary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              '추천할 레시피를 찾지 못했습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              '다른 재료 조합을 시도해보세요.\n더 다양한 재료를 추가하면\n더 좋은 추천을 받을 수 있습니다.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textTertiary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}