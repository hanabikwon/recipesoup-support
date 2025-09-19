import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/mood.dart';
import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../services/openai_service.dart';
import '../utils/date_utils.dart';
import 'create_screen.dart';

class DetailScreen extends StatefulWidget {
  final Recipe recipe;
  final bool fromIngredientRecommendation;
  final List<String>? originalIngredients;
  final bool isTemporaryRecipe; // AI 생성된 임시 레시피 여부

  const DetailScreen({
    super.key,
    required this.recipe,
    this.fromIngredientRecommendation = false,
    this.originalIngredients,
    this.isTemporaryRecipe = false, // 기본값은 실제 저장된 레시피
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late Recipe _currentRecipe;
  bool _isSaved = false; // 저장 상태 추적
  bool _isSaving = false; // 저장 중 상태

  @override
  void initState() {
    super.initState();
    _currentRecipe = widget.recipe;
    _isSaved = !widget.isTemporaryRecipe; // 임시 레시피가 아니면 이미 저장된 것
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
            // "저장하기" 버튼 (AI 생성 임시 레시피인 경우)
            if (widget.isTemporaryRecipe && !_isSaved) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveRecipe,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.bookmark_add, size: 18),
                  label: Text(_isSaving ? '저장 중...' : '레시피 보관하기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
            // "다른 레시피 추천" 버튼 (재료 추천에서 온 경우에만 표시)
            if (widget.fromIngredientRecommendation && widget.originalIngredients != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _requestAnotherRecipe,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('다른 레시피 추천해줘요'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
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
    // 임시 레시피(저장되지 않은)의 경우 즐겨찾기 불가
    if (widget.isTemporaryRecipe && !_isSaved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('레시피를 먼저 저장한 후 즐겨찾기를 설정할 수 있습니다'),
          backgroundColor: AppTheme.warningColor,
          // action 제거 (이미 화면에 저장 버튼이 있음)
        ),
      );
      return;
    }

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
            content: Text('즐겨찾기 설정 중 오류 발생: $e'),
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

  void _requestAnotherRecipe() async {
    if (widget.originalIngredients == null || widget.originalIngredients!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('원본 재료 정보가 없어 다른 레시피를 추천할 수 없습니다'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryColor),
            SizedBox(height: 16),
            Text('다른 레시피를 찾고 있습니다...'),
          ],
        ),
      ),
    );

    try {
      final openAiService = context.read<OpenAiService>();

      // 🔥 ULTRA CREATIVE FIX: 완전히 다른 요리 메뉴 추천을 위한 창의적 컨텍스트
      final baseIngredients = [...widget.originalIngredients!];

      // 현재 레시피 제목을 기반으로 다른 카테고리 유도
      final currentTitle = _currentRecipe.title.toLowerCase();

      // 🎯 완전히 다른 요리 카테고리로 유도하는 강력한 프롬프트 생성
      final creativeCookingStyles = [
        // 서양식 요리 카테고리
        '이탈리아 정통 파스타나 리조또로 만들어주세요',
        '프랑스식 타르트나 키쉬 요리로 만들어주세요',
        '지중해식 브루스케타나 크로스티니로 만들어주세요',
        '미국식 팬케이크나 와플 요리로 만들어주세요',

        // 아시아 퓨전 요리
        '일본식 오니기리나 덮밥 요리로 만들어주세요',
        '한국식 전이나 부침개 요리로 만들어주세요',
        '중국식 딤섬이나 만두 요리로 만들어주세요',
        '동남아시아식 쌈이나 롤 요리로 만들어주세요',

        // 베이킹 & 디저트
        '베이킹한 머핀이나 스콘으로 만들어주세요',
        '달콤한 디저트나 케이크로 만들어주세요',
        '아이스크림이나 셔벗 디저트로 만들어주세요',

        // 창의적 퓨전 요리
        '창의적인 퓨전 요리로 색다르게 만들어주세요',
        '길거리 음식 스타일로 간편하게 만들어주세요',
        '고급 레스토랑 스타일의 정찬 요리로 만들어주세요',
        '브런치 스타일의 특별한 요리로 만들어주세요',
        '스낵이나 핑거푸드 스타일로 만들어주세요'
      ];

      // 현재 시간 기반으로 완전히 다른 카테고리 선택
      final randomIndex = DateTime.now().millisecondsSinceEpoch % creativeCookingStyles.length;
      final selectedCookingStyle = creativeCookingStyles[randomIndex];

      // 🎨 현재 레시피와 반대되는 스타일 유도 (더 강력한 차별화)
      String additionalContext = '';
      if (currentTitle.contains('샐러드') || currentTitle.contains('salad')) {
        additionalContext = '샐러드가 아닌 완전히 다른 조리 방식으로';
      } else if (currentTitle.contains('파스타') || currentTitle.contains('pasta')) {
        additionalContext = '파스타가 아닌 전혀 다른 형태의 요리로';
      } else if (currentTitle.contains('리조또') || currentTitle.contains('risotto')) {
        additionalContext = '리조또가 아닌 색다른 방식으로';
      } else if (currentTitle.contains('수프') || currentTitle.contains('soup')) {
        additionalContext = '수프가 아닌 고체 형태의 요리로';
      } else {
        additionalContext = '이전과 완전히 다른 조리법과 형태로';
      }

      // 최종 창의적 재료 리스트 구성
      final enhancedIngredients = [
        ...baseIngredients,
        selectedCookingStyle,
        additionalContext,
        '기존 레시피와는 전혀 다른 새로운 요리를 만들어주세요'
      ];

      final analysis = await openAiService.analyzeIngredientsForRecipe(
        enhancedIngredients,
      );

      if (mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기

        // 🎨 새로운 요리에 어울리는 다양한 감정 선택
        final creativeeMoodOptions = [
          Mood.excited,    // 설렘 - 새로운 도전
          Mood.comfortable, // 편안함 - 익숙한 재료, 새로운 방식
          Mood.happy,      // 기쁨 - 창의적 발견
          Mood.grateful,   // 감사 - 새로운 레시피에 대한 감사
          Mood.peaceful,   // 평온 - 요리하는 즐거움
        ];
        final selectedMood = creativeeMoodOptions[DateTime.now().microsecond % creativeeMoodOptions.length];

        // 🎭 완전히 새로운 요리에 맞는 창의적 감정 메시지
        final creativeStoryOptions = [
          '와! 같은 재료로 이렇게 색다른 요리가 가능하다니 신기해요!',
          '완전히 새로운 요리 스타일에 도전해보는 설렘이 느껴져요.',
          '이런 창의적인 조리법을 시도해보니 요리가 더 재미있어집니다!',
          '전혀 생각지 못했던 요리 방식이네요. 새로운 맛의 세계가 열릴 것 같아요!',
          '평범한 재료로 이렇게 특별한 요리를 만들 수 있다니 감동이에요.',
          '오늘은 완전히 새로운 요리에 도전하는 모험을 떠나봅시다!',
          '같은 재료, 전혀 다른 요리! 이런 변신이 가능하다니 놀라워요.',
          '창의적인 요리법으로 새로운 맛의 경험을 만들어보려 해요.'
        ];
        final selectedStory = creativeStoryOptions[DateTime.now().microsecond % creativeStoryOptions.length];

        final newRecipe = analysis.toRecipe(
          emotionalStory: selectedStory,
          mood: selectedMood,
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => DetailScreen(
              recipe: newRecipe,
              fromIngredientRecommendation: true,
              originalIngredients: widget.originalIngredients,
              isTemporaryRecipe: true, // 새 AI 레시피는 임시 레시피
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('다른 레시피 추천에 실패했습니다: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // 🔥 NEW: 레시피 저장 기능 구현
  void _saveRecipe() async {
    if (_isSaving) return; // 중복 클릭 방지

    setState(() {
      _isSaving = true;
    });

    try {
      // 현재 시간으로 ID 업데이트 (고유성 보장)
      final savedRecipe = _currentRecipe.copyWith(
        id: 'recipe_${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
      );

      await context.read<RecipeProvider>().addRecipe(savedRecipe);

      setState(() {
        _currentRecipe = savedRecipe;
        _isSaved = true;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('레시피가 성공적으로 저장되었습니다!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('레시피 저장에 실패했습니다: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
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
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              
              try {
                await context.read<RecipeProvider>().deleteRecipe(_currentRecipe.id);
                if (mounted) {
                  navigator.pop(); // 다이얼로그 닫기
                  navigator.pop(); // 상세보기 화면 닫기
                  
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('레시피가 삭제되었습니다'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  navigator.pop();
                  scaffoldMessenger.showSnackBar(
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