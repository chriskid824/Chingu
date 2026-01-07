import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('編輯個人資料', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {},
            child: Text('儲存', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar Section
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
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
                    child: const Icon(Icons.person_rounded, size: 60, color: Colors.white),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: chinguTheme?.success ?? Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: (chinguTheme?.success ?? Colors.green).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '點擊相機圖標更換照片',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Basic Info Section
            _buildSectionTitle(context, '📝 基本資料', theme.colorScheme.primary),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: '張小明',
              decoration: InputDecoration(
                labelText: '姓名',
                hintText: '請輸入您的姓名',
                prefixIcon: Icon(Icons.person_outline, color: theme.colorScheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.colorScheme.outline),
                ),
                filled: true,
                fillColor: theme.cardColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: '28',
                    decoration: InputDecoration(
                      labelText: '年齡',
                      hintText: '年齡',
                      prefixIcon: Icon(Icons.cake_outlined, color: theme.colorScheme.secondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: theme.colorScheme.outline),
                      ),
                      filled: true,
                      fillColor: theme.cardColor,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: 'male',
                    decoration: InputDecoration(
                      labelText: '性別',
                      prefixIcon: Icon(Icons.male, color: theme.colorScheme.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: theme.colorScheme.outline),
                      ),
                      filled: true,
                      fillColor: theme.cardColor,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('男性')),
                      DropdownMenuItem(value: 'female', child: Text('女性')),
                    ],
                    onChanged: (v) {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Career Section
            _buildSectionTitle(context, '💼 職業資訊', theme.colorScheme.secondary),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: '軟體工程師',
              decoration: InputDecoration(
                labelText: '職業',
                hintText: '您的職業',
                prefixIcon: Icon(Icons.work_outline, color: chinguTheme?.warning ?? Colors.orange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.colorScheme.outline),
                ),
                filled: true,
                fillColor: theme.cardColor,
              ),
            ),
            const SizedBox(height: 24),
            
            // Location Section
            _buildSectionTitle(context, '📍 地點資訊', chinguTheme?.success ?? Colors.green),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: '台北市',
              decoration: InputDecoration(
                labelText: '城市',
                hintText: '您所在的城市',
                prefixIcon: Icon(Icons.location_city_outlined, color: chinguTheme?.success ?? Colors.green),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.colorScheme.outline),
                ),
                filled: true,
                fillColor: theme.cardColor,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: '信義區',
              decoration: InputDecoration(
                labelText: '地區',
                hintText: '您所在的地區',
                prefixIcon: Icon(Icons.place_outlined, color: chinguTheme?.success ?? Colors.green),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.colorScheme.outline),
                ),
                filled: true,
                fillColor: theme.cardColor,
              ),
            ),
            const SizedBox(height: 24),
            
            // About Me Section
            _buildSectionTitle(context, '✨ 關於我', theme.colorScheme.primary),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                gradient: chinguTheme?.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(2),
              child: TextFormField(
                maxLines: 4,
                initialValue: '喜歡美食、旅遊和攝影。希望能認識志同道合的朋友，一起探索台北的各種美食餐廳！',
                decoration: InputDecoration(
                  labelText: '自我介紹',
                  hintText: '分享一些關於您的事情...',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 60),
                    child: Icon(Icons.edit_note_rounded, color: Colors.white),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Save Button
            Container(
              decoration: BoxDecoration(
                gradient: chinguTheme?.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                label: const Text('儲存變更', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(BuildContext context, String title, Color color) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
