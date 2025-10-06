import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../config/constants.dart';
import '../models/mood.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../providers/recipe_provider.dart';
import '../widgets/common/required_badge.dart';

class CreateScreen extends StatefulWidget {
  final Recipe? editingRecipe; // 편집할 레시피 또는 미리 채워진 데이터
  final bool isEditMode; // 실제 편집 모드인지 여부

  // 새로운 프리필 기능 (기존 호환성 완전 유지)
  final String? prefilledTitle;           // AI 추천에서 받은 요리명
  final List<String>? prefilledIngredients; // 통합 재료 리스트
  final String? prefilledCookingMethod;   // AI 추천 조리법
  final String? dataSource;              // 데이터 출처 ('fridge_ingredients' 등)

  const CreateScreen({
    super.key,
    this.editingRecipe,
    this.isEditMode = false, // 기본값은 생성 모드
    // 새로운 매개변수들 (모두 optional)
    this.prefilledTitle,
    this.prefilledIngredients,
    this.prefilledCookingMethod,
    this.dataSource,
  });

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _emotionalStoryController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _sauceController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _tagsController = TextEditingController();
  final _sourceUrlController = TextEditingController();
  
  Mood _selectedMood = Mood.happy;
  int? _rating;
  bool _isSaving = false;
  String? _currentImagePath;
  
  bool get _isEditMode => widget.isEditMode;

