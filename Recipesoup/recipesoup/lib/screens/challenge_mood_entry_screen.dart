import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../providers/challenge_provider.dart';
import '../models/challenge_models.dart';
import 'challenge_detail_screen.dart';

/// 감정 기반 챌린지 진입 화면
/// 사용자의 현재 감정을 선택하고 맞춤형 챌린지를 추천하는 화면
class ChallengeMoodEntryScreen extends StatefulWidget {
  const ChallengeMoodEntryScreen({super.key});

  @override
  State<ChallengeMoodEntryScreen> createState() => _ChallengeMoodEntryScreenState();
}

class _ChallengeMoodEntryScreenState extends State<ChallengeMoodEntryScreen>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  String? _selectedMood;
  List<Challenge> _recommendedChallenges = [];
  bool _showRecommendations = false;
  bool _isLoadingRecommendations = false;

  // 감정 선택지들
  final List<MoodOption> _moodOptions = [
    MoodOption(
      id: 'happy',
      icon: Icons.sentiment_very_satisfied,
      title: '기쁘고 행복해요',
      subtitle: '기분 좋은 날\n즐겁게 요리할래요',
      color: Color(0xFFFFD700),
      tags: ['#축하', '#파티', '#특별한날', '#달달함'],
    ),
    MoodOption(
      id: 'calm',
      icon: Icons.self_improvement,
      title: '평온하고 차분해요',
      subtitle: '조용히 마음을\n정리하는 시간이 필요해요',
      color: Color(0xFF87CEEB),
      tags: ['#혼밥', '#명상', '#차분함', '#단순함'],
    ),
    MoodOption(
      id: 'energetic',
      icon: Icons.flash_on,
      title: '활기차고 신나요',
      subtitle: '새로운 요리에\n도전 해보고 싶어요',
      color: Color(0xFFFF6347),
      tags: ['#도전', '#복잡한요리', '#새로운맛', '#활력'],
    ),
    MoodOption(
      id: 'nostalgic',
      icon: Icons.favorite,
      title: '그리움이 느껴져요',
      subtitle: '추억의 맛을\n다시 느끼고 싶어요',
      color: Color(0xFFDDA0DD),
      tags: ['#엄마음식', '#추억', '#집밥', '#따뜻함'],
    ),
    MoodOption(
      id: 'tired',
      icon: Icons.bedtime,
      title: '피곤하고 지쳐요',
      subtitle: '간단하면서도\n든든한 음식이 필요해요',
      color: Color(0xFF708090),
      tags: ['#간편식', '#든든함', '#회복', '#영양'],
    ),
    MoodOption(
      id: 'adventurous',
      icon: Icons.star,
      title: '모험하고 싶어요',
      subtitle: '새로운 세계의\n낯선 맛을 경험하고 싶어요',
      color: Color(0xFF20B2AA),
      tags: ['#세계요리', '#이국적', '#탐험', '#새로운경험'],
    ),
    MoodOption(
      id: 'cozy',
      icon: Icons.home,
      title: '아늑하고 포근해요',
      subtitle: '편안하고 따뜻하게\n홈쿠킹을 하고 싶어요',
      color: Color(0xFFD2691E),
      tags: ['#집밥', '#따뜻함', '#포근함', '#가족'],
    ),
    MoodOption(
      id: 'healthy',
      icon: Icons.eco,
      title: '건강해지고 싶어요',
      subtitle: '몸에 좋은 음식으로\n나를 돌보고 싶어요',
      color: Color(0xFF32CD32),
      tags: ['#건강식', '#영양', '#자기관리', '#웰빙'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: _buildContent(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoadingRecommendations) {
      return _buildLoadingScreen();
    } else if (_showRecommendations) {
      return _buildRecommendations();
    } else {
      return _buildMoodSelection();
    }
  }

  /// 로딩 화면
  Widget _buildLoadingScreen() {
    final selectedMoodOption = _selectedMood != null 
        ? _moodOptions.firstWhere((mood) => mood.id == _selectedMood)
        : null;
    
    if (selectedMoodOption == null) return Container();
    
    return Stack(
      children: [
        // 뒤로가기 버튼
        Positioned(
          top: 60,
          left: 20,
          child: IconButton(
            onPressed: () {
              setState(() {
                _isLoadingRecommendations = false;
                _selectedMood = null;
                _showRecommendations = false;
              });
            },
            icon: Icon(
              Icons.arrow_back_ios,
              color: AppTheme.textPrimary,
              size: 20,
            ),
          ),
        ),
        
        // 중앙 콘텐츠
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 선택된 감정 표시
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: selectedMoodOption.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selectedMoodOption.color.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  selectedMoodOption.icon,
                  size: 64,
                  color: selectedMoodOption.color,
                ),
              ),
              
              SizedBox(height: 32),
              
              Text(
                '${selectedMoodOption.title} ',
                style: TextStyle(
                  fontSize: 18,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 8),
              
              Text(
                '맞춤 챌린지를 찾고 있어요',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: selectedMoodOption.color,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 40),
              
              // 로딩 애니메이션
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(selectedMoodOption.color),
                strokeWidth: 3,
              ),
              
              SizedBox(height: 24),
              
              Text(
                '잠시만 기다려주세요...',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 감정 선택 화면
  Widget _buildMoodSelection() {
    return CustomScrollView(
      slivers: [
        _buildHeader(),
        _buildMoodGrid(),
        _buildFooter(),
      ],
    );
  }

  /// 헤더
  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: AppTheme.textPrimary,
                    size: 20,
                  ),
                ),
                Spacer(),
              ],
            ),
            SizedBox(height: 40),
            Text(
              '지금 기분이 어떠세요?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              '당신의 마음 상태에 맞는\n요리 챌린지를 찾아드릴게요',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 감정 선택 그리드
  Widget _buildMoodGrid() {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final mood = _moodOptions[index];
            return _buildMoodCard(mood);
          },
          childCount: _moodOptions.length,
        ),
      ),
    );
  }

  /// 감정 카드
  Widget _buildMoodCard(MoodOption mood) {
    final isSelected = _selectedMood == mood.id;
    
    return InkWell(
      onTap: () => _selectMood(mood),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? mood.color.withValues(alpha: 0.2)
              : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? mood.color
                : AppTheme.primaryLight.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected 
              ? [
                  BoxShadow(
                    color: mood.color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ]
              : AppTheme.vintageShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              mood.icon,
              size: 48,
              color: mood.color,
            ),
            SizedBox(height: 16),
            Text(
              mood.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected 
                    ? mood.color 
                    : AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              mood.subtitle,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// 하단 안내 메시지
  Widget _buildFooter() {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lightbulb,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '감정을 선택하면 바로 맞춤 챌린지를 찾아드려요!',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  /// 추천 결과 화면
  Widget _buildRecommendations() {
    final selectedMoodOption = _moodOptions.firstWhere(
      (mood) => mood.id == _selectedMood,
    );

    return CustomScrollView(
      slivers: [
        _buildRecommendationHeader(selectedMoodOption),
        _buildRecommendationList(),
        _buildRecommendationFooter(),
      ],
    );
  }

  /// 추천 헤더
  Widget _buildRecommendationHeader(MoodOption mood) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showRecommendations = false;
                      _selectedMood = null;
                    });
                  },
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: AppTheme.textPrimary,
                    size: 20,
                  ),
                ),
                Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    '완료',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: mood.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: mood.color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    mood.icon,
                    size: 48,
                    color: mood.color,
                  ),
                  SizedBox(height: 12),
                  Text(
                    '"${mood.title}"',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '챌린지를 찾았어요!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: mood.color,
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

  /// 추천 리스트
  Widget _buildRecommendationList() {
    // 빈 리스트일 때를 위한 fallback UI
    if (_recommendedChallenges.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          padding: EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(
                Icons.search_off,
                size: 60,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16),
              Text(
                '선택한 감정과 맞는 챌린지가 없습니다',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                '다른 감정을 선택하거나\n나중에 다시 시도해보세요',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final challenge = _recommendedChallenges[index];
            return _buildRecommendationCard(challenge, index);
          },
          childCount: _recommendedChallenges.length,
        ),
      ),
    );
  }

  /// 추천 카드
  Widget _buildRecommendationCard(Challenge challenge, int index) {
    final provider = Provider.of<ChallengeProvider>(context);
    final progress = provider.getProgressById(challenge.id);
    final isCompleted = progress?.isCompleted ?? false;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChallengeDetailScreen(challenge: challenge),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowColor.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
              BoxShadow(
                color: AppTheme.shadowColor.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
            border: isCompleted 
                ? Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.5), width: 2)
                : Border.all(color: AppTheme.dividerColor.withValues(alpha: 0.6), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(challenge.category).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getCategoryIcon(challenge.category),
                      color: _getCategoryColor(challenge.category),
                      size: 20,
                    ),
                  ),
                  Spacer(),
                  if (isCompleted)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            '완료',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                challenge.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                challenge.description,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Row(
                    children: List.generate(
                      3,
                      (index) => Icon(
                        Icons.star,
                        size: 16,
                        color: index < challenge.difficulty 
                            ? AppTheme.primaryColor 
                            : AppTheme.primaryLight.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.access_time, size: 14, color: AppTheme.textSecondary),
                  SizedBox(width: 4),
                  Text(
                    '${challenge.estimatedMinutes}분',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.restaurant, size: 14, color: AppTheme.textSecondary),
                  SizedBox(width: 4),
                  Text(
                    challenge.servings,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Spacer(),
                  // 포인트 시스템이 제거됨
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 추천 하단
  Widget _buildRecommendationFooter() {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lightbulb,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '팁: 감정은 언제든 바뀔 수 있어요',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              '다른 기분이 들면 언제든 다시 선택해보세요!',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  /// 감정 선택 처리 - 즉시 추천 실행
  void _selectMood(MoodOption mood) {
    setState(() {
      _selectedMood = mood.id;
    });
    
    // 감정 선택 즉시 추천 챌린지 찾기 실행
    _findRecommendations();
  }

  /// 추천 챌린지 찾기
  Future<void> _findRecommendations() async {
    if (_selectedMood == null) return;
    
    setState(() {
      _isLoadingRecommendations = true;
    });

    try {
      final provider = Provider.of<ChallengeProvider>(context, listen: false);
      final selectedMoodOption = _moodOptions.firstWhere(
        (mood) => mood.id == _selectedMood,
      );

      // 로딩 효과를 위한 짧은 지연 (UX 개선)
      await Future.delayed(Duration(milliseconds: 500));

      // 선택한 감정에 맞는 챌린지들 필터링
      final allChallenges = provider.allChallenges;
      final recommendations = <Challenge>[];

      debugPrint('🔍 추천 찾기 시작: 전체 챌린지 ${allChallenges.length}개, 선택된 감정: ${selectedMoodOption.id}');
      debugPrint('🏷️ 감정 태그: ${selectedMoodOption.tags}');

      // 태그 기반 매칭
      for (final challenge in allChallenges) {
        if (!challenge.isActive) continue;
        
        final matchingTags = challenge.tags.where((tag) =>
            selectedMoodOption.tags.any((moodTag) =>
                tag.toLowerCase().contains(moodTag.replaceAll('#', '').toLowerCase()))).length;
        
        if (matchingTags > 0) {
          recommendations.add(challenge);
          debugPrint('✅ 매칭된 챌린지: ${challenge.title} (태그 ${matchingTags}개 매칭)');
        }
      }

      // 태그 매칭이 실패했을 때 카테고리 기반 fallback
      if (recommendations.isEmpty) {
        debugPrint('⚠️ 태그 매칭 실패, 카테고리 기반 fallback 실행');
        
        // 감정 카테고리와 챌린지 카테고리 매핑
        final fallbackChallenges = allChallenges.where((challenge) {
          if (!challenge.isActive) return false;
          
          // 감정에 따른 카테고리 매핑 로직
          switch (selectedMoodOption.id) {
            case 'happy':
            case 'excited':
            case 'grateful':
              return challenge.category.toString().contains('emotional') || 
                     challenge.category.toString().contains('Happy') ||
                     challenge.category.toString().contains('Energy');
            case 'sad':
            case 'lonely':
            case 'nostalgic':
              return challenge.category.toString().contains('emotional') || 
                     challenge.category.toString().contains('Comfort') ||
                     challenge.category.toString().contains('Nostalgic');
            case 'tired':
            case 'stressed':
              return challenge.category.toString().contains('healthy') || 
                     challenge.category.toString().contains('Care') ||
                     challenge.category.toString().contains('Healing');
            case 'curious':
            case 'adventurous':
              return challenge.category.toString().contains('world') || 
                     challenge.category.toString().contains('Asian') ||
                     challenge.category.toString().contains('European');
            default:
              return true; // 기본적으로 모든 챌린지 포함
          }
        }).toList();
        
        recommendations.addAll(fallbackChallenges.take(10));
        debugPrint('🔄 Fallback으로 ${recommendations.length}개 챌린지 추가');
      }

      // 추천 순서 정렬 (매칭도, 미완료 우선, 난이도)
      recommendations.sort((a, b) {
        final aProgress = provider.getProgressById(a.id);
        final bProgress = provider.getProgressById(b.id);
        final aCompleted = aProgress?.isCompleted ?? false;
        final bCompleted = bProgress?.isCompleted ?? false;
        
        // 미완료 우선
        if (aCompleted != bCompleted) {
          return aCompleted ? 1 : -1;
        }
        
        // 난이도 순
        return a.difficulty.compareTo(b.difficulty);
      });

      final finalRecommendations = recommendations.take(5).toList();
      debugPrint('🎯 최종 추천 결과: ${finalRecommendations.length}개 챌린지');
      for (int i = 0; i < finalRecommendations.length; i++) {
        debugPrint('   ${i + 1}. ${finalRecommendations[i].title}');
      }

      setState(() {
        _recommendedChallenges = finalRecommendations;
        _isLoadingRecommendations = false;
        _showRecommendations = true;
      });

      debugPrint('✅ UI 상태 업데이트 완료: showRecommendations=${_showRecommendations}, challenges=${_recommendedChallenges.length}개');

      // 애니메이션 재시작
      _animationController.reset();
      _animationController.forward();
      
    } catch (e) {
      setState(() {
        _isLoadingRecommendations = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('추천 챌린지를 불러오는 중 오류가 발생했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 카테고리별 색상
  Color _getCategoryColor(ChallengeCategory category) {
    switch (category) {
      // 메인 카테고리
      case ChallengeCategory.emotional:
        return Color(0xFFFF6B9D);
      case ChallengeCategory.worldCuisine:
        return Color(0xFF4ECDC4);
      case ChallengeCategory.healthy:
        return Color(0xFF45B7D1);
      
      // 감정별 서브카테고리
      case ChallengeCategory.emotionalHappy:
        return Color(0xFFFFD700); // 기쁨 골드
      case ChallengeCategory.emotionalComfort:
        return Color(0xFFFF6B9D); // 위로 핑크
      case ChallengeCategory.emotionalNostalgic:
        return Color(0xFF9B7FB3); // 그리움 라벤더
      case ChallengeCategory.emotionalEnergy:
        return Color(0xFFFF8C00); // 활력 오렌지
      
      // 세계 요리 서브카테고리
      case ChallengeCategory.worldAsian:
        return Color(0xFFE74C3C); // 아시아 레드
      case ChallengeCategory.worldEuropean:
        return Color(0xFF3498DB); // 유럽 블루
      case ChallengeCategory.worldAmerican:
        return Color(0xFF27AE60); // 아메리카 그린
      case ChallengeCategory.worldFusion:
        return Color(0xFFE67E22); // 중동 오렌지
      
      // 건강 라이프 서브카테고리
      case ChallengeCategory.healthyNatural:
        return Color(0xFF8BC34A); // 자연 친화 - 연한 초록
      case ChallengeCategory.healthyEnergy:
        return Color(0xFFFF9800); // 에너지 충전 - 주황
      case ChallengeCategory.healthyCare:
        return Color(0xFF9C27B0); // 건강 관리 - 보라
      case ChallengeCategory.healthyHealing:
        return Color(0xFF00BCD4); // 몸과 마음 케어 - 청록
    }
  }

  /// 카테고리별 아이콘
  IconData _getCategoryIcon(ChallengeCategory category) {
    switch (category) {
      // 메인 카테고리
      case ChallengeCategory.emotional:
        return Icons.favorite;
      case ChallengeCategory.worldCuisine:
        return Icons.travel_explore;
      case ChallengeCategory.healthy:
        return Icons.eco;
      
      // 감정별 서브카테고리
      case ChallengeCategory.emotionalHappy:
        return Icons.celebration;
      case ChallengeCategory.emotionalComfort:
        return Icons.healing;
      case ChallengeCategory.emotionalNostalgic:
        return Icons.history;
      case ChallengeCategory.emotionalEnergy:
        return Icons.battery_charging_full;
      
      // 세계 요리 서브카테고리
      case ChallengeCategory.worldAsian:
        return Icons.ramen_dining;
      case ChallengeCategory.worldEuropean:
        return Icons.local_pizza;
      case ChallengeCategory.worldAmerican:
        return Icons.fastfood;
      case ChallengeCategory.worldFusion:
        return Icons.outdoor_grill;
      
      // 건강 라이프 서브카테고리
      case ChallengeCategory.healthyNatural:
        return Icons.nature;
      case ChallengeCategory.healthyEnergy:
        return Icons.bolt;
      case ChallengeCategory.healthyCare:
        return Icons.local_hospital;
      case ChallengeCategory.healthyHealing:
        return Icons.self_improvement;
    }
  }
}

/// 감정 선택지 모델
class MoodOption {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final List<String> tags;

  MoodOption({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.tags,
  });
}