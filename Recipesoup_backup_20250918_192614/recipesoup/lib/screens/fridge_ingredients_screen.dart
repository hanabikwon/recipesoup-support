import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../services/openai_service.dart';
// Removed unused import: ../models/recipe_analysis.dart
import '../models/mood.dart';
// 로딩 다이얼로그는 기본 Material 위젯 사용
import 'detail_screen.dart';
import 'create_screen.dart';

/// 냉장고 재료 입력 화면
/// 사용자가 가지고 있는 재료를 입력하면 AI가 레시피를 추천하는 기능
class FridgeIngredientsScreen extends StatefulWidget {
  const FridgeIngredientsScreen({super.key});

  @override
  State<FridgeIngredientsScreen> createState() => _FridgeIngredientsScreenState();
}

class _FridgeIngredientsScreenState extends State<FridgeIngredientsScreen> {
  final TextEditingController _ingredientsController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<String> _selectedIngredients = [];
  bool _isLoading = false;

  /// 자주 사용하는 재료 프리셋 (한국 가정 기준)
  final List<String> _commonIngredients = [
    '양파', '마늘', '당근', '감자', '대파',
    '계란', '쇠고기', '돼지고기', '닭고기', '두부',
    '배추', '무', '브로콜리', '양배추', '시금치',
    '버섯', '토마토', '오이', '호박', '가지',
    '새우', '오징어', '생선', '치즈', '우유',
    '간장', '고추장', '된장', '참기름', '올리브오일',
  ];

  @override
  void dispose() {
    _ingredientsController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 재료 추가 (중복 방지)
  void _addIngredient(String ingredient) {
    final trimmedIngredient = ingredient.trim();
    if (trimmedIngredient.isNotEmpty &&
        !_selectedIngredients.contains(trimmedIngredient)) {
      setState(() {
        _selectedIngredients.add(trimmedIngredient);
      });
    }
  }

  /// 재료 제거
  void _removeIngredient(String ingredient) {
    setState(() {
      _selectedIngredients.remove(ingredient);
    });
  }

  /// 텍스트 필드에서 재료 추가 (쉼표 또는 엔터로 구분)
  void _addIngredientFromTextField() {
    final text = _ingredientsController.text.trim();
    if (text.isEmpty) return;

    // 쉼표로 구분된 여러 재료 처리
    final ingredients = text.split(RegExp(r'[,\n]'));
    int addedCount = 0;
    List<String> duplicates = [];

    for (final ingredient in ingredients) {
      final trimmed = ingredient.trim();
      if (trimmed.isNotEmpty) {
        if (!_selectedIngredients.contains(trimmed)) {
          _addIngredient(ingredient);
          addedCount++;
        } else {
          duplicates.add(trimmed);
        }
      }
    }

    _ingredientsController.clear();

    // 중복 재료 알림
    if (duplicates.isNotEmpty) {
      final duplicateText = duplicates.join(', ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이미 선택된 재료입니다: $duplicateText'),
          duration: const Duration(seconds: 2),
          backgroundColor: AppTheme.warningColor,
        ),
      );
    }

