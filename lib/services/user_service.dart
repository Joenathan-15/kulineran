import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  Future<void> createUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'darkMode': false,
    });
  }

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  Future<void> setDarkMode(String uid, bool value) async {
    await _db.collection('users').doc(uid).set({'darkMode': value}, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>?> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) => doc.data());
  }
}
