import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../providers/challenge_provider.dart';
import '../models/challenge_models.dart';
import '../services/cooking_method_service.dart';

/// 챌린지 진행 화면
/// 사용자가 실제로 챌린지를 수행하며 단계별로 진행할 수 있는 화면
class ChallengeProgressScreen extends StatefulWidget {
  final Challenge challenge;

  const ChallengeProgressScreen({
    super.key,
    required this.challenge,
  });

  @override
  State<ChallengeProgressScreen> createState() => _ChallengeProgressScreenState();
}

class _ChallengeProgressScreenState extends State<ChallengeProgressScreen>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  
  // 사용자 입력 데이터
  final TextEditingController _notesController = TextEditingController();
  int _userRating = 0;
  
  // 스텝별 완료 상태 추적
  List<bool> _completedSteps = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// 스텝 완료 상태 초기화 (안전한 방식으로 다음 프레임에서 실행)
  void _initializeSteps(int stepCount) {
    if (_completedSteps.length != stepCount) {
      // build 중에 setState를 호출하는 대신, 다음 프레임에서 실행
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _completedSteps = List.filled(stepCount, false);
          });
        }
      });
    }
  }

  /// 스텝 완료/미완료 토글
  void _toggleStep(int stepIndex) {
    setState(() {
      _completedSteps[stepIndex] = !_completedSteps[stepIndex];
    });
  }

  /// 다음 해야 할 스텝 인덱스 찾기 (강조 표시용)
  int? _getNextStepIndex() {
    for (int i = 0; i < _completedSteps.length; i++) {
      if (!_completedSteps[i]) {
        return i;
      }
    }
    return null; // 모든 스텝 완료
  }

  /// 완료된 스텝 개수
  int get _completedCount => _completedSteps.where((completed) => completed).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.cardColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: Text(
          widget.challenge.title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _getCategoryColor(widget.challenge.category),
          labelColor: AppTheme.textPrimary,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: [
            Tab(text: '단계별 진행'),
            Tab(text: '완료 & 기록'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProgressTab(),
          _buildCompletionTab(),
        ],
      ),
    );
  }

  /// 진행 탭 - 간단한 레시피 정보만 표시
  Widget _buildProgressTab() {
    final isWorldCuisine = widget.challenge.category == ChallengeCategory.worldCuisine;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 세계 요리 탐험에서만 프로그래스바 표시
          if (isWorldCuisine) ...[
            _buildWorldCuisineProgress(),
            SizedBox(height: 24),
          ],
          
          // 챌린지 정보
          _buildChallengeInfo(),
          SizedBox(height: 24),
          
          // 요리 방법
          _buildCookingMethod(),
          SizedBox(height: 24),
          
          // 완료 버튼
          _buildSimpleCompleteButton(),
        ],
      ),
    );
  }
  
  /// 세계 요리 탐험 전용 프로그래스바
  Widget _buildWorldCuisineProgress() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.vintageShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '🌍 세계 맛 여행',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Spacer(),
              Text(
                '진행률 75%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _getCategoryColor(widget.challenge.category),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          LinearProgressIndicator(
            value: 0.75,
            backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              _getCategoryColor(widget.challenge.category),
            ),
            minHeight: 6,
          ),
          SizedBox(height: 12),
          Text(
            '이탈리아 → 일본 → 중국 → 프랑스 → 인도',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 챌린지 기본 정보
  Widget _buildChallengeInfo() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.restaurant_menu,
                color: _getCategoryColor(widget.challenge.category),
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.challenge.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            widget.challenge.description,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              _buildInfoTag(
                icon: Icons.timer,
                text: '${widget.challenge.estimatedMinutes}분',
                color: Colors.orange,
              ),
              SizedBox(width: 12),
              _buildInfoTag(
                icon: Icons.restaurant,
                text: widget.challenge.servings,
                color: Colors.green,
              ),
              SizedBox(width: 12),
              _buildInfoTag(
                icon: Icons.star,
                text: _getDifficultyText(widget.challenge.difficulty),
                color: _getDifficultyColor(widget.challenge.difficulty),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// 요리 방법
  Widget _buildCookingMethod() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.vintageShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '요리 방법',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          FutureBuilder<DetailedCookingMethod?>(
            future: CookingMethodService().getCookingMethodById(widget.challenge.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        '조리 방법을 불러오는 중...',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.hasData && snapshot.data != null) {
                final cookingMethod = snapshot.data!;
                final steps = cookingMethod.cookingSteps;
                
                // 스텝 수가 변경되면 초기화
                _initializeSteps(steps.length);
                
                final nextStepIndex = _getNextStepIndex();
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 진행 상황 헤더
                    Container(
                      padding: EdgeInsets.all(20),
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryLight.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.checklist_rtl,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '진행 상황: $_completedCount / ${steps.length}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Spacer(),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryLight.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${((_completedCount / steps.length) * 100).round()}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: steps.isNotEmpty ? _completedCount / steps.length : 0,
                            backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor,
                            ),
                            minHeight: 6,
                          ),
                        ],
                      ),
                    ),
                    
                    // 스텝별 체크박스가 있는 요리 단계 (미완료를 위로, 완료를 아래로 정렬)
                    ...() {
                      final sortedSteps = steps.asMap().entries.toList();
                      sortedSteps.sort((a, b) {
                        final aCompleted = a.key < _completedSteps.length ? _completedSteps[a.key] : false;
                        final bCompleted = b.key < _completedSteps.length ? _completedSteps[b.key] : false;
                        // 미완료(false)를 먼저, 완료(true)를 나중에
                        if (aCompleted != bCompleted) {
                          return aCompleted ? 1 : -1;
                        }
                        // 같은 완료 상태일 때는 원래 순서 유지
                        return a.key.compareTo(b.key);
                      });
                      return sortedSteps.map((entry) {
                      final index = entry.key;
                      final step = entry.value;
                      final isCompleted = index < _completedSteps.length ? _completedSteps[index] : false;
                      final isNextStep = nextStepIndex == index;
                      
                      return InkWell(
                        onTap: () => _toggleStep(index),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          margin: EdgeInsets.only(bottom: 12),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isNextStep 
                                ? Colors.grey.withValues(alpha: 0.15)
                                : isCompleted 
                                    ? Colors.grey.withValues(alpha: 0.1)
                                    : Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isNextStep 
                                  ? AppTheme.primaryColor.withValues(alpha: 0.5)
                                  : isCompleted 
                                      ? AppTheme.successColor.withValues(alpha: 0.3)
                                      : AppTheme.primaryLight.withValues(alpha: 0.2),
                              width: isNextStep ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 체크박스
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isCompleted 
                                      ? AppTheme.successColor 
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isCompleted 
                                        ? AppTheme.successColor 
                                        : AppTheme.primaryColor,
                                    width: 2,
                                  ),
                                ),
                                child: isCompleted
                                    ? Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            color: AppTheme.primaryColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                              ),
                              
                              SizedBox(width: 12),
                              
                              // 스텝 설명과 다음 단계 표시
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 다음 단계 라벨 (필요시)
                                    if (isNextStep) ...[
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '다음 단계',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                    ],
                                    
                                    // 스텝 내용
                                    Text(
                                      step,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isCompleted 
                                            ? AppTheme.textSecondary
                                            : AppTheme.textPrimary,
                                        height: 1.5,
                                        decoration: isCompleted 
                                            ? TextDecoration.lineThrough 
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // 완료/미완료 아이콘
                              if (isNextStep) 
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: AppTheme.primaryColor,
                                ),
                            ],
                          ),
                        ),
                      );
                      });
                    }(),
                  ],
                );
              }

              // 데이터가 없거나 오류가 발생한 경우
              return Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.textTertiary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '이 챌린지의 상세한 조리 방법이 아직 준비되지 않았습니다.\n주요 재료를 참고하여 요리해보세요!',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  /// 간단한 완료 버튼
  Widget _buildSimpleCompleteButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // 완료 탭으로 이동
              _tabController.animateTo(1);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '완료하기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(height: 12),
        Text(
          '위 재료와 방법을 참고하여 요리한 후 완료 버튼을 눌러주세요',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  /// 정보 태그
  Widget _buildInfoTag({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 완료 및 기록 탭
  Widget _buildCompletionTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 챌린지 완료 헤더
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getCategoryColor(widget.challenge.category).withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: AppTheme.vintageShadow,
            ),
            child: Column(
              children: [
                Icon(
                  Icons.celebration,
                  color: _getCategoryColor(widget.challenge.category),
                  size: 48,
                ),
                SizedBox(height: 12),
                Text(
                  '챌린지 완료!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  widget.challenge.title,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // 사용자 노트
          Text(
            '나만의 기록',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryLight.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '이 챌린지를 통해 느낀 점이나 특별한 경험을 기록해보세요...',
                hintStyle: TextStyle(color: AppTheme.textTertiary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // 만족도 평가
          Text(
            '만족도 평가',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryLight.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '이 챌린지는 어떠셨나요?',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _userRating = index + 1;
                        });
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.star,
                          size: 32,
                          color: index < _userRating
                              ? Colors.amber
                              : AppTheme.textTertiary.withValues(alpha: 0.3),
                        ),
                      ),
                    );
                  }),
                ),
                SizedBox(height: 8),
                Text(
                  _getRatingText(_userRating),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // 만족도 평가 필수 안내문구 (별점 박스 외부)
          Text(
            '※ 만족도 평가는 필수입니다',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 16),
          
          // 완료 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _userRating > 0 ? () => _completeChallenge() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: AppTheme.textTertiary.withValues(alpha: 0.3),
              ),
              child: Text(
                '챌린지 완료하기',
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
  }


  /// 챌린지 완료
  Future<void> _completeChallenge() async {
    final provider = context.read<ChallengeProvider>();
    
    final success = await provider.completeChallenge(
      widget.challenge.id,
      userRating: _userRating,
      userNote: _notesController.text.trim().isNotEmpty 
          ? _notesController.text.trim() 
          : null,
    );
    
    if (success && mounted) {
      // 완료 다이얼로그 표시
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.celebration,
                color: _getCategoryColor(widget.challenge.category),
              ),
              SizedBox(width: 8),
              Text('챌린지 완료'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(''),
              SizedBox(height: 8),
              Text(
                '새로운 요리 레시피를 완성하셨네요!',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _getCategoryColor(widget.challenge.category),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
                Navigator.of(context).pop(); // 진행 화면 닫기
              },
              child: Text('확인'),
            ),
          ],
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('챌린지 완료에 실패했습니다'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  /// 유틸리티 메서드들
  
  /// 난이도 텍스트 반환
  String _getDifficultyText(int difficulty) {
    switch (difficulty) {
      case 1:
        return '쉬움';
      case 2:
        return '보통';
      case 3:
        return '어려움';
      default:
        return '보통';
    }
  }

  /// 난이도 색상 반환
  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  /// 평점 텍스트 반환
  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return '아쉬워요';
      case 2:
        return '그저 그래요';
      case 3:
        return '괜찮아요';
      case 4:
        return '좋아요';
      case 5:
        return '최고예요';
      default:
        return '평가해주세요';
    }
  }

  /// 카테고리 색상 반환
  Color _getCategoryColor(ChallengeCategory category) {
    switch (category) {
      // 메인 카테고리
      case ChallengeCategory.emotional:
        return Color(0xFFE8A5C0); // 핑크 계열 (홈화면과 일치하는 부드러운 핑크)
      case ChallengeCategory.worldCuisine:
        return Color(0xFF4ECDC4); // 청록 계열
      case ChallengeCategory.healthy:
        return Color(0xFF45B7D1); // 파랑 계열
      
      // 감정별 서브카테고리
      case ChallengeCategory.emotionalHappy:
        return Color(0xFFF4D03F); // 기쁨 골드 (홈화면과 일치하는 부드러운 골드)
      case ChallengeCategory.emotionalComfort:
        return Color(0xFFE8A5C0); // 위로 핑크 (홈화면과 일치하는 부드러운 핑크)
      case ChallengeCategory.emotionalNostalgic:
        return Color(0xFF9B7FB3); // 그리움 라벤더
      case ChallengeCategory.emotionalEnergy:
        return Color(0xFFF39C12); // 활력 오렌지 (홈화면과 일치하는 부드러운 오렌지)
      
      // 세계 요리 서브카테고리
      case ChallengeCategory.worldAsian:
        return Color(0xFFE57373); // 아시아 레드 (부드러운 레드)
      case ChallengeCategory.worldEuropean:
        return Color(0xFF3498DB); // 유럽 블루
      case ChallengeCategory.worldAmerican:
        return Color(0xFF27AE60); // 아메리카 그린
      case ChallengeCategory.worldFusion:
        return Color(0xFFE67E22); // 중동 오렌지
      
      // 건강 라이프 서브카테고리
      case ChallengeCategory.healthyNatural:
        return Color(0xFF7BC04A); // 자연 올리브 그린
      case ChallengeCategory.healthyEnergy:
        return Color(0xFFF7DC6F); // 에너지 옐로우 (부드러운 에너지 색상)
      case ChallengeCategory.healthyCare:
        return Color(0xFF3498DB); // 건강 블루
      case ChallengeCategory.healthyHealing:
        return Color(0xFF9B59B6); // 힐링 퍼플
    }
  }

}