import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:chingu/services/auth_service.dart';
import 'package:chingu/services/moment_service.dart';
import 'package:chingu/widgets/moment_card.dart';
import 'package:chingu/widgets/comment_bottom_sheet.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final MomentService _momentService = MomentService();
  final AuthService _authService = AuthService();
  List<MomentModel> _moments = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _authService.currentUser?.uid;
    _fetchMoments();
  }

  Future<void> _fetchMoments() async {
    if (_currentUserId == null) {
      // Handle guest or unauthenticated state appropriately
      setState(() => _isLoading = false);
      return;
    }

    try {
      final moments = await _momentService.getMoments(
        currentUserId: _currentUserId!,
      );
      if (mounted) {
        setState(() {
          _moments = moments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Show error snackbar?
      }
    }
  }

  void _handleLike(String momentId, bool isLiked) async {
    if (_currentUserId == null) return;
    try {
      // Optimistically update the local state
      setState(() {
        final index = _moments.indexWhere((m) => m.id == momentId);
        if (index != -1) {
          final moment = _moments[index];
          _moments[index] = moment.copyWith(
            isLiked: isLiked,
            likeCount: moment.likeCount + (isLiked ? 1 : -1),
          );
        }
      });

      await _momentService.toggleLike(momentId, _currentUserId!);
    } catch (e) {
      // Revert optimistic update on failure
      setState(() {
        final index = _moments.indexWhere((m) => m.id == momentId);
        if (index != -1) {
          final moment = _moments[index];
          _moments[index] = moment.copyWith(
            isLiked: !isLiked,
            likeCount: moment.likeCount + (!isLiked ? 1 : -1),
          );
        }
      });
    }
  }

  void _showComments(BuildContext context, MomentModel moment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => CommentBottomSheet(
          momentId: moment.id,
          commentsStream: _momentService.getCommentsStream(moment.id),
          onAddComment: (content) async {
             if (_currentUserId == null) return;
             final user = _authService.currentUser!;
             await _momentService.addComment(
               moment.id,
               _currentUserId!,
               content,
               user.displayName ?? 'User',
               user.photoURL,
             );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '探索',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchMoments,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar Placeholder
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: chinguTheme?.surfaceVariant ?? theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.dividerColor.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '搜尋感興趣的人、事、物...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Categories
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildCategoryChip(context, '全部', isSelected: true),
                    _buildCategoryChip(context, '美食'),
                    _buildCategoryChip(context, '運動'),
                    _buildCategoryChip(context, '學習'),
                    _buildCategoryChip(context, '娛樂'),
                    _buildCategoryChip(context, '戶外'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Section 1: Moments Feed (Replacing Trending)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '最新動態',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              if (_isLoading)
                 const Padding(
                   padding: EdgeInsets.all(32.0),
                   child: Center(child: CircularProgressIndicator()),
                 )
              else if (_moments.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(child: Text("尚無動態")),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _moments.length,
                  itemBuilder: (context, index) {
                    final moment = _moments[index];
                    return MomentCard(
                      moment: moment,
                      onLikeChanged: (isLiked) => _handleLike(moment.id, isLiked),
                      onCommentTap: () => _showComments(context, moment),
                    );
                  },
                ),

              const SizedBox(height: 24),

              // Section 2: Nearby
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '附近活動',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 280,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.dividerColor.withOpacity(0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1 + (index * 0.1)),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.event,
                                  size: 40,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '週末聚餐活動 #${index + 1}',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 14,
                                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '台北市信義區',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 80), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context, String label, {bool isSelected = false}) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : chinguTheme?.surfaceVariant ?? theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.dividerColor.withOpacity(0.5),
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : theme.colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
