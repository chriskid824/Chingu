import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/widgets/empty_state.dart';
import 'package:chingu/widgets/user_card.dart';
import 'package:chingu/core/routes/app_router.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<UserModel> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final favoriteIds = authProvider.userModel?.favoriteIds ?? [];

    if (favoriteIds.isEmpty) {
      setState(() {
        _favorites = [];
        _isLoading = false;
      });
      return;
    }

    try {
      final users = await _firestoreService.getBatchUsers(favoriteIds);
      if (mounted) {
        setState(() {
          _favorites = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '我的收藏',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
      );
    }

    if (_favorites.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.favorite_border,
        title: '還沒有收藏的用戶',
        message: '在瀏覽時點擊愛心圖標收藏感興趣的用戶',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final user = _favorites[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.userDetail,
                  arguments: user,
                ).then((_) {
                  // Return from user detail might have changed favorite status
                  _loadFavorites();
                });
              },
              child: UserCard(
                name: user.name,
                age: user.age,
                job: user.job,
                jobIcon: Icons.work, // Default icon since it's not in UserModel
                imageUrl: user.avatarUrl,
                tags: user.interests.take(3).toList(),
                color: theme.colorScheme.surface,
              ),
            ),
          );
        },
      ),
    );
  }
}