  @override
  void initState() {
    super.initState();
    
    // 편집 모드 또는 미리 채워진 데이터가 있는 경우 폼 초기화
    if (widget.editingRecipe != null) {
      final recipe = widget.editingRecipe!;
      _titleController.text = recipe.title;
      _emotionalStoryController.text = recipe.emotionalStory;
      _selectedMood = recipe.mood;
      _rating = recipe.rating;
      
      // 재료를 문자열로 변환
      _ingredientsController.text = recipe.ingredients
          .map((ingredient) => '${ingredient.name}${ingredient.amount != null ? ' ${ingredient.amount}${ingredient.unit ?? ''}' : ''}')
          .join(', ');
      
      // 소스 설정
      _sauceController.text = recipe.sauce ?? '';
      
      // 조리법을 문자연로 변환
      _instructionsController.text = recipe.instructions
          .asMap()
          .entries
          .map((entry) => '${entry.key + 1}. ${entry.value}')
          .join('\n');
      
      // 태그를 문자열로 변환
      _tagsController.text = recipe.tags.join(' ');
      
      // 출처 URL 설정
      _sourceUrlController.text = recipe.sourceUrl ?? '';
    }
    // 새로운 프리필 데이터 처리 (기존 editingRecipe가 없을 때만)
    else if (widget.prefilledTitle != null ||
             widget.prefilledIngredients != null ||
             widget.prefilledCookingMethod != null) {

      // AI 추천에서 받은 요리명 프리필
      if (widget.prefilledTitle != null) {
        _titleController.text = widget.prefilledTitle!;
      }

      // 통합 재료 리스트 프리필
      if (widget.prefilledIngredients != null && widget.prefilledIngredients!.isNotEmpty) {
        _ingredientsController.text = widget.prefilledIngredients!.join(', ');
      }

      // AI 추천 조리법 프리필
      if (widget.prefilledCookingMethod != null) {
        _instructionsController.text = widget.prefilledCookingMethod!;
      }

      // 프리필 데이터 출처에 따른 추가 처리
      if (widget.dataSource == 'fridge_ingredients') {
        // 냉장고 재료 기반 추천의 경우 기본 태그 추가
        _tagsController.text = '#냉장고재료 #AI추천';
        // 기본 감정을 평온함으로 설정 (요리 추천받는 상황)
        _selectedMood = Mood.peaceful;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _emotionalStoryController.dispose();
    _ingredientsController.dispose();
    _sauceController.dispose();
    _instructionsController.dispose();
    _tagsController.dispose();
    _sourceUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveRecipe,
            child: _isSaving 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor,
                    ),
                  )
                : const Text(
                    '저장',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
          ),
          const SizedBox(width: AppTheme.spacing8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModeHeader(),
              const SizedBox(height: AppTheme.spacing24),
              _buildTitleField(),
              const SizedBox(height: AppTheme.spacing16),
              _buildEmotionalStoryField(),
              const SizedBox(height: AppTheme.spacing16),
              _buildMoodSelector(),
              const SizedBox(height: AppTheme.spacing16),
              _buildIngredientsField(),
              const SizedBox(height: AppTheme.spacing16),
              _buildSauceField(),
              const SizedBox(height: AppTheme.spacing16),
              _buildInstructionsField(),
              const SizedBox(height: AppTheme.spacing16),
              _buildTagsField(),
              const SizedBox(height: AppTheme.spacing16),
              _buildSourceUrlField(),
              const SizedBox(height: AppTheme.spacing16),
              _buildRatingField(),
              const SizedBox(height: AppTheme.spacing32),
            ],
          ),
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    if (_isEditMode) {
      return '레시피 수정';
    } else {
      return '레시피 작성';
    }
  }

  Widget _buildModeHeader() {
    IconData icon;
    String title;
    String subtitle;
    
    if (_isEditMode) {
      icon = Icons.edit;
      title = '레시피 수정';
      subtitle = '기존 레시피를 수정하고 저장하세요';
    } else {
      icon = Icons.restaurant_menu;
      title = '감정과 함께하는 레시피 작성';
      subtitle = '오늘의 요리 이야기를 감정과 함께 기록해보세요.';
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        boxShadow: AppTheme.vintageShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.paddingSmall),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            ),
            child: Icon(
              icon,
              color: AppTheme.textPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '레시피 제목',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: '예: 직장인 힐링 히야시츄카',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '레시피 제목을 입력해주세요';
            }
            if (value.trim().length > AppConstants.maxRecipeTitleLength) {
              return '레시피 제목이 너무 길어요';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEmotionalStoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LabelWithRequiredBadge(
          label: '감정 이야기',
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          AppConstants.emotionalStoryGuide,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        TextFormField(
          controller: _emotionalStoryController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: AppConstants.emotionalStoryExamples.first,
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '감정 이야기를 입력해주세요';
            }
            if (value.trim().length < AppConstants.minEmotionalStoryLength) {
              return '감정 이야기가 너무 짧아요';
            }
            if (value.trim().length > AppConstants.maxEmotionalStoryLength) {
              return '감정 이야기가 너무 길어요';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildMoodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '오늘 기분',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        Wrap(
          spacing: AppTheme.spacing8,
          runSpacing: AppTheme.spacing8,
          children: Mood.values.map((mood) {
            final isSelected = _selectedMood == mood;
            return GestureDetector(
              onTap: () => setState(() => _selectedMood = mood),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing12,
                  vertical: AppTheme.spacing8,
                ),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppTheme.primaryColor 
                      : AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  border: Border.all(
                    color: isSelected 
                        ? AppTheme.primaryColor 
                        : AppTheme.dividerColor,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      mood.icon,
                      size: 20,
                      color: isSelected 
                          ? Colors.white 
                          : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: AppTheme.spacing4),
                    Text(
                      mood.korean,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected 
                            ? Colors.white 
                            : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildIngredientsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '재료 (선택사항)',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        TextFormField(
          controller: _ingredientsController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '예: 중화면 1봉지, 오이 1/2개, 달걀 1개, 햄 50g',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '만드는 법 (선택사항)',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        TextFormField(
          controller: _instructionsController,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: '예:\n1. 면을 삶아 찬물에 헹군다\n2. 오이, 햄을 채 썬다\n3. 소스와 함께 비벼 완성',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '태그 (선택사항)',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        TextFormField(
          controller: _tagsController,
          decoration: const InputDecoration(
            hintText: '예: #직장인레시피 #여름별미 #셀프케어 #5분요리',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '평점',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Row(
          children: List.generate(5, (index) {
            final rating = index + 1;
            final isSelected = _rating != null && _rating! >= rating;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _rating = _rating == rating ? null : rating;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(right: AppTheme.spacing4),
                child: Icon(
                  isSelected ? Icons.star : Icons.star_border,
                  color: isSelected ? AppTheme.accentOrange : AppTheme.textTertiary,
                  size: 32,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSourceUrlField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '출처 URL (선택사항)',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: AppTheme.spacing8),
            Icon(
              Icons.link,
              size: 16,
              color: AppTheme.primaryColor,
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          '블로그나 웹사이트 등 레시피의 출처를 기록해두세요',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        TextFormField(
          controller: _sourceUrlController,
          decoration: const InputDecoration(
            hintText: '예: https://blog.naver.com/...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.link, color: AppTheme.primaryColor),
          ),
          validator: (value) {
            if (value != null && value.trim().isNotEmpty) {
              if (Uri.tryParse(value)?.hasScheme != true) {
                return '올바른 URL 형식이 아닙니다';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  void _saveRecipe() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final recipe = Recipe(
        id: _isEditMode ? widget.editingRecipe!.id : DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        emotionalStory: _emotionalStoryController.text.trim(),
        ingredients: _parseIngredients(_ingredientsController.text),
        sauce: _sauceController.text.trim().isEmpty ? null : _sauceController.text.trim(),
        instructions: _parseInstructions(_instructionsController.text),
        tags: _parseTags(_tagsController.text),
        createdAt: _isEditMode ? widget.editingRecipe!.createdAt : DateTime.now(),
        mood: _selectedMood,
        rating: _rating,
        isFavorite: _isEditMode ? widget.editingRecipe!.isFavorite : false,
        sourceUrl: _sourceUrlController.text.trim().isEmpty ? null : _sourceUrlController.text.trim(),
      );

      if (_isEditMode) {
        await context.read<RecipeProvider>().updateRecipe(recipe);
      } else {
        await context.read<RecipeProvider>().addRecipe(recipe);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? AppConstants.recipeUpdatedMessage : AppConstants.recipeSavedMessage),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_isEditMode ? '레시피 수정' : '레시피 저장'} 중 오류가 발생했습니다: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  List<Ingredient> _parseIngredients(String text) {
    if (text.trim().isEmpty) return [];
    
    return text.split(',').where((line) => line.trim().isNotEmpty).map((line) {
      final parts = line.trim().split(' ');
      if (parts.length >= 2) {
        final name = parts.first;
        final amountWithUnit = parts.skip(1).join(' ');
        return Ingredient(
          name: name,
          amount: amountWithUnit,
          unit: null,
          category: null,
        );
      } else {
        return Ingredient(
          name: line.trim(),
          amount: null,
          unit: null,
          category: null,
        );
      }
    }).toList();
  }

  List<String> _parseInstructions(String text) {
    if (text.trim().isEmpty) return [];
    
    return text.split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) => line.trim())
        .toList();
  }

  List<String> _parseTags(String text) {
    if (text.trim().isEmpty) return [];
    
    return text.split(' ')
        .where((tag) => tag.trim().isNotEmpty && tag.startsWith('#'))
        .map((tag) => tag.trim())
        .toList();
  }

  /// 조미료/소스 재료 키워드 목록
  static const List<String> _sauceKeywords = [
    '기름', '오일', '올리브오일', '참기름', '들기름', '식용유',
    '소금', '설탕', '간장', '된장', '고추장', '청국장',
    '고춧가루', '후춧가루', '후추', '겨자', '와사비',
    '식초', '발사믹', '레몬즙', '라임즙',
    '마늘', '생강', '양파가루', '마늘가루',
    '바질', '로즈마리', '타임', '오레가노', '파슬리',
    '계피', '정향', '넛멕', '커민', '파프리카',
    '케첩', '마요네즈', '머스타드', '타바스코', '굴소스',
    '미림', '청주', '요리술', '맛술',
    '닭육수', '멸치육수', '다시마육수', '소스', '양념',
    '허브', '향신료', '조미료', '드레싱'
  ];

  /// 재료에서 조미료/소스 재료를 자동으로 분리하는 기능
  void _separateIngredientsToSauce() {
    final ingredientsText = _ingredientsController.text.trim();
    if (ingredientsText.isEmpty) return;

    // 재료 파싱 (콤마로 분리)
    final allIngredients = ingredientsText
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final List<String> mainIngredients = [];
    final List<String> sauceIngredients = [];

    // 각 재료를 조미료/소스인지 확인
    for (final ingredient in allIngredients) {
      if (_isSauceIngredient(ingredient)) {
        sauceIngredients.add(ingredient);
      } else {
        mainIngredients.add(ingredient);
      }
    }

    // 분리된 재료가 있는 경우에만 업데이트
    if (sauceIngredients.isNotEmpty) {
      // 메인 재료 업데이트
      _ingredientsController.text = mainIngredients.join(', ');
      
      // 소스 재료 추가 (기존 소스에 추가)
      final existingSauce = _sauceController.text.trim();
      final newSauceText = existingSauce.isEmpty 
          ? sauceIngredients.join(', ')
          : '$existingSauce, ${sauceIngredients.join(', ')}';
      _sauceController.text = newSauceText;

      // 사용자에게 피드백
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${sauceIngredients.length}개의 조미료/소스 재료를 분리했습니다'),
          backgroundColor: AppTheme.successColor,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // 분리할 재료가 없는 경우
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('분리할 조미료/소스 재료가 없습니다'),
          backgroundColor: AppTheme.primaryColor,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// 특정 재료가 조미료/소스인지 판단
  bool _isSauceIngredient(String ingredient) {
    final ingredientLower = ingredient.toLowerCase().replaceAll(' ', '');
    
    // 키워드 매칭
    for (final keyword in _sauceKeywords) {
      if (ingredientLower.contains(keyword.toLowerCase())) {
        return true;
      }
    }
    
    // 추가적인 패턴 매칭
    if (ingredient.contains('소스') || 
        ingredient.contains('양념') || 
        ingredient.contains('드레싱') ||
        ingredient.contains('액젓') ||
        ingredient.contains('젓갈')) {
      return true;
    }
    
    return false;
  }

  Widget _buildSauceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '소스 비율 (선택사항)',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _separateIngredientsToSauce,
              icon: const Icon(
                Icons.auto_awesome,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              label: const Text(
                '재료에서 분리',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryColor,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing8),
        TextFormField(
          controller: _sauceController,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: '예: 간장 2큰술, 설탕 1큰술, 참기름 1작은술, 마늘 1쪽',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

}