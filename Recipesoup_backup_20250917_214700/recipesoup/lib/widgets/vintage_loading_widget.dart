import 'package:flutter/material.dart';
import '../config/theme.dart';

/// 빈티지 아이보리 테마에 어울리는 요리 감성 로딩 위젯
/// 여러 화면에서 일관된 로딩 경험을 제공
class VintageLoadingWidget extends StatefulWidget {
  final String message;
  final double? progress; // null이면 무한 로딩, 0.0-1.0이면 진행률 표시
  final bool showProgressBar; // 진행률 바 표시 여부
  
  const VintageLoadingWidget({
    super.key,
    required this.message,
    this.progress,
    this.showProgressBar = false,
  });

  @override
  State<VintageLoadingWidget> createState() => _VintageLoadingWidgetState();
}

class _VintageLoadingWidgetState extends State<VintageLoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  
  double _targetProgress = 0.0;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    
    // 진행률 애니메이션 컨트롤러
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    
    // 초기 진행률 설정
    if (widget.progress != null) {
      _targetProgress = widget.progress!;
      _progressController.animateTo(widget.progress!);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }
  
  @override
  void didUpdateWidget(VintageLoadingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 진행률이 변경되면 애니메이션으로 업데이트
    if (widget.progress != oldWidget.progress && widget.progress != null) {
      _targetProgress = widget.progress!;
      _progressController.animateTo(widget.progress!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 요리 감성의 빈티지 로딩 애니메이션
            _buildVintageLoadingAnimation(),
            const SizedBox(height: 40),

            // 로딩 메시지 카드
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowColor,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    widget.message,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.showProgressBar && widget.progress != null) ...[
                    const SizedBox(height: 8),
                    _buildVintageProgressBar(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 심플하고 모던한 로딩 애니메이션
  Widget _buildVintageLoadingAnimation() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 부드러운 맥동 효과 원
              Container(
                width: 60 + (_pulseController.value * 20),
                height: 60 + (_pulseController.value * 20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withValues(alpha: 0.1 - _pulseController.value * 0.05),
                ),
              ),
              
              // 중앙 아이콘 (간단한 맥동)
              Container(
                width: 50 + (_pulseController.value * 4),
                height: 50 + (_pulseController.value * 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withValues(alpha: 230),
                ),
                child: Icon(
                  Icons.restaurant_menu,
                  size: 24 + (_pulseController.value * 2),
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  /// 심플하고 엣지있는 진행률 바
  Widget _buildVintageProgressBar() {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        final animatedProgress = _progressAnimation.value * _targetProgress;
        
        return Column(
          children: [
            // 진행률 숫자 (깔끔한 스타일)
            AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                final displayProgress = (_progressAnimation.value * _targetProgress * 100).toInt();
                return Text(
                  '$displayProgress%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.5,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            // 심플한 사각형 진행률 바
            Container(
              width: 240,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFFE8E3D8), // 연한 베이지 배경
              ),
              child: Stack(
                children: [
                  // 진행률 바 (사각형, 그라데이션 없음)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 240 * animatedProgress,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppTheme.textPrimary, // 다크 올리브로 심플하게
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 간단한 빈티지 로딩 (진행률 없는 버전)
class SimpleVintageLoading extends StatelessWidget {
  final String message;
  
  const SimpleVintageLoading({
    super.key,
    this.message = '잠시만 기다려 주세요...',
  });

  @override
  Widget build(BuildContext context) {
    return VintageLoadingWidget(
      message: message,
      showProgressBar: false,
    );
  }
}

/// 진행률이 있는 빈티지 로딩
class ProgressVintageLoading extends StatelessWidget {
  final String message;
  final double progress;
  
  const ProgressVintageLoading({
    super.key,
    required this.message,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return VintageLoadingWidget(
      message: message,
      progress: progress,
      showProgressBar: true,
    );
  }
}