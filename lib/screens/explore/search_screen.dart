import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/widgets/user_card.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final FocusNode _searchFocusNode = FocusNode();

  List<UserModel> _searchResults = [];
  List<String> _searchHistory = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_searchFocusNode);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _searchHistory = prefs.getStringList('search_history') ?? [];
      });
    } catch (e) {
      debugPrint('Error loading search history: $e');
    }
  }

  Future<void> _saveSearchHistory(String query) async {
    if (query.trim().isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('search_history') ?? [];

      // Remove if exists to push to top
      history.remove(query);
      history.insert(0, query);

      // Limit to 10 items
      if (history.length > 10) {
        history.removeLast();
      }

      await prefs.setStringList('search_history', history);
      setState(() {
        _searchHistory = history;
      });
    } catch (e) {
      debugPrint('Error saving search history: $e');
    }
  }

  Future<void> _clearSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('search_history');
      setState(() {
        _searchHistory = [];
      });
    } catch (e) {
      debugPrint('Error clearing search history: $e');
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await _firestoreService.searchUsersAdvanced(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
      _saveSearchHistory(query);
    } catch (e) {
      setState(() {
        _errorMessage = '搜尋失敗，請稍後再試';
        _isLoading = false;
      });
      debugPrint('Search error: $e');
    }
  }

  void _onSearchSubmitted(String value) {
    _performSearch(value);
  }

  void _onHistoryTap(String query) {
    _searchController.text = query;
    _performSearch(query);
  }

  void _removeHistoryItem(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('search_history') ?? [];
      history.remove(query);
      await prefs.setStringList('search_history', history);
      setState(() {
        _searchHistory = history;
      });
    } catch (e) {
      debugPrint('Error removing history item: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: '搜尋用戶名或興趣...',
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: theme.colorScheme.onSurface),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchResults = [];
                        _errorMessage = '';
                      });
                    },
                  )
                : null,
          ),
          style: theme.textTheme.bodyLarge,
          textInputAction: TextInputAction.search,
          onSubmitted: _onSearchSubmitted,
          onChanged: (value) {
            // Update state to show/hide clear button
            setState(() {
              if (value.isEmpty) {
                _searchResults = [];
              }
            });
          },
        ),
      ),
      body: _buildBody(theme, chinguTheme),
    );
  }

  Widget _buildBody(ThemeData theme, ChinguTheme? chinguTheme) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          _errorMessage,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      );
    }

    // Show History if no search results and search box is empty (or has focus but no results yet)
    // Actually, logic: if search controller is empty, show history.
    // If search controller is not empty and we have results, show results.
    // If search controller is not empty but no results (and not loading), show "No results".

    if (_searchController.text.isEmpty) {
      return _buildHistoryList(theme);
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '沒有找到相關用戶',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return _buildResultsGrid(theme);
  }

  Widget _buildHistoryList(ThemeData theme) {
    if (_searchHistory.isEmpty) {
      return Center(
        child: Text(
          '輸入關鍵字開始搜尋',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '搜尋歷史',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_searchHistory.isNotEmpty)
                TextButton(
                  onPressed: _clearSearchHistory,
                  child: Text(
                    '清除全部',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _searchHistory.length,
            itemBuilder: (context, index) {
              final query = _searchHistory[index];
              return ListTile(
                leading: Icon(
                  Icons.history,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                title: Text(query),
                trailing: IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  onPressed: () => _removeHistoryItem(query),
                ),
                onTap: () => _onHistoryTap(query),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultsGrid(ThemeData theme) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75, // Adjust to fit UserCard
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        // Reuse UserCard
        return LayoutBuilder(
          builder: (context, constraints) {
            // UserCard expects fixed width usually but in GridView it gets constraints.
            // We can wrap it in a container that takes available width.
            // But UserCard has `width` param.
            return UserCard(
              width: constraints.maxWidth,
              name: user.name,
              age: user.age,
              job: user.job,
              jobIcon: Icons.work, // Default icon since UserModel job is string
              color: theme.colorScheme.primary, // Or random color
              matchScore: 0, // No match score in search
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
  }
}
