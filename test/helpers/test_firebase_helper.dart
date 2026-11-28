import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/core/auth/firebase_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fake implementation of [UserMetadata] for testing.
class FakeUserMetadata extends Fake implements UserMetadata {
  @override
  final DateTime creationTime;

  FakeUserMetadata({DateTime? creationTime})
      : creationTime = creationTime ?? DateTime(2026, 1, 1);
}

/// Fake implementation of [User] for testing.
class FakeUser extends Fake implements User {
  @override
  final String uid;

  @override
  String? email;

  @override
  String? displayName;

  @override
  String? phoneNumber;

  @override
  final UserMetadata metadata;
  final void Function()? onDelete;

  FakeUser({
    required this.uid,
    this.email,
    this.displayName,
    this.phoneNumber,
    this.onDelete,
    DateTime? creationTime,
  }) : metadata = FakeUserMetadata(creationTime: creationTime);

  @override
  Future<void> updateDisplayName(String? name) async {
    displayName = name;
  }

  @override
  Future<void> delete() async => onDelete?.call();
}

/// Fake implementation of [UserCredential] for testing.
class FakeUserCredential extends Fake implements UserCredential {
  @override
  final User? user;

  FakeUserCredential({this.user});
}

/// Controllable fake [FirebaseAuth] for unit & widget tests.
class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  User? _currentUser;
  final Map<String, String> _users = {}; // email -> password
  final Map<String, FakeUser> _userProfiles = {}; // email -> FakeUser

  String? lastResetEmailSent;
  String? lastConfirmedResetCode;
  String? lastConfirmedNewPassword;

  // Error simulation hooks
  FirebaseAuthException? nextException;

  void seedUser({
    required String uid,
    required String email,
    required String password,
    String? displayName,
    String? phoneNumber,
  }) {
    _users[email.toLowerCase()] = password;
    _userProfiles[email.toLowerCase()] = FakeUser(
      uid: uid,
      email: email,
      displayName: displayName,
      phoneNumber: phoneNumber,
    );
  }

  @override
  User? get currentUser => _currentUser;

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (nextException != null) {
      final ex = nextException!;
      nextException = null;
      throw ex;
    }

    final normalized = email.toLowerCase();
    if (!_users.containsKey(normalized)) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user found for that email.',
      );
    }
    if (_users[normalized] != password) {
      throw FirebaseAuthException(
        code: 'wrong-password',
        message: 'Wrong password provided.',
      );
    }

    final user = _userProfiles[normalized]!;
    _currentUser = user;
    return FakeUserCredential(user: user);
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (nextException != null) {
      final ex = nextException!;
      nextException = null;
      throw ex;
    }

    final normalized = email.toLowerCase();
    if (_users.containsKey(normalized)) {
      throw FirebaseAuthException(
        code: 'email-already-in-use',
        message: 'The account already exists for that email.',
      );
    }

    final user = FakeUser(
      uid: 'uid_${DateTime.now().millisecondsSinceEpoch}_${_users.length}',
      email: email,
      onDelete: () {
        _users.remove(normalized);
        _userProfiles.remove(normalized);
        _currentUser = null;
      },
    );
    _users[normalized] = password;
    _userProfiles[normalized] = user;
    _currentUser = user;
    return FakeUserCredential(user: user);
  }

  @override
  Future<UserCredential> signInWithProvider(AuthProvider provider) async {
    if (nextException != null) {
      final ex = nextException!;
      nextException = null;
      throw ex;
    }

    final user = FakeUser(
      uid: 'google_uid_123',
      email: 'google.customer@example.com',
      displayName: 'Google Customer',
    );
    _currentUser = user;
    return FakeUserCredential(user: user);
  }

  @override
  Future<UserCredential> signInWithPopup(AuthProvider provider) async {
    return signInWithProvider(provider);
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    if (nextException != null) {
      final ex = nextException!;
      nextException = null;
      throw ex;
    }
    lastResetEmailSent = email;
  }

  @override
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    if (nextException != null) {
      final ex = nextException!;
      nextException = null;
      throw ex;
    }
    lastConfirmedResetCode = code;
    lastConfirmedNewPassword = newPassword;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }
}

/// Helper to instantiate a test-ready [FirebaseAuthService] with in-memory persistence.
Future<FirebaseAuthService> createTestFirebaseAuthService({
  FakeFirebaseAuth? fakeAuth,
  FirebaseFirestore? firestore,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return FirebaseAuthService(
    firebaseAuth: fakeAuth ?? FakeFirebaseAuth(),
    prefs: prefs,
    firestore: firestore,
  );
}

const testTechnicianInviteId = 'test-invite-with-32-characters-0001';
const testTechnicianEmail = 'borey@example.test';
const testTechnicianCompanyId = 'company-1';

Future<void> seedTechnicianInvite(FirebaseFirestore firestore, {DateTime? expiresAt}) =>
    firestore.collection('technicianInvites').doc(testTechnicianInviteId).set({
      'email': testTechnicianEmail,
      'companyId': testTechnicianCompanyId,
      'expiresAt': Timestamp.fromDate(
        expiresAt ?? DateTime.now().add(const Duration(days: 1)),
      ),
    });
