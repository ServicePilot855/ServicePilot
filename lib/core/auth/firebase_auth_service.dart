import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
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
/// - Local profile caching and Firestore persistence for company accounts.
/// - Full role-based user management across Customers, Technicians, Companies, and Admins.
/// - Comprehensive [FirebaseAuthException] mapping to user-friendly messages.
class FirebaseAuthService implements IAuthService {
  static const String _tokenPrefix = 'INVITE-';

  final FirebaseAuth? _injectedAuth;
  final SharedPreferences? _injectedPrefs;
  final FirebaseFirestore? _injectedFirestore;

  FirebaseAuthService({
    FirebaseAuth? firebaseAuth,
    SharedPreferences? prefs,
    FirebaseFirestore? firestore,
  })  : _injectedAuth = firebaseAuth,
        _injectedPrefs = prefs,
        _injectedFirestore = firestore;

  FirebaseFirestore? get _companyFirestore => _injectedFirestore ??
      (_injectedAuth == null && Firebase.apps.isNotEmpty
          ? FirebaseFirestore.instance
          : null);

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

      await _persistNewProviderRegistration(
        fbUser,
        user,
        _pendingIndependentProfile(user),
      );
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
        companyId: fbUser.uid,
        companyName: cleanCompany,
        serviceArea: cleanArea,
        createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
      );

      await _persistNewProviderRegistration(
        fbUser,
        user,
        _pendingCompanyProfile(user),
      );
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

  Future<void> _persistNewProviderRegistration(
    User fbUser,
    UserModel user,
    Map<String, dynamic> profileData,
  ) async {
    final firestore = _companyFirestore;
    if (firestore != null) {
      final batch = firestore.batch();
      batch.set(firestore.collection('users').doc(user.id), user.toJson());
      batch.set(firestore.collection('providers').doc(user.id), profileData);
      try {
        await batch.commit();
      } catch (_) {
        try {
          await fbUser.delete();
        } on FirebaseAuthException catch (error) {
          debugPrint(
            '[FirebaseAuth] Could not roll back provider sign-up: ${error.code}',
          );
        }
        rethrow;
      }
    }
    await _saveUserProfile(user);
  }

  Map<String, dynamic> _pendingCompanyProfile(UserModel owner) => {
        'id': owner.id,
        'businessName': owner.companyName,
        'providerType': 'company',
        'status': 'pending_verification',
        'isVerified': false,
        'serviceArea': owner.serviceArea,
        'createdAt': FieldValue.serverTimestamp(),
      };

  Map<String, dynamic> _pendingIndependentProfile(UserModel technician) => {
        'id': technician.id,
        'name': technician.fullName,
        'fullName': technician.fullName,
        if (technician.email.trim().isNotEmpty) 'email': technician.email.trim(),
        'phoneNumber': technician.phoneNumber,
        'providerType': 'independent',
        'status': 'pending_verification',
        'isVerified': false,
        if (technician.serviceArea != null &&
            technician.serviceArea!.trim().isNotEmpty)
          'serviceArea': technician.serviceArea!.trim(),
        'createdAt': Timestamp.fromDate(technician.createdAt ?? DateTime.now()),
      };

  Future<UserModel> _linkLegacyCompany(UserModel owner) async {
    if (owner.companyName?.trim().isNotEmpty != true ||
        owner.serviceArea?.trim().isNotEmpty != true) {
      return owner;
    }
    final linked = owner.copyWith(companyId: owner.id);
    return _linkLegacyProviderAccount(
      actor: owner,
      linked: linked,
      expectedRole: 'company',
      isMatchingProfile: (profileData) =>
          (profileData['type'] ?? profileData['providerType']) == 'company',
      isMatchingAccount: (accountData) =>
          (accountData['companyId'] ?? owner.id) == owner.id,
      buildProfile: _pendingCompanyProfile,
    );
  }

  Future<UserModel> _linkLegacyTechnician(UserModel technician) async {
    if (technician.fullName.trim().isEmpty) {
      return technician;
    }
    return _linkLegacyProviderAccount(
      actor: technician,
      linked: technician,
      expectedRole: AppRole.independentProvider.value,
      isMatchingProfile: (profileData) =>
          (profileData['type'] ?? profileData['providerType']) != 'company',
      isMatchingAccount: (_) => true,
      buildProfile: _pendingIndependentProfile,
    );
  }

  Future<UserModel> _linkLegacyProviderAccount({
    required UserModel actor,
    required UserModel linked,
    required String expectedRole,
    required bool Function(Map<String, dynamic>) isMatchingProfile,
    required bool Function(Map<String, dynamic>) isMatchingAccount,
    required Map<String, dynamic> Function(UserModel) buildProfile,
  }) async {
    final firestore = _companyFirestore;
    if (firestore == null) return actor;

    final account = firestore.collection('users').doc(actor.id);
    final profile = firestore.collection('providers').doc(actor.id);
    try {
      final didLink = await firestore.runTransaction((transaction) async {
        final accountData = (await transaction.get(account)).data();
        final profileData = (await transaction.get(profile)).data();
        if (accountData != null &&
            (accountData['role'] != expectedRole ||
                accountData['status'] == 'suspended' ||
                !isMatchingAccount(accountData))) {
          return false;
        }
        if (profileData != null && !isMatchingProfile(profileData)) {
          return false;
        }
        // A device-only registration can create a pending record, never approve one.
        if (accountData == null) {
          transaction.set(account,
              linked.copyWith(status: 'pending_verification').toJson());
        }
        if (profileData == null) {
          transaction.set(profile, buildProfile(linked));
        }
        return accountData == null || profileData == null;
      });
      if (didLink) {
        await _saveUserProfile(linked);
        return linked;
      }
    } on FirebaseException catch (error) {
      debugPrint('[FirebaseAuth] Could not link legacy provider: ${error.code}');
    }
    return actor;
  }

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
    final cached = await _loadCachedProfile(fbUser.uid);
    if (cached != null) {
      if (cached.isCompany && !cached.isSuspended && cached.companyId == null &&
          cached.id == fbUser.uid &&
          cached.email.toLowerCase() == fbUser.email?.toLowerCase()) {
        final company = await _linkLegacyCompany(cached);
        await _recordActiveSession(company.id);
        return company;
      }
      if (cached.isIndependentTechnician && !cached.isSuspended &&
          cached.id == fbUser.uid &&
          cached.email.toLowerCase() == fbUser.email?.toLowerCase()) {
        final technician = await _linkLegacyTechnician(cached);
        await _recordActiveSession(technician.id);
        return technician;
      }
      await _recordActiveSession(cached.id);
      return cached;
    }

    final firestore = _companyFirestore;
    if (firestore != null) {
      try {
        final data = (await firestore.collection('users').doc(fbUser.uid).get())
            .data();
        if (data != null &&
            (data['role'] == AppRole.company.value ||
                data['role'] == AppRole.independentProvider.value)) {
          final createdAt = data['createdAt'];
          final updatedAt = data['updatedAt'];
          final providerUser = UserModel.fromJson({
            ...data,
            'id': fbUser.uid,
            if (createdAt is Timestamp)
              'createdAt': createdAt.toDate().toIso8601String(),
            if (updatedAt is Timestamp)
              'updatedAt': updatedAt.toDate().toIso8601String(),
          });
          final linkedUser = providerUser.isIndependentTechnician &&
                  !providerUser.isSuspended
              ? await _linkLegacyTechnician(providerUser)
              : providerUser;
          await _saveUserProfile(linkedUser);
          return linkedUser;
        }
      } on FirebaseException catch (error) {
        debugPrint('[FirebaseAuth] Provider account lookup failed: ${error.code}');
      }
    }

    final cachedByEmail =
        await _loadCachedProfile(fbUser.uid, email: email ?? fbUser.email);
    if (cachedByEmail != null) {
      await _recordActiveSession(cachedByEmail.id);
      return cachedByEmail;
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

    final linkedUser = user.isIndependentTechnician
        ? await _linkLegacyTechnician(user)
        : user;
    await _saveUserProfile(linkedUser);
    return linkedUser;
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
