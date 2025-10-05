import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';

import '../config/theme.dart';
import '../models/mood.dart';
import '../models/recipe_analysis.dart';
import '../services/openai_service.dart';
import '../services/image_service.dart';
import '../widgets/common/vintage_info_dialog.dart';
import '../widgets/common/vintage_info_card.dart';
import 'create_screen.dart';

/// 사진으로 레시피를 가져와서 분석하는 화면
class PhotoImportScreen extends StatefulWidget {
  const PhotoImportScreen({super.key});

  @override
  State<PhotoImportScreen> createState() => _PhotoImportScreenState();
}

class _PhotoImportScreenState extends State<PhotoImportScreen> {
  final _openAiService = OpenAiService();
  final _imageService = ImageService();
  final _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  String? _error;
  File? _selectedImage;
  RecipeAnalysis? _analysisResult;
  String _currentLoadingMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('사진으로 가져오기'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppTheme.spacing24),
            _buildPhotoSection(),
            const SizedBox(height: AppTheme.spacing16),
            _buildActionButtons(),
            if (_error != null) ...[
              const SizedBox(height: AppTheme.spacing16),
              _buildErrorCard(),
            ],
            if (_analysisResult != null) ...[
              const SizedBox(height: AppTheme.spacing16),
              _buildAnalysisResult(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
              color: AppTheme.secondaryLight,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            ),
            child: const Icon(
              Icons.camera_alt,
              color: AppTheme.textPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Text(
              '음식 사진 또는 레시피 스크린샷을 찍거나 선택하면 재료와 조리법을 분석해드려요.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '음식 사진',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        GestureDetector(
          onTap: _isLoading ? null : _showImageSourceDialog,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedImage != null 
                    ? AppTheme.primaryColor 
                    : AppTheme.dividerColor,
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              color: _selectedImage != null 
                  ? AppTheme.surfaceColor 
                  : AppTheme.cardColor,
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium - 2),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        size: 48,
                        color: AppTheme.textTertiary,
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      Text(
                        '사진을 선택해주세요',
                        style: TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        '카메라 촬영 또는 앨범에서 선택',
                        style: TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: (_isLoading || _selectedImage == null) ? null : _analyzePhoto,
            icon: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_awesome, size: 20),
            label: Text(_isLoading 
                ? _currentLoadingMessage.isNotEmpty 
                    ? _currentLoadingMessage 
                    : '분석 중...' 
                : '사진 분석하기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              ),
            ),
          ),
        ),
        if (_analysisResult != null) ...[
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _createRecipe,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('레시피 작성'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorCard() {
    // 에러 메시지 안전성 확인 (Ultra Think 추가)
    final errorText = _error?.trim();
    if (errorText == null || errorText.isEmpty) {
      return Container(); // 빈 에러 메시지인 경우 카드 숨김
    }

    // VintageInfoCard 컴포넌트 사용
    return VintageInfoCard(
      title: '잠시만 기다려주세요 🐰',
      message: errorText,
    );
  }

  Widget _buildAnalysisResult() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        boxShadow: AppTheme.vintageShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _analysisResult!.isScreenshot ? Icons.auto_fix_high : Icons.auto_awesome,
                color: AppTheme.accentOrange,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                _analysisResult!.isScreenshot ? 'AI 레시피 완성' : 'AI 분석 결과',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (_analysisResult!.isScreenshot) ...[
                const SizedBox(width: AppTheme.spacing8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange.withValues(alpha: 51),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '스마트',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentOrange,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          
          // OCR 텍스트는 내부적으로만 사용하고 UI에서는 숨김
          
          // 요리명
          _buildAnalysisItem(
            '요리명',
            _analysisResult!.dishName,
            Icons.restaurant,
          ),
          const SizedBox(height: AppTheme.spacing12),
          
          // 재료
          _buildAnalysisItem(
            '재료',
            _analysisResult!.ingredients.map((i) => '${i.name}${i.amount != null ? ' ${i.amount}' : ''}').join(', '),
            Icons.shopping_basket,
          ),
          const SizedBox(height: AppTheme.spacing12),
          
          // 조리법
          _buildAnalysisItem(
            '조리법',
            _analysisResult!.instructions.asMap().entries
                .map((entry) => '${entry.key + 1}. ${entry.value}')
                .join('\n'),
            Icons.list_alt,
          ),
          
          if (_analysisResult!.estimatedTime.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacing12),
            _buildAnalysisItem(
              '조리 시간',
              _analysisResult!.estimatedTime,
              Icons.timer,
            ),
          ],
          
          if (_analysisResult!.difficulty.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacing12),
            _buildAnalysisItem(
              '난이도',
              _analysisResult!.difficulty,
              Icons.bar_chart,
            ),
          ],
          
          if (_analysisResult!.servings.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacing12),
            _buildAnalysisItem(
              '인분',
              _analysisResult!.servings,
              Icons.people,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalysisItem(String label, String content, IconData icon, {bool isOcrText = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.primaryColor),
            const SizedBox(width: AppTheme.spacing4),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing4),
        Container(
          padding: isOcrText ? const EdgeInsets.all(12) : EdgeInsets.zero,
          decoration: isOcrText ? BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.primaryLight, width: 1),
          ) : null,
          child: Text(
            content,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontStyle: isOcrText ? FontStyle.italic : FontStyle.normal,
              fontWeight: isOcrText ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '사진 선택',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Row(
              children: [
                Expanded(
                  child: _buildSourceButton(
                    onPressed: () => _selectImage(ImageSource.camera),
                    icon: Icons.camera_alt,
                    label: '카메라 촬영',
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: _buildSourceButton(
                    onPressed: () => _selectImage(ImageSource.gallery),
                    icon: Icons.photo_library,
                    label: '앨범에서 선택',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing16),
          ],
        ),
      ),
    );
  }

  /// Rate Limit 전용 다이얼로그 표시
  void _showRateLimitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VintageInfoDialog.rateLimit(),
    );
  }

