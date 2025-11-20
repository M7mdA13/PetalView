import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // State Management
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
// ignore: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart'
    show Timestamp; // Only needed for helper type

// Import your Clean Architecture files
import 'data/community_repository.dart';
import 'logic/community_view_model.dart';

/* -------------------- HELPERS -------------------- */

String formatTimeAgo(Timestamp timestamp) {
  final now = DateTime.now();
  final date = timestamp.toDate();
  final diff = now.difference(date);

  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';

  return "${date.day}/${date.month}/${date.year}";
}

/* -------------------- MAIN SCREEN -------------------- */

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});
  static const routeName = 'Community';

  @override
  Widget build(BuildContext context) {
    // 1. INJECT DEPENDENCIES
    // We provide the ViewModel to the widget tree
    return ChangeNotifierProvider(
      create: (_) => CommunityViewModel(repository: CommunityRepository()),
      child: const _CommunityView(),
    );
  }
}

class _CommunityView extends StatefulWidget {
  const _CommunityView();

  @override
  State<_CommunityView> createState() => _CommunityViewState();
}

class _CommunityViewState extends State<_CommunityView> {
  final TextEditingController _composerCtrl = TextEditingController();
  String _search = '';
  File? _composerImage;

  Future<void> _pickComposerImage() async {
    final picker = ImagePicker();
    final XFile? img = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (img != null) setState(() => _composerImage = File(img.path));
  }

  // Connects UI event to ViewModel Logic
  Future<void> _submitPost(CommunityViewModel viewModel) async {
    final text = _composerCtrl.text.trim();
    if (text.isEmpty && _composerImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something or attach a photo')),
      );
      return;
    }

    // Call ViewModel
    final success = await viewModel.submitPost(text, _composerImage);

