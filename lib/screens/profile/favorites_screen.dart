import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/widgets/user_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<UserModel>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _refreshFavorites();
  }

  void _refreshFavorites() {
    final userId = context.read<AuthProvider>().uid;
    if (userId != null) {
      _favoritesFuture = FirestoreService().getFavoriteUsers(userId);
    } else {
      _favoritesFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('我的收藏'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('載入失敗: ${snapshot.error}'),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _refreshFavorites();
                      });
                    },
                    child: const Text('重試'),
                  ),
                ],
              ),
            );
          }

          final favorites = snapshot.data ?? [];

          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 64,
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '還沒有收藏任何用戶',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final user = favorites[index];
              return LayoutBuilder(
                builder: (context, constraints) {
                  return UserCard(
                    width: constraints.maxWidth,
                    name: user.name,
                    age: user.age,
                    job: user.job.isNotEmpty ? user.job : '未填寫',
                    jobIcon: Icons.work_outline_rounded,
                    color: theme.colorScheme.primary,
                    matchScore: 0, // In favorites list, match score might not be relevant or available without calculation
                    onTap: () async {
                      await Navigator.pushNamed(
                        context,
                        AppRoutes.userDetail,
                        arguments: user,
                      );
                      // Refresh list when returning, in case user removed favorite
                      setState(() {
                        _refreshFavorites();
                      });
                    },
                  );
                }
              );
            },
          );
        },
      ),
    );
  }
}