    // 연속 입력을 위해 포커스 유지
    if (addedCount > 0) {
      _focusNode.requestFocus();
    }
  }

  /// AI 추천 요청
  Future<void> _requestRecommendations() async {
    if (_selectedIngredients.length < 2) {
      _showErrorDialog('최소 2개 이상의 재료를 입력해주세요');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final openAiService = context.read<OpenAiService>();

      // 로딩 다이얼로그 표시
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
                const SizedBox(height: 16),
                const Text(
                  'AI 레시피 추천',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_selectedIngredients.join(", ")}로\n맞춤 레시피를 찾고 있어요...',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  '보통 5-10초 정도 걸려요',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = false;
                    });
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text('취소'),
                ),
              ],
            ),
          ),
        );
      }

      // AI 단일 레시피 추천 요청 (새로운 API)
      final recipeAnalysis = await openAiService.analyzeIngredientsForRecipe(
        _selectedIngredients,
        onProgress: (message, progress) {
          // LoadingDialog에서 진행률 업데이트
        },
      );

      if (mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기

        if (recipeAnalysis.dishName.isNotEmpty && recipeAnalysis.ingredients.isNotEmpty) {
          // AI 분석 결과를 Recipe 객체로 변환 (재료 추천 기본 감정 메모 포함)
          final recipe = recipeAnalysis.toRecipe(
            emotionalStory: '냉장고 재료로 추천받은 레시피입니다. 수정은 보관함에서 할 수 있어요.',
            mood: Mood.comfortable, // 재료 추천의 기본 감정: 편안함
          );

          // 단일 레시피 상세보기 화면으로 이동 (저장하기 버튼 + "다른 레시피 추천" 버튼 포함)
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DetailScreen(
                recipe: recipe,
                fromIngredientRecommendation: true, // 재료 추천에서 온 것 표시
                originalIngredients: _selectedIngredients, // "다른 레시피 추천" 기능용
                isTemporaryRecipe: true, // 🔥 FIX: AI 생성 임시 레시피 (저장 필요)
              ),
            ),
          );
        } else {
          _showErrorDialog('추천할 레시피를 찾을 수 없습니다.\n다른 재료 조합을 시도해보세요.');
        }
      }

    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        _showEnhancedErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 오류 다이얼로그 표시
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          '알림',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
            ),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 향상된 오류 다이얼로그 표시 (구체적인 에러 분석 및 해결책 제시)
  void _showEnhancedErrorDialog(String errorDetails) {
    // 에러 타입 분석
    String title;
    String message;
    String actionText;
    VoidCallback? retryAction;

    if (errorDetails.toLowerCase().contains('network') ||
        errorDetails.toLowerCase().contains('connection') ||
        errorDetails.toLowerCase().contains('timeout')) {
      title = '네트워크 연결 오류';
      message = '인터넷 연결을 확인해주세요.\n\nWiFi나 모바일 데이터가 연결되어 있는지 확인하고 다시 시도해보세요.';
      actionText = '재시도';
      retryAction = () {
        Navigator.of(context).pop();
        _requestRecommendations(); // 같은 재료로 재시도
      };
    } else if (errorDetails.toLowerCase().contains('401') ||
               errorDetails.toLowerCase().contains('api') ||
               errorDetails.toLowerCase().contains('key')) {
      title = '서비스 일시 중단';
      message = '현재 AI 추천 서비스가 일시적으로 중단되었습니다.\n\n직접 레시피를 작성하거나 나중에 다시 시도해보세요.';
      actionText = '직접 작성하기';
      retryAction = () {
        Navigator.of(context).pop();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const CreateScreen(),
          ),
        );
      };
    } else if (errorDetails.toLowerCase().contains('500') ||
               errorDetails.toLowerCase().contains('server')) {
      title = '서버 점검 중';
      message = '서버가 일시적으로 점검 중입니다.\n\n잠시 후 다시 시도해주세요.';
      actionText = '재시도';
      retryAction = () {
        Navigator.of(context).pop();
        _requestRecommendations(); // 같은 재료로 재시도
      };
    } else {
      title = '추천 요청 실패';
      message = '예상치 못한 오류가 발생했습니다.\n\n인터넷 연결을 확인하거나 직접 레시피를 작성해보세요.';
      actionText = '직접 작성하기';
      retryAction = () {
        Navigator.of(context).pop();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const CreateScreen(),
          ),
        );
      };
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: AppTheme.errorColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryLight.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '오프라인에서도 나만의 레시피를 직접 작성할 수 있어요!',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
            ),
            child: const Text('닫기'),
          ),
          if (retryAction != null)
            ElevatedButton(
              onPressed: retryAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(actionText),
            ),
        ],
      ),
    );
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
          '냉장고 재료 입력하기',
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
            // 메인 콘텐츠
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 안내 텍스트
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withValues(alpha: 0.1),
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
                            children: const [
                              Icon(
                                Icons.kitchen,
                                color: AppTheme.primaryColor,
                                size: 24,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '냉장고 재료로 요리 추천받기',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '집에 있는 재료들을 입력하면 Ai가 레시피를 추천해드려요',
                            // "다른 레시피 추천" 버튼으로 추가 레시피 요청 가능
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 재료 입력 필드
                    const Text(
                      '재료 입력',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ingredientsController,
                            focusNode: _focusNode,
                            onChanged: (_) => setState(() {}), // + 버튼 상태 실시간 업데이트
                            decoration: InputDecoration(
                              hintText: '양상추, 무화과, 썬드라이 토마토',
                              hintStyle: const TextStyle(
                                color: AppTheme.textTertiary,
                                fontSize: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppTheme.dividerColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppTheme.primaryColor,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              filled: true,
                              fillColor: AppTheme.surfaceColor,
                            ),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _addIngredientFromTextField(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FloatingActionButton.small(
                          onPressed: _addIngredientFromTextField,
                          backgroundColor: _ingredientsController.text.trim().isNotEmpty
                              ? AppTheme.primaryColor
                              : AppTheme.disabledColor,
                          foregroundColor: Colors.white,
                          heroTag: 'add_ingredient',
                          elevation: _ingredientsController.text.trim().isNotEmpty ? 4 : 2,
                          child: const Icon(Icons.add, size: 20),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // 입력 도움말
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        '💡 여러 재료는 쉼표로 구분하거나 + 버튼으로 추가하세요',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textTertiary,
                          height: 1.3,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 선택된 재료들 표시
                    if (_selectedIngredients.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '선택한 재료',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '${_selectedIngredients.length}개',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedIngredients.map((ingredient) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: AppTheme.vintageShadow,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  ingredient,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => _removeIngredient(ingredient),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),
                    ],

                    // 자주 사용하는 재료 섹션
                    const Text(
                      '자주 사용하는 재료',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _commonIngredients.map((ingredient) {
                        final isSelected = _selectedIngredients.contains(ingredient);
                        return GestureDetector(
                          onTap: () {
                            if (isSelected) {
                              _removeIngredient(ingredient);
                            } else {
                              _addIngredient(ingredient);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryLight
                                  : AppTheme.cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.dividerColor,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? AppTheme.vintageShadow
                                  : null,
                            ),
                            child: Text(
                              ingredient,
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            // 하단 추천 요청 버튼
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowColor,
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading || _selectedIngredients.length < 2
                      ? null
                      : _requestRecommendations,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.fabColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    shadowColor: AppTheme.shadowColor,
                    disabledBackgroundColor: AppTheme.disabledColor,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.restaurant_menu,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedIngredients.length < 2
                            ? '재료를 2개 이상 입력해주세요'
                            : 'AI 맞춤 레시피 추천받기 (${_selectedIngredients.length}개 재료)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}