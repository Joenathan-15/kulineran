import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kulineran/services/user_service.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  Future<void> register(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    if (googleUser == null) {
      throw Exception('Google sign-in was cancelled');
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);

    if (userCredential.additionalUserInfo?.isNewUser ?? false) {
      final user = userCredential.user;
      if (user != null) {
        await UserService().createUser(user.uid, {
          'displayName': user.displayName ?? '',
          'email': user.email ?? '',
          'phoneNumber': user.phoneNumber ?? '',
          'bio': '',
          'photoBase64': '',
          'darkMode': false,
        });
      }
    }

    return userCredential;
  }

  Future<UserCredential> signInWithGitHub() async {
    final githubProvider = GithubAuthProvider();

    final userCredential = await _auth.signInWithProvider(githubProvider);

    if (userCredential.additionalUserInfo?.isNewUser ?? false) {
      final user = userCredential.user;
      if (user != null) {
        await UserService().createUser(user.uid, {
          'displayName': user.displayName ?? '',
          'email': user.email ?? '',
          'phoneNumber': user.phoneNumber ?? '',
          'bio': '',
          'photoBase64': '',
          'darkMode': false,
        });
      }
    }

    return userCredential;
  }

  Future<void> logout() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  String? get currentUid => _auth.currentUser?.uid;
  String? get currentEmail => _auth.currentUser?.email;
}
