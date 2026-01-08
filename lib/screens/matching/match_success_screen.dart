import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/utils/image_cache_manager.dart';

class MatchSuccessScreen extends StatefulWidget {
  final UserModel currentUser;
  final UserModel partner;
  final String chatRoomId;

  const MatchSuccessScreen({
    super.key,
    required this.currentUser,
    required this.partner,
    required this.chatRoomId,
  });

  @override
  State<MatchSuccessScreen> createState() => _MatchSuccessScreenState();
}

class _MatchSuccessScreenState extends State<MatchSuccessScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimationLeft;
  late Animation<Offset> _slideAnimationRight;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _slideAnimationLeft = Tween<Offset>(
      begin: const Offset(-1.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    ));

    _slideAnimationRight = Tween<Offset>(
      begin: const Offset(1.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      body: Stack(
        children: [
          // 背景光效
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    chinguTheme?.primaryGradient.colors.first.withOpacity(0.3) ?? theme.colorScheme.primary.withOpacity(0.3),
                    Colors.transparent,
                  ],
                  center: Alignment.center,
                  radius: 1.0,
                ),
              ),
            ),
          ),
          
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 標題
              ScaleTransition(
                scale: _scaleAnimation,
                child: const Text(
                  "It's a Match!",
                  style: TextStyle(
                    fontFamily: 'Pacifico', // 如果有這個字體，或者用其他手寫體
                    fontSize: 48,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(0, 4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ScaleTransition(
                scale: _scaleAnimation,
                child: Text(
                  "你和 ${widget.partner.name} 互相喜歡！",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(height: 60),

              // 頭像區域
              SizedBox(
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 左邊頭像 (自己)
                    SlideTransition(
                      position: _slideAnimationLeft,
                      child: Transform.translate(
                        offset: const Offset(-40, 0),
                        child: Transform.rotate(
                          angle: -0.1,
                          child: _buildAvatar(widget.currentUser.avatarUrl),
                        ),
                      ),
                    ),
                    // 右邊頭像 (對方)
                    SlideTransition(
                      position: _slideAnimationRight,
                      child: Transform.translate(
                        offset: const Offset(40, 0),
                        child: Transform.rotate(
                          angle: 0.1,
                          child: _buildAvatar(widget.partner.avatarUrl),
                        ),
                      ),
                    ),
                    // 中間愛心
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.favorite_rounded,
                          color: chinguTheme?.primaryGradient.colors.first ?? theme.colorScheme.primary,
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 80),

              // 按鈕區域
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          // 關閉當前頁面並導航到聊天室
                          Navigator.pop(context); // 關閉 MatchSuccessScreen
                          Navigator.pushNamed(
                            context,
                            AppRoutes.chatDetail,
                            arguments: {
                              'chatRoomId': widget.chatRoomId,
                              'otherUser': widget.partner,
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: chinguTheme?.primaryGradient.colors.first ?? theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          '發送訊息',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          '繼續滑動',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? url) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        image: DecorationImage(
          image: (url != null && url.isNotEmpty)
              ? CachedNetworkImageProvider(
                  url,
                  cacheManager: ImageCacheManager().manager,
                )
              : const AssetImage('assets/images/placeholder_avatar.png') as ImageProvider,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
