import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:service_pilot/core/auth/auth_service.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Production Firebase Authentication service implementation of [IAuthService].
///
/// Features:
/// - Real [FirebaseAuth] integration for user identity, sessions, and security.
/// - Extended user profile persistence via [SharedPreferences] keyed by Firebase UID.
/// - Full role-based user management across Customers, Technicians, Companies, and Admins.
/// - Comprehensive [FirebaseAuthException] mapping to user-friendly messages.
class FirebaseAuthService implements IAuthService {
  static const String _tokenPrefix = 'INVITE-';

  final FirebaseAuth? _injectedAuth;
  final SharedPreferences? _injectedPrefs;

  FirebaseAuthService({
    FirebaseAuth? firebaseAuth,
    SharedPreferences? prefs,
  })  : _injectedAuth = firebaseAuth,
        _injectedPrefs = prefs;

  FirebaseAuth get _auth {
    final injected = _injectedAuth;
    if (injected != null) return injected;
    if (Firebase.apps.isEmpty) {
      throw const AuthException(
        'Firebase is not initialized. Please ensure Firebase.initializeApp() has run.',
      );
    }
    return FirebaseAuth.instance;
  }

  Future<SharedPreferences> _getPrefs() async {
    final prefs = _injectedPrefs;
    if (prefs != null) return prefs;
    return await SharedPreferences.getInstance();
  }

  // ── Session & Current User ────────────────────────────────────────────────

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      if (_injectedAuth == null && Firebase.apps.isEmpty) {
        return null;
      }

