import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../providers/recipe_provider.dart';
import '../models/recipe.dart';
import '../models/mood.dart';
import '../widgets/recipe/recipe_card.dart';
import 'detail_screen.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> 
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  
  // 🔥 ULTRA FIX: 바텀시트 검색 기능을 위한 상태 변수들
  late DraggableScrollableController _bottomSheetController;
  final _searchController = TextEditingController();
  List<Recipe> _searchResults = [];
  String _currentQuery = '';
  Mood? _selectedMood;
  String? _selectedHashtag;
  String? _selectedTag; // 선택된 태그 추적
  bool _isInSearchMode = false; // 검색 모드 여부
  bool _isBottomSheetVisible = false; // 바텀시트 표시 여부
  bool _isSearching = false; // 로딩 상태
  final double _bottomSheetSize = 0.75; // 바텀시트 기본 크기 (더 크게)
  
  // 실제 레시피에서 추출한 추천 태그들
  List<String> _getRecommendedTags() {
    final provider = context.read<RecipeProvider>();
    final allRecipes = provider.recipes;
    
    // 모든 레시피의 태그 수집
    Map<String, int> tagCounts = {};
    for (var recipe in allRecipes) {
      for (var tag in recipe.tags) {
        String cleanTag = tag.startsWith('#') ? tag.substring(1) : tag;
        tagCounts[cleanTag] = (tagCounts[cleanTag] ?? 0) + 1;
      }
    }
    
    // 사용 빈도순으로 정렬하여 상위 10개 반환
    var sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // 기본 추천 태그 (레시피가 없을 때)
    final defaultTags = [
      '혼밥', '가족시간', '간편식', '건강식', '야식',
      '국물요리', '디저트', '기념일', '도시락', '브런치',
      '기쁨', '평온', '슬픔', '피로', '설렘', '그리움', '편안함', '감사'
    ];
    
    if (sortedTags.isEmpty) {
      return defaultTags.take(10).toList();
    }
    
    // 실제 사용된 태그 상위 10개 + 기본 태그 조합
    List<String> recommendedTags = sortedTags
        .take(10)
        .map((e) => e.key)
        .toList();
    
    // 기본 태그 중 누락된 것들 추가 (최대 10개까지)
    for (String defaultTag in defaultTags) {
      if (!recommendedTags.contains(defaultTag) && recommendedTags.length < 10) {
        recommendedTags.add(defaultTag);
      }
    }
    
    return recommendedTags;
  }
  
  @override
  bool get wantKeepAlive => true; // 🔥 ULTRA FIX: 탭 전환시 상태 유지

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _bottomSheetController = DraggableScrollableController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bottomSheetController.dispose(); // 🔥 ULTRA FIX: 바텀시트 컨트롤러 dispose
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // 메인 컨텐츠: 헤더 + 탭바 + 탭뷰 (항상 표시)
            Consumer<RecipeProvider>(
              builder: (context, provider, child) {
                return Column(
                  children: [
                    // 🔥 ULTRA FIX: 보관함 헤더 영역 추가 (상태바 충돌 방지)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      color: AppTheme.backgroundColor,
                      child: Row(
                        children: [
                          const Text(
                            '보관함',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          // 검색 아이콘 (X 버튼 제거, 검색 아이콘만)
                          IconButton(
                            icon: const Icon(
                              Icons.search,
                              color: AppTheme.primaryColor,
                              size: 24,
                            ),
                            onPressed: () {
                              setState(() {
                                _isBottomSheetVisible = true; // 항상 열기만
                              });
                            },
                            tooltip: _isBottomSheetVisible ? '검색 닫기' : '검색',
                          ),
                          // 알림 아이콘 (다른 화면들과 동일)
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_none,
                              color: AppTheme.primaryColor,
                              size: 24,
                            ),
                            onPressed: () {
                              // 알림 기능 (추후 구현)
                            },
                            tooltip: '알림',
                          ),
                        ],
                      ),
                    ),
                    // 탭바 영역
                    Container(
                      color: AppTheme.backgroundColor,
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: AppTheme.primaryColor,
                        labelColor: AppTheme.primaryColor,
                        unselectedLabelColor: AppTheme.textSecondary,
                        tabs: const [
                          Tab(text: '전체'),
                          Tab(text: '즐겨찾기'),
                          Tab(text: '최근'),
                        ],
                      ),
                    ),
                  // 탭바 뷰
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAllRecipes(provider.recipes),
                        _buildFavoriteRecipes(provider.recipes.where((r) => r.isFavorite).toList()),
                        _buildRecentRecipes(provider.recentRecipes),
                      ],
                    ),
                  ),
                ],
              );
            },
            ),
            
            // 바텀시트 검색 UI
            if (_isBottomSheetVisible) _buildBottomSheetSearch(),
          ],
        ),
      ),
    );
  }

  Widget _buildAllRecipes(List<Recipe> recipes) {
    if (recipes.isEmpty) {
      return _buildEmptyState('아직 레시피가 없어요', '지금 첫 레시피를 만들어 보세요!');
    }

    return RecipeCardList(
      recipes: recipes,
      onRecipeTap: _navigateToDetail,
      showFavoriteButton: true,
      onFavoriteToggle: _toggleFavorite,
    );
  }

  Widget _buildFavoriteRecipes(List<Recipe> recipes) {
    if (recipes.isEmpty) {
      return _buildEmptyState('아직 즐겨찾기가 없어요', '좋아하는 레시피를 추가해 보세요');
    }

    return RecipeCardList(
      recipes: recipes,
      onRecipeTap: _navigateToDetail,
      showFavoriteButton: true,
      onFavoriteToggle: _toggleFavorite,
    );
  }

  Widget _buildRecentRecipes(List<Recipe> recipes) {
    if (recipes.isEmpty) {
      return _buildEmptyState('아직 최근 레시피가 없어요', '최근에 만든 레시피가 여기에 표시돼요');
    }

    return RecipeCardList(
      recipes: recipes,
      onRecipeTap: _navigateToDetail,
      showFavoriteButton: true,
      onFavoriteToggle: _toggleFavorite,
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: AppTheme.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
      
      // 🔥 ULTRA FIX: 검색 모드일 때 검색 결과도 업데이트
      if (_isInSearchMode) {
        setState(() {
          final index = _searchResults.indexWhere((r) => r.id == recipe.id);
          if (index != -1) {
            _searchResults[index] = updatedRecipe;
          }
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(updatedRecipe.isFavorite 
                ? 'Added to favorites' 
                : 'Removed from favorites'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
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
  
  // 🔥 ULTRA FIX: SearchScreen 기능들 통합





  void _performSearch() {
    final provider = context.read<RecipeProvider>();
    
    setState(() {
      _isSearching = true;
      _isInSearchMode = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        List<Recipe> results;
        
        // 선택된 태그가 있으면 태그 기반 검색
        if (_selectedTag != null) {
          results = provider.recipes.where((recipe) {
            return recipe.tags.any((tag) {
              String cleanTag = tag.startsWith('#') ? tag.substring(1) : tag;
              return cleanTag.toLowerCase().contains(_selectedTag!.toLowerCase());
            });
          }).toList();
        } else {
          // 일반 텍스트 검색
          results = provider.searchRecipes(_currentQuery, mood: _selectedMood);
        }
        
        // 추가 해시태그 필터링
        if (_selectedHashtag != null) {
          results = results.where((recipe) => recipe.matchesTag(_selectedHashtag!)).toList();
        }
        
        setState(() {
          _searchResults = results;
          _isSearching = false;
          _isInSearchMode = _currentQuery.isNotEmpty || _selectedMood != null || _selectedHashtag != null || _selectedTag != null;
        });
      }
    });
  }


  // 바텀시트 검색 위젯 생성
  Widget _buildBottomSheetSearch() {
    return DraggableScrollableSheet(
      controller: _bottomSheetController,
      initialChildSize: _bottomSheetSize,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // 드래그 핸들
              Container(
                margin: EdgeInsets.symmetric(vertical: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 검색 헤더 (X 버튼 포함)
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '레시피 검색',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isBottomSheetVisible = false;
                          _isInSearchMode = false;
                          _searchController.clear();
                          _currentQuery = '';
                          _selectedMood = null;
                          _selectedHashtag = null;
                          _selectedTag = null; // 선택된 태그도 초기화
                          _searchResults.clear();
                          _isSearching = false;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 검색 입력 필드
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '마음이 향하는 레시피를 찾아보세요',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (query) {
                    _currentQuery = query;
                    _performSearch();
                  },
                ),
              ),
              // 태그 추천 (항상 표시)
              ...[
                SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '추천 태그',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _getRecommendedTags().map((tag) {
                      return GestureDetector(
                        onTap: () {
                          if (_selectedTag == tag) {
                            // 이미 선택된 태그를 다시 누르면 해제
                            setState(() {
                              _selectedTag = null;
                              _searchController.clear();
                              _currentQuery = '';
                              _isInSearchMode = false;
                              _searchResults.clear();
                            });
                          } else {
                            // 새로운 태그 선택
                            setState(() {
                              _selectedTag = tag;
                              _searchController.text = tag;
                              _currentQuery = tag;
                            });
                            _performSearch();
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _selectedTag == tag 
                                ? AppTheme.primaryColor 
                                : AppTheme.primaryLight.withValues(alpha: 77),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedTag == tag 
                                  ? AppTheme.primaryColor 
                                  : AppTheme.primaryColor.withValues(alpha: 77),
                              width: _selectedTag == tag ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 14,
                              color: _selectedTag == tag 
                                  ? Colors.white 
                                  : AppTheme.textPrimary,
                              fontWeight: _selectedTag == tag 
                                  ? FontWeight.w600 
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              SizedBox(height: 16),
              // 검색 결과 또는 상태 메시지
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: _isInSearchMode 
                    ? (_isSearching
                        ? Container(
                            height: 200,
                            child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: AppTheme.primaryColor,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  '검색 중...',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ))
                        : (_searchResults.isNotEmpty
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 검색 결과 개수 표시
                                  Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Text(
                                          '검색 결과 ${_searchResults.length}개',
                                          style: TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (_selectedTag != null) ...[
                                          SizedBox(width: 8),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '#$_selectedTag',
                                              style: TextStyle(
                                                color: AppTheme.primaryColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  // 검색 결과 리스트
                                  ...List.generate(_searchResults.length, (index) {
                                    final recipe = _searchResults[index];
                                    return Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                                  SizedBox(height: 80), // 바텀 여백
                                ],
                              )
                            : Container(
                                height: 200,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 60,
                                        color: AppTheme.textTertiary.withValues(alpha: 0.5),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        '검색 결과가 없습니다',
                                        style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '다른 검색어를 입력하거나 태그를 눌러보세요',
                                        style: TextStyle(
                                          color: AppTheme.textTertiary,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                        )
                    )
                    : SizedBox(height: 100), // 검색 모드가 아닐 때 여백
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}