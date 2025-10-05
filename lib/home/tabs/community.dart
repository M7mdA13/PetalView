import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  static const routeName = 'Community';

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  // THEME
  static const mint   = Color(0xFFE6F3EA);
  static const green  = Color(0xFF2E7D32);
  static const mintCard = Color(0xFFDFF0E3);
  static const mintBorder = Color(0xFFB7E0C2);
  static const cardShadow = BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0,6));

  // STATE
  final TextEditingController _composerCtrl = TextEditingController();
  final List<_Post> _posts = [];
  String _search = '';
  File? _composerImage;

  @override
  void initState() {
    super.initState();
    _seedDemoPosts(); // 10 بوست بصور أونلاين ثابتة
  }

  // ACTIONS
  Future<void> _pickComposerImage() async {
    final picker = ImagePicker();
    final XFile? img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null) setState(() => _composerImage = File(img.path));
  }

  void _submitPost() {
    final text = _composerCtrl.text.trim();
    if (text.isEmpty && _composerImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something or attach a photo')),
      );
      return;
    }
    setState(() {
      _posts.insert(
        0,
        _Post(
          name: 'You',
          tag: 'General',
          timeAgo: 'now',
          text: text,
          fileImage: _composerImage,
          likes: 0,
          comments: [],
        ),
      );
      _composerCtrl.clear();
      _composerImage = null;
    });
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() {});
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

  @override
  Widget build(BuildContext context) {
    final filteredPosts = _posts.where((p) {
      if (_search.isEmpty) return true;
      return p.tag.toLowerCase().contains(_search.toLowerCase()) ||
          p.text.toLowerCase().contains(_search.toLowerCase());
    }).toList();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/bg_welcome.png', fit: BoxFit.cover),
          Container(color: mint.withOpacity(0.15)),

          SafeArea(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Image.asset('assets/onboarding/logo.png', height: 48),
                  ),
                  const SizedBox(height: 10),

                  // SEARCH
                  _SearchBar(
                    onChanged: (v) => setState(() => _search = v),
                    onOpenFilters: _openFiltersSheet,
                  ),

                  const SizedBox(height: 14),

                  // COMPOSER
                  _Composer(
                    controller: _composerCtrl,
                    onPickImage: _pickComposerImage,
                    onPost: _submitPost,
                    attachedImage: _composerImage,
                  ),
                  const SizedBox(height: 12),

                  // FEED
                  for (final post in filteredPosts)
                    _PostCard(
                      post: post,
                      onToggleLike: () => setState(() => post.toggleLike()),
                      onComment: () => _openComments(post),
                      onShare: () => Share.share(post.text),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openComments(_Post post) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16, right: 16, top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4, width: 36, margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2)),
              ),
              Text('Comments', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: post.comments.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (_, i) => Text('• ${post.comments[i]}', style: GoogleFonts.poppins()),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: 'Write a comment…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final txt = controller.text.trim();
                      if (txt.isNotEmpty) {
                        setState(() => post.comments.add(txt));
                        controller.clear();
                      }
                    },
                    child: const Text('Send'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // ---------- Seed 10 posts (network images via Picsum) ----------
  void _seedDemoPosts() {
    _posts
      ..clear()
      ..addAll([
        _Post(
          name: 'Ahmed Khaled',
          tag: 'General',
          timeAgo: '1d',
          text: "Guys look what I found today!!",
          networkImageUrl: 'https://picsum.photos/seed/flower1/800/600',
          likes: 12,
          comments: ['Wow!', 'Where is this?'],
        ),
        _Post(
          name: 'Sofia N.',
          tag: 'Photos',
          timeAgo: '5h',
          text: "Jacaranda in full bloom 💜",
          networkImageUrl: 'https://picsum.photos/seed/flower2/800/600',
          likes: 31,
          comments: ['So pretty!', 'My favorite tree.'],
        ),
        _Post(
          name: 'Mahmoud A.',
          tag: 'Phenology',
          timeAgo: '2d',
          text: "First buds on the almond trees this season.",
          networkImageUrl: 'https://picsum.photos/seed/flower3/800/600',
          likes: 21,
          comments: ['Early this year!', 'Nice capture.'],
        ),
        _Post(
          name: 'Nora H.',
          tag: 'General',
          timeAgo: '3h',
          text: "Wild poppies by the roadside 🌺",
          networkImageUrl: 'https://picsum.photos/seed/flower4/800/600',
          likes: 18,
          comments: ['Love these!', 'Where was this?'],
        ),
        _Post(
          name: 'Omar E.',
          tag: 'Photos',
          timeAgo: '8h',
          text: "Morning dew on rose petals.",
          networkImageUrl: 'https://picsum.photos/seed/flower5/800/600',
          likes: 44,
          comments: ['Crisp shot!', 'Amazing details.'],
        ),
        _Post(
          name: 'Lina M.',
          tag: 'Help',
          timeAgo: '12h',
          text: "Can someone ID this purple shrub?",
          networkImageUrl: 'https://picsum.photos/seed/flower6/800/600',
          likes: 7,
          comments: ['Looks like lilac?', 'Maybe buddleia.'],
        ),
        _Post(
          name: 'Hassan R.',
          tag: 'General',
          timeAgo: '4d',
          text: "Sunflowers tracking the sun ☀️🌻",
          networkImageUrl: 'https://picsum.photos/seed/flower7/800/600',
          likes: 52,
          comments: ['Iconic!', 'So bright!'],
        ),
        _Post(
          name: 'Farah T.',
          tag: 'Photos',
          timeAgo: '1d',
          text: "Bougainvillea on an old wall.",
          networkImageUrl: 'https://picsum.photos/seed/flower8/800/600',
          likes: 23,
          comments: ['Mediterranean vibes!', 'Lovely color.'],
        ),
        _Post(
          name: 'Youssef K.',
          tag: 'Phenology',
          timeAgo: '2h',
          text: "Acacia starting to bloom—earlier than last year.",
          networkImageUrl: 'https://picsum.photos/seed/flower9/800/600',
          likes: 14,
          comments: ['Interesting shift.', 'Logging this!'],
        ),
        _Post(
          name: 'Maya S.',
          tag: 'Photos',
          timeAgo: '6h',
          text: "Cherry blossoms downtown 🌸",
          networkImageUrl: 'https://picsum.photos/seed/flower10/800/600',
          likes: 36,
          comments: ['Sakura season!', 'So soft.'],
        ),
      ]);
  }
}

