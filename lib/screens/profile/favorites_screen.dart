import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/widgets/user_card.dart';
import 'package:chingu/core/routes/app_router.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('我的收藏'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final favoriteIds = authProvider.userModel?.favoriteIds ?? [];

          if (favoriteIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border_rounded, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '還沒有收藏任何用戶',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return FutureBuilder<List<UserModel>>(
            future: _firestoreService.getBatchUsers(favoriteIds),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('載入失敗: ${snapshot.error}'));
              }

              final users = snapshot.data ?? [];

              if (users.isEmpty) {
                return const Center(child: Text('找不到收藏的用戶'));
              }

              return GridView.builder(
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
                    jobIcon: Icons.work_outline_rounded,
                    color: _getColorForUser(user, theme),
                    matchScore: 0,
                    width: double.infinity,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.userDetail,
                        arguments: user,
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Color _getColorForUser(UserModel user, ThemeData theme) {
    final colors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    // 使用 uid 的 hash code 來決定顏色，保證同一個用戶顏色固定
    return colors[user.uid.hashCode.abs() % colors.length];
  }
}
