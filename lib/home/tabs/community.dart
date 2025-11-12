import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';

// <-- NEW: Import all the Firebase packages
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

// <-- NEW: A proper Post model that matches our Firestore data
class Post {
  final String id; // Document ID
  final String authorId;
  final String authorName;
  final String? authorProfilePicUrl;
  final String text;
  final String? imageUrl;
  final String tag;
  final Timestamp createdAt;
  final List<String> likes; // A list of UIDs who liked the post

  Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorProfilePicUrl,
    required this.text,
    this.imageUrl,
    required this.tag,
    required this.createdAt,
    required this.likes,
  });

  // Factory constructor to create a Post from a Firestore document
  factory Post.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'User',
      authorProfilePicUrl: data['authorProfilePicUrl'],
      text: data['text'] ?? '',
      imageUrl: data['imageUrl'],
      tag: data['tag'] ?? 'General',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      likes: List<String>.from(data['likes'] ?? []),
    );
  }
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  static const routeName = 'Community';

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  // THEME
  static const mint = Color(0xFFE6F3EA);
  static const green = Color(0xFF2E7D32);
  static const mintCard = Color(0xFFDFF0E3);
  static const mintBorder = Color(0xFFB7E0C2);
  static const cardShadow =
      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6));

  // STATE
  final TextEditingController _composerCtrl = TextEditingController();
  String _search = '';
  File? _composerImage;

  // <-- NEW: State variables for loading and current user info
  bool _isLoadingPost = false;
  String? _currentUserFirstName;
  String? _currentUserProfilePicUrl;

  // <-- NEW: Get the current user's UID
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    // <-- NEW: Load user data for posting, remove _seedDemoPosts()
    _loadCurrentUserData();
  }

  // <-- NEW: Fetch the logged-in user's name and pic for new posts
  Future<void> _loadCurrentUserData() async {
    if (_currentUserId.isEmpty) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _currentUserFirstName = data['firstName'];
          _currentUserProfilePicUrl = data['profilePicUrl'];
        });
      }
    } catch (e) {
      print("Error loading user data for community: $e");
    }
  }

  // ACTIONS
  Future<void> _pickComposerImage() async {
    final picker = ImagePicker();
    final XFile? img =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null) setState(() => _composerImage = File(img.path));
  }

  // <-- CHANGED: This is now async and saves to Firebase
  Future<void> _submitPost() async {
    final text = _composerCtrl.text.trim();
    if (text.isEmpty && _composerImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something or attach a photo')),
      );
      return;
    }
    if (_isLoadingPost) return;

    setState(() => _isLoadingPost = true);

    try {
      String? imageUrl;

      // 1. Upload image to Firebase Storage (if one exists)
      if (_composerImage != null) {
        // Create a unique file name
        final imageId = DateTime.now().millisecondsSinceEpoch.toString();
        final ref = FirebaseStorage.instance
            .ref()
            .child('post_images')
            .child('$imageId.jpg');

        await ref.putFile(_composerImage!);
        imageUrl = await ref.getDownloadURL();
      }

      // 2. Create the post document in Firestore
      await FirebaseFirestore.instance.collection('posts').add({
        'authorId': _currentUserId,
        'authorName': _currentUserFirstName ?? 'A User',
        'authorProfilePicUrl': _currentUserProfilePicUrl,
        'text': text,
        'imageUrl': imageUrl,
        'tag': 'General', // TODO: You can add a tag selector later
        'createdAt': Timestamp.now(),
        'likes': [], // Starts with no likes
      });

      // 3. Clear the composer
      setState(() {
        _composerCtrl.clear();
        _composerImage = null;
        _isLoadingPost = false;
      });
    } catch (e) {
      print("Error posting: $e");
      setState(() => _isLoadingPost = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error posting: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // <-- NEW: Handles liking a post in Firestore
  Future<void> _toggleLike(Post post) async {
    if (_currentUserId.isEmpty) return;

    final postRef =
        FirebaseFirestore.instance.collection('posts').doc(post.id);

    try {
      if (post.likes.contains(_currentUserId)) {
        // User already liked it, so "unlike" it
        await postRef.update({
          'likes': FieldValue.arrayRemove([_currentUserId])
        });
      } else {
        // User hasn't liked it, so "like" it
        await postRef.update({
          'likes': FieldValue.arrayUnion([_currentUserId])
        });
      }
    } catch (e) {
      print("Error toggling like: $e");
    }
  }

  // <-- REFRESH is no longer needed, StreamBuilder handles updates
  // Future<void> _refresh() async { ... }

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
    // <-- REMOVED: final filteredPosts = ... (this logic moves inside the StreamBuilder)

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/bg_welcome.png', fit: BoxFit.cover),
          Container(color: mint.withOpacity(0.15)),
          SafeArea(
            // <-- CHANGED: RefreshIndicator is removed, not needed with a Stream
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

                // <-- CHANGED: Composer now shows user's profile pic and loading
                _Composer(
                  controller: _composerCtrl,
                  onPickImage: _pickComposerImage,
                  onPost: _submitPost,
                  attachedImage: _composerImage,
                  isPosting: _isLoadingPost, // <-- NEW
                  userProfilePicUrl: _currentUserProfilePicUrl, // <-- NEW
                ),
                const SizedBox(height: 12),

                // <-- CHANGED: This is now a StreamBuilder to show the live feed
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(color: green),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text('No posts yet. Be the first!'),
                        ),
                      );
                    }

                    // Map Firestore docs to Post objects
                    final posts = snapshot.data!.docs
                        .map((doc) => Post.fromFirestore(doc))
                        .toList();

                    // Apply local search filter to the live data
                    final filteredPosts = posts.where((p) {
                      if (_search.isEmpty) return true;
                      return p.tag
                              .toLowerCase()
                              .contains(_search.toLowerCase()) ||
                          p.text.toLowerCase().contains(_search.toLowerCase());
                    }).toList();

                    // Use Column instead of ListView.builder since we are
                    // already inside a ListView
                    return Column(
                      children: filteredPosts
                          .map((post) => _PostCard(
                                post: post,
                                // <-- Pass the real user ID
                                currentUserId: _currentUserId,
                                // <-- Pass the new Firestore function
                                onToggleLike: () => _toggleLike(post),
                                // <-- Stubbed out for now
                                onComment: () => _openComments(post),
                                onShare: () => Share.share(post.text),
                              ))
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

  // <-- CHANGED: Stubbed out for simplicity.
  // Real comments should be a subcollection in Firestore.
  void _openComments(Post post) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Comments are the next step! (Requires subcollection)')),
    );
    // The old logic (showModalBottomSheet) won't work as it only
    // updated a local list.
  }
}