/* ---------- MODELS ---------- */

class _Post {
  _Post({
    required this.name,
    required this.tag,
    required this.timeAgo,
    required this.text,
    this.assetImage,
    this.fileImage,
    this.networkImageUrl,
    this.likes = 0,
    this.comments = const [],
  });

  String name;
  String tag;
  String timeAgo;
  String text;

  // image sources
  String? assetImage;       // bundled demo images
  File? fileImage;          // composed images
  String? networkImageUrl;  // online images

  int likes;
  bool liked = false;
  List<String> comments;

  void toggleLike() {
    liked = !liked;
    likes += liked ? 1 : -1;
  }
}

/* ---------- WIDGETS (look & feel) ---------- */

class _SearchBar extends StatelessWidget {
  const _SearchBar({this.onChanged, this.onOpenFilters});
  final ValueChanged<String>? onChanged;
  final VoidCallback? onOpenFilters;

  static const green = Color(0xFF2E7D32);

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
              backgroundColor: green,
              child: Icon(Icons.tune_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReelCardAdd extends StatelessWidget {
  const _ReelCardAdd();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: _CommunityStyle.mintCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [_CommunityStyle.cardShadow],
        border: Border.all(color: _CommunityStyle.mintBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reels coming soon ✨')),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(backgroundColor: Colors.white, radius: 20, child: Icon(Icons.add, color: Color(0xFF2E7D32))),
            const SizedBox(height: 8),
            Text('Add Reel', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF2E7D32))),
          ],
        ),
      ),
    );
  }
}

