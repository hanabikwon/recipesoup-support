import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../providers/recipe_provider.dart';
import '../models/mood.dart';
import '../models/recipe.dart';
import '../services/hive_service.dart';
import '../widgets/recipe/recipe_card.dart';
import 'detail_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int? _selectedMonth; // 선택된 월 (1~12, null이면 미선택)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: AppTheme.backgroundColor,
              child: Row(
                children: [
                  const Text(
                    '통계',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Expanded(
              child: Consumer<RecipeProvider>(
                builder: (context, provider, child) {
                  if (provider.recipes.isEmpty) {
                    return _buildEmptyState();
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.spacing16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOverviewCard(provider),
                        const SizedBox(height: AppTheme.spacing16),
                        _buildEmotionDistributionCard(provider),
                        const SizedBox(height: AppTheme.spacing16),
                        _buildMostUsedTagsCard(provider),
                        const SizedBox(height: AppTheme.spacing16),
                        _buildMonthlyRecipesCard(provider),
                        const SizedBox(height: AppTheme.spacing16),
                        _buildCookingPatternCard(provider),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics,
            size: 80,
            color: AppTheme.textTertiary.withValues(alpha: 128),
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            '통계를 보려면\n레시피를 작성해보세요',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(RecipeProvider provider) {
    final totalRecipes = provider.recipes.length;
    final thisMonthCount = provider.recipes.where((recipe) {
      final now = DateTime.now();
      return recipe.createdAt.year == now.year && recipe.createdAt.month == now.month;
    }).length;
    final favoriteCount = provider.recipes.where((r) => r.isFavorite).length;
    final averageRating = provider.recipes.isNotEmpty
        ? provider.recipes
            .where((r) => r.rating != null)
            .map((r) => r.rating!)
            .fold(0, (sum, rating) => sum + rating) / 
          provider.recipes.where((r) => r.rating != null).length
        : 0.0;

    return Card(
      elevation: 4,
      color: AppTheme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.analytics,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacing8),
                Text(
                  '전체 요약',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('총 레시피', '$totalRecipes개', Icons.book),
                ),
                Expanded(
                  child: _buildStatItem('이번 달', '$thisMonthCount개', Icons.calendar_month),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('즐겨찾기', '$favoriteCount개', Icons.favorite),
                ),
                Expanded(
                  child: _buildStatItem(
                    '평균 평점', 
                    averageRating > 0 ? '${averageRating.toStringAsFixed(1)}점' : '-',
                    Icons.star,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmotionDistributionCard(RecipeProvider provider) {
    final emotionCounts = <Mood, int>{};
    for (final recipe in provider.recipes) {
      emotionCounts[recipe.mood] = (emotionCounts[recipe.mood] ?? 0) + 1;
    }
    
    final sortedEmotions = emotionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 4,
      color: AppTheme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.mood,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacing8),
                Text(
                  '감정 분포',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing16),
            ...sortedEmotions.map((entry) {
              final percentage = (entry.value / provider.recipes.length * 100);
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
                child: Row(
                  children: [
                    Text(
                      entry.key.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key.korean,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${entry.value}회 (${percentage.toStringAsFixed(0)}%)',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: AppTheme.dividerColor,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.emotionColors[entry.key.english] ?? AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMostUsedTagsCard(RecipeProvider provider) {
    final tagCounts = <String, int>{};
    for (final recipe in provider.recipes) {
      for (final tag in recipe.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    
    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTags = sortedTags.take(10).toList();

    return Card(
      elevation: 4,
      color: AppTheme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.tag,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacing8),
                Text(
                  '자주 사용한 태그',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing16),
            if (topTags.isEmpty)
              Text(
                '아직 태그가 없습니다',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              )
            else
              Wrap(
                spacing: AppTheme.spacing8,
                runSpacing: AppTheme.spacing8,
                children: topTags.map((entry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing12,
                      vertical: AppTheme.spacing8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withValues(alpha: 77),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                      border: Border.all(
                        color: AppTheme.primaryLight,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.key,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${entry.value}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyRecipesCard(RecipeProvider provider) {
    final now = DateTime.now();
    final currentYear = now.year;

    return Card(
      elevation: 4,
      color: AppTheme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_month,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacing8),
                Text(
                  '월별 레시피',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              '$currentYear년',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(12, (index) {
                final month = index + 1;
                final isSelected = _selectedMonth == month;

                return ChoiceChip(
                  label: Text('$month월'),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryColor,
                  backgroundColor: AppTheme.backgroundColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _selectedMonth = selected ? month : null;
                    });
                  },
                );
              }),
            ),
            if (_selectedMonth != null) ...[
              const SizedBox(height: AppTheme.spacing16),
              const Divider(color: AppTheme.dividerColor),
              const SizedBox(height: AppTheme.spacing16),
              _buildSelectedMonthRecipes(currentYear),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedMonthRecipes(int year) {
    return FutureBuilder<List<Recipe>>(
      future: _getRecipesByMonth(_selectedMonth!, year),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacing16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              '오류가 발생했습니다',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.errorColor,
              ),
            ),
          );
        }

        final recipes = snapshot.data ?? [];

        if (recipes.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                children: [
                  Icon(
                    Icons.no_meals,
                    size: 48,
                    color: AppTheme.textTertiary.withValues(alpha: 128),
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  Text(
                    '$year년 $_selectedMonth월에는\n레시피가 없습니다',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$year년 $_selectedMonth월 (${recipes.length}개)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            ...recipes.map((recipe) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
                child: RecipeCard(
                  recipe: recipe,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(recipe: recipe),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Future<List<Recipe>> _getRecipesByMonth(int month, int year) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    final hiveService = HiveService();
    return await hiveService.getRecipesByDateRange(startDate, endDate);
  }

  Widget _buildCookingPatternCard(RecipeProvider provider) {
    final preferredTime = _getPreferredCookingTime(provider);
    final mostActiveDay = _getMostActiveDay(provider);
    final averageRecipesPerMonth = _getAverageRecipesPerMonth(provider);

    return Card(
      elevation: 4,
      color: AppTheme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.insights,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacing8),
                Text(
                  '요리 패턴',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing16),
            _buildPatternItem(
              '선호 시간대',
              preferredTime,
              Icons.access_time,
            ),
            const SizedBox(height: AppTheme.spacing12),
            _buildPatternItem(
              '가장 활발한 요일',
              mostActiveDay,
              Icons.calendar_today,
            ),
            const SizedBox(height: AppTheme.spacing12),
            _buildPatternItem(
              '월 평균 레시피',
              '${averageRecipesPerMonth.toStringAsFixed(1)}개',
              Icons.trending_up,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.textSecondary,
        ),
        const SizedBox(width: AppTheme.spacing8),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getPreferredCookingTime(RecipeProvider provider) {
    final hourCounts = <int, int>{};
    
    for (final recipe in provider.recipes) {
      final hour = recipe.createdAt.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }
    
    if (hourCounts.isEmpty) return '데이터 없음';
    
    final mostActiveHour = hourCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
      
    if (mostActiveHour >= 6 && mostActiveHour < 12) {
      return '오전 시간';
    } else if (mostActiveHour >= 12 && mostActiveHour < 18) {
      return '오후 시간';
    } else if (mostActiveHour >= 18 && mostActiveHour < 24) {
      return '저녁 시간';
    } else {
      return '밤 시간';
    }
  }

  String _getMostActiveDay(RecipeProvider provider) {
    final dayCounts = <int, int>{};
    
    for (final recipe in provider.recipes) {
      final weekday = recipe.createdAt.weekday;
      dayCounts[weekday] = (dayCounts[weekday] ?? 0) + 1;
    }
    
    if (dayCounts.isEmpty) return '데이터 없음';
    
    final mostActiveDay = dayCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    const weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];
    return '${weekdayNames[mostActiveDay - 1]}요일';
  }

  double _getAverageRecipesPerMonth(RecipeProvider provider) {
    if (provider.recipes.isEmpty) return 0.0;
    
    final oldestRecipe = provider.recipes
        .reduce((a, b) => a.createdAt.isBefore(b.createdAt) ? a : b);
    final monthsSinceOldest = DateTime.now().difference(oldestRecipe.createdAt).inDays / 30.44;
    
    return monthsSinceOldest > 0 ? provider.recipes.length / monthsSinceOldest : provider.recipes.length.toDouble();
  }
}