    if (success) {
      setState(() {
        _composerCtrl.clear();
        _composerImage = null;
      });
    } else if (mounted && viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openFiltersSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _FiltersSheet(
        onApply: (String tag) {
          Navigator.pop(context);
          setState(() => _search = tag == 'All' ? '' : tag);
        },
      ),
    );
  }

  void _openComments(BuildContext context, Post post) {
    // Pass the existing ViewModel to the bottom sheet
    final viewModel = context.read<CommunityViewModel>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        // Re-provide the VM to the sheet so it can listen/act
        return ChangeNotifierProvider.value(
          value: viewModel,
          child: _CommentsSheet(post: post),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to ViewModel changes
    final viewModel = context.watch<CommunityViewModel>();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/bg_welcome.png', fit: BoxFit.cover),
          Container(color: _CommunityStyle.mint.withOpacity(0.15)),
          SafeArea(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Image.asset('assets/onboarding/logo.png', height: 48),
                ),
                const SizedBox(height: 10),
                _SearchBar(
                  onChanged: (v) => setState(() => _search = v),
                  onOpenFilters: _openFiltersSheet,
                ),
                const SizedBox(height: 14),

                // COMPOSER (Uses ViewModel state)
                _Composer(
                  controller: _composerCtrl,
                  onPickImage: _pickComposerImage,
                  onPost: () => _submitPost(viewModel),
                  attachedImage: _composerImage,
                  isPosting: viewModel.isLoading,
                  userProfilePicUrl: viewModel.currentUserPic,
                ),
                const SizedBox(height: 12),

                // FEED (Stream from ViewModel)
                StreamBuilder<List<Post>>(
                  stream: viewModel.postsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(
                            color: _CommunityStyle.green,
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final posts = snapshot.data ?? [];
                    if (posts.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('No posts yet. Be the first!'),
                        ),
                      );
                    }

                    // Filter locally based on search
                    final filteredPosts = posts.where((p) {
                      if (_search.isEmpty) return true;
                      return p.tag.toLowerCase().contains(
                            _search.toLowerCase(),
                          ) ||
                          p.text.toLowerCase().contains(_search.toLowerCase());
                    }).toList();

                    return Column(
                      children: filteredPosts
                          .map(
                            (post) => _PostCard(
                              post: post,
                              currentUserId: viewModel.currentUserId,
                              onToggleLike: () =>
                                  viewModel.togglePostLike(post),
                              onComment: () => _openComments(context, post),
                              onShare: () => Share.share(post.text),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------- COMMENTS SHEET -------------------- */

class _CommentsSheet extends StatefulWidget {
  final Post post;
  const _CommentsSheet({required this.post});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CommunityViewModel>();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 4,
            width: 36,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Comments',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: StreamBuilder<List<Comment>>(
              stream: viewModel.getCommentsStream(widget.post.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data!;
                if (comments.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text("No comments yet."),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: comments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (ctx, i) {
                    final c = comments[i];
                    final isMe = c.authorId == viewModel.currentUserId;
                    final isLiked = c.likes.contains(viewModel.currentUserId);

                    return InkWell(
                      onLongPress: isMe
                          ? () => viewModel.deleteComment(widget.post.id, c.id)
                          : null,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: c.authorProfilePicUrl != null
                                ? CachedNetworkImageProvider(
                                    c.authorProfilePicUrl!,
                                  )
                                : null,
                            child: c.authorProfilePicUrl == null
                                ? const Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        c.authorName,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        formatTimeAgo(c.createdAt),
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    c.text,
                                    style: GoogleFonts.poppins(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(
                                iconSize: 18,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Icon(
                                  isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isLiked ? Colors.red : Colors.grey,
                                ),
                                onPressed: () => viewModel.toggleCommentLike(
                                  widget.post.id,
                                  c,
                                ),
                              ),
                              if (c.likesCount > 0)
                                Text(
                                  '${c.likesCount}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: const InputDecoration(
                    hintText: 'Write a comment…',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  final txt = _ctrl.text.trim();
                  if (txt.isNotEmpty) {
                    viewModel.addComment(widget.post.id, txt);
                    _ctrl.clear();
                    FocusScope.of(context).unfocus();
                  }
                },
                icon: const Icon(Icons.send, color: _CommunityStyle.green),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/* -------------------- WIDGETS (COMPOSER, CARDS, ETC) -------------------- */

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onPickImage,
    required this.onPost,
    this.attachedImage,
    this.userProfilePicUrl,
    this.isPosting = false,
  });

  final TextEditingController controller;
  final VoidCallback onPickImage;
  final VoidCallback onPost;
  final File? attachedImage;
  final String? userProfilePicUrl;
  final bool isPosting;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: _CommunityStyle.mintCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _CommunityStyle.mintBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                backgroundImage: userProfilePicUrl != null
                    ? CachedNetworkImageProvider(userProfilePicUrl!)
                    : null,
                child: userProfilePicUrl == null
                    ? const Icon(Icons.person, color: _CommunityStyle.green)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: "What’s on your mind?",
                    border: InputBorder.none,
                    hintStyle: GoogleFonts.poppins(color: Colors.black54),
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
              ),
              IconButton(
                onPressed: onPickImage,
                icon: const Icon(
                  Icons.image_rounded,
                  color: _CommunityStyle.green,
                ),
              ),
            ],
          ),
          if (attachedImage != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                attachedImage!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: isPosting ? null : onPost,
              style: FilledButton.styleFrom(
                backgroundColor: _CommunityStyle.green,
                foregroundColor: Colors.white,
              ),
              child: isPosting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Post'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.currentUserId,
    required this.onToggleLike,
    required this.onComment,
    required this.onShare,
  });

  final Post post;
  final String currentUserId;
  final VoidCallback onToggleLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final bool isLiked = post.likes.contains(currentUserId);
    Widget? img;
    if (post.imageUrl != null) {
      img = CachedNetworkImage(
        imageUrl: post.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (ctx, url) => const _ImageSkeleton(),
        errorWidget: (ctx, url, err) => const _ImageError(),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [_CommunityStyle.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFEFF6F1),
                backgroundImage: post.authorProfilePicUrl != null
                    ? CachedNetworkImageProvider(post.authorProfilePicUrl!)
                    : null,
                child: post.authorProfilePicUrl == null
                    ? const Icon(Icons.person, color: _CommunityStyle.green)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${formatTimeAgo(post.createdAt)} · ${post.tag}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_horiz, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            post.text,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 10),
          if (img != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(width: double.infinity, height: 220, child: img),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              InkWell(
                onTap: onToggleLike,
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: isLiked ? Colors.red : _CommunityStyle.green,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${post.likes.length}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              InkWell(
                onTap: onComment,
                child: Row(
                  children: [
                    const Icon(
                      Icons.mode_comment_outlined,
                      size: 20,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${post.commentCount}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              InkWell(
                onTap: onShare,
                child: Row(
                  children: const [
                    Icon(Icons.share_outlined, size: 20, color: Colors.black54),
                    SizedBox(width: 6),
                    Text(
                      'Share',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({this.onChanged, this.onOpenFilters});
  final ValueChanged<String>? onChanged;
  final VoidCallback? onOpenFilters;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [_CommunityStyle.cardShadow],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: GoogleFonts.poppins(color: Colors.black45),
                border: InputBorder.none,
              ),
            ),
          ),
          InkWell(
            onTap: onOpenFilters,
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: _CommunityStyle.green,
              child: Icon(Icons.tune_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet({required this.onApply});
  final ValueChanged<String> onApply;

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  final List<String> _tags = const [
    'All',
    'General',
    'Help',
    'Phenology',
    'Photos',
  ];
  String _selected = 'All';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 4,
              width: 36,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Filters',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _tags.map((t) {
              final sel = t == _selected;
              return ChoiceChip(
                label: Text(t),
                selected: sel,
                onSelected: (_) => setState(() => _selected = t),
                selectedColor: _CommunityStyle.mintCard,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => widget.onApply(_selected),
              style: FilledButton.styleFrom(
                backgroundColor: _CommunityStyle.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageSkeleton extends StatelessWidget {
  const _ImageSkeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _CommunityStyle.mintCard,
      child: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: _CommunityStyle.green,
          ),
        ),
      ),
    );
  }
}

class _ImageError extends StatelessWidget {
  const _ImageError();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _CommunityStyle.mintCard,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.broken_image_outlined,
            color: _CommunityStyle.green,
            size: 28,
          ),
          SizedBox(height: 6),
          Text(
            'Image unavailable',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CommunityStyle {
  static const mint = Color(0xFFE6F3EA);
  static const green = Color(0xFF2E7D32);
  static const cardShadow = BoxShadow(
    color: Colors.black12,
    blurRadius: 10,
    offset: Offset(0, 6),
  );
  static const mintCard = Color(0xFFDFF0E3);
  static const mintBorder = Color(0xFFB7E0C2);
}
