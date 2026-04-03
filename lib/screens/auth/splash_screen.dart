import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';
import 'package:chingu/core/routes/app_router.dart';

/// Chingu 開場動畫 — 品牌 Logo + 6 人圓桌動畫
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Phase 1: Logo 出現（0 → 1000ms）
  late final AnimationController _logoController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;

  // Phase 2: 文字滑入（400 → 1400ms）
  late final AnimationController _textController;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<double> _sloganFade;

  // Phase 3: 6 人圓桌動畫（800 → 2000ms）
  late final AnimationController _dotsController;

  // Phase 4: 整體退場（2500 → 3000ms）
  late final AnimationController _exitController;
  late final Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();

    // Phase 1: Logo
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    // Phase 2: 文字
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic));
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: const Interval(0.0, 0.6)),
    );
    _sloganFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: const Interval(0.4, 1.0)),
    );

    // Phase 3: 6 人圓點
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Phase 4: 退場
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    // Phase 1: Logo 出現
    _logoController.forward();

    // Phase 2: 文字稍微延後
    await Future.delayed(const Duration(milliseconds: 400));
    _textController.forward();

    // Phase 3: 圓點動畫
    await Future.delayed(const Duration(milliseconds: 400));
    _dotsController.forward();

    // 等待展示
    await Future.delayed(const Duration(milliseconds: 1700));

    // Phase 4: 退場
    _exitController.forward();
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _dotsController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _exitFade,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2E5364), // primary
                Color(0xFF3A6B7E),
                Color(0xFF6B93B8), // info
              ],
            ),
          ),
          child: Stack(
            children: [
              // 背景裝飾圓環
              ..._buildBackgroundRings(),

              // 主要內容
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    // Logo
                    _buildLogo(),

                    const SizedBox(height: 32),

                    // App 名稱
                    _buildTitle(),

                    const SizedBox(height: 12),

                    // 標語
                    _buildSlogan(),

                    const Spacer(flex: 2),

                    // 6 人圓桌動畫
                    _buildDinnerDots(),

                    const SizedBox(height: 20),

                    // 載入文字
                    FadeTransition(
                      opacity: _sloganFade,
                      child: Text(
                        '每週四，6 個人，1 張桌子',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.5),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    const Spacer(flex: 1),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Logo — 使用實際 Logo 圖片
  Widget _buildLogo() {
    return FadeTransition(
      opacity: _logoFade,
      child: ScaleTransition(
        scale: _logoScale,
        child: Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/Chingu_Logo.jpg',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  /// App 名稱
  Widget _buildTitle() {
    return SlideTransition(
      position: _titleSlide,
      child: FadeTransition(
        opacity: _titleFade,
        child: const Text(
          'Chingu',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  /// 標語
  Widget _buildSlogan() {
    return FadeTransition(
      opacity: _sloganFade,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppColorsMinimal.radiusFull),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: const Text(
          '讓每一次晚餐都有意義',
          style: TextStyle(
            fontSize: 15,
            color: Colors.white,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// 6 人圓桌動畫 — 6 個圓點繞圓排列，依序出現
  Widget _buildDinnerDots() {
    // 6 個莫蘭迪色圓點
    const dotColors = [
      Color(0xFFD67756), // 磚橘
      Color(0xFFE9967A), // 蜜桃
      Color(0xFF8DB6C9), // 淺藍
      Color(0xFFB88A6B), // 駝色
      Color(0xFF7CAF7C), // 莫蘭迪綠
      Color(0xFFA64A25), // 深磚橘
    ];

    return AnimatedBuilder(
      animation: _dotsController,
      builder: (context, _) {
        return SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 中央餐盤
              AnimatedBuilder(
                animation: _dotsController,
                builder: (context, _) {
                  final centerScale = Curves.easeOutBack.transform(
                    (_dotsController.value * 1.5).clamp(0.0, 1.0),
                  );
                  return Transform.scale(
                    scale: centerScale,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.restaurant_rounded,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  );
                },
              ),

              // 6 個人的圓點
              ...List.generate(6, (i) {
                final angle = (i * math.pi * 2 / 6) - (math.pi / 2);
                final radius = 40.0;
                final delay = i / 6.0;

                // 每個圓點交錯出現
                final progress = ((_dotsController.value - delay) * 2).clamp(0.0, 1.0);
                final scale = Curves.easeOutBack.transform(progress);
                final opacity = Curves.easeOut.transform(progress);

                return Positioned(
                  left: 50 + radius * math.cos(angle) - 8,
                  top: 50 + radius * math.sin(angle) - 8,
                  child: Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: dotColors[i],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: dotColors[i].withValues(alpha: 0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  /// 背景裝飾圓環
  List<Widget> _buildBackgroundRings() {
    return [
      Positioned(
        top: -80,
        right: -80,
        child: _buildRing(250, 0.06),
      ),
      Positioned(
        bottom: -120,
        left: -120,
        child: _buildRing(350, 0.04),
      ),
      Positioned(
        top: MediaQuery.of(context).size.height * 0.3,
        left: -60,
        child: _buildRing(150, 0.05),
      ),
    ];
  }

  Widget _buildRing(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: opacity),
          width: 1.5,
        ),
      ),
    );
  }
}
