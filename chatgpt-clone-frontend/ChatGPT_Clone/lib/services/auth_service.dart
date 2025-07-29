import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';

/// PROVIDES USER AUTHORISATION - GOOGLE SIGN-IN/SIGN-OUT - UTILIZES FIREBASE AUTH
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn;

  AuthService() {
    _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      clientId: Platform.isIOS ? '623536412375-ijnu333i5pluilbdqq03l8gcj2k9tf6s.apps.googleusercontent.com' : null,
    );
  }


  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Map<String, dynamic>? getUserProfile() => userProfile;

  Future<UserCredential?> signInWithGoogle() async {
    try {

      await _googleSignIn.signOut();
      await _auth.signOut();


      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;


      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;


      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );


      return await _auth.signInWithCredential(credential);
    } catch (e, stackTrace) {
      print('Google Sign-In Error: $e');
      print('Stack Trace: $stackTrace');

      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _googleSignIn.signOut(),
        _auth.signOut(),
      ]);
    } catch (e, stackTrace) {
      print('Sign Out Error: $e');
      print('Stack Trace: $stackTrace');
      rethrow;
    }
  }

  //  user profile data
  Map<String, dynamic>? get userProfile {
    final user = _auth.currentUser;
    if (user == null) return null;

    return {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'emailVerified': user.emailVerified,
      'providerData': user.providerData.map((p) => p.providerId).toList(),
    };
  }


  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  Future<bool> isSignedIn() async {
    await reloadUser();
    return _auth.currentUser != null;
  }
}