  Widget _buildSourceButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryLight,
        foregroundColor: AppTheme.textPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> _selectImage(ImageSource source) async {
    Navigator.of(context).pop(); // 바텀시트 닫기

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80, // 품질 조정으로 파일 크기 최적화
      );

      if (image != null) {
        // 크롭 단계 추가: 사용자가 원하는 부분만 선택 가능
        await _cropImage(image.path);
      }
    } catch (e) {
      setState(() {
        _error = '이미지를 선택할 수 없습니다: $e';
      });
    }
  }

  /// 이미지 크롭 기능 (원하는 부분만 선택)
  Future<void> _cropImage(String imagePath) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '음식 부분 선택',
            toolbarColor: AppTheme.primaryColor,
            toolbarWidgetColor: Colors.white,
            backgroundColor: AppTheme.backgroundColor,
            activeControlsWidgetColor: AppTheme.primaryColor,
            cropGridColor: AppTheme.primaryLight,
            cropFrameColor: AppTheme.primaryColor,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false, // 자유 비율 (음식 모양이 다양하므로)
          ),
          IOSUiSettings(
            title: '음식 부분 선택',
            cancelButtonTitle: '취소',
            doneButtonTitle: '완료',
            aspectRatioLockEnabled: false, // 자유 비율
            resetAspectRatioEnabled: true, // 비율 리셋 가능
            rotateButtonsHidden: false, // 회전 버튼 표시
          ),
          WebUiSettings(
            context: context,
          ),
        ],
      );

      if (croppedFile != null) {
        // 크롭된 이미지로 설정
        setState(() {
          _selectedImage = File(croppedFile.path);
          _error = null;
          _analysisResult = null;
        });
      } else {
        // 사용자가 크롭 취소 시 - 원본 이미지도 선택 안된 것으로 처리
        if (kDebugMode) {
          print('사용자가 크롭을 취소했습니다.');
        }
      }
    } catch (e) {
      setState(() {
        _error = '이미지를 편집할 수 없습니다: $e';
      });
    }
  }

  Future<void> _analyzePhoto() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _analysisResult = null;
      _currentLoadingMessage = '레시피 재료 준비중';
    });

    try {
      // 1단계: 레시피 재료 준비중
      await Future.delayed(Duration(milliseconds: 500));

      setState(() {
        _currentLoadingMessage = '이미지 타입 감지중';
      });

      // 이미지를 Base64로 인코딩
      final bytes = await _selectedImage!.readAsBytes();
      final optimizedBytes = await _imageService.optimizeForApi(bytes);
      final base64Image = await _imageService.toBase64(optimizedBytes);

      // 2단계: 이미지 타입 감지중
      await Future.delayed(Duration(milliseconds: 800));

      // 3단계: 이미지 분석 시작 (스크린샷 vs 일반 사진은 내부에서 결정)
      setState(() {
        _currentLoadingMessage = '음식 사진 분석중'; // 기본값
      });

      await Future.delayed(Duration(milliseconds: 600));

      // 4단계: AI로 레시피 분석중
      setState(() {
        _currentLoadingMessage = 'AI로 레시피 분석중';
      });

      // OpenAI로 이미지 분석 (내부 프로그레스 메시지 무시)
      final analysisResult = await _openAiService.analyzeImage(
        base64Image,
        onProgress: (message, progress) {
          // 스크린샷 vs 일반 사진 구분하여 3단계 메시지 업데이트
          if (mounted) {
            if (message.contains('스크린샷')) {
              setState(() {
                _currentLoadingMessage = '스크린샷에서 레시피 추출중';
              });
            } else if (message.contains('분석중') && !message.contains('완료')) {
              setState(() {
                _currentLoadingMessage = 'AI로 레시피 분석중';
              });
            } else if (message.contains('마무리중')) {
              setState(() {
                _currentLoadingMessage = '레시피 마무리중';
              });
            }
          }
        },
      );

      // 5단계: 레시피 마무리중
      setState(() {
        _currentLoadingMessage = '레시피 마무리중';
      });

      await Future.delayed(Duration(milliseconds: 600));

      // 6단계: 레시피 작성 완료
      setState(() {
        _analysisResult = analysisResult;
        _currentLoadingMessage = '레시피 작성 완료 🐰';
        _isLoading = false;
      });

      await Future.delayed(Duration(milliseconds: 400));

    } catch (e) {
      // 구체적인 에러 메시지 생성 (Ultra Think 개선)
      String errorMessage;
      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('invalid image format') || errorStr.contains('image format')) {
        errorMessage = '지원하지 않는 이미지 형식입니다.\nJPG, PNG 파일을 사용해주세요.';
      } else if (errorStr.contains('api key') || errorStr.contains('unauthorized') || errorStr.contains('401')) {
        errorMessage = 'AI 분석 서비스에 연결할 수 없습니다.\n잠시 후 다시 시도해주세요.';
      } else if (errorStr.contains('rate limit') || errorStr.contains('429') || errorStr.contains('quota')) {
        // Rate Limit 전용 다이얼로그 표시
        if (mounted) {
          setState(() {
            _isLoading = false;
            _currentLoadingMessage = '';
          });
          _showRateLimitDialog();
        }
        return;
      } else if (errorStr.contains('network') || errorStr.contains('timeout') || errorStr.contains('connection')) {
        errorMessage = '네트워크 연결을 확인해주세요.\n인터넷 연결 상태를 점검해보세요.';
      } else if (errorStr.contains('food') || errorStr.contains('음식') || errorStr.contains('not food') ||
                 errorStr.contains('no food') || errorStr.contains('recipe') || errorStr.contains('cooking')) {
        errorMessage = '음식이나 요리가 보이지 않습니다.\n맛있는 음식 사진으로 다시 시도해주세요!';
      } else if (errorStr.isEmpty || errorStr.trim().isEmpty || errorStr == 'null') {
        errorMessage = '음식이나 요리가 보이지 않습니다.\n맛있는 음식 사진으로 다시 시도해주세요!';
      } else {
        // 기본 fallback: 음식이 아닌 모든 사진에 대한 안내 (MacBook, 풍경 등)
        errorMessage = '음식이나 요리가 보이지 않습니다.\n맛있는 음식 사진으로 다시 시도해주세요!';
      }

      if (mounted) {
        setState(() {
          _error = errorMessage;
          _isLoading = false;
          _currentLoadingMessage = '';
        });
      }

      // 디버깅용 로그 (개발 모드에서만)
      if (kDebugMode) {
        print('Photo analysis error: $e');
      }
    }
  }

  void _createRecipe() {
    if (_analysisResult == null || _selectedImage == null) return;

    // RecipeAnalysis의 toRecipe 메서드를 사용하여 Recipe 객체 생성 (OCR 정보 포함)
    final recipe = _analysisResult!.toRecipe(
      emotionalStory: '', // 사용자가 나중에 입력
      mood: Mood.happy, // 기본값
      // 추가 정보는 CreateScreen에서 사용자가 입력
    );

    // CreateScreen으로 이동 (생성 모드, AI 분석 결과로 미리 채움)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => CreateScreen(
          editingRecipe: recipe, 
          isEditMode: false, // 새로운 레시피 생성 모드
        ),
      ),
    );
  }
}