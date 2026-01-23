import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/favorites_service.dart';
import 'package:chingu/widgets/user_card.dart';
import 'package:chingu/core/routes/app_router.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  late Future<List<UserModel>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    final user = context.read<AuthProvider>().userModel;
    if (user != null) {
      _favoritesFuture = _favoritesService.getFavoriteUsers(user.uid);
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
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
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
                  Icon(Icons.error_outline_rounded, size: 64, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text('載入失敗: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _loadFavorites();
                      });
                    },
                    child: const Text('重試'),
                  ),
                ],
              ),
            );
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 80,
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '還沒有收藏的用戶',
                    style: TextStyle(
                      fontSize: 18,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '在配對或探索頁面遇到感興趣的人，\n可以點擊收藏按鈕將其加入此列表',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _loadFavorites();
              });
              await _favoritesFuture;
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return UserCard(
                  name: user.name,
                  age: user.age,
                  job: user.job,
                  jobIcon: Icons.work_outline_rounded, // 簡單起見使用固定圖標，實際可根據 job 判斷
                  color: _getGenderColor(user.gender),
                  // 如果有配對分數邏輯可在此添加
                  onTap: () async {
                    await Navigator.pushNamed(
                      context,
                      AppRoutes.userDetail,
                      arguments: user,
                    );
                    // 返回後刷新列表，以防用戶取消收藏
                    setState(() {
                      _loadFavorites();
                    });
                  },
                  width: double.infinity, // GridView 會控制寬度
                );
              },
            ),
          );
        },
      ),
    );
  }

  Color _getGenderColor(String gender) {
    if (gender == 'male') {
      return Colors.blue;
    } else if (gender == 'female') {
      return Colors.pink;
    }
    return Colors.purple;
  }
}
