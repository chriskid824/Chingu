import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/providers/auth_provider.dart';

class MatchesListScreen extends StatefulWidget {
  const MatchesListScreen({super.key});

  @override
  State<MatchesListScreen> createState() => _MatchesListScreenState();
}

class _MatchesListScreenState extends State<MatchesListScreen> {
  late Future<List<UserModel>> _matchesFuture;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  void _loadMatches() {
    final user = context.read<AuthProvider>().userModel;
    // Use user city or default if not set
    final city = user?.city.isNotEmpty == true ? user!.city : '台北市';

    _matchesFuture = _firestoreService.queryMatchingUsers(
      city: city,
      limit: 20, // Fetch enough to populate lists
    );
  }

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
      body: FutureBuilder<List<UserModel>>(
        future: _matchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allMatches = snapshot.data ?? [];

          // Split matches for demo purposes (e.g., first half mutual, second half liked)
          // In a real app, these would come from different queries or filtered lists.
          final mid = (allMatches.length / 2).ceil();
          final mutualMatches = allMatches.take(mid).toList();
          final likedMatches = allMatches.skip(mid).toList();

          return DefaultTabController(
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
                      _buildMatchesList(context, mutualMatches, true, theme, chinguTheme),
                      _buildMatchesList(context, likedMatches, false, theme, chinguTheme),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMatchesList(
      BuildContext context, List<UserModel> matches, bool isMutual, ThemeData theme, ChinguTheme? chinguTheme) {
    if (matches.isEmpty) {
      return _buildEmptyState(context, theme, chinguTheme);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final user = matches[index];
        // Calculate a mock score based on hash if needed, or use a field if available
        final score = 80 + (user.name.hashCode % 20);

        return _buildMatchCard(
          context,
          user,
          score,
          isMutual,
          theme,
          chinguTheme,
        );
      },
    );
  }
  
  Widget _buildEmptyState(BuildContext context, ThemeData theme, ChinguTheme? chinguTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_search_rounded,
              size: 64,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '尋找新朋友',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '去發現頁尋找更多朋友吧',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              gradient: chinguTheme?.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (chinguTheme?.primary ?? theme.colorScheme.primary).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.mainNavigation,
                  (route) => false,
                  arguments: {'initialIndex': 1},
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.explore_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    '去發現',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, UserModel user, int matchScore, bool isMutual, ThemeData theme, ChinguTheme? chinguTheme) {
    return InkWell(
      onTap: () {
        // Pass the REAL user model
        Navigator.of(context).pushNamed(
          AppRoutes.userDetail,
          arguments: user,
        );
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
                  child: user.avatarUrl != null
                    ? ClipOval(
                        child: Image.network(
                          user.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : const Icon(
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
                    '${user.name}, ${user.age}',
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
                        user.job,
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
                        color: theme.scaffoldBackgroundColor,
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
