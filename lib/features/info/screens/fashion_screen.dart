import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/providers/street_styles_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/auth_provider.dart';

class FashionScreen extends ConsumerWidget {
  const FashionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final styles = ref.watch(streetStylesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'STREET STYLE',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      body: styles.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.style_outlined,
                    color: theme.colorScheme.secondary.withValues(alpha: 0.5),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No style lookbooks posted yet.',
                    style: GoogleFonts.inter(
                      color: theme.colorScheme.secondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: styles.length,
              itemBuilder: (context, index) {
                final style = styles[index];
                return _StylePostCard(style: style);
              },
            ),
    );
  }
}

class _StylePostCard extends ConsumerStatefulWidget {
  final StreetStyle style;
  const _StylePostCard({required this.style});

  @override
  ConsumerState<_StylePostCard> createState() => _StylePostCardState();
}

class _StylePostCardState extends ConsumerState<_StylePostCard> {
  int _currentPage = 0;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _loadPersistedState();
  }

  Future<void> _loadPersistedState() async {
    try {
      final user = ref.read(currentUserProvider);
      final userId = user?.id ?? 'guest';
      final prefs = await SharedPreferences.getInstance();
      final bookmarkedKey = 'style_bookmarked_${userId}_${widget.style.id}';
      
      final isBookmarked = prefs.getBool(bookmarkedKey) ?? false;
      
      if (mounted) {
        setState(() {
          _isBookmarked = isBookmarked;
        });
      }
    } catch (_) {}
  }

  void _showCommentsSheet(BuildContext context) {
    final theme = Theme.of(context);
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final styles = ref.watch(streetStylesProvider);
            final currentStyleIndex = styles.indexWhere((s) => s.id == widget.style.id);
            final style = currentStyleIndex != -1 ? styles[currentStyleIndex] : widget.style;
            final comments = style.comments;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'COMMENTS (${comments.length})',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: comments.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Text(
                                'Be the first to comment...',
                                style: GoogleFonts.inter(
                                  color: theme.colorScheme.secondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final c = comments[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                      child: Text(
                                        c.username.isNotEmpty ? c.username.substring(0, 1).toUpperCase() : 'U',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c.username,
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            c.comment,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: theme.colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  Divider(color: theme.colorScheme.outline),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              hintStyle: TextStyle(
                                color: theme.colorScheme.secondary.withValues(alpha: 0.5),
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final text = commentController.text.trim();
                            if (text.isNotEmpty) {
                              commentController.clear();
                              await ref.read(streetStylesProvider.notifier).addComment(style.id, text);
                            }
                          },
                          child: Text(
                            'POST',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeAgo = _timeAgo(widget.style.createdAt);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.style.username.isNotEmpty
                        ? widget.style.username.replaceAll('@', '').substring(0, 1).toUpperCase()
                        : 'Z',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.style.username,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 11,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            widget.style.location,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.secondary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          // Image Gallery (PageView)
          if (widget.style.images.isNotEmpty)
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                AspectRatio(
                  aspectRatio: 0.85,
                  child: PageView.builder(
                    itemCount: widget.style.images.length,
                    onPageChanged: (page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemBuilder: (context, imgIndex) {
                      return CachedNetworkImage(
                        imageUrl: widget.style.images[imgIndex],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: theme.colorScheme.outline.withValues(alpha: 0.5),
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: theme.colorScheme.outline,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (widget.style.images.length > 1)
                  Positioned(
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          widget.style.images.length,
                          (dotIndex) => Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPage == dotIndex
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

          // Description & Actions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            widget.style.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: widget.style.isLiked ? AppColors.sale : theme.colorScheme.primary,
                            size: 22,
                          ),
                          onPressed: () {
                            ref.read(streetStylesProvider.notifier).likeStyle(widget.style.id);
                          },
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.style.likesCount}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(width: 18),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.mode_comment_outlined,
                            color: theme.colorScheme.primary,
                            size: 22,
                          ),
                          onPressed: () => _showCommentsSheet(context),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.style.comments.length}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: theme.colorScheme.primary,
                        size: 22,
                      ),
                      onPressed: () async {
                        setState(() {
                          _isBookmarked = !_isBookmarked;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_isBookmarked ? 'Style bookmarked!' : 'Bookmark removed.'),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        try {
                          final user = ref.read(currentUserProvider);
                          final userId = user?.id ?? 'guest';
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('style_bookmarked_${userId}_${widget.style.id}', _isBookmarked);
                        } catch (_) {}
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: theme.colorScheme.onSurface,
                    ),
                    children: [
                      TextSpan(
                        text: '${widget.style.username} ',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: widget.style.description,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays >= 7) {
      return DateFormat('MMM d, yyyy').format(dateTime);
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}
