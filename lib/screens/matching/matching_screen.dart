import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/providers/matching_provider.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/screens/matching/match_success_screen.dart';
import 'package:chingu/widgets/card_stack.dart';
import 'package:chingu/widgets/match_card.dart';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  @override
  void initState() {
    super.initState();
    // 初始化時載入候選人
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.userModel;
      if (currentUser != null) {
        context.read<MatchingProvider>().loadCandidates(currentUser);
      }
    });
  }

  Future<void> _handleSwipe(String userId, UserModel targetUser, bool isLike) async {
    final result = await context.read<MatchingProvider>().swipe(
      userId,
      targetUser.uid,
      isLike,
    );

    if (result != null && mounted) {
      // 配對成功！顯示慶祝畫面
      final currentUser = context.read<AuthProvider>().userModel!;
      
      showGeneralDialog(
        context: context,
        pageBuilder: (context, animation, secondaryAnimation) {
          return MatchSuccessScreen(
            currentUser: currentUser,
            partner: result['partner'] as UserModel,
            chatRoomId: result['chatRoomId'] as String,
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        barrierDismissible: false,
        barrierLabel: 'Match Success',
        barrierColor: Colors.black54,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final matchingProvider = context.watch<MatchingProvider>();
    final authProvider = context.watch<AuthProvider>();
    final candidates = matchingProvider.candidates;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '尋找配對',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.tune_rounded,
              color: theme.colorScheme.primary,
            ),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.filter),
          ),
        ],
      ),
      body: matchingProvider.isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : matchingProvider.errorMessage != null
              ? _buildErrorState(context, theme, matchingProvider.errorMessage!)
              : candidates.isEmpty
                  ? _buildEmptyState(context, theme)
              : Stack(
                  children: [
                    // 卡片堆疊
                    Center(
                      child: Container(
                        height: 520,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        child: CardStack<UserModel>(
                          items: candidates,
                          stackDepth: 3,
                          keyBuilder: (user) => Key(user.uid),
                          itemBuilder: (context, user, index) {
                            // Only show MatchCard content for top card or simplified view for others if needed
                            // But MatchCard is optimized enough.
                            return MatchCard(user: user);
                          },
                          onSwipe: (user, direction) {
                            // 修正方向：startToEnd (右滑) -> Like, endToStart (左滑) -> Dislike
                            final isLikeCorrect = direction == DismissDirection.startToEnd;
                            
                            if (authProvider.uid != null) {
                              _handleSwipe(
                                authProvider.uid!,
                                user,
                                isLikeCorrect,
                              );
                            }
                          },
                          swipeBackground: _buildSwipeBackground(theme, true), // 左邊背景 (右滑時顯示) -> 喜歡
                          swipeSecondaryBackground: _buildSwipeBackground(theme, false), // 右邊背景 (左滑時顯示) -> 不喜歡
                        ),
                      ),
                    ),
                    
                    // 操作按鈕
                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildActionButton(
                            context,
                            Icons.close_rounded,
                            chinguTheme?.error ?? Colors.red,
                            () {
                              if (candidates.isNotEmpty && authProvider.uid != null) {
                                _handleSwipe(
                                  authProvider.uid!,
                                  candidates.first,
                                  false,
                                );
                              }
                            },
                          ),
                          const SizedBox(width: 20),
                          _buildActionButton(
                            context,
                            Icons.star_rounded,
                            chinguTheme?.warning ?? Colors.amber,
                            () {
                              // 超級喜歡功能 (暫時當作喜歡)
                              if (candidates.isNotEmpty && authProvider.uid != null) {
                                _handleSwipe(
                                  authProvider.uid!,
                                  candidates.first,
                                  true,
                                );
                              }
                            },
                            isSmall: true,
                          ),
                          const SizedBox(width: 20),
                          _buildActionButton(
                            context,
                            Icons.favorite_rounded,
                            chinguTheme?.success ?? Colors.green,
                            () {
                              if (candidates.isNotEmpty && authProvider.uid != null) {
                                _handleSwipe(
                                  authProvider.uid!,
                                  candidates.first,
                                  true,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildErrorState(BuildContext context, ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              '發生錯誤',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.red[400],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final authProvider = context.read<AuthProvider>();
                final currentUser = authProvider.userModel;
                if (currentUser != null) {
                  context.read<MatchingProvider>().loadCandidates(currentUser);
                }
              },
              child: const Text('重試'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            '暫無配對人選',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey[500],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '試試調整篩選條件或稍後再來',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              final authProvider = context.read<AuthProvider>();
              final currentUser = authProvider.userModel;
              if (currentUser != null) {
                context.read<MatchingProvider>().loadCandidates(currentUser);
              }
            },
            child: const Text('重新整理'),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              final authProvider = context.read<AuthProvider>();
              final currentUser = authProvider.userModel;
              if (currentUser != null) {
                context.read<MatchingProvider>().resetHistory(currentUser);
              }
            },
            icon: Icon(Icons.restore_rounded, color: theme.colorScheme.secondary),
            label: Text(
              '重置滑動紀錄 (開發測試用)',
              style: TextStyle(color: theme.colorScheme.secondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeBackground(ThemeData theme, bool isLike) {
    final color = isLike ? Colors.green : Colors.red;
    final icon = isLike ? Icons.favorite_rounded : Icons.close_rounded;
    final alignment = isLike ? Alignment.centerLeft : Alignment.centerRight;
    
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Icon(icon, color: color, size: 48),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isSmall = false,
  }) {
    final size = isSmall ? 50.0 : 64.0;
    final iconSize = isSmall ? 24.0 : 32.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color,
          size: iconSize,
        ),
      ),
    );
  }
}