      final fbUser = _auth.currentUser;
      if (fbUser != null) {
        return await _loadOrCreateUserModel(fbUser);
      }
    } catch (e) {
      debugPrint('[FirebaseAuth] Session check failed: $e');
    }
    return null;
  }

  // ── Authentication ────────────────────────────────────────────────────────

  @override
  Future<UserModel> login(String email, String password) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) {
      throw const AuthException('Email is required.');
    }
    if (password.isEmpty) {
      throw const AuthException('Password is required.');
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final fbUser = credential.user;
      if (fbUser == null) {
        throw const AuthException('Login failed. Please verify your credentials.');
      }

      final user = await _loadOrCreateUserModel(fbUser, email: cleanEmail);
      await _recordActiveSession(user.id);
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('An unexpected error occurred during login: $e');
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      UserCredential credential;
      final provider = GoogleAuthProvider();

      if (kIsWeb) {
        credential = await _auth.signInWithPopup(provider);
      } else {
        credential = await _auth.signInWithProvider(provider);
      }

      final fbUser = credential.user;
      if (fbUser == null) {
        throw const AuthException('Google sign-in was cancelled or failed.');
      }

      final user = await _loadOrCreateUserModel(
        fbUser,
        defaultRole: AppRole.homeowner,
        defaultName: fbUser.displayName ?? 'Google Customer',
      );
      await _recordActiveSession(user.id);
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Google sign-in failed: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      if (_injectedAuth != null || Firebase.apps.isNotEmpty) {
        await _auth.signOut();
      }
    } catch (e) {
      debugPrint('[FirebaseAuth] Error during signOut: $e');
    } finally {
      await _clearActiveSession();
    }
  }

  // ── Customer Registration ─────────────────────────────────────────────────

  @override
  Future<UserModel> registerCustomer({
    required String fullName,
    required String email,
    required String phoneNumber,
    String? password,
  }) async {
    final cleanEmail = email.trim();
    final cleanName = fullName.trim();
    final cleanPhone = phoneNumber.trim();
    final effectivePassword = password ?? '';

    if (cleanName.isEmpty) {
      throw const AuthException('Full name is required.');
    }
    if (cleanEmail.isEmpty) {
      throw const AuthException('Email is required.');
    }
    if (cleanPhone.isEmpty) {
      throw const AuthException('Phone number is required.');
    }
    if (effectivePassword.length < 8) {
      throw const AuthException('Password must be at least 8 characters long.');
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: effectivePassword,
      );

      final fbUser = credential.user;
      if (fbUser == null) {
        throw const AuthException('Could not create account. Please try again.');
      }

      await fbUser.updateDisplayName(cleanName);
      final user = UserModel(
        id: fbUser.uid,
        fullName: cleanName,
        email: cleanEmail,
        phoneNumber: cleanPhone,
        role: AppRole.homeowner,
        status: 'active',
        createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
      );

      await _saveUserProfile(user);
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Registration failed: $e');
    }
  }

  // ── Technician Registration ───────────────────────────────────────────────

  @override
  Future<UserModel> registerTechnician({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String serviceArea,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    final cleanName = fullName.trim();
    final cleanPhone = phoneNumber.trim();
    final cleanArea = serviceArea.trim();

    if (cleanName.isEmpty) {
      throw const AuthException('Full name is required.');
    }
    if (cleanEmail.isEmpty) {
      throw const AuthException('Email is required.');
    }
    if (cleanPhone.isEmpty) {
      throw const AuthException('Phone number is required.');
    }
    if (cleanArea.isEmpty) {
      throw const AuthException('Service area is required.');
    }
    if (password.length < 8) {
      throw const AuthException('Password must be at least 8 characters long.');
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final fbUser = credential.user;
      if (fbUser == null) {
        throw const AuthException('Could not create technician account.');
      }

      await fbUser.updateDisplayName(cleanName);
      final user = UserModel(
        id: fbUser.uid,
        fullName: cleanName,
        email: cleanEmail,
        phoneNumber: cleanPhone,
        role: AppRole.independentProvider,
        status: 'pending_verification',
        serviceArea: cleanArea,
        createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
      );

      await _saveUserProfile(user);
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Technician registration failed: $e');
    }
  }

  // ── Company Registration ──────────────────────────────────────────────────

  @override
  Future<UserModel> registerCompany({
    required String ownerFullName,
    required String email,
    required String phoneNumber,
    required String companyName,
    required String serviceArea,
    String? password,
  }) async {
    final cleanEmail = email.trim();
    final cleanOwner = ownerFullName.trim();
    final cleanPhone = phoneNumber.trim();
    final cleanCompany = companyName.trim();
    final cleanArea = serviceArea.trim();
    final effectivePassword = password ?? '';

    if (cleanOwner.isEmpty) {
      throw const AuthException('Owner full name is required.');
    }
    if (cleanEmail.isEmpty) {
      throw const AuthException('Email is required.');
    }
    if (cleanPhone.isEmpty) {
      throw const AuthException('Phone number is required.');
    }
    if (cleanCompany.isEmpty) {
      throw const AuthException('Company name is required.');
    }
    if (cleanArea.isEmpty) {
      throw const AuthException('Service area is required.');
    }
    if (effectivePassword.length < 8) {
      throw const AuthException('Password must be at least 8 characters long.');
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: effectivePassword,
      );

      final fbUser = credential.user;
      if (fbUser == null) {
        throw const AuthException('Could not create company account.');
      }

      await fbUser.updateDisplayName(cleanOwner);
      final user = UserModel(
        id: fbUser.uid,
        fullName: cleanOwner,
        email: cleanEmail,
        phoneNumber: cleanPhone,
        role: AppRole.company,
        status: 'pending_verification',
        companyName: cleanCompany,
        serviceArea: cleanArea,
        createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
      );

      await _saveUserProfile(user);
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Company registration failed: $e');
    }
  }

  // ── Password Management ───────────────────────────────────────────────────

  @override
  Future<bool> requestPasswordReset(String email) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) {
      throw const AuthException('Email is required.');
    }
    try {
      await _auth.sendPasswordResetEmail(email: cleanEmail);
      return true;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Could not send password reset email: $e');
    }
  }

  @override
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final cleanToken = token.trim();
    if (cleanToken.isEmpty) {
      throw const AuthException('Password reset token is missing or invalid.');
    }
    if (newPassword.length < 8) {
      throw const AuthException('Password must be at least 8 characters long.');
    }
    try {
      await _auth.confirmPasswordReset(
        code: cleanToken,
        newPassword: newPassword,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Password reset failed: $e');
    }
  }

  // ── Technician Activation ─────────────────────────────────────────────────

  @override
  bool validateInviteToken(String token) {
    final trimmed = token.trim();
    if (trimmed.isEmpty) return false;
    return trimmed.startsWith(_tokenPrefix) || trimmed.length >= 6;
  }

  @override
  Future<UserModel> activateTechnicianAccount({
    required String token,
    required String fullName,
    required String password,
    String? email,
  }) async {
    if (!validateInviteToken(token)) {
      throw const AuthException('Invalid or expired invitation token.');
    }
    if (password.length < 8) {
      throw const AuthException('Password must be at least 8 characters long.');
    }

    final cleanName = fullName.trim();
    if (cleanName.isEmpty) {
      throw const AuthException('Full name is required.');
    }

    final sanitizedToken = token.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final effectiveEmail = (email != null && email.trim().isNotEmpty)
        ? email.trim().toLowerCase()
        : 'tech.$sanitizedToken@servicepilot.app';

    try {
      UserCredential credential;
      try {
        credential = await _auth.createUserWithEmailAndPassword(
          email: effectiveEmail,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          credential = await _auth.signInWithEmailAndPassword(
            email: effectiveEmail,
            password: password,
          );
        } else {
          rethrow;
        }
      }

      final fbUser = credential.user;
      if (fbUser == null) {
        throw const AuthException('Could not activate technician account.');
      }

      await fbUser.updateDisplayName(cleanName);
      final user = UserModel(
        id: fbUser.uid,
        fullName: cleanName,
        email: effectiveEmail,
        phoneNumber: fbUser.phoneNumber ?? '+85500000099',
        role: AppRole.companyTechnician,
        status: 'active',
        companyName: 'Service Partner Company',
        createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
      );

      await _saveUserProfile(user);
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Technician activation failed: $e');
    }
  }

  // ── Profile Persistence Helpers ───────────────────────────────────────────

  Future<void> _saveUserProfile(UserModel user) async {
    final prefs = await _getPrefs();
    final jsonStr = jsonEncode(user.toJson());
    await prefs.setString('sp_user_profile_${user.id}', jsonStr);
    await prefs.setString('sp_user_profile_email_${user.email.toLowerCase().trim()}', jsonStr);
    await prefs.setString('sp_active_user_id', user.id);
  }

  Future<UserModel?> _loadCachedProfile(String uid, {String? email}) async {
    final prefs = await _getPrefs();
    final directJson = prefs.getString('sp_user_profile_$uid');
    if (directJson != null) {
      try {
        return UserModel.fromJson(jsonDecode(directJson) as Map<String, dynamic>);
      } catch (_) {}
    }

    if (email != null) {
      final emailJson = prefs.getString('sp_user_profile_email_${email.toLowerCase().trim()}');
      if (emailJson != null) {
        try {
          final model = UserModel.fromJson(jsonDecode(emailJson) as Map<String, dynamic>);
          return model.copyWith(id: uid);
        } catch (_) {}
      }
    }

    return null;
  }

  Future<UserModel> _loadOrCreateUserModel(
    User fbUser, {
    String? email,
    AppRole? defaultRole,
    String? defaultName,
  }) async {
    final cached = await _loadCachedProfile(fbUser.uid, email: email ?? fbUser.email);
    if (cached != null) {
      await _recordActiveSession(cached.id);
      return cached;
    }

    final userEmail = (email ?? fbUser.email ?? '').trim().toLowerCase();
    final role = defaultRole ?? _inferRoleFromEmail(userEmail);
    final name = fbUser.displayName ?? defaultName ?? _inferNameFromEmail(userEmail);

    final user = UserModel(
      id: fbUser.uid,
      fullName: name,
      email: userEmail.isEmpty ? '${fbUser.uid}@servicepilot.app' : userEmail,
      phoneNumber: fbUser.phoneNumber ?? '',
      role: role,
      status: 'active',
      createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
    );

    await _saveUserProfile(user);
    return user;
  }

  Future<void> _recordActiveSession(String userId) async {
    final prefs = await _getPrefs();
    await prefs.setString('sp_active_user_id', userId);
  }

  Future<void> _clearActiveSession() async {
    final prefs = await _getPrefs();
    await prefs.remove('sp_active_user_id');
  }

  AppRole _inferRoleFromEmail(String email) {
    final lower = email.toLowerCase();
    if (lower.contains('tech@') || lower.contains('.tech@')) return AppRole.companyTechnician;
    if (lower.contains('technician') || lower.contains('provider')) return AppRole.independentProvider;
    if (lower.contains('company') || lower.contains('business')) return AppRole.company;
    if (lower.contains('admin')) return AppRole.admin;
    return AppRole.homeowner;
  }

  String _inferNameFromEmail(String email) {
    final parts = email.split('@').first.split(RegExp(r'[._-]'));
    return parts
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1))
        .join(' ');
  }

  // ── Error Detection & Mapping ─────────────────────────────────────────────

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 8 characters long.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled in Firebase Console.';
      case 'network-request-failed':
        return 'Network connection error. Please check your internet connection.';
      case 'expired-action-code':
        return 'The password reset link has expired.';
      case 'invalid-action-code':
        return 'The password reset link is invalid or has already been used.';
      default:
        final msg = e.message;
        if (msg == null || msg.isEmpty || msg == 'Error' || msg == '[object Object]') {
          return 'Authentication failed. Please verify your details and try again.';
        }
        return msg;
    }
  }
}
