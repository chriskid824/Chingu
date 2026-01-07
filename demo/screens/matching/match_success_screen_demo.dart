import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';

class MatchSuccessScreenDemo extends StatelessWidget {
  const MatchSuccessScreenDemo({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColorsMinimal.transparentGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 慶祝動畫區域
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // 背景光圈
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColorsMinimal.error.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    // 頭像組
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildAvatar(),
                        const SizedBox(width: 40),
                        _buildAvatar(),
                      ],
                    ),
                    // 愛心圖標
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColorsMinimal.error,
                            AppColorsMinimal.error.withOpacity(0.8),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColorsMinimal.error.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 48),
                
                // 標題
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '配對成功！',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColorsMinimal.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('🎉', style: TextStyle(fontSize: 36)),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // 描述
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColorsMinimal.error.withOpacity(0.1),
                        AppColorsMinimal.error.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '您和 ',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColorsMinimal.textSecondary,
                            ),
                          ),
                          const Text(
                            '王小華',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColorsMinimal.textPrimary,
                            ),
                          ),
                          const Text(
                            ' 互相喜歡',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColorsMinimal.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 16,
                            color: AppColorsMinimal.error,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '95% 配對度',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColorsMinimal.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                const Text(
                  '現在可以開始聊天了！',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColorsMinimal.textSecondary,
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // 開始聊天按鈕
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColorsMinimal.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColorsMinimal.primary.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chat_bubble, size: 22, color: Colors.white),
                        const SizedBox(width: 12),
                        const Text(
                          '開始聊天',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 繼續尋找
                TextButton(
                  onPressed: () {},
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: AppColorsMinimal.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '繼續尋找配對',
                        style: TextStyle(
                          color: AppColorsMinimal.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColorsMinimal.primary,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColorsMinimal.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        Icons.person,
        size: 50,
        color: AppColorsMinimal.primary,
      ),
    );
  }
}
