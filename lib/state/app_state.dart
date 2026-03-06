import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/models.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class _JobSnapshot {
  final int applicantCount;
  final String? hiredId;
  final JobStatus status;

  const _JobSnapshot({
    required this.applicantCount,
    required this.hiredId,
    required this.status,
  });
}

enum WorkerTier { newWorker, reliable, topRated }

class AppState extends ChangeNotifier {
  static const String _googleServerClientId =
      '387879577336-qeh1hns71n3fd2rscd020d3e734ruglr.apps.googleusercontent.com';
  static const String currentTermsVersion = '2026-03-01';
  static final RegExp _phoneRe = RegExp(r'(?<!\d)(?:\+?\d[\d\s().-]{7,}\d)');
  static final RegExp _emailRe =
      RegExp(r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b', caseSensitive: false);
  static final RegExp _socialRe = RegExp(
    r'(?:^|\s)(@[\w._]{2,}|snap(?:chat)?|instagram|insta|ig|tiktok|discord|telegram|whatsapp)\b',
    caseSensitive: false,
  );

  final _auth = FirebaseAuth.instance;
  ThemeMode _themeMode = ThemeMode.system;

  UserProfile? _profile;
  bool get isLoggedIn => _auth.currentUser != null;
  UserProfile? get profile => _profile;
  ThemeMode get themeMode => _themeMode;
  bool get privacyBubbleEnabled => _profile?.privacyBubbleEnabled ?? true;
  bool get isShadowBanned => _profile?.shadowBanned == true;

  String get currentUserId => _auth.currentUser?.uid ?? 'guest';
  String get currentUserName {
    final profileName = _profile?.name.trim();
    if (profileName != null && profileName.isNotEmpty) return profileName;
    final displayName = _auth.currentUser?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;
    final email = _auth.currentUser?.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }
    return 'Guest';
  }

  List<Job> _jobs = [];
  List<Service> _services = [];
  List<Report> _reports = [];
  List<Review> _reviews = [];

  StreamSubscription? _jobsSub;
  StreamSubscription? _servicesSub;
  StreamSubscription? _reportsSub;
  StreamSubscription? _reviewsSub;
  StreamSubscription? _conversationsSub;

  bool _jobsBootstrapComplete = false;
  final Map<String, _JobSnapshot> _lastJobSnapshots = {};

  bool _conversationBootstrapComplete = false;
  final Map<String, DateTime> _lastConversationSeenAt = {};
  final Map<String, DateTime> _recentOutgoingAt = {};

  final Set<String> _blockedUserIds = {};
  final Set<String> _hiddenJobIds = {};
  final Set<String> _hiddenServiceIds = {};
  final Set<String> _hiddenHuddlePostIds = {};
  final List<DateTime> _deleteStrikes = [];
  DateTime? _postingSuspendedUntil;

  String _userLocationText = '';
  String get userLocationText => _userLocationText;
  void setUserLocation(String location) {
    _userLocationText = location;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }

  bool get canPostJobs => isLoggedIn;
  bool get hasAcceptedTerms {
    final p = _profile;
    if (p == null) return false;
    final versionOk = (p.termsAcceptedVersion ?? '').trim() == currentTermsVersion;
    final accepted = p.termsAcceptedAt != null;
    final waiver = p.liabilityWaiverAcceptedAt != null;
    final risk = p.riskAcknowledgedAt != null;
    final guardianRequired = (p.age ?? 17) < 18;
    final guardian = !guardianRequired || p.guardianConsentAt != null;
    return accepted && versionOk && waiver && risk && guardian;
  }

  AppState() {
    if (kIsWeb) {
      // Keep users signed in across refreshes/restarts on this device.
      unawaited(_auth.setPersistence(Persistence.LOCAL));
    }
    _auth.authStateChanges().listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    if (user != null) {
      await _syncProfileForCurrentUser();
    } else {
      _profile = null;
      _stopListening();
      _jobsBootstrapComplete = false;
      _lastJobSnapshots.clear();
      _conversationBootstrapComplete = false;
      _lastConversationSeenAt.clear();
      _recentOutgoingAt.clear();
      _jobs = [];
      _services = [];
      _reports = [];
      _reviews = [];
      _blockedUserIds.clear();
      _hiddenJobIds.clear();
      _hiddenServiceIds.clear();
      _hiddenHuddlePostIds.clear();
    }
    notifyListeners();
  }

  void _startListening() {
    _jobsSub?.cancel();
    _servicesSub?.cancel();
    _reportsSub?.cancel();
    _reviewsSub?.cancel();
    _conversationsSub?.cancel();

    _jobsBootstrapComplete = false;
    _lastJobSnapshots.clear();
    _jobsSub = FirestoreService.jobsStream().listen((data) async {
      if (!_jobsBootstrapComplete) {
        for (final j in data) {
          _lastJobSnapshots[j.id] = _toSnapshot(j);
        }
        _jobsBootstrapComplete = true;
      } else {
        await _notifyOnJobEvents(data);
      }
      _jobs = data;
      notifyListeners();
    });
    _servicesSub = FirestoreService.servicesStream().listen((data) {
      _services = data;
      notifyListeners();
    });
    _reportsSub = FirestoreService.reportsStream().listen((data) {
      _reports = data;
      _blockedUserIds.clear();
      for (final r in _reports) {
        if (r.blocked && r.reportedUserId != null && r.reporterId == currentUserId) {
          _blockedUserIds.add(r.reportedUserId!);
        }
      }
      notifyListeners();
    });
    _reviewsSub = FirestoreService.reviewsStream().listen((data) {
      _reviews = data;
      notifyListeners();
    });

    _conversationBootstrapComplete = false;
    _lastConversationSeenAt.clear();
    _recentOutgoingAt.clear();
    _conversationsSub = FirestoreService.conversationsStream(currentUserId).listen(
      (items) async {
        final activeIds = items.map((c) => c.id).toSet();
        _lastConversationSeenAt.removeWhere((id, _) => !activeIds.contains(id));
        _recentOutgoingAt.removeWhere((id, at) =>
            !activeIds.contains(id) ||
            DateTime.now().difference(at) > const Duration(minutes: 3));

        if (!_conversationBootstrapComplete) {
          for (final conv in items) {
            final last = conv.lastMessageTime;
            if (last != null) _lastConversationSeenAt[conv.id] = last;
          }
          _conversationBootstrapComplete = true;
          return;
        }

        for (final conv in items) {
          final last = conv.lastMessageTime;
          if (last == null) continue;
          final prev = _lastConversationSeenAt[conv.id];
          final isNew = prev == null || last.isAfter(prev);
          _lastConversationSeenAt[conv.id] = last;
          if (!isNew) continue;

          final outgoingAt = _recentOutgoingAt[conv.id];
          final likelyOwnMessage = outgoingAt != null &&
              last.isBefore(outgoingAt.add(const Duration(seconds: 8)));
          if (likelyOwnMessage) continue;

          await NotificationService.instance.showMessageNotification(
            title: conv.otherUserName.isEmpty
                ? 'New message'
                : 'New message from ${conv.otherUserName}',
            body: conv.lastMessagePreview,
            payload: {
              'type': 'conversation',
              'conversationId': conv.id,
              'otherUserName': conv.otherUserName,
              'contextLabel': conv.contextLabel,
            },
          );
        }
      },
    );
  }

  void _stopListening() {
    _jobsSub?.cancel();
    _servicesSub?.cancel();
    _reportsSub?.cancel();
    _reviewsSub?.cancel();
    _conversationsSub?.cancel();
  }

  _JobSnapshot _toSnapshot(Job job) => _JobSnapshot(
        applicantCount: job.applicantIds.length,
        hiredId: job.hiredId,
        status: job.status,
      );

  Future<void> _notifyOnJobEvents(List<Job> jobs) async {
    final activeIds = jobs.map((j) => j.id).toSet();
    _lastJobSnapshots.removeWhere((id, _) => !activeIds.contains(id));

    for (final j in jobs) {
      final prev = _lastJobSnapshots[j.id];
      final next = _toSnapshot(j);
      _lastJobSnapshots[j.id] = next;
      if (prev == null) continue;

      final applicantDelta = j.applicantIds.length - prev.applicantCount;
      if (j.posterId == currentUserId && applicantDelta > 0) {
        await NotificationService.instance.showMessageNotification(
          title: 'New applicant',
          body: '$applicantDelta new applicant${applicantDelta == 1 ? '' : 's'} for "${j.title}"',
          payload: {
            'type': 'dashboard',
            'jobId': j.id,
            'source': 'new_applicant',
          },
        );
      }

      final justHiredYou =
          j.hiredId == currentUserId && prev.hiredId != currentUserId;
      if (justHiredYou) {
        await NotificationService.instance.showMessageNotification(
          title: 'You were hired',
          body: 'You were hired for "${j.title}".',
          payload: {
            'type': 'dashboard',
            'jobId': j.id,
            'source': 'hired',
          },
        );
      }

      final completedNow =
          prev.status != JobStatus.completed && j.status == JobStatus.completed;
      final relatedToMe =
          j.posterId == currentUserId || j.hiredId == currentUserId;
      if (completedNow && relatedToMe) {
        await NotificationService.instance.showMessageNotification(
          title: 'Job completed',
          body: '"${j.title}" was marked completed.',
          payload: {
            'type': 'dashboard',
            'jobId': j.id,
            'source': 'completed',
          },
        );
      }
    }
  }

  // ── Auth ──