class _ReelCardEmpty extends StatelessWidget {
  const _ReelCardEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: _CommunityStyle.mintCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [_CommunityStyle.cardShadow],
        border: Border.all(color: _CommunityStyle.mintBorder),
      ),
      child: Center(
        child: Text(
          'No reels yet.\nBe the first to share!',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(color: const Color(0xFF2E7D32), fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onPickImage,
    required this.onPost,
    this.attachedImage,
  });

  final TextEditingController controller;
  final VoidCallback onPickImage;
  final VoidCallback onPost;
  final File? attachedImage;

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
              const CircleAvatar(backgroundColor: Colors.white, radius: 18, child: Icon(Icons.person, color: Color(0xFF2E7D32))),
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
              IconButton(onPressed: onPickImage, icon: const Icon(Icons.image_rounded, color: Color(0xFF2E7D32))),
            ],
          ),
          if (attachedImage != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(attachedImage!, height: 160, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: onPost,
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
              child: const Text('Post'),
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
    required this.onToggleLike,
    required this.onComment,
    required this.onShare,
  });

  final _Post post;
  final VoidCallback onToggleLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  static const green = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    // اختيار مصدر الصورة حسب الأولوية (file -> network -> asset)
    Widget? img;
    if (post.fileImage != null) {
      img = Image.file(post.fileImage!, fit: BoxFit.cover);
    } else if (post.networkImageUrl != null) {
      img = CachedNetworkImage(
        imageUrl: post.networkImageUrl!,
        fit: BoxFit.cover,
        placeholder: (ctx, url) => const _ImageSkeleton(),
        errorWidget: (ctx, url, err) => const _ImageError(),
      );
    } else if (post.assetImage != null) {
      img = Image.asset(post.assetImage!, fit: BoxFit.cover);
    } else {
      img = null;
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: const [_CommunityStyle.cardShadow]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(backgroundColor: Color(0xFFEFF6F1), child: Icon(Icons.person, color: green)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(post.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.black87)),
                  Text('${post.tag} · ${post.timeAgo}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
                ]),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz, color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 6),
          Text(post.text, style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87)),
          const SizedBox(height: 10),

          if (img != null)
            ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: double.infinity, height: 220, child: img)),

          const SizedBox(height: 10),
          Row(
            children: [
              InkWell(
                onTap: onToggleLike,
                child: Row(children: [
                  Icon(post.liked ? Icons.favorite : Icons.favorite_border, size: 20, color: green),
                  const SizedBox(width: 6),
                  Text('${post.likes}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
                ]),
              ),
              const SizedBox(width: 18),
              InkWell(
                onTap: onComment,
                child: Row(children: [
                  const Icon(Icons.mode_comment_outlined, size: 20, color: Colors.black54),
                  const SizedBox(width: 6),
                  Text('${post.comments.length}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
                ]),
              ),
              const SizedBox(width: 18),
              InkWell(
                onTap: onShare,
                child: Row(children: const [
                  Icon(Icons.share_outlined, size: 20, color: Colors.black54),
                  SizedBox(width: 6),
                  Text('Share', style: TextStyle(fontSize: 12, color: Colors.black54)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Placeholders للتحميل/الخطأ بنفس الثيم
class _ImageSkeleton extends StatelessWidget {
  const _ImageSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _CommunityStyle.mintCard,
      child: const Center(
        child: SizedBox(
          width: 28, height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.4, color: Color(0xFF2E7D32)),
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
          Icon(Icons.broken_image_outlined, color: Color(0xFF2E7D32), size: 28),
          SizedBox(height: 6),
          Text('Image unavailable', style: TextStyle(color: Colors.black54, fontSize: 12)),
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
  final List<String> _tags = const ['All', 'General', 'Help', 'Phenology', 'Photos'];
  String _selected = 'All';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(height: 4, width: 36, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 12),
        Text('Filters', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
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
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
            child: const Text('Apply'),
          ),
        ),
      ]),
    );
  }
}

/// shared style constants
class _CommunityStyle {
  static const cardShadow = BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0,6));
  static const mintCard = Color(0xFFDFF0E3);
  static const mintBorder = Color(0xFFB7E0C2);
}
