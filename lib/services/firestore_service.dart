import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/foundation.dart';
import '../constants/communities.dart';
import '../providers/user_role_provider.dart';

/// Service for Firestore database operations
/// Handles user data, worshipers, and leaders collections
class FirestoreService {
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;

  // Collection references
  firestore.CollectionReference get _usersCollection => _firestore.collection('users');
  firestore.CollectionReference get _worshipersCollection => _firestore.collection('worshipers');
  firestore.CollectionReference get _leadersCollection => _firestore.collection('leaders');
  firestore.CollectionReference get _postsCollection => _firestore.collection('posts');
  firestore.CollectionReference get _reelsCollection => _firestore.collection('reels');
  firestore.CollectionReference get _conversationsCollection => _firestore.collection('conversations');

  /// Create user document in users collection
  Future<void> createUser({
    required String uid,
    required String name,
    required String email,
    required UserRole role,
    required String community,
  }) async {
    if (!Communities.isValid(community)) {
      throw Exception('Invalid community: $community');
    }

    await _usersCollection.doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'role': role == UserRole.worshiper ? 'worshiper' : 'leader',
      'community': community,
      'createdAt': firestore.FieldValue.serverTimestamp(),
    });
  }

  /// Create worshiper document
  Future<void> createWorshiper({
    required String uid,
    required String name,
    required String email,
    required String community,
  }) async {
    if (!Communities.isValid(community)) {
      throw Exception('Invalid community: $community');
    }

    await _worshipersCollection.doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'community': community,
      'connectedLeaders': <String>[],
      'createdAt': firestore.FieldValue.serverTimestamp(),
    });
  }

  /// Create leader document
  Future<void> createLeader({
    required String uid,
    required String name,
    required String email,
    required String community,
  }) async {
    if (!Communities.isValid(community)) {
      throw Exception('Invalid community: $community');
    }

    await _leadersCollection.doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'community': community,
      'bio': '',
      'profileImageUrl': '',
      'isProfileComplete': false,
      'followers': <String>[],
      'createdAt': firestore.FieldValue.serverTimestamp(),
    });
  }

  /// Get user document from users collection
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>?;
    }
    return null;
  }

  /// Get worshiper document
  Future<Map<String, dynamic>?> getWorshiperData(String uid) async {
    final doc = await _worshipersCollection.doc(uid).get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>?;
    }
    return null;
  }

  /// Get leader document
  Future<Map<String, dynamic>?> getLeaderData(String uid) async {
    final doc = await _leadersCollection.doc(uid).get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>?;
    }
    return null;
  }

  /// Follow a leader (add to worshiper's connectedLeaders)
  Future<void> followLeader({
    required String worshiperId,
    required String leaderId,
  }) async {
    final worshiperRef = _worshipersCollection.doc(worshiperId);
    await worshiperRef.update({
      'connectedLeaders': firestore.FieldValue.arrayUnion([leaderId]),
    });

    // Also add worshiper to leader's followers list
    final leaderRef = _leadersCollection.doc(leaderId);
    await leaderRef.update({
      'followers': firestore.FieldValue.arrayUnion([worshiperId]),
    });
  }

  /// Unfollow a leader
  Future<void> unfollowLeader({
    required String worshiperId,
    required String leaderId,
  }) async {
    final worshiperRef = _worshipersCollection.doc(worshiperId);
    await worshiperRef.update({
      'connectedLeaders': firestore.FieldValue.arrayRemove([leaderId]),
    });

    // Remove worshiper from leader's followers list
    final leaderRef = _leadersCollection.doc(leaderId);
    await leaderRef.update({
      'followers': firestore.FieldValue.arrayRemove([worshiperId]),
    });
  }

  /// Check if worshiper is following a leader
  Future<bool> isFollowingLeader({
    required String worshiperId,
    required String leaderId,
  }) async {
    final worshiperData = await getWorshiperData(worshiperId);
    if (worshiperData == null) return false;
    
    final connectedLeaders = worshiperData['connectedLeaders'] as List<dynamic>? ?? [];
    return connectedLeaders.contains(leaderId);
  }

  /// Get followed leaders for a worshiper
  Future<List<String>> getFollowedLeaders(String worshiperId) async {
    final worshiperData = await getWorshiperData(worshiperId);
    if (worshiperData == null) return [];
    
    final connectedLeaders = worshiperData['connectedLeaders'] as List<dynamic>? ?? [];
    return connectedLeaders.map((e) => e.toString()).toList();
  }

  /// Get leaders filtered by community
  /// Returns a stream of leaders from the same community
  Stream<List<Map<String, dynamic>>> getLeadersByCommunity(String community) {
    if (!Communities.isValid(community)) {
      return Stream.value([]);
    }

    return _leadersCollection
        .where('community', isEqualTo: community)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Update leader profile
  Future<void> updateLeaderProfile({
    required String uid,
    String? bio,
    String? profileImageUrl,
    bool? isProfileComplete,
  }) async {
    final updateData = <String, dynamic>{};
    if (bio != null) updateData['bio'] = bio;
    if (profileImageUrl != null) updateData['profileImageUrl'] = profileImageUrl;
    if (isProfileComplete != null) updateData['isProfileComplete'] = isProfileComplete;

    if (updateData.isNotEmpty) {
      await _leadersCollection.doc(uid).update(updateData);
    }
  }

  /// Update worshiper data
  Future<void> updateWorshiperData({
    required String uid,
    String? name,
    String? email,
    String? profileImageUrl,
  }) async {
    final updateData = <String, dynamic>{};
    if (name != null) updateData['name'] = name;
    if (email != null) updateData['email'] = email;
    if (profileImageUrl != null) updateData['profileImageUrl'] = profileImageUrl;

    if (updateData.isNotEmpty) {
      await _worshipersCollection.doc(uid).update(updateData);
    }
  }

  /// Create a post
  Future<String> createPost({
    required String authorId,
    required String content,
    String? imageUrl,
    String? videoUrl,
    required String community,
  }) async {
    final docRef = _postsCollection.doc();
    await docRef.set({
      'id': docRef.id,
      'authorId': authorId,
      'content': content,
      'imageUrl': imageUrl ?? '',
      'videoUrl': videoUrl ?? '',
      'community': community,
      'likes': 0,
      'comments': 0,
      'shares': 0,
      'views': 0,
      'createdAt': firestore.FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Create a reel
  Future<String> createReel({
    required String authorId,
    required String content,
    required String videoUrl,
    required String community,
  }) async {
    final docRef = _reelsCollection.doc();
    await docRef.set({
      'id': docRef.id,
      'authorId': authorId,
      'content': content,
      'videoUrl': videoUrl,
      'community': community,
      'likes': 0,
      'comments': 0,
      'shares': 0,
      'views': 0,
      'createdAt': firestore.FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Get posts filtered by community
  /// Note: Sorting done in memory to avoid composite index requirement
  Stream<List<Map<String, dynamic>>> getPostsByCommunity(String community) {
    if (!Communities.isValid(community)) {
      return Stream.value([]);
    }

    return _postsCollection
        .where('community', isEqualTo: community)
        .snapshots()
        .map((snapshot) {
      final posts = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Sort by createdAt in descending order (most recent first)
      posts.sort((a, b) {
        final aTime = a['createdAt'] as firestore.Timestamp?;
        final bTime = b['createdAt'] as firestore.Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      
      return posts;
    });
  }

  /// Get reels filtered by community
  /// Note: Sorting done in memory to avoid composite index requirement
  Stream<List<Map<String, dynamic>>> getReelsByCommunity(String community) {
    if (!Communities.isValid(community)) {
      return Stream.value([]);
    }

    return _reelsCollection
        .where('community', isEqualTo: community)
        .snapshots()
        .map((snapshot) {
      final reels = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Sort by createdAt in descending order (most recent first)
      reels.sort((a, b) {
        final aTime = a['createdAt'] as firestore.Timestamp?;
        final bTime = b['createdAt'] as firestore.Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      
      return reels;
    });
  }

  /// Get posts by leader
  Stream<List<Map<String, dynamic>>> getPostsByLeader(String leaderId) {
    return _postsCollection
        .where('authorId', isEqualTo: leaderId)
        .snapshots()
        .map((snapshot) {
      final posts = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Sort by createdAt in descending order
      posts.sort((a, b) {
        final aTime = a['createdAt'] as firestore.Timestamp?;
        final bTime = b['createdAt'] as firestore.Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      
      return posts;
    });
  }

  /// Get reels by leader
  Stream<List<Map<String, dynamic>>> getReelsByLeader(String leaderId) {
    return _reelsCollection
        .where('authorId', isEqualTo: leaderId)
        .snapshots()
        .map((snapshot) {
      final reels = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Sort by createdAt in descending order
      reels.sort((a, b) {
        final aTime = a['createdAt'] as firestore.Timestamp?;
        final bTime = b['createdAt'] as firestore.Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      
      return reels;
    });
  }

  /// Create or get conversation between two users
  Future<String> getOrCreateConversation({
    required String participant1Id,
    required String participant2Id,
  }) async {
    // Try to find existing conversation
    final existing1 = await _conversationsCollection
        .where('participants', arrayContains: participant1Id)
        .get();
    
    for (var doc in existing1.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final participants = data['participants'] as List<dynamic>? ?? [];
      if (participants.contains(participant2Id)) {
        return doc.id;
      }
    }

    // Create new conversation
    final docRef = _conversationsCollection.doc();
    final sortedIds = [participant1Id, participant2Id]..sort();
    await docRef.set({
      'id': docRef.id,
      'participants': sortedIds,
      'lastMessage': '',
      'lastMessageTime': firestore.FieldValue.serverTimestamp(),
      'createdAt': firestore.FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  /// Send a message
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    // Add message to messages subcollection
    await _conversationsCollection
        .doc(conversationId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': firestore.FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // Update conversation with last message
    await _conversationsCollection.doc(conversationId).update({
      'lastMessage': text,
      'lastMessageTime': firestore.FieldValue.serverTimestamp(),
    });
  }

  /// Get messages for a conversation
  /// Note: Sorting done in memory to avoid index requirement
  Stream<List<Map<String, dynamic>>> getMessages(String conversationId) {
    return _conversationsCollection
        .doc(conversationId)
        .collection('messages')
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs.map((doc) {
        final data = doc.data();
        final messageData = <String, dynamic>{'id': doc.id};
        messageData.addAll(data);
        return messageData;
      }).toList();
      
      // Sort by timestamp in descending order (most recent first)
      messages.sort((a, b) {
        final aTime = a['timestamp'] as firestore.Timestamp?;
        final bTime = b['timestamp'] as firestore.Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      
      return messages;
    });
  }

  /// Get conversations for a user
  /// Note: Sorting done in memory to avoid composite index requirement
  Stream<List<Map<String, dynamic>>> getConversations(String userId) {
    return _conversationsCollection
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final conversations = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Sort by lastMessageTime in descending order
      conversations.sort((a, b) {
        final aTime = a['lastMessageTime'] as firestore.Timestamp?;
        final bTime = b['lastMessageTime'] as firestore.Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      
      return conversations;
    });
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead({
    required String conversationId,
    required String userId,
  }) async {
    final messagesSnapshot = await _conversationsCollection
        .doc(conversationId)
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in messagesSnapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Increment share count for a post
  Future<void> sharePost(String postId) async {
    await _postsCollection.doc(postId).update({
      'shares': firestore.FieldValue.increment(1),
    });
  }

  /// Increment share count for a reel
  Future<void> shareReel(String reelId) async {
    await _reelsCollection.doc(reelId).update({
      'shares': firestore.FieldValue.increment(1),
    });
  }

  /// Check if a post is liked by a user
  Future<bool> isPostLiked({
    required String postId,
    required String userId,
  }) async {
    try {
      final likeDoc = await _postsCollection
          .doc(postId)
          .collection('likes')
          .doc(userId)
          .get();
      return likeDoc.exists;
    } catch (e) {
      debugPrint('Error checking if post is liked: $e');
      return false;
    }
  }

  /// Check if a reel is liked by a user
  Future<bool> isReelLiked({
    required String reelId,
    required String userId,
  }) async {
    try {
      final likeDoc = await _reelsCollection
          .doc(reelId)
          .collection('likes')
          .doc(userId)
          .get();
      return likeDoc.exists;
    } catch (e) {
      debugPrint('Error checking if reel is liked: $e');
      return false;
    }
  }

  /// Like a post
  Future<void> likePost({
    required String postId,
    required String userId,
  }) async {
    try {
      final postRef = _postsCollection.doc(postId);
      final likeRef = postRef.collection('likes').doc(userId);

      // Use transaction to ensure atomicity
      await _firestore.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);
        if (!postDoc.exists) {
          throw Exception('Post does not exist');
        }

        final likeDoc = await transaction.get(likeRef);
        if (likeDoc.exists) {
          // Already liked, do nothing
          return;
        }

        // Add like document
        transaction.set(likeRef, {
          'likedAt': firestore.FieldValue.serverTimestamp(),
        });

        // Increment likes count
        final currentLikes = (postDoc.data()?['likes'] as int?) ?? 0;
        transaction.update(postRef, {
          'likes': firestore.FieldValue.increment(1),
        });
      });
    } catch (e) {
      debugPrint('Error liking post: $e');
      rethrow;
    }
  }

  /// Like a reel
  Future<void> likeReel({
    required String reelId,
    required String userId,
  }) async {
    try {
      final reelRef = _reelsCollection.doc(reelId);
      final likeRef = reelRef.collection('likes').doc(userId);

      // Use transaction to ensure atomicity
      await _firestore.runTransaction((transaction) async {
        final reelDoc = await transaction.get(reelRef);
        if (!reelDoc.exists) {
          throw Exception('Reel does not exist');
        }

        final likeDoc = await transaction.get(likeRef);
        if (likeDoc.exists) {
          // Already liked, do nothing
          return;
        }

        // Add like document
        transaction.set(likeRef, {
          'likedAt': firestore.FieldValue.serverTimestamp(),
        });

        // Increment likes count
        transaction.update(reelRef, {
          'likes': firestore.FieldValue.increment(1),
        });
      });
    } catch (e) {
      debugPrint('Error liking reel: $e');
      rethrow;
    }
  }

  /// Unlike a post
  Future<void> unlikePost({
    required String postId,
    required String userId,
  }) async {
    try {
      final postRef = _postsCollection.doc(postId);
      final likeRef = postRef.collection('likes').doc(userId);

      // Use transaction to ensure atomicity
      await _firestore.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);
        if (!postDoc.exists) {
          throw Exception('Post does not exist');
        }

        final likeDoc = await transaction.get(likeRef);
        if (!likeDoc.exists) {
          // Not liked, do nothing
          return;
        }

        // Remove like document
        transaction.delete(likeRef);

        // Decrement likes count (prevent negative)
        final currentLikes = (postDoc.data()?['likes'] as int?) ?? 0;
        if (currentLikes > 0) {
          transaction.update(postRef, {
            'likes': firestore.FieldValue.increment(-1),
          });
        }
      });
    } catch (e) {
      debugPrint('Error unliking post: $e');
      rethrow;
    }
  }

  /// Unlike a reel
  Future<void> unlikeReel({
    required String reelId,
    required String userId,
  }) async {
    try {
      final reelRef = _reelsCollection.doc(reelId);
      final likeRef = reelRef.collection('likes').doc(userId);

      // Use transaction to ensure atomicity
      await _firestore.runTransaction((transaction) async {
        final reelDoc = await transaction.get(reelRef);
        if (!reelDoc.exists) {
          throw Exception('Reel does not exist');
        }

        final likeDoc = await transaction.get(likeRef);
        if (!likeDoc.exists) {
          // Not liked, do nothing
          return;
        }

        // Remove like document
        transaction.delete(likeRef);

        // Decrement likes count (prevent negative)
        final currentLikes = (reelDoc.data()?['likes'] as int?) ?? 0;
        if (currentLikes > 0) {
          transaction.update(reelRef, {
            'likes': firestore.FieldValue.increment(-1),
          });
        }
      });
    } catch (e) {
      debugPrint('Error unliking reel: $e');
      rethrow;
    }
  }

  /// Add a comment to a post
  Future<void> addComment({
    required String postId,
    required String userId,
    required String text,
  }) async {
    try {
      final postRef = _postsCollection.doc(postId);
      final commentsRef = postRef.collection('comments');

      // Use transaction to ensure atomicity
      await _firestore.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);
        if (!postDoc.exists) {
          throw Exception('Post does not exist');
        }

        // Add comment document
        final commentRef = commentsRef.doc();
        transaction.set(commentRef, {
          'userId': userId,
          'text': text,
          'createdAt': firestore.FieldValue.serverTimestamp(),
        });

        // Increment comments count
        transaction.update(postRef, {
          'comments': firestore.FieldValue.increment(1),
        });
      });
    } catch (e) {
      debugPrint('Error adding comment: $e');
      rethrow;
    }
  }

  /// Add a comment to a reel
  Future<void> addReelComment({
    required String reelId,
    required String userId,
    required String text,
  }) async {
    try {
      final reelRef = _reelsCollection.doc(reelId);
      final commentsRef = reelRef.collection('comments');

      // Use transaction to ensure atomicity
      await _firestore.runTransaction((transaction) async {
        final reelDoc = await transaction.get(reelRef);
        if (!reelDoc.exists) {
          throw Exception('Reel does not exist');
        }

        // Add comment document
        final commentRef = commentsRef.doc();
        transaction.set(commentRef, {
          'userId': userId,
          'text': text,
          'createdAt': firestore.FieldValue.serverTimestamp(),
        });

        // Increment comments count
        transaction.update(reelRef, {
          'comments': firestore.FieldValue.increment(1),
        });
      });
    } catch (e) {
      debugPrint('Error adding reel comment: $e');
      rethrow;
    }
  }

  /// Get comments for a post
  Stream<List<Map<String, dynamic>>> getPostComments(String postId) {
    return _postsCollection
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Get comments for a reel
  Stream<List<Map<String, dynamic>>> getReelComments(String reelId) {
    return _reelsCollection
        .doc(reelId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }
}
