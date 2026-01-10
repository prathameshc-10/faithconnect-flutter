import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/communities.dart';
import '../providers/user_role_provider.dart';

/// Service for Firestore database operations
/// Handles user data, worshipers, and leaders collections
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _worshipersCollection => _firestore.collection('worshipers');
  CollectionReference get _leadersCollection => _firestore.collection('leaders');
  CollectionReference get _postsCollection => _firestore.collection('posts');
  CollectionReference get _reelsCollection => _firestore.collection('reels');

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
      'createdAt': FieldValue.serverTimestamp(),
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
      'createdAt': FieldValue.serverTimestamp(),
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
      'createdAt': FieldValue.serverTimestamp(),
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
      'createdAt': FieldValue.serverTimestamp(),
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
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Get posts filtered by community
  Stream<List<Map<String, dynamic>>> getPostsByCommunity(String community) {
    if (!Communities.isValid(community)) {
      return Stream.value([]);
    }

    return _postsCollection
        .where('community', isEqualTo: community)
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

  /// Get reels filtered by community
  Stream<List<Map<String, dynamic>>> getReelsByCommunity(String community) {
    if (!Communities.isValid(community)) {
      return Stream.value([]);
    }

    return _reelsCollection
        .where('community', isEqualTo: community)
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

  /// Get posts by leader
  Stream<List<Map<String, dynamic>>> getPostsByLeader(String leaderId) {
    return _postsCollection
        .where('authorId', isEqualTo: leaderId)
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

  /// Get reels by leader
  Stream<List<Map<String, dynamic>>> getReelsByLeader(String leaderId) {
    return _reelsCollection
        .where('authorId', isEqualTo: leaderId)
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
