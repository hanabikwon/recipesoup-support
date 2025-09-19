import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../models/recipe.dart';
import '../../utils/date_utils.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final bool showFavoriteButton;
  final VoidCallback? onFavoriteToggle;
  final bool isCompact;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.showFavoriteButton = false,
    this.onFavoriteToggle,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(4), // 덜 둥글게 (12 → 4)
          boxShadow: AppTheme.vintageShadow,
          border: Border.all(
            color: AppTheme.dividerColor,
            width: 0.5,
          ),
        ),
        child: isCompact ? _buildCompactLayout() : _buildFullLayout(),
      ),
    );
  }

  Widget _buildFullLayout() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: AppTheme.spacing12),
          _buildTitle(),
          const SizedBox(height: AppTheme.spacing8),
          _buildEmotionalStory(),
          const SizedBox(height: AppTheme.spacing12),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildCompactLayout() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.paddingSmall),
      child: Row(
        children: [
          _buildMoodIndicator(),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitle(),
                const SizedBox(height: 4),
                _buildEmotionalStory(maxLines: 2),
                const SizedBox(height: 4),
                _buildCompactFooter(),
              ],
            ),
          ),
          if (showFavoriteButton) _buildFavoriteButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _buildMoodIndicator(),
        const SizedBox(width: AppTheme.spacing8),
        Text(
          recipe.mood.korean,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        const Spacer(),
        if (showFavoriteButton) _buildFavoriteButton(),
        _buildRating(),
      ],
    );
  }

  Widget _buildMoodIndicator() {
    return Container(
      width: isCompact ? 40 : 48,
      height: isCompact ? 40 : 48,
      decoration: BoxDecoration(
        color: AppTheme.emotionColors[recipe.mood.english] ?? AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(8), // 덜 둥글게 (원형 → 둥근사각형)
        border: Border.all(
          color: AppTheme.dividerColor,
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          recipe.mood.icon,
          size: isCompact ? 20 : 24,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      recipe.title,
      style: TextStyle(
        fontSize: isCompact ? 14 : 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
      maxLines: isCompact ? 1 : 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildEmotionalStory({int? maxLines}) {
    return Text(
      recipe.emotionalStory,
      style: TextStyle(
        fontSize: isCompact ? 12 : 14,
        fontStyle: FontStyle.italic,
        color: AppTheme.textSecondary,
        height: 1.3,
      ),
      maxLines: maxLines ?? (isCompact ? 2 : 3),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        _buildDate(),
        const Spacer(),
        _buildTags(),
      ],
    );
  }

  Widget _buildCompactFooter() {
    return Row(
      children: [
        _buildDate(),
        const SizedBox(width: AppTheme.spacing8),
        if (recipe.tags.isNotEmpty) ...
          recipe.tags.take(2).map(
            (tag) => Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withValues(alpha: 77),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tag,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        const Spacer(),
        if (recipe.rating != null) _buildRating(),
      ],
    );
  }

  Widget _buildDate() {
    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: isCompact ? 12 : 14,
          color: AppTheme.textTertiary,
        ),
        const SizedBox(width: 4),
        Text(
          RecipeDateUtils.formatRelativeTime(recipe.createdAt, DateTime.now()),
          style: TextStyle(
            fontSize: isCompact ? 10 : 12,
            color: AppTheme.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildTags() {
    if (recipe.tags.isEmpty) return const SizedBox();
    
    final visibleTags = recipe.tags.take(isCompact ? 2 : 3).toList();
    
    return Wrap(
      spacing: 4,
      children: visibleTags.map(
        (tag) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight.withValues(alpha: 77),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            tag,
            style: TextStyle(
              fontSize: isCompact ? 10 : 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ).toList(),
    );
  }

  Widget _buildRating() {
    if (recipe.rating == null) return const SizedBox();
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star,
          size: isCompact ? 12 : 14,
          color: AppTheme.accentOrange,
        ),
        const SizedBox(width: 2),
        Text(
          '${recipe.rating}',
          style: TextStyle(
            fontSize: isCompact ? 10 : 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteButton() {
    return GestureDetector(
      onTap: onFavoriteToggle,
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Icon(
          recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
          size: isCompact ? 16 : 18,
          color: recipe.isFavorite ? AppTheme.errorColor : AppTheme.textTertiary,
        ),
      ),
    );
  }
}

// RecipeCard의 다양한 변형들
class RecipeCardList extends StatelessWidget {
  final List<Recipe> recipes;
  final Function(Recipe) onRecipeTap;
  final Function(Recipe)? onFavoriteToggle;
  final bool showFavoriteButton;
  final String? emptyMessage;

  const RecipeCardList({
    super.key,
    required this.recipes,
    required this.onRecipeTap,
    this.onFavoriteToggle,
    this.showFavoriteButton = false,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 48,
                color: AppTheme.textTertiary,
              ),
              const SizedBox(height: AppTheme.spacing16),
              Text(
                emptyMessage ?? AppConstants.emptyRecipesMessage.replaceAll('\\n', '\n'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return RecipeCard(
          recipe: recipe,
          onTap: () => onRecipeTap(recipe),
          showFavoriteButton: showFavoriteButton,
          onFavoriteToggle: onFavoriteToggle != null 
              ? () => onFavoriteToggle!(recipe)
              : null,
        );
      },
    );
  }
}

// 그리드 형태의 RecipeCard
class RecipeCardGrid extends StatelessWidget {
  final List<Recipe> recipes;
  final Function(Recipe) onRecipeTap;
  final Function(Recipe)? onFavoriteToggle;
  final bool showFavoriteButton;
  final int crossAxisCount;
  final String? emptyMessage;

  const RecipeCardGrid({
    super.key,
    required this.recipes,
    required this.onRecipeTap,
    this.onFavoriteToggle,
    this.showFavoriteButton = false,
    this.crossAxisCount = 2,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 48,
                color: AppTheme.textTertiary,
              ),
              const SizedBox(height: AppTheme.spacing16),
              Text(
                emptyMessage ?? AppConstants.emptyRecipesMessage.replaceAll('\\n', '\n'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.8,
        crossAxisSpacing: AppTheme.spacing8,
        mainAxisSpacing: AppTheme.spacing8,
      ),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return RecipeCard(
          recipe: recipe,
          onTap: () => onRecipeTap(recipe),
          showFavoriteButton: showFavoriteButton,
          onFavoriteToggle: onFavoriteToggle != null 
              ? () => onFavoriteToggle!(recipe)
              : null,
          isCompact: true,
        );
      },
    );
  }
}