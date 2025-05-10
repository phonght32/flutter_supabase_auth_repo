import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'model/supabase_user.dart';

class SupabaseAuthRepo {
  final _supabase = Supabase.instance.client;
  final String _androidClientId;
  final String _webClientId;

  SupabaseAuthRepo({required String androidClientId, required String webClientId}) :
        _androidClientId = androidClientId, _webClientId = webClientId;

  /// Get the current authenticated user
  SupabaseUser get user {
    final currentUser = _supabase.auth.currentUser;
    return currentUser == null ? SupabaseUser.empty : SupabaseUser(
      id: currentUser.id,
      email: currentUser.email,
      name: currentUser.userMetadata?['name'],
      photo: currentUser.userMetadata?['avatar_url'],
    );
  }

  /// Check if a user is logged in
  bool isLoggedIn() {
    return _supabase.auth.currentSession != null;
  }

  /// Sign up a new user with email and password
  Future<void> signUp({required String email, required String password}) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Sign up failed');
      }
    } catch (e) {
      throw Exception('Sign up error: $e');
    }
  }

  /// Sign in using email and password
  Future<void> logInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login failed');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  /// Sign in using Google authentication
  Future<void> logInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: _androidClientId,
        serverClientId: _webClientId,
      );

      final googleUser = await googleSignIn.signIn();
      final googleAuth = await googleUser!.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw Exception('No Access Token found.');
      }
      if (idToken == null) {
        throw Exception('No ID Token found.');
      }

      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      // Check if sign-in was successful
      if (_supabase.auth.currentSession == null) {
        throw Exception('Google Sign-in failed');
      }
    } catch (e) {
      throw Exception('Google Login error: $e');
    }
  }

  /// Sign out the current user
  Future<void> logOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Logout error: $e');
    }
  }
}