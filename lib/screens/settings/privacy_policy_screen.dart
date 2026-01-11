import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('隱私權政策', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '隱私權政策',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '生效日期：2025年1月1日',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              context,
              '1. 引言',
              '歡迎使用 Chingu（以下簡稱「我們」或「本應用程式」）。我們非常重視您的隱私權，並致力於保護您的個人資料。本隱私權政策旨在說明我們如何收集、使用、披露及保護您的資訊。',
            ),

            _buildSection(
              context,
              '2. 我們收集的資訊',
              '為了提供更好的服務，我們可能會收集以下類型的資訊：\n\n'
              '• 帳號資訊：註冊時提供的姓名、電子郵件、出生日期等。\n'
              '• 個人檔案：您上傳的照片、興趣標籤、自我介紹。\n'
              '• 位置資訊：若您授權，我們會收集您的地理位置以提供附近的配對和活動建議。\n'
              '• 使用數據：您在本應用程式內的互動記錄、配對歷史、參加活動記錄等。\n'
              '• 裝置資訊：您的裝置型號、操作系統版本、唯一裝置識別碼。',
            ),

            _buildSection(
              context,
              '3. 資訊的使用方式',
              '我們將收集的資訊用於以下用途：\n\n'
              '• 提供、維護和改善我們的服務。\n'
              '• 處理您的帳號註冊和身份驗證。\n'
              '• 為您推薦合適的配對對象和晚餐活動。\n'
              '• 發送服務通知、更新和促銷訊息。\n'
              '• 監測和分析使用趨勢，以優化用戶體驗。\n'
              '• 偵測、預防和解決技術問題或詐欺行為。',
            ),

            _buildSection(
              context,
              '4. 資訊的分享與披露',
              '除非經您同意或法律要求，我們不會將您的個人資訊出售給第三方。但在以下情況下，我們可能會分享您的資訊：\n\n'
              '• 服務供應商：協助我們營運服務的第三方（如雲端託管、數據分析）。\n'
              '• 法律要求：為了遵守法律義務、法院命令或政府機關的要求。\n'
              '• 保護權利：為了保護我們或用戶的權利、財產或安全。',
            ),

            _buildSection(
              context,
              '5. 資料安全',
              '我們採取合理的技術和組織措施來保護您的個人資料，防止未經授權的存取、使用或披露。然而，請注意，沒有任何網路傳輸或電子儲存方式是 100% 安全的。',
            ),

            _buildSection(
              context,
              '6. 您的權利',
              '根據適用法律，您可能擁有以下權利：\n\n'
              '• 存取、更正或刪除您的個人資料。\n'
              '• 限制或反對我們處理您的資料。\n'
              '• 隨時撤回您的同意。\n'
              '您可以透過應用程式內的設定或聯絡我們的客服團隊來行使這些權利。',
            ),

             _buildSection(
              context,
              '7. 兒童隱私',
              '本服務不適用於未滿 18 歲的兒童。我們不會故意收集未滿 18 歲兒童的個人資訊。',
            ),

            _buildSection(
              context,
              '8. 政策變更',
              '我們可能會不時更新本隱私權政策。重大變更時，我們將透過應用程式通知您。繼續使用本服務即表示您同意受修訂後的政策約束。',
            ),

            _buildSection(
              context,
              '9. 聯絡我們',
              '如果您對本隱私權政策有任何疑問，請聯繫我們：support@chingu.app',
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
