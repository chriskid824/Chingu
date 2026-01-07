import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';

class MatchingScreenDemo extends StatelessWidget {
  const MatchingScreenDemo({super.key});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
          color: theme.colorScheme.onSurface,
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.tune_rounded,
              color: theme.colorScheme.primary,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // 卡片堆疊
          Center(
            child: Container(
              height: 520,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Stack(
                children: [
                  _buildCard(
                    context,
                    '李小美',
                    26,
                    '設計師',
                    ['美食', '旅遊', '攝影'],
                    92,
                    offset: const Offset(8, 8),
                    opacity: 0.5,
                  ),
                  _buildCard(
                    context,
                    '王小華',
                    28,
                    '行銷專員',
                    ['咖啡', '電影', '音樂'],
                    88,
                    offset: const Offset(4, 4),
                    opacity: 0.7,
                  ),
                  _buildCard(
                    context,
                    '陳大明',
                    30,
                    '軟體工程師',
                    ['科技', '美食', '運動'],
                    95,
                    offset: Offset.zero,
                    opacity: 1.0,
                  ),
                ],
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
                  () {},
                ),
                const SizedBox(width: 20),
                _buildActionButton(
                  context,
                  Icons.star_rounded,
                  chinguTheme?.warning ?? Colors.amber,
                  () {},
                  size: 70,
                ),
                const SizedBox(width: 20),
                _buildActionButton(
                  context,
                  Icons.favorite_rounded,
                  chinguTheme?.success ?? Colors.green,
                  () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCard(
    BuildContext context,
    String name,
    int age,
    String job,
    List<String> interests,
    int matchScore, {
    required Offset offset,
    required double opacity,
  }) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Transform.translate(
      offset: offset,
      child: Opacity(
        opacity: opacity,
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: chinguTheme?.surfaceVariant ?? Colors.grey[200]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: chinguTheme?.shadowMedium ?? Colors.black12,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // 頭像區域
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: chinguTheme?.transparentGradient,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: chinguTheme?.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 70,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // 配對度標籤
                      Positioned(
                        top: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: chinguTheme?.successGradient,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: (chinguTheme?.success ?? Colors.green).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.favorite,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$matchScore%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // 資訊區域
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$name, $age',
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: chinguTheme?.success ?? Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.work_rounded,
                            size: 16,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            job,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: interests.asMap().entries.map((entry) {
                          final colors = [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                            chinguTheme?.success ?? Colors.green,
                          ];
                          final color = colors[entry.key % colors.length];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  color.withOpacity(0.15),
                                  color.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: color.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              entry.value,
                              style: TextStyle(
                                fontSize: 13,
                                color: color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    double size = 60,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.cardColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: size * 0.45),
        color: color,
        onPressed: onPressed,
      ),
    );
  }
}
