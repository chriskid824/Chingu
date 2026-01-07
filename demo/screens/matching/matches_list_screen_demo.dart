import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';

class MatchesListScreenDemo extends StatelessWidget {
  const MatchesListScreenDemo({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsMinimal.background,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.favorite_rounded,
              color: AppColorsMinimal.error,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              '我的配對',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColorsMinimal.textPrimary,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
          color: AppColorsMinimal.textPrimary,
        ),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColorsMinimal.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: AppColorsMinimal.textSecondary,
                indicator: BoxDecoration(
                  gradient: AppColorsMinimal.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: '💕 互相喜歡'),
                  Tab(text: '👍 我喜歡的'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildMatchesList(true),
                  _buildMatchesList(false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMatchesList(bool isMutual) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMatchCard('王小華', 28, '行銷專員', 92, isMutual),
        _buildMatchCard('李小美', 26, '設計師', 88, isMutual),
        _buildMatchCard('陳大明', 30, '軟體工程師', 95, isMutual),
        _buildMatchCard('林小芳', 27, '產品經理', 90, isMutual),
      ],
    );
  }
  
  Widget _buildMatchCard(String name, int age, String job, int matchScore, bool isMutual) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColorsMinimal.surfaceVariant),
        boxShadow: [
          BoxShadow(
            color: AppColorsMinimal.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 頭像
            Stack(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: AppColorsMinimal.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColorsMinimal.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            
            // 資訊
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$name, $age',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: AppColorsMinimal.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.work_rounded,
                        size: 14,
                        color: AppColorsMinimal.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        job,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColorsMinimal.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (isMutual)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColorsMinimal.error.withOpacity(0.2),
                            AppColorsMinimal.error.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 14,
                            color: AppColorsMinimal.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '互相喜歡',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColorsMinimal.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!isMutual)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColorsMinimal.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 14,
                            color: AppColorsMinimal.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$matchScore% 配對',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColorsMinimal.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            // 操作按鈕
            if (isMutual)
              Container(
                decoration: BoxDecoration(
                  gradient: AppColorsMinimal.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      const Text(
                        '聊天',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (!isMutual)
              IconButton(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: AppColorsMinimal.textTertiary,
                ),
                onPressed: () {},
              ),
          ],
        ),
      ),
    );
  }
}
