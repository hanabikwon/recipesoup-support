import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../utils/date_utils.dart';
import 'create_screen.dart';

class DetailScreen extends StatefulWidget {
  final Recipe recipe;

  const DetailScreen({
    super.key,
    required this.recipe,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late Recipe _currentRecipe;

  @override
  void initState() {
    super.initState();
    _currentRecipe = widget.recipe;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          _buildRecipeInfo(),
          _buildTabBar(),
          _buildTabContent(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _currentRecipe.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryDark,
              ],
            ),
          ),
          child: _currentRecipe.localImagePath != null
              ? Image.asset(
                  _currentRecipe.localImagePath!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholderImage();
                  },
                )
              : _buildPlaceholderImage(),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _toggleFavorite,
          icon: Icon(
            _currentRecipe.isFavorite
                ? Icons.favorite
                : Icons.favorite_border,
            color: _currentRecipe.isFavorite
                ? AppTheme.errorColor
                : Colors.white,
          ),
        ),
        PopupMenuButton<String>(
          onSelected: _onMenuSelected,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('수정'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: AppTheme.errorColor),
                  SizedBox(width: 8),
                  Text('삭제', style: TextStyle(color: AppTheme.errorColor)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppTheme.primaryLight,
      child: Center(
        child: Icon(
          Icons.restaurant_menu,
          size: 80,
          color: Colors.white.withValues(alpha: 179),
        ),
      ),
    );
  }

  Widget _buildRecipeInfo() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _currentRecipe.mood.icon,
                  size: 24,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  _currentRecipe.mood.korean,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  RecipeDateUtils.formatKoreanDate(_currentRecipe.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor, // 따뜻한 아이보리 배경
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.dividerColor.withValues(alpha: 179), // Subtle border
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '감정 이야기',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentRecipe.emotionalStory,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        minHeight: 48,
        maxHeight: 48,
        child: Container(
          color: AppTheme.backgroundColor,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primaryColor,
            indicatorWeight: 2,
            tabs: const [
              Tab(text: '재료'),
              Tab(text: '소스'),
              Tab(text: '조리법'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildIngredientsTab(),
          _buildSauceTab(),
          _buildInstructionsTab(),
        ],
      ),
    );
  }

  Widget _buildIngredientsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '재료 (${_currentRecipe.ingredients.length}개)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: _currentRecipe.ingredients.length,
              separatorBuilder: (context, index) => const Divider(
                color: AppTheme.dividerColor,
                height: 1,
              ),
              itemBuilder: (context, index) {
                final ingredient = _currentRecipe.ingredients[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  minVerticalPadding: 0,
                  leading: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  title: Text(
                    ingredient.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  trailing: ingredient.amount != null
                      ? Text(
                          '${ingredient.amount}${ingredient.unit ?? ''}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '조리법 (${_currentRecipe.instructions.length}단계)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: _currentRecipe.instructions.length,
              separatorBuilder: (context, index) => const Divider(
                color: AppTheme.dividerColor,
                height: 1,
              ),
              itemBuilder: (context, index) {
                final instruction = _currentRecipe.instructions[index];
                // Remove any existing number prefixes (like "1. ", "2) ", etc.)
                final cleanInstruction = instruction.replaceFirst(RegExp(r'^\d+[.)\s]*'), '').trim();
                
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  minVerticalPadding: 0,
                  leading: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    cleanInstruction,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      height: 1.5,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSauceTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '소스 & 양념',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (_currentRecipe.sauce != null && _currentRecipe.sauce!.isNotEmpty)
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: _currentRecipe.sauce!.split(',').length,
                separatorBuilder: (context, index) => const Divider(
                  color: AppTheme.dividerColor,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final sauceItem = _currentRecipe.sauce!.split(',')[index].trim();
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    minVerticalPadding: 0,
                    leading: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    title: Text(
                      sauceItem,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  );
                },
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 48,
                    color: AppTheme.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '소스 정보가 없습니다',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '소스나 양념 정보를 추가하려면 레시피를 수정해주세요',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _toggleFavorite() async {
    try {
      await context.read<RecipeProvider>().toggleFavorite(_currentRecipe.id);
      setState(() {
        _currentRecipe = _currentRecipe.copyWith(
          isFavorite: !_currentRecipe.isFavorite,
        );
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _currentRecipe.isFavorite
                  ? '즐겨찾기에 추가되었습니다'
                  : '즐겨찾기에서 제거되었습니다',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류 발생: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _onMenuSelected(String value) {
    switch (value) {
      case 'edit':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CreateScreen(
              editingRecipe: _currentRecipe,
              isEditMode: true, // 실제 레시피 편집 모드
            ),
          ),
        ).then((_) {
          // 편집 후 돌아왔을 때 업데이트된 데이터 반영
          if (mounted) {
            final provider = context.read<RecipeProvider>();
            final updatedRecipe = provider.recipes.firstWhere(
              (r) => r.id == _currentRecipe.id,
              orElse: () => _currentRecipe,
            );
            if (updatedRecipe != _currentRecipe) {
              setState(() {
                _currentRecipe = updatedRecipe;
              });
            }
          }
        });
        break;
      case 'delete':
        _showDeleteDialog();
        break;
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('레시피 삭제'),
        content: const Text(
          '정말로 이 레시피를 삭제하시겠습니까?\n'
          '삭제된 레시피는 복구할 수 없습니다.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await context.read<RecipeProvider>().deleteRecipe(_currentRecipe.id);
                if (mounted) {
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                  Navigator.of(context).pop(); // 상세보기 화면 닫기
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('레시피가 삭제되었습니다'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('삭제 중 오류 발생: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text(
              '삭제',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}