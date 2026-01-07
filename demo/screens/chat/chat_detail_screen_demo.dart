import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';

class ChatDetailScreenDemo extends StatelessWidget {
  const ChatDetailScreenDemo({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsMinimal.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppColorsMinimal.primaryGradient,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.person_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '王小華',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColorsMinimal.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColorsMinimal.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '線上',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColorsMinimal.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppColorsMinimal.background,
        foregroundColor: AppColorsMinimal.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.videocam_rounded, color: AppColorsMinimal.primary),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: AppColorsMinimal.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColorsMinimal.transparentGradient,
              ),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildDateDivider(context, '今天'),
                  _buildReceivedMessage(context, '嗨！很高興認識你', '10:15'),
                  _buildSentMessage(context, '你好！我也是', '10:16'),
                  _buildReceivedMessage(context, '你喜歡吃什麼類型的料理？', '10:17'),
                  _buildSentMessage(context, '我喜歡義式料理和日本料理', '10:18'),
                  _buildSentMessage(context, '你呢？', '10:18'),
                  _buildReceivedMessage(context, '我也喜歡！那我們可以約在信義區的義式餐廳', '10:20'),
                  _buildSentMessage(context, '好啊！星期五晚上七點可以嗎？', '10:25'),
                  _buildReceivedMessage(context, '好的，那我們晚上七點見！', '10:30'),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColorsMinimal.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColorsMinimal.shadowLight,
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.add_circle_outline_rounded, color: AppColorsMinimal.primary),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '輸入訊息...',
                      hintStyle: TextStyle(color: AppColorsMinimal.textTertiary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: AppColorsMinimal.surfaceVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: AppColorsMinimal.surfaceVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: AppColorsMinimal.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: AppColorsMinimal.background,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColorsMinimal.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColorsMinimal.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDateDivider(BuildContext context, String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppColorsMinimal.divider)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              date,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColorsMinimal.textTertiary,
              ),
            ),
          ),
          Expanded(child: Divider(color: AppColorsMinimal.divider)),
        ],
      ),
    );
  }
  
  Widget _buildReceivedMessage(BuildContext context, String message, String time) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, right: 50),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColorsMinimal.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: AppColorsMinimal.surfaceVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColorsMinimal.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColorsMinimal.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSentMessage(BuildContext context, String message, String time) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, left: 50),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: AppColorsMinimal.primaryGradient,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColorsMinimal.primary.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}





