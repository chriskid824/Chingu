import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';

class MatchesListScreen extends StatelessWidget {
  const MatchesListScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.favorite_rounded,
              color: chinguTheme?.error ?? Colors.red,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '我的配對',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
          color: theme.colorScheme.onSurface,
        ),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
                indicator: BoxDecoration(
                  gradient: chinguTheme?.primaryGradient,
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
                  _buildMatchesList(context, true, theme, chinguTheme),
                  _buildMatchesList(context, false, theme, chinguTheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMatchesList(BuildContext context, bool isMutual, ThemeData theme, ChinguTheme? chinguTheme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMatchCard(context, '王小華', 28, '行銷專員', 92, isMutual, theme, chinguTheme),
        _buildMatchCard(context, '李小美', 26, '設計師', 88, isMutual, theme, chinguTheme),
        _buildMatchCard(context, '陳大明', 30, '軟體工程師', 95, isMutual, theme, chinguTheme),
        _buildMatchCard(context, '林小芳', 27, '產品經理', 90, isMutual, theme, chinguTheme),
      ],
    );
  }
  
  Widget _buildMatchCard(BuildContext context, String name, int age, String job, int matchScore, bool isMutual, ThemeData theme, ChinguTheme? chinguTheme) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed(AppRoutes.userDetail);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: chinguTheme?.surfaceVariant ?? theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: chinguTheme?.shadowLight ?? Colors.black12,
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
                    gradient: chinguTheme?.primaryGradient,
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
                      color: chinguTheme?.success ?? Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2), // Careful: White border on avatar check icon
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
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.work_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        job,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
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
                            (chinguTheme?.error ?? Colors.red).withOpacity(0.2),
                            (chinguTheme?.error ?? Colors.red).withOpacity(0.1),
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
                            color: chinguTheme?.error ?? Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '互相喜歡',
                            style: TextStyle(
                              fontSize: 12,
                              color: chinguTheme?.error ?? Colors.red,
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
                        color: theme.scaffoldBackgroundColor, // Using darker color for contrast
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$matchScore% 配對',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.primary,
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
                  gradient: chinguTheme?.primaryGradient,
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
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
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                onPressed: () {},
              ),
          ],
        ),
        ),
      ),
    );
  }
}
