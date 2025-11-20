import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/community_repository.dart';

class CommunityViewModel extends ChangeNotifier {
  final CommunityRepository _repository;

  // State
  bool isLoading = false;
  String? errorMessage;

  // Current User Data (Cached in VM)
  String? _currentUserId;
  String? _firstName;
  String? _profilePicUrl;

  String get currentUserId => _currentUserId ?? '';
  String get currentUserName => _firstName ?? 'User';
  String? get currentUserPic => _profilePicUrl;

  // Constructor
  CommunityViewModel({required CommunityRepository repository})
    : _repository = repository {
    _loadCurrentUser();
  }

  // --- Setup ---
  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      try {
        final userData = await _repository.getUserProfile(user.uid);
        if (userData != null) {
          _firstName = userData['firstName'];
          _profilePicUrl = userData['profilePicUrl'];
          notifyListeners(); // Tell UI to update
        }
      } catch (e) {
        debugPrint("Error loading user profile: $e");
      }
    }
  }

  // --- Actions ---

  // Expose Streams to UI
  Stream<List<Post>> get postsStream => _repository.getPostsStream();

  Stream<List<Comment>> getCommentsStream(String postId) =>
      _repository.getCommentsStream(postId);

  // Submit Post Logic
  Future<bool> submitPost(String text, File? image) async {
    if (_currentUserId == null) return false;

    isLoading = true;
    errorMessage = null;
    notifyListeners(); // Show spinner

    try {
      await _repository.addPost({
        'authorId': _currentUserId,
        'authorName': _firstName,
        'authorProfilePicUrl': _profilePicUrl,
        'text': text,
        'tag': 'General', // Default tag
      }, image);

      isLoading = false;
      notifyListeners(); // Hide spinner
      return true; // Success
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
      return false; // Failed
    }
  }

  Future<void> togglePostLike(Post post) async {
    if (_currentUserId == null) return;
    await _repository.togglePostLike(post.id, _currentUserId!, post.likes);
  }

  Future<void> addComment(String postId, String text) async {
    if (_currentUserId == null) return;
    await _repository.addComment(postId, {
      'text': text,
      'authorId': _currentUserId,
      'authorName': _firstName,
      'authorProfilePicUrl': _profilePicUrl,
    });
  }

  Future<void> toggleCommentLike(String postId, Comment comment) async {
    if (_currentUserId == null) return;
    await _repository.toggleCommentLike(
      postId,
      comment.id,
      _currentUserId!,
      comment.likes,
    );
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await _repository.deleteComment(postId, commentId);
  }
}