/* ---------- MODELS ---------- */

// <-- REMOVED: The old _Post class is replaced by the new public Post class

/* ---------- WIDGETS (look & feel) ---------- */

// <-- No changes to _SearchBar, _ReelCardAdd, _ReelCardEmpty -->
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

// ... (Keep _ReelCardAdd and _ReelCardEmpty exactly as they were) ...
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


// <-- CHANGED: _Composer now shows user's pic and loading state
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
  final String? userProfilePicUrl; // <-- NEW
  final bool isPosting; // <-- NEW

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
              // <-- NEW: Show user's profile pic
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                backgroundImage: userProfilePicUrl != null
                    ? CachedNetworkImageProvider(userProfilePicUrl!)
                    : null,
                child: userProfilePicUrl == null
                    ? const Icon(Icons.person, color: Color(0xFF2E7D32))
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
                  icon:
                      const Icon(Icons.image_rounded, color: Color(0xFF2E7D32))),
            ],
          ),
          if (attachedImage != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(attachedImage!,
                  height: 160, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            // <-- NEW: Show loading indicator on button
            child: FilledButton(
              onPressed: isPosting ? null : onPost,
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white),
              child: isPosting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Post'),
            ),
          ),
        ],
      ),
    );
  }
}

// <-- CHANGED: _PostCard now takes the new Post model
class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.currentUserId,
    required this.onToggleLike,
    required this.onComment,
    required this.onShare,
  });

  final Post post; // <-- CHANGED
  final String currentUserId; // <-- NEW
  final VoidCallback onToggleLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  static const green = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    // <-- NEW: Check if the current user liked this post
    final bool isLiked = post.likes.contains(currentUserId);

    Widget? img;
    // <-- CHANGED: Simplified image logic
    if (post.imageUrl != null) {
      img = CachedNetworkImage(
        imageUrl: post.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (ctx, url) => const _ImageSkeleton(),
        errorWidget: (ctx, url, err) => const _ImageError(),
      );
    } else {
      img = null;
    }

    // <-- NEW: Logic to format the timestamp
    String timeAgo = 'Just now';
    final duration = DateTime.now().difference(post.createdAt.toDate());
    if (duration.inDays > 0) {
      timeAgo = '${duration.inDays}d ago';
    } else if (duration.inHours > 0) {
      timeAgo = '${duration.inHours}h ago';
    } else if (duration.inMinutes > 0) {
      timeAgo = '${duration.inMinutes}m ago';
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [_CommunityStyle.cardShadow]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // <-- CHANGED: Show author's profile pic
              CircleAvatar(
                backgroundColor: const Color(0xFFEFF6F1),
                backgroundImage: post.authorProfilePicUrl != null
                    ? CachedNetworkImageProvider(post.authorProfilePicUrl!)
                    : null,
                child: post.authorProfilePicUrl == null
                    ? const Icon(Icons.person, color: green)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // <-- CHANGED: Use data from Post model
                    Text(post.authorName,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: Colors.black87)),
                    Text('$timeAgo · ${post.tag}', // <-- Use new timeAgo
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
              IconButton(
                  onPressed: () {
                    // TODO: Add delete/report logic
                  },
                  icon: const Icon(Icons.more_horiz, color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 6),
          // <-- CHANGED: Use data from Post model
          Text(post.text,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87)),
          const SizedBox(height: 10),
          if (img != null)
            ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(width: double.infinity, height: 220, child: img)),
          const SizedBox(height: 10),
          Row(
            children: [
              InkWell(
                onTap: onToggleLike,
                child: Row(children: [
                  // <-- CHANGED: Use new isLiked bool
                  Icon(isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 20, color: isLiked ? Colors.red : green),
                  const SizedBox(width: 6),
                  // <-- CHANGED: Use likes list length
                  Text('${post.likes.length}',
                      style:
                          GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
                ]),
              ),
              const SizedBox(width: 18),
              InkWell(
                onTap: onComment,
                child: Row(children: [
                  const Icon(Icons.mode_comment_outlined,
                      size: 20, color: Colors.black54),
                  const SizedBox(width: 6),
                  // <-- CHANGED: Stubbed comment count
                  Text('0',
                      style:
                          GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
                ]),
              ),
              const SizedBox(width: 18),
              InkWell(
                onTap: onShare,
                child: Row(children: const [
                  Icon(Icons.share_outlined, size: 20, color: Colors.black54),
                  SizedBox(width: 6),
                  Text('Share',
                      style: TextStyle(fontSize: 12, color: Colors.black54)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ... (Keep _ImageSkeleton, _ImageError, _FiltersSheet, and _CommunityStyle exactly as they were) ...
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