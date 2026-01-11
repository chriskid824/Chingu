import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('服務條款', style: TextStyle(fontWeight: FontWeight.bold)),
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
              '服務條款',
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
              '1. 同意條款',
              '歡迎使用 Chingu。當您存取或使用本應用程式時，即表示您已閱讀、理解並同意受本服務條款（以下簡稱「本條款」）的約束。如果您不同意本條款的任何部分，請勿使用本服務。',
            ),

            _buildSection(
              context,
              '2. 資格',
              '您必須年滿 18 歲才能使用本服務。透過使用本服務，您聲明並保證您具有簽訂本協議的權利、權限和能力，並遵守本條款的所有規定。',
            ),

            _buildSection(
              context,
              '3. 帳號註冊與安全',
              '為了使用某些功能，您需要註冊帳號。您同意提供準確、完整且最新的資訊。您有責任維護您帳號密碼的機密性，並對您帳號下的所有活動負責。若發現任何未經授權的使用，請立即通知我們。',
            ),

            _buildSection(
              context,
              '4. 用戶行為規範',
              '您同意在使用本服務時不會：\n\n'
              '• 發布違法、有害、威脅、辱罵、騷擾、誹謗、淫穢或令人反感的內容。\n'
              '• 冒充任何人或實體，或虛假陳述您與任何人或實體的關係。\n'
              '• 干擾或破壞本服務或與本服務連接的伺服器或網路。\n'
              '• 騷擾、跟蹤或傷害其他用戶。\n'
              '• 未經同意收集其他用戶的個人資訊。\n'
              '• 從事任何商業用途，除非經我們明確授權。',
            ),

            _buildSection(
              context,
              '5. 內容所有權與授權',
              '您保留您在 Chingu 上發布內容的所有權。但透過發布內容，您授予我們非獨家、可轉讓、可分許可、免版稅的全球許可，以使用、複製、修改、分發、公開展示該內容，用於營運和推廣本服務。',
            ),

            _buildSection(
              context,
              '6. 安全互動',
              'Chingu 致力於提供安全的社交環境，但我們無法完全控制用戶的行為。您同意在與其他用戶互動（無論是線上還是線下）時保持謹慎。我們不對用戶之間的爭議負責。',
            ),

            _buildSection(
              context,
              '7. 服務變更與終止',
              '我們保留隨時修改、暫停或終止本服務（或其任何部分）的權利，恕不另行通知。如果我們認為您違反了本條款，我們有權暫停或終止您的帳號。',
            ),

            _buildSection(
              context,
              '8. 免責聲明',
              '本服務按「現狀」和「現有」基礎提供，不附帶任何形式的保證。我們不保證服務將不中斷、安全或無錯誤。',
            ),

            _buildSection(
              context,
              '9. 責任限制',
              '在法律允許的最大範圍內，Chingu 不對任何間接、附帶、特殊、後果性或懲罰性損害負責，包括但不限於利潤損失、數據丟失或商譽損害。',
            ),

            _buildSection(
              context,
              '10. 聯絡我們',
              '如果您對本服務條款有任何疑問，請聯繫我們：support@chingu.app',
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
