import 'package:cloud_firestore/cloud_firestore.dart';

class PostService {
  final _db = FirebaseFirestore.instance;

  Future<void> createPost(Map<String, dynamic> postData) async {
    await _db.collection('posts').add({
      ...postData,
      'createdAt': FieldValue.serverTimestamp(),
      'favoriteCount': 0,
      'likeCount': 0,
    });
  }

  Future<void> deletePost(String postId) async {
    await _db.collection('posts').doc(postId).delete();
  }

  Stream<List<Map<String, dynamic>>> getFeed() {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['postId'] = doc.id;
              return data;
            }).toList());
  }

  Future<Map<String, dynamic>?> getPost(String postId) async {
    final doc = await _db.collection('posts').doc(postId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['postId'] = doc.id;
    return data;
  }

  Future<void> addComment(String postId, Map<String, dynamic> comment) async {
    await _db.collection('posts').doc(postId).collection('comments').add({
      ...comment,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getComments(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['commentId'] = doc.id;
              return data;
            }).toList());
  }

  Future<void> toggleLike(String uid, String postId, bool isLiked) async {
    final likeRef = _db.collection('users').doc(uid).collection('likes').doc(postId);
    final postRef = _db.collection('posts').doc(postId);

    await _db.runTransaction((transaction) async {
      final likeSnapshot = await transaction.get(likeRef);
      final postSnapshot = await transaction.get(postRef);

      if (!postSnapshot.exists) return;

      final alreadyLiked = likeSnapshot.exists;
      final currentLikeCount = postSnapshot.data()?['likeCount'] ?? postSnapshot.data()?['favoriteCount'] ?? 0;

      if (alreadyLiked && isLiked) {
        // Client wants to unlike, and it is currently liked in DB.
        transaction.delete(likeRef);
        transaction.update(postRef, {'likeCount': currentLikeCount > 0 ? currentLikeCount - 1 : 0});
      } else if (!alreadyLiked && !isLiked) {
        // Client wants to like, and it is currently not liked in DB.
        transaction.set(likeRef, {
          'postId': postId,
          'likedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(postRef, {'likeCount': currentLikeCount + 1});
      }
    });
  }

  Stream<Map<String, dynamic>?> getPostStream(String postId) {
    return _db.collection('posts').doc(postId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      data['postId'] = doc.id;
      return data;
    });
  }

  Stream<bool> isLikedStream(String uid, String postId) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('likes')
        .doc(postId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<bool> isFavoritedStream(String uid, String postId) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(postId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Future<bool> isLiked(String uid, String postId) async {
    final doc = await _db.collection('users').doc(uid).collection('likes').doc(postId).get();
    return doc.exists;
  }

  Future<bool> isFavorited(String uid, String postId) async {
    final doc = await _db.collection('users').doc(uid).collection('favorites').doc(postId).get();
    return doc.exists;
  }

  Future<void> toggleFavorite(String uid, String postId, bool isFavorited) async {
    final batch = _db.batch();
    final favoriteRef = _db.collection('users').doc(uid).collection('favorites').doc(postId);

    if (isFavorited) {
      batch.delete(favoriteRef);
    } else {
      batch.set(favoriteRef, {
        'postId': postId,
        'savedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> getFavorites(String uid) async {
    final snapshot = await _db.collection('users').doc(uid).collection('favorites').get();
    final postIds = snapshot.docs.map((doc) => doc.id).toList();
    
    if (postIds.isEmpty) return [];

    // Firestore 'whereIn' limit is 10 (or 30 in newer versions). 
    // For simplicity, we'll fetch them individually or in chunks if needed.
    // Let's assume a reasonable number of favorites for now or fetch manually.
    List<Map<String, dynamic>> posts = [];
    for (var postId in postIds) {
      final post = await getPost(postId);
      if (post != null) posts.add(post);
    }
    return posts;
  }

  Future<List<Map<String, dynamic>>> searchByName(String keyword) async {
    final snapshot = await _db
        .collection('posts')
        .where('foodSpotName', isGreaterThanOrEqualTo: keyword)
        .where('foodSpotName', isLessThanOrEqualTo: '$keyword\uf8ff')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['postId'] = doc.id;
      return data;
    }).toList();
  }
}