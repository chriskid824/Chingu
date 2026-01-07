import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/providers/matching_provider.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/screens/matching/match_success_screen.dart';

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
                        child: Stack(
                          children: candidates.asMap().entries.map((entry) {
                            final index = entry.key;
                            final user = entry.value;
                            
                            // 只顯示前3張卡片
                            if (index >= 3) return const SizedBox.shrink();
                            
                            // 計算偏移和透明度，製造堆疊效果
                            final reverseIndex = index; // 0 是最上面
                            final offset = Offset(reverseIndex * 4.0, reverseIndex * 4.0);
                            final scale = 1.0 - (reverseIndex * 0.05);
                            
                            // 注意：列表的第一個元素應該顯示在最上面，但在 Stack 中最後一個元素顯示在最上面
                            // 所以我們應該反轉順序或者只渲染第一個
                            // 為了簡化，我們這裡只顯示第一個（當前候選人），背景可以放一個假卡片增加層次感
                            
                            // 修改邏輯：只顯示最上面一張卡片，背景放一張裝飾
                            if (index > 0) {
                               return Transform.translate(
                                offset: const Offset(10, 10),
                                child: Transform.scale(
                                  scale: 0.95,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: chinguTheme?.surfaceVariant ?? Colors.grey[200]!,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }

                            return Dismissible(
                              key: Key(user.uid),
                              direction: DismissDirection.horizontal,
                              onDismissed: (direction) {
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
                              background: _buildSwipeBackground(theme, true), // 左邊背景 (右滑時顯示) -> 喜歡
                              secondaryBackground: _buildSwipeBackground(theme, false), // 右邊背景 (左滑時顯示) -> 不喜歡
                              child: _buildCard(context, user),
                            );
                          }).toList().reversed.toList(), // 反轉列表，讓第一個元素在 Stack 的最上面
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

  Widget _buildCard(BuildContext context, UserModel user) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: chinguTheme?.shadowLight ?? Colors.black12,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 圖片 (如果有頭像URL，否則顯示漸層)
            user.avatarUrl != null 
                ? Image.network(user.avatarUrl!, fit: BoxFit.cover)
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.grey[300]!,
                          Colors.grey[400]!,
                        ],
                      ),
                    ),
                    child: Icon(Icons.person_rounded, size: 100, color: Colors.white),
                  ),
            
            // 漸層遮罩
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.5, 0.7, 1.0],
                ),
              ),
            ),
            
            // 內容
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 匹配度標籤 (假設值)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '92% 匹配',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // 名字和年齡
                  Row(
                    children: [
                      Text(
                        '${user.name}, ${user.age}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (user.subscription == 'premium')
                        const Icon(Icons.verified_rounded, color: Colors.blue, size: 24),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // 職業
                  Row(
                    children: [
                      const Icon(Icons.work_outline_rounded, color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        user.job,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // 興趣標籤
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: user.interests.take(3).map((interest) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Text(
                          interest,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
