import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/recipe_provider.dart';
import '../models/recipe.dart';
import '../models/mood.dart';
import '../widgets/recipe/recipe_card.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<Recipe> _searchResults = [];
  String _currentQuery = '';
  Mood? _selectedMood;
  String? _selectedHashtag;
  bool _isSearching = false;
  
  // 자주 찾는 레시피 해시태그 (실제로는 분석을 통해 동적 생성 가능)
  final List<String> _frequentlySearchedTags = [
    '#혼밥', '#가족시간', '#간편식', '#건강식', '#야식',
    '#국물요리', '#디저트', '#기념일', '#도시락', '#브런치'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      // 🔥 ULTRA FIX: SearchScreen에서 AppBar 제거 (MainScreen AppBar 사용)
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: AppConstants.searchHintText,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                    )
                  : null,
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: AppTheme.spacing12),
          _buildMoodFilters(),
          const SizedBox(height: AppTheme.spacing16),
          _buildHashtagFilters(),
        ],
      ),
    );
  }

  Widget _buildMoodFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildMoodFilterChip(null, 'All'),
          ...Mood.values.map((mood) => _buildMoodFilterChip(mood, mood.korean)),
        ],
      ),
    );
  }

  Widget _buildMoodFilterChip(Mood? mood, String label) {
    final isSelected = _selectedMood == mood;
    return Padding(
      padding: const EdgeInsets.only(right: AppTheme.spacing8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mood != null) ...[
              Icon(
                mood.icon,
                size: 16,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedMood = selected ? mood : null;
          });
          _performSearch();
        },
        selectedColor: AppTheme.primaryColor.withValues(alpha: 77),
        checkmarkColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildHashtagFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.tag,
              size: 20,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: AppTheme.spacing8),
            Text(
              '자주 찾은 레시피',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing12),
        Wrap(
          spacing: AppTheme.spacing8,
          runSpacing: AppTheme.spacing8,
          children: _frequentlySearchedTags.map((hashtag) => 
            _buildHashtagButton(hashtag)
          ).toList(),
        ),
      ],
    );
  }

  Widget _buildHashtagButton(String hashtag) {
    final isSelected = _selectedHashtag == hashtag;
    return GestureDetector(
      onTap: () => _onHashtagSelected(hashtag),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.accentOrange
              : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          border: Border.all(
            color: isSelected 
                ? AppTheme.accentOrange
                : AppTheme.dividerColor,
            width: 1,
          ),
          boxShadow: isSelected 
              ? [
                  BoxShadow(
                    color: AppTheme.accentOrange.withValues(alpha: 77),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          hashtag,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected 
                ? Colors.white
                : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_currentQuery.isEmpty && _selectedMood == null && _selectedHashtag == null) {
      return _buildInitialState();
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyResults();
    }

    return RecipeCardList(
      recipes: _searchResults,
      onRecipeTap: _navigateToDetail,
      showFavoriteButton: true,
      onFavoriteToggle: _toggleFavorite,
    );
  }

  Widget _buildInitialState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: AppTheme.textTertiary,
          ),
          SizedBox(height: AppTheme.spacing16),
          Text(
            'Search by recipe name,\nfeeling, or tags',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              AppConstants.emptySearchMessage.replaceAll('\\n', '\n'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSearchChanged(String query) {
    setState(() {
      _currentQuery = query;
    });
    _performSearch();
  }

  void _performSearch() {
    final provider = context.read<RecipeProvider>();
    
    setState(() {
      _isSearching = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        List<Recipe> results = provider.searchRecipes(_currentQuery, mood: _selectedMood);
        
        // 해시태그 필터링 추가
        if (_selectedHashtag != null) {
          results = results.where((recipe) => recipe.matchesTag(_selectedHashtag!)).toList();
        }
        
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _onHashtagSelected(String hashtag) {
    setState(() {
      if (_selectedHashtag == hashtag) {
        _selectedHashtag = null; // 이미 선택된 해시태그를 다시 클릭하면 해제
      } else {
        _selectedHashtag = hashtag;
      }
    });
    _performSearch();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _currentQuery = '';
      _selectedMood = null;
      _selectedHashtag = null;
      _searchResults = [];
    });
  }

  void _navigateToDetail(Recipe recipe) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetailScreen(recipe: recipe),
      ),
    );
  }

  void _toggleFavorite(Recipe recipe) async {
    final provider = context.read<RecipeProvider>();
    final updatedRecipe = recipe.copyWith(isFavorite: !recipe.isFavorite);
    
    try {
      await provider.updateRecipe(updatedRecipe);
      
      setState(() {
        final index = _searchResults.indexWhere((r) => r.id == recipe.id);
        if (index != -1) {
          _searchResults[index] = updatedRecipe;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Favorite error occurred: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}