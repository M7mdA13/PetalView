import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

// ================= MODELS =================

class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorProfilePicUrl;
  final String text;
  final String? imageUrl;
  final String tag;
  final Timestamp createdAt;
  final List<String> likes;
  final int commentCount;

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
    required this.commentCount,
  });

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
      commentCount: data['commentCount'] ?? 0,
    );
  }
}

class Comment {
  final String id;
  final String text;
  final String authorId;
  final String authorName;
  final String? authorProfilePicUrl;
  final Timestamp createdAt;
  final List<String> likes;
  final int likesCount;

  Comment({
    required this.id,
    required this.text,
    required this.authorId,
    required this.authorName,
    this.authorProfilePicUrl,
    required this.createdAt,
    required this.likes,
    required this.likesCount,
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      text: data['text'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'User',
      authorProfilePicUrl: data['authorProfilePicUrl'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      likes: List<String>.from(data['likes'] ?? []),
      likesCount: data['likesCount'] ?? 0,
    );
  }
}

// ================= REPOSITORY IMPLEMENTATION =================

class CommunityRepository {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  // --- READ ---

  Stream<List<Post>> getPostsStream() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<Comment>> getCommentsStream(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('likesCount', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList(),
        );
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  // --- WRITE ---

  Future<void> addPost(Map<String, dynamic> postData, File? imageFile) async {
    String? imageUrl;

    // 1. Upload Image if exists
    if (imageFile != null) {
      final imageId = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = _storage.ref().child('post_images').child('$imageId.jpg');
      await ref.putFile(imageFile);
      imageUrl = await ref.getDownloadURL();
    }

    // 2. Prepare final data
    final data = {
      ...postData,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.now(),
      'likes': [],
      'commentCount': 0,
    };

    // 3. Write to Firestore
    await _firestore.collection('posts').add(data);
  }

  Future<void> togglePostLike(
    String postId,
    String userId,
    List<String> currentLikes,
  ) async {
    final docRef = _firestore.collection('posts').doc(postId);
    if (currentLikes.contains(userId)) {
      await docRef.update({
        'likes': FieldValue.arrayRemove([userId]),
      });
    } else {
      await docRef.update({
        'likes': FieldValue.arrayUnion([userId]),
      });
    }
  }

  Future<void> addComment(
    String postId,
    Map<String, dynamic> commentData,
  ) async {
    final data = {
      ...commentData,
      'createdAt': Timestamp.now(),
      'likes': [],
      'likesCount': 0,
    };

    // Add comment to subcollection
    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add(data);

    // Denormalization: Increment count on parent Post
    await _firestore.collection('posts').doc(postId).update({
      'commentCount': FieldValue.increment(1),
    });
  }

  Future<void> toggleCommentLike(
    String postId,
    String commentId,
    String userId,
    List<String> currentLikes,
  ) async {
    final docRef = _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId);

    if (currentLikes.contains(userId)) {
      await docRef.update({
        'likes': FieldValue.arrayRemove([userId]),
        'likesCount': FieldValue.increment(-1),
      });
    } else {
      await docRef.update({
        'likes': FieldValue.arrayUnion([userId]),
        'likesCount': FieldValue.increment(1),
      });
    }
  }

  Future<void> deleteComment(String postId, String commentId) async {
    // Delete comment
    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .delete();

    // Decrement count on parent Post
    await _firestore.collection('posts').doc(postId).update({
      'commentCount': FieldValue.increment(-1),
    });
  }
}
