import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import '../../widgets/gradient_header.dart';

class ProfileDetailScreenDemo extends StatelessWidget {
  const ProfileDetailScreenDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 頂部個人資料卡片
            GradientHeader(
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '張小明, 28',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.work_outline_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text(
                            '產品經理 @ Tech Corp',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            
            // 詳細資料
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, '關於我'),
                  const SizedBox(height: 12),
                  Text(
                    '熱愛美食和旅遊，喜歡在週末探索新的餐廳。希望能找到志同道合的朋友一起享受美食！',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  _buildSectionTitle(context, '興趣'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildInterestChip(context, '美食', Icons.restaurant),
                      _buildInterestChip(context, '旅遊', Icons.flight),
                      _buildInterestChip(context, '攝影', Icons.camera_alt),
                      _buildInterestChip(context, '電影', Icons.movie),
                      _buildInterestChip(context, '咖啡', Icons.coffee),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  _buildSectionTitle(context, '基本資料'),
                  const SizedBox(height: 12),
                  _buildInfoRow(context, Icons.location_on_outlined, '居住地', '台北市'),
                  _buildInfoRow(context, Icons.school_outlined, '學歷', '台灣大學'),
                  _buildInfoRow(context, Icons.height, '身高', '178 cm'),
                  _buildInfoRow(context, Icons.wine_bar_outlined, '飲酒', '偶爾小酌'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInterestChip(BuildContext context, String label, IconData icon) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: chinguTheme?.surfaceVariant ?? Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: chinguTheme?.shadowLight ?? Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall,
              ),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