  Future<void> _syncProfileForCurrentUser({
    String? preferredName,
    int? preferredAge,
    String? authProvider,
    bool touchLogin = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    UserProfile? existing;
    try {
      existing = await FirestoreService.getUser(user.uid);
    } catch (_) {
      existing = null;
    }

    final normalizedEmail =
        (user.email ?? existing?.email ?? '').trim().toLowerCase();
    final nameFromInput = preferredName?.trim();
    final resolvedName = (nameFromInput != null && nameFromInput.isNotEmpty)
        ? nameFromInput
        : ((existing?.name.isNotEmpty ?? false)
            ? existing!.name
            : ((user.displayName?.trim().isNotEmpty ?? false)
                ? user.displayName!.trim()
                : (normalizedEmail.isNotEmpty
                    ? normalizedEmail.split('@').first
                    : 'User')));

    final profile = existing ??
        UserProfile(
          id: user.uid,
          name: resolvedName,
          email: normalizedEmail,
          age: preferredAge,
        );

    profile.name = resolvedName;
    if (normalizedEmail.isNotEmpty) {
      profile.email = normalizedEmail;
    }
    if (preferredAge != null) {
      profile.age = preferredAge;
    }

    try {
      await FirestoreService.createOrUpdateUser(
        profile,
        authProvider: authProvider,
        touchLogin: touchLogin,
      );
    } catch (_) {
      // Keep local profile active even if Firestore write is temporarily unavailable.
    }

    _profile = profile;
    _hiddenJobIds
      ..clear()
      ..addAll(profile.hiddenJobIds);
    _hiddenServiceIds
      ..clear()
      ..addAll(profile.hiddenServiceIds);
    _hiddenHuddlePostIds
      ..clear()
      ..addAll(profile.hiddenHuddlePostIds);
    _startListening();
    notifyListeners();
  }

  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    int? age,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    try {
      // Join-now should create a brand-new account session.
      // If someone is currently logged in, clear that session first.
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }
      final cred = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      try {
        await cred.user?.updateDisplayName(name.trim());
      } catch (_) {}
      return await _finalizeAuthSession(
        credential: cred,
        preferredName: name,
        preferredAge: age,
        authProvider: 'password',
        touchLogin: true,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'That email is already in use. Use a different email or log in.';
      }
      if (e.code == 'configuration-not-found' ||
          e.code == 'operation-not-allowed') {
        return 'Email/Password auth is not enabled in Firebase. '
            'Open Firebase Console > Authentication > Sign-in method > enable Email/Password.';
      }
      return 'Sign up failed (${e.code}): ${e.message ?? 'Unknown auth error'}';
    } catch (e) {
      return 'Sign up failed: $e';
    }
  }

  Future<String?> login(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    try {
      final rawPassword = password;
      final trimmedPassword = password.trim();

      UserCredential cred;
      try {
        cred = await _auth.signInWithEmailAndPassword(
          email: normalizedEmail,
          password: rawPassword,
        );
      } on FirebaseAuthException catch (e) {
        final canRetryTrimmed = (e.code == 'invalid-credential' ||
                e.code == 'invalid-login-credentials' ||
                e.code == 'wrong-password') &&
            trimmedPassword.isNotEmpty &&
            trimmedPassword != rawPassword;
        if (!canRetryTrimmed) rethrow;
        cred = await _auth.signInWithEmailAndPassword(
          email: normalizedEmail,
          password: trimmedPassword,
        );
      }

      return await _finalizeAuthSession(
        credential: cred,
        authProvider: 'password',
        touchLogin: true,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'configuration-not-found' ||
          e.code == 'operation-not-allowed') {
        return 'Email/Password auth is not enabled in Firebase. '
            'Open Firebase Console > Authentication > Sign-in method > enable Email/Password.';
      }
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-login-credentials') {
        try {
          final userDoc = await FirestoreService.getUserByEmail(normalizedEmail);
          final provider = (userDoc?['authProvider'] ?? '').toString();
          if (provider == 'google.com') {
            return 'This account is linked to Google sign-in. '
                'Tap "Continue with Google" for this email.';
          }
          if (userDoc != null) {
            return 'Password is incorrect for this account. '
                'Use "Forgot password?" to reset it.';
          }
        } catch (_) {}
        return 'Email or password is incorrect.';
      }
      if (e.code == 'network-request-failed') {
        return 'Network error. Check your internet and try again.';
      }
      if (e.code == 'too-many-requests') {
        return 'Too many attempts. Please wait a bit and try again.';
      }
      if (e.code == 'internal-error') {
        // Firebase can occasionally return this transiently even with valid creds.
        return 'Temporary login error. Please try again in a few seconds.';
      }
      return 'Login failed (${e.code}): ${e.message ?? 'Unknown auth error'}';
    }
  }

  Future<String?> loginWithEmailPasswordDirect(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      return await _finalizeAuthSession(
        credential: cred,
        authProvider: 'password',
        touchLogin: true,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'configuration-not-found' ||
          e.code == 'operation-not-allowed') {
        return 'Email/Password auth is not enabled in Firebase. '
            'Open Firebase Console > Authentication > Sign-in method > enable Email/Password.';
      }
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-login-credentials') {
        return 'Email or password is incorrect.';
      }
      if (e.code == 'network-request-failed') {
        return 'Network error. Check your internet and try again.';
      }
      if (e.code == 'too-many-requests') {
        return 'Too many attempts. Please wait a bit and try again.';
      }
      if (e.code == 'internal-error') {
        // Firebase can occasionally return this transiently even with valid creds.
        return 'Temporary login error. Please try again in a few seconds.';
      }
      return 'Login failed (${e.code}): ${e.message ?? 'Unknown auth error'}';
    }
  }

  Future<String?> loginWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedLink = emailLink.trim();
    try {
      if (!_auth.isSignInWithEmailLink(normalizedLink)) {
        return 'That link is invalid. Paste the full sign-in link from your email.';
      }
      final cred = await _auth.signInWithEmailLink(
        email: normalizedEmail,
        emailLink: normalizedLink,
      );
      return await _finalizeAuthSession(
        credential: cred,
        authProvider: 'email-link',
        touchLogin: true,
      );
    } on FirebaseAuthException catch (e) {
      return 'Email link login failed (${e.code}): ${e.message ?? 'Unknown auth error'}';
    } catch (e) {
      return 'Email link login failed: $e';
    }
  }

  Future<String?> _finalizeAuthSession({
    required UserCredential credential,
    String? preferredName,
    int? preferredAge,
    String? authProvider,
    bool touchLogin = false,
  }) async {
    final userFromCredential = credential.user;
    final user = userFromCredential ?? _auth.currentUser;
    if (user == null) {
      return 'Sign in failed: Firebase did not return a user session.';
    }

    try {
      await user.reload();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'user-token-expired' ||
          e.code == 'invalid-user-token') {
        return 'Sign in failed: session token is invalid. Please try again.';
      }
    }

    User? activeUser = _auth.currentUser;
    if (activeUser == null) {
      // Some environments report credential success before currentUser settles.
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        activeUser = _auth.currentUser;
        if (activeUser != null) break;
      }
    }
    if (activeUser == null) {
      return 'Sign in failed: account exists but session was not established.';
    }

    try {
      // Prefer non-forced token read to avoid transient internal errors.
      String? token = await activeUser.getIdToken(false);
      if (token == null || token.isEmpty) {
        token = await activeUser.getIdToken(true);
      }
      if (token == null || token.isEmpty) {
        return 'Sign in failed: Firebase did not provide a valid sign-in token.';
      }
    } on FirebaseAuthException catch (e) {
      // Do not block login on transient token refresh failures if session exists.
      if (e.code == 'internal-error' || e.code == 'network-request-failed') {
        await _syncProfileForCurrentUser(
          preferredName: preferredName,
          preferredAge: preferredAge,
          authProvider: authProvider,
          touchLogin: touchLogin,
        );
        return null;
      }
      return 'Sign in failed (${e.code}): ${e.message ?? 'Could not read auth token'}';
    }

    await _syncProfileForCurrentUser(
      preferredName: preferredName,
      preferredAge: preferredAge,
      authProvider: authProvider,
      touchLogin: touchLogin,
    );
    return null;
  }

  Future<String?> loginWithGoogle({bool forceAccountPicker = false}) async {
    final googleSignIn = GoogleSignIn.instance;
    final trace = <String>[];
    void step(String s) {
      trace.add(s);
      debugPrint('[GoogleAuth] $s');
    }

    String fail(String message) {
      final diag = trace.join(' | ');
      if (diag.isEmpty) return message;
      return '$message\n[diag] $diag';
    }

    step('start platform=${kIsWeb ? 'web' : defaultTargetPlatform.name} forcePicker=$forceAccountPicker');
    try {
      UserCredential cred;
      if (kIsWeb) {
        step('web: signInWithPopup begin');
        final provider = GoogleAuthProvider();
        cred = await _auth.signInWithPopup(provider);
        step('web: signInWithPopup success');
      } else {
        if (defaultTargetPlatform == TargetPlatform.android) {
          // Use a single Google plugin flow on Android to avoid double prompts.
          await googleSignIn.initialize();
          step('android: plugin initialize success');
          GoogleSignInAccount? account;
          if (forceAccountPicker) {
            try {
              await googleSignIn.signOut();
              step('android: plugin signOut success');
            } catch (_) {}
          }
          if (!forceAccountPicker) {
            try {
              account = await googleSignIn.attemptLightweightAuthentication();
              step('android: lightweightAuth ${account == null ? 'miss' : 'hit'}');
            } catch (_) {}
          }
          step('android: plugin authenticate begin');
          account ??= await googleSignIn.authenticate();
          step('android: plugin authenticate success');
          final auth = account.authentication;
          if (auth.idToken == null || auth.idToken!.isEmpty) {
            return fail('Google sign-in did not return a valid ID token. '
                'Check your Firebase Google provider setup and SHA fingerprint.');
          }
          final credential = GoogleAuthProvider.credential(
            idToken: auth.idToken,
          );
          cred = await _auth.signInWithCredential(credential);
          step('android: signInWithCredential success');
        } else {
          await googleSignIn.initialize(
            serverClientId: _googleServerClientId,
          );
          step('non-android: plugin initialize success');
          // Keep last Google session on device so returning users don't need
          // to re-enter email/password every time.
          GoogleSignInAccount? account;
          if (forceAccountPicker) {
            try {
              await googleSignIn.signOut();
              step('non-android: plugin signOut success');
            } catch (_) {}
          }
          if (!forceAccountPicker) {
            try {
              account = await googleSignIn.attemptLightweightAuthentication();
              step('non-android: lightweightAuth ${account == null ? 'miss' : 'hit'}');
            } catch (_) {}
          }
          step('non-android: plugin authenticate begin');
          account ??= await googleSignIn.authenticate();
          step('non-android: plugin authenticate success');
          final auth = account.authentication;
          if (auth.idToken == null || auth.idToken!.isEmpty) {
            return fail('Google sign-in did not return a valid ID token. '
                'Check your Firebase Google provider setup and SHA fingerprint.');
          }
          final credential = GoogleAuthProvider.credential(
            idToken: auth.idToken,
          );
          cred = await _auth.signInWithCredential(credential);
          step('non-android: signInWithCredential success');
        }
      }

      final user = cred.user;
      if (user == null) return fail('Google sign in failed: no user returned.');
      step('firebase user uid=${user.uid}');

      return await _finalizeAuthSession(
        credential: cred,
        preferredName: user.displayName,
        authProvider: 'google.com',
        touchLogin: true,
      );
    } on GoogleSignInException catch (e) {
      step('GoogleSignInException code=${e.code.name} desc=${(e.description ?? '').trim()}');
      switch (e.code) {
        case GoogleSignInExceptionCode.canceled:
          // Some Android builds report "canceled" even though account selection
          // just succeeded. Give Firebase a brief moment to settle currentUser.
          for (var i = 0; i < 5; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 180));
            final settled = _auth.currentUser;
            if (settled == null) continue;
            final hasGoogleProvider = settled.providerData.any(
              (p) => p.providerId == 'google.com',
            );
            if (!hasGoogleProvider) continue;
            step('canceled-recovery: found settled firebase google session');
            await _syncProfileForCurrentUser(
              preferredName: settled.displayName,
              authProvider: 'google.com',
              touchLogin: true,
            );
            return null;
          }
          // If plugin reports canceled but Firebase already has a Google session,
          // continue and treat this as successful sign-in.
          final active = _auth.currentUser;
          if (active != null) {
            final hasGoogleProvider = active.providerData.any(
              (p) => p.providerId == 'google.com',
            );
            if (hasGoogleProvider) {
              step('canceled-recovery: active firebase google provider');
              await _syncProfileForCurrentUser(
                preferredName: active.displayName,
                authProvider: 'google.com',
                touchLogin: true,
              );
              return null;
            }
          }
          // Some Android devices can return "canceled" after account selection.
          // If a lightweight session exists, continue sign-in instead of failing.
          try {
            final recovered = await googleSignIn.attemptLightweightAuthentication();
            if (recovered != null) {
              step('canceled-recovery: lightweightAuth hit');
              final auth = recovered.authentication;
              if (auth.idToken != null && auth.idToken!.isNotEmpty) {
                final credential = GoogleAuthProvider.credential(
                  idToken: auth.idToken,
                );
                final cred = await _auth.signInWithCredential(credential);
                final user = cred.user;
                if (user != null) {
                  step('canceled-recovery: signInWithCredential success');
                  return await _finalizeAuthSession(
                    credential: cred,
                    preferredName: user.displayName,
                    authProvider: 'google.com',
                    touchLogin: true,
                  );
                }
              }
            }
          } catch (_) {}
          return fail('Google sign-in was canceled.');
        case GoogleSignInExceptionCode.interrupted:
          return fail('Google sign-in was interrupted. Try again.');
        case GoogleSignInExceptionCode.uiUnavailable:
          return fail('Google sign-in UI is unavailable on this device/emulator.');
        case GoogleSignInExceptionCode.clientConfigurationError:
          return fail('Google sign-in client is misconfigured. '
              'Check SHA fingerprints and google-services.json.');
        case GoogleSignInExceptionCode.providerConfigurationError:
          return fail('Google Play Services/Google provider is not configured correctly on this device.');
        case GoogleSignInExceptionCode.userMismatch:
          return fail('Google account mismatch. Try again and pick the account explicitly.');
        case GoogleSignInExceptionCode.unknownError:
          final desc = e.description?.trim();
          if (desc != null && desc.isNotEmpty) {
            return fail('Google sign-in failed: $desc');
          }
          return fail('Google sign-in failed (unknown error).');
      }
    } on FirebaseAuthException catch (e) {
      step('FirebaseAuthException code=${e.code} msg=${e.message ?? ''}');
      if (e.code == 'account-exists-with-different-credential' ||
          e.code == 'credential-already-in-use' ||
          e.code == 'email-already-in-use') {
        return fail('That email already has a different sign-in method. '
            'Use your password (or "Forgot password?") first, then try Google again.');
      }
      if (e.code == 'operation-not-allowed' ||
          e.code == 'configuration-not-found') {
        return fail('Google sign-in is not enabled/configured in Firebase for this app.');
      }
      return fail('Google sign in failed (${e.code}): ${e.message ?? 'Unknown auth error'}');
    } catch (e) {
      step('UnknownException $e');
      return fail('Google sign in failed: $e');
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> ensureProfileLoaded() async {
    if (_auth.currentUser == null) return;
    if (_profile != null) return;
    await _syncProfileForCurrentUser();
  }

  Future<void> updateProfile({
    String? name,
    String? location,
    String? bio,
    Set<String>? skills,
    Set<String>? interests,
    String? school,
    int? age,
    String? vaultGoal,
    double? vaultTargetAmount,
  }) async {
    if (_profile == null) return;
    if (name != null) _profile!.name = name;
    if (location != null) _profile!.location = location;
    if (bio != null) _profile!.bio = bio;
    if (skills != null) _profile!.skills = skills;
    if (interests != null) _profile!.interests = interests;
    if (school != null) _profile!.school = school;
    if (age != null) {
      final currentAge = _profile!.age;
      if (currentAge != null && age != currentAge) {
        if (age <= currentAge) {
          throw Exception('Age can only increase, by 1 year each year.');
        }
        if ((age - currentAge) != 1) {
          throw Exception('Age can only increase by 1 year at a time.');
        }
        final lastChanged = _profile!.ageLastUpdatedAt;
        if (lastChanged != null &&
            DateTime.now().difference(lastChanged) < const Duration(days: 365)) {
          throw Exception('You can only change age once every year.');
        }
        _profile!.ageLastUpdatedAt = DateTime.now();
      } else if (currentAge == null) {
        _profile!.ageLastUpdatedAt = DateTime.now();
      }
      _profile!.age = age;
    }
    if (vaultGoal != null) _profile!.vaultGoal = vaultGoal;
    if (vaultTargetAmount != null) _profile!.vaultTargetAmount = vaultTargetAmount;
    await FirestoreService.createOrUpdateUser(_profile!);
    notifyListeners();
  }

  Future<void> acceptTerms({
    required String version,
    required bool guardianConsent,
  }) async {
    if (_profile == null) return;
    final now = DateTime.now();
    _profile!.termsAcceptedAt = now;
    _profile!.termsAcceptedVersion = version.trim();
    _profile!.liabilityWaiverAcceptedAt = now;
    _profile!.riskAcknowledgedAt = now;
    if ((_profile!.age ?? 17) < 18 && guardianConsent) {
      _profile!.guardianConsentAt = now;
    }
    await FirestoreService.createOrUpdateUser(_profile!);
    notifyListeners();
  }

  Future<void> markHuddleRepliesSeen() async {
    if (_profile == null) return;
    _profile!.huddleRepliesSeenAt = DateTime.now();
    await FirestoreService.createOrUpdateUser(_profile!);
    notifyListeners();
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return 'You are not logged in.';
    final email = user.email;
    if (email == null || email.trim().isEmpty) {
      return 'Your account does not have a password login email.';
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: email.trim().toLowerCase(),
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-login-credentials') {
        return 'Current password is incorrect.';
      }
      if (e.code == 'weak-password') return 'New password is too weak.';
      if (e.code == 'requires-recent-login') {
        return 'Please log in again, then try changing password.';
      }
      return 'Password change failed (${e.code}).';
    } catch (e) {
      return 'Password change failed: $e';
    }
  }

  // ── Data getters ──

  List<Job> get jobs => _jobs;
  List<Service> get services => _services;
  List<Report> get reports => _reports;
  List<Review> get reviews => _reviews;
  Set<String> get blockedUserIds => Set.unmodifiable(_blockedUserIds);
  Set<String> get hiddenJobIds => Set.unmodifiable(_hiddenJobIds);
  Set<String> get hiddenServiceIds => Set.unmodifiable(_hiddenServiceIds);
  Set<String> get hiddenHuddlePostIds => Set.unmodifiable(_hiddenHuddlePostIds);

  // ── Stats ──

  List<Job> get myPostedJobs =>
      _jobs.where((j) => j.posterId == currentUserId).toList();

  List<Job> get myAppliedJobs =>
      _jobs.where((j) => j.applicantIds.contains(currentUserId)).toList();

  List<Job> get myCurrentJobs => _jobs
      .where((j) =>
          (j.status == JobStatus.inProgress ||
              j.status == JobStatus.pendingCompletion) &&
          (j.posterId == currentUserId || j.hiredId == currentUserId))
      .toList();

  List<Job> get myCompletedJobs => _jobs
      .where((j) =>
          j.status == JobStatus.completed &&
          (j.posterId == currentUserId || j.hiredId == currentUserId))
      .toList();

  int get peopleHired =>
      _jobs.where((j) => j.posterId == currentUserId && j.hiredId != null).length;

  double get moneyEarned => _jobs
      .where(
          (j) => j.status == JobStatus.completed && j.hiredId == currentUserId)
      .fold(0.0, (sum, j) => sum + j.payment);

  double get moneySpent => _jobs
      .where(
          (j) => j.status == JobStatus.completed && j.posterId == currentUserId)
      .fold(0.0, (sum, j) => sum + j.payment);

  String? get vaultGoal => _profile?.vaultGoal;
  double? get vaultTargetAmount => _profile?.vaultTargetAmount;
  bool get hasVaultGoal =>
      (vaultGoal ?? '').trim().isNotEmpty &&
      (vaultTargetAmount ?? 0) > 0;
  double get vaultSavedAmount => moneyEarned;
  double get vaultRemainingAmount {
    if (!hasVaultGoal) return 0;
    final remaining = (vaultTargetAmount ?? 0) - vaultSavedAmount;
    return remaining <= 0 ? 0 : remaining;
  }

  double get vaultProgress {
    if (!hasVaultGoal) return 0;
    final target = vaultTargetAmount ?? 0;
    if (target <= 0) return 0;
    final value = vaultSavedAmount / target;
    return value.clamp(0.0, 1.0);
  }

  Job? get vaultSuggestedJob {
    if (!hasVaultGoal) return null;
    final openJobs = _jobs.where((j) => j.status == JobStatus.open);
    final local = (_userLocationText.isNotEmpty
            ? _userLocationText
            : (_profile?.location ?? ''))
        .toLowerCase();

    if (local.isNotEmpty) {
      for (final j in openJobs) {
        if (j.posterId == currentUserId) continue;
        if (_blockedUserIds.contains(j.posterId)) continue;
        if (j.location.toLowerCase().contains(local)) return j;
      }
    }

    for (final j in openJobs) {
      if (j.posterId == currentUserId) continue;
      if (_blockedUserIds.contains(j.posterId)) continue;
      return j;
    }
    return null;
  }

  String get vaultNudgeMessage {
    if (!hasVaultGoal) return '';
    if (vaultRemainingAmount <= 0) {
      return 'You reached your "${vaultGoal!.trim()}" goal. Great job!';
    }

    final left = vaultRemainingAmount.toStringAsFixed(0);
    final suggested = vaultSuggestedJob;
    if (suggested != null) {
      return 'You are only \$$left away from "${vaultGoal!.trim()}". '
          'There is a "${suggested.title}" job near ${suggested.location}.';
    }
    return 'You are only \$$left away from "${vaultGoal!.trim()}". '
        'Check new jobs to move closer to your goal.';
  }

  List<Review> reviewsForUser(String userId) =>
      _reviews.where((r) => r.workerId == userId).toList();

  double averageRatingForUser(String userId) {
    final r = reviewsForUser(userId);
    if (r.isEmpty) return 0;
    return r.map((x) => x.stars).reduce((a, b) => a + b) / r.length;
  }

  int completedJobCountForUser(String userId) => _jobs
      .where((j) => j.status == JobStatus.completed && j.hiredId == userId)
      .length;

  WorkerTier workerTierForUser(String userId) {
    final completed = completedJobCountForUser(userId);
    final rating = averageRatingForUser(userId);
    if (completed >= 15 && rating >= 4.0) return WorkerTier.topRated;
    if (completed >= 5 && rating >= 3.5) return WorkerTier.reliable;
    return WorkerTier.newWorker;
  }

  bool isVerified(String userId) {
    final tier = workerTierForUser(userId);
    return tier == WorkerTier.reliable || tier == WorkerTier.topRated;
  }

  double get myRating => averageRatingForUser(currentUserId);
  int get myReviewCount => reviewsForUser(currentUserId).length;
  bool get amVerified => isVerified(currentUserId);
  WorkerTier get myWorkerTier => workerTierForUser(currentUserId);

  List<Job> get myPendingConfirmJobs => _jobs
      .where((j) =>
          j.status == JobStatus.pendingCompletion &&
          j.posterId == currentUserId)
      .toList();

  bool hasReviewedJob(String jobId) =>
      _reviews.any((r) => r.jobId == jobId && r.reviewerId == currentUserId);

  // ── Limits ──

  int get myActiveHiredJobs => _jobs
      .where((j) =>
          j.hiredId == currentUserId &&
          (j.status == JobStatus.inProgress ||
              j.status == JobStatus.pendingCompletion))
      .length;

  bool get canWorkMoreJobs => myActiveHiredJobs < 3;

  int get myCompletedPostedJobCount => _jobs
      .where(
          (j) => j.posterId == currentUserId && j.status == JobStatus.completed)
      .length;

  bool get isTrustedPoster => myCompletedPostedJobCount >= 5;

  int get myActivePostedJobs => _jobs
      .where((j) =>
          j.posterId == currentUserId &&
          j.status != JobStatus.completed)
      .length;

  int get maxPostableJobs => isTrustedPoster ? 5 : 3;

  bool get canPostMoreJobs =>
      !isPostingSuspended &&
      !amReportSuspended &&
      myActivePostedJobs < maxPostableJobs;

  // ── Deletion strike / suspension ──

  static const _strikeWindow = Duration(days: 7);
  static const _suspensionDuration = Duration(days: 3);
  static const _maxStrikesBeforeBan = 3;

  List<DateTime> get _recentStrikes {
    final cutoff = DateTime.now().subtract(_strikeWindow);
    _deleteStrikes.removeWhere((d) => d.isBefore(cutoff));
    return _deleteStrikes;
  }

  int get deleteStrikeCount => _recentStrikes.length;
  int get strikesRemaining => _maxStrikesBeforeBan - deleteStrikeCount;

  bool get isPostingSuspended =>
      _postingSuspendedUntil != null &&
      DateTime.now().isBefore(_postingSuspendedUntil!);

  DateTime? get postingSuspendedUntil => _postingSuspendedUntil;

  Duration get suspensionTimeLeft => isPostingSuspended
      ? _postingSuspendedUntil!.difference(DateTime.now())
      : Duration.zero;

  bool jobHasApplicants(String jobId) {
    final job = _jobs.cast<Job?>().firstWhere(
          (j) => j!.id == jobId,
          orElse: () => null,
        );
    return job != null && job.applicantIds.isNotEmpty;
  }

  Future<String?> deleteJobWithStrike(String jobId) async {
    final job = _jobs.cast<Job?>().firstWhere(
          (j) => j!.id == jobId,
          orElse: () => null,
        );
    if (job == null) return null;

    final hadApplicants = job.applicantIds.isNotEmpty;
    await FirestoreService.deleteJob(jobId);

    if (!hadApplicants) return null;

    _deleteStrikes.add(DateTime.now());
    await FirestoreService.addDeleteStrike(currentUserId);

    String? warning;
    if (_recentStrikes.length >= _maxStrikesBeforeBan) {
      _postingSuspendedUntil = DateTime.now().add(_suspensionDuration);
      await FirestoreService.setUserSuspension(
          currentUserId, _postingSuspendedUntil);
      warning = 'suspended';
    } else {
      final left = _maxStrikesBeforeBan - _recentStrikes.length;
      warning = 'strike:$left';
    }

    notifyListeners();
    return warning;
  }

  List<Service> get myServices =>
      _services.where((s) => s.providerId == currentUserId).toList();

  // ── Jobs ──

  Future<void> addJob(Job job) async {
    if (isShadowBanned) {
      throw Exception('Your account is restricted while under safety review.');
    }
    if (job.posterId.trim().isEmpty || job.posterId == 'guest') {
      throw Exception('You must be logged in to post a job.');
    }
    // Optimistic update so "Posted Jobs" shows immediately in Dashboard.
    final exists = _jobs.any((j) => j.id == job.id);
    if (!exists) {
      _jobs = [job, ..._jobs];
      notifyListeners();
    }
    try {
      await FirestoreService.addJob(job);
    } catch (e) {
      // Roll back optimistic insert when backend write fails.
      _jobs.removeWhere((j) => j.id == job.id);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> applyToJob(String jobId) async {
    final job = _jobs.firstWhere((j) => j.id == jobId);
    if (!job.applicantIds.contains(currentUserId)) {
      job.applicantIds.add(currentUserId);
      job.applicantNames.add(_publicApplicantName(currentUserName));
      await FirestoreService.updateJob(job);
    }
  }

  String _publicApplicantName(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'User';
    if (parts.length == 1) return parts.first;
    return '${parts.first} ${parts.last[0]}.';
  }

  Future<void> hireApplicant(
      String jobId, String applicantId, String applicantName) async {
    final job = _jobs.firstWhere((j) => j.id == jobId);
    job.hiredId = applicantId;
    job.hiredName = applicantName;
    job.status = JobStatus.inProgress;
    await FirestoreService.updateJob(job);

    final conv = await FirestoreService.getOrCreateConversation(
      myId: currentUserId,
      myName: currentUserName,
      otherUserId: applicantId,
      otherUserName: applicantName,
      contextLabel: 'Job: ${job.title}',
      scopeKey: 'job:$jobId',
    );
    await FirestoreService.sendMessage(
      conversationId: conv.id,
      message: ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        senderId: currentUserId,
        senderName: currentUserName,
        text:
            'Hey $applicantName! You\'re hired for "${job.title}". Let\'s chat about the details!',
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  Future<void> requestCompletion(String jobId) async {
    final job = _jobs.firstWhere((j) => j.id == jobId);
    job.status = JobStatus.pendingCompletion;
    await FirestoreService.updateJob(job);
  }

  Future<void> confirmCompletion(String jobId, double payment) async {
    final job = _jobs.firstWhere((j) => j.id == jobId);
    job.status = JobStatus.completed;
    job.payment = payment;
    job.completedAt = DateTime.now();
    await FirestoreService.updateJob(job);
  }

  Future<void> completeJob(String jobId, double payment) async {
    final job = _jobs.firstWhere((j) => j.id == jobId);
    job.status = JobStatus.completed;
    job.payment = payment;
    job.completedAt = DateTime.now();
    await FirestoreService.updateJob(job);
  }

  Future<void> addReview({
    required String jobId,
    required String workerId,
    required String workerName,
    required int stars,
    String? comment,
  }) async {
    final review = Review(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      jobId: jobId,
      reviewerId: currentUserId,
      reviewerName: currentUserName,
      workerId: workerId,
      workerName: workerName,
      stars: stars,
      comment: comment,
      createdAt: DateTime.now(),
    );
    await FirestoreService.addReview(review);
  }

  Future<void> deleteJob(String jobId) async {
    await FirestoreService.deleteJob(jobId);
  }

  Future<void> withdrawApplication(String jobId) async {
    final job = _jobs.firstWhere((j) => j.id == jobId);
    final idx = job.applicantIds.indexOf(currentUserId);
    if (idx != -1) {
      job.applicantIds.removeAt(idx);
      job.applicantNames.removeAt(idx);
      await FirestoreService.updateJob(job);
    }
  }

  // ── Services ──

  Future<void> addService(Service service) async {
    if (isShadowBanned) {
      throw Exception('Your account is restricted while under safety review.');
    }
    final existing = myServices;
    final alreadyHasDifferentService = existing.any((s) => s.id != service.id);
    if (alreadyHasDifferentService) {
      throw Exception(
        'You can only publish one service. Edit your existing service instead.',
      );
    }
    await FirestoreService.addService(service);
  }

  Future<void> updateService(Service service) async {
    await FirestoreService.updateService(service);
  }

  Future<void> deleteService(String serviceId) async {
    await FirestoreService.deleteService(serviceId);
  }

  // ── Report / Block ──

  final Map<String, DateTime> _reportSuspensions = {};
  static const _reportWindow = Duration(days: 30);

  bool hasAlreadyReported(String targetId) {
    return _reports.any(
        (r) => r.targetId == targetId && r.reporterId == currentUserId);
  }

  int uniqueReportCountForUser(String userId) {
    final cutoff = DateTime.now().subtract(_reportWindow);
    final recent = _reports.where((r) =>
        r.reportedUserId == userId && r.createdAt.isAfter(cutoff));
    final uniqueReporters = recent.map((r) => r.reporterId).toSet();
    return uniqueReporters.length;
  }

  bool isUserReportSuspended(String userId) {
    final expiry = _reportSuspensions[userId];
    return expiry != null && DateTime.now().isBefore(expiry);
  }

  DateTime? reportSuspensionEnd(String userId) => _reportSuspensions[userId];

  Duration reportSuspensionTimeLeft(String userId) {
    final expiry = _reportSuspensions[userId];
    if (expiry == null || DateTime.now().isAfter(expiry)) return Duration.zero;
    return expiry.difference(DateTime.now());
  }

  bool get amReportSuspended => isUserReportSuspended(currentUserId);

  Future<void> reportContent({
    required String targetType,
    required String targetId,
    required String reason,
    bool block = false,
    String? userId,
  }) async {
    final report = Report(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      reporterId: currentUserId,
      targetType: targetType,
      targetId: targetId,
      reportedUserId: userId,
      reason: reason,
      blocked: block,
      createdAt: DateTime.now(),
    );
    await FirestoreService.addReport(report);
    if (block && userId != null) {
      _blockedUserIds.add(userId);
    }
    if (userId != null) {
      _evaluateReportSuspension(userId);
    }
    notifyListeners();
  }

  void _evaluateReportSuspension(String userId) {
    final count = uniqueReportCountForUser(userId);
    Duration? duration;
    if (count >= 20) {
      duration = const Duration(days: 7);
    } else if (count >= 10) {
      duration = const Duration(days: 3);
    } else if (count >= 5) {
      duration = const Duration(days: 1);
    }
    if (duration != null) {
      _reportSuspensions[userId] = DateTime.now().add(duration);
    }
  }

  bool isBlocked(String userId) => _blockedUserIds.contains(userId);

  bool isJobHidden(String jobId) => _hiddenJobIds.contains(jobId);
  bool isServiceHidden(String serviceId) => _hiddenServiceIds.contains(serviceId);
  bool isHuddlePostHidden(String postId) => _hiddenHuddlePostIds.contains(postId);

  Future<void> hideJob(String jobId) async {
    if (jobId.trim().isEmpty || _hiddenJobIds.contains(jobId)) return;
    _hiddenJobIds.add(jobId);
    _profile?.hiddenJobIds.add(jobId);
    notifyListeners();
    if (_profile != null) {
      await FirestoreService.createOrUpdateUser(_profile!);
    }
  }

  Future<void> hideService(String serviceId) async {
    if (serviceId.trim().isEmpty || _hiddenServiceIds.contains(serviceId)) return;
    _hiddenServiceIds.add(serviceId);
    _profile?.hiddenServiceIds.add(serviceId);
    notifyListeners();
    if (_profile != null) {
      await FirestoreService.createOrUpdateUser(_profile!);
    }
  }

  Future<void> hideHuddlePost(String postId) async {
    if (postId.trim().isEmpty || _hiddenHuddlePostIds.contains(postId)) return;
    _hiddenHuddlePostIds.add(postId);
    _profile?.hiddenHuddlePostIds.add(postId);
    notifyListeners();
    if (_profile != null) {
      await FirestoreService.createOrUpdateUser(_profile!);
    }
  }

  Future<void> blockUser({
    required String userId,
    required String targetType,
    String? targetId,
    String reason = 'Blocked by user',
  }) async {
    if (userId.trim().isEmpty || userId == currentUserId || isBlocked(userId)) {
      return;
    }
    await reportContent(
      targetType: targetType,
      targetId: targetId ?? 'user:$userId',
      reason: reason,
      block: true,
      userId: userId,
    );
  }

  // ── Conversations ──

  Stream<List<Conversation>> get conversationsStream =>
      FirestoreService.conversationsStream(currentUserId);

  Stream<List<ChatMessage>> messagesStream(String conversationId) =>
      FirestoreService.messagesStream(conversationId);

  Stream<Conversation?> conversationStream(String conversationId) =>
      FirestoreService.conversationStream(conversationId, currentUserId);

  Future<Conversation> getOrCreateConversation({
    required String otherUserId,
    required String otherUserName,
    String? contextLabel,
    String? scopeKey,
  }) async {
    return FirestoreService.getOrCreateConversation(
      myId: currentUserId,
      myName: currentUserName,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      contextLabel: contextLabel,
      scopeKey: scopeKey,
    );
  }

  Future<void> deleteConversation(String conversationId) async {
    await FirestoreService.deleteConversation(conversationId);
  }

  Future<void> setConversationTyping(String conversationId, bool isTyping) async {
    await FirestoreService.setConversationTyping(
      conversationId: conversationId,
      userId: currentUserId,
      isTyping: isTyping,
    );
  }

  Future<void> markConversationSeen(String conversationId) async {
    final items = await FirestoreService.messagesStream(conversationId).first;
    DateTime seenAt = DateTime.now();
    for (final m in items.reversed) {
      if (m.senderId != currentUserId) {
        seenAt = m.timestamp;
        break;
      }
    }
    await FirestoreService.markConversationSeen(
      conversationId: conversationId,
      userId: currentUserId,
      seenAt: seenAt,
    );
  }

  Future<void> sendMessage(String conversationId, String text) async {
    if (isShadowBanned) {
      throw Exception('Messaging is restricted while your account is under review.');
    }
    final trimmed = text.trim();
    if (_phoneRe.hasMatch(trimmed) ||
        _emailRe.hasMatch(trimmed) ||
        _socialRe.hasMatch(trimmed)) {
      throw Exception(
        'Keep it in the app! For your safety, sharing personal contact info is disabled.',
      );
    }
    _recentOutgoingAt[conversationId] = DateTime.now();
    final message = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      senderId: currentUserId,
      senderName: currentUserName,
      text: trimmed,
      timestamp: DateTime.now(),
    );
    await FirestoreService.sendMessage(
      conversationId: conversationId,
      message: message,
    );
  }

  Future<void> deleteMessageForEveryone({
    required String conversationId,
    required ChatMessage message,
  }) async {
    if (message.senderId != currentUserId) {
      throw Exception('You can only delete your own messages.');
    }
    if (message.isDeleted) return;
    await FirestoreService.deleteMessageForEveryone(
      conversationId: conversationId,
      messageId: message.id,
      deletedById: currentUserId,
      deletedByName: currentUserName,
    );
  }

  Future<void> setPrivacyBubbleEnabled(bool enabled) async {
    final p = _profile;
    if (p == null) return;
    if (p.privacyBubbleEnabled == enabled) return;
    p.privacyBubbleEnabled = enabled;
    notifyListeners();
    await FirestoreService.createOrUpdateUser(p);
  }

  Future<void> deleteAccountWithDataWipe() async {
    if (!isLoggedIn) return;
    await FirestoreService.deleteMyAccountData();
    try {
      await _auth.currentUser?.delete();
    } catch (_) {
      // Deletion can fail when auth session is stale; data wipe still completes.
    }
    await logout();
  }

  // ── The Huddle ──

  HuddleAgeGroup get myAgeGroup =>
      (_profile?.age ?? 18) < 16
          ? HuddleAgeGroup.under16
          : HuddleAgeGroup.sixteenPlus;

  Future<void> addHuddlePost({
    required String text,
    required HuddleTag tag,
    required HuddleAgeGroup ageGroup,
  }) async {
    final post = HuddlePost(
      id: 'huddle_${DateTime.now().millisecondsSinceEpoch}',
      authorId: currentUserId,
      authorName: currentUserName,
      text: text,
      tag: tag,
      ageGroup: ageGroup,
      createdAt: DateTime.now(),
    );
    await FirestoreService.addHuddlePost(post);
  }

  Future<void> addHuddleReply({
    required String postId,
    required String text,
  }) async {
    final reply = HuddleReply(
      id: 'reply_${DateTime.now().millisecondsSinceEpoch}',
      authorId: currentUserId,
      authorName: currentUserName,
      text: text,
      createdAt: DateTime.now(),
    );
    await FirestoreService.addHuddleReply(postId, reply);
  }

  Future<void> deleteHuddlePost(String postId) async {
    await FirestoreService.deleteHuddlePost(postId);
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }
}
