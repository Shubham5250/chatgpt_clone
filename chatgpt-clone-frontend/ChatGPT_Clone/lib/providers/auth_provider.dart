import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthNotifier extends StateNotifier<User?> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(_authService.currentUser) {
    // listens to auth state changes
    _authService.authStateChanges.listen((user) {
      state = user;
    });
  }

  //login
  Future<bool> signInWithGoogle() async {
    try {
      final userCredential = await _authService.signInWithGoogle();
      return userCredential != null;
    } catch (e) {
      print('Error in AuthNotifier signInWithGoogle: $e');
      return false;
    }
  }

  //logout
  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      print('Error in AuthNotifier signOut: $e');
    }
  }

  Map<String, dynamic> getUserProfile() {
    return _authService.getUserProfile() ?? {};
  }


  String? get currentUserId => _authService.currentUserId;
}


final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  final authService = ref.read(authServiceProvider);
  return AuthNotifier(authService);
}); 