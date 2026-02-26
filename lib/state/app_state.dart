import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/models.dart';
import '../services/firestore_service.dart';

class AppState extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;

  UserProfile? _profile;
  bool get isLoggedIn => _auth.currentUser != null;
  UserProfile? get profile => _profile;

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

  final Set<String> _blockedUserIds = {};
  final List<DateTime> _deleteStrikes = [];
  DateTime? _postingSuspendedUntil;

  String _userLocationText = '';
  String get userLocationText => _userLocationText;
  void setUserLocation(String location) {
    _userLocationText = location;
    notifyListeners();
  }

  bool get canPostJobs => isLoggedIn;

  AppState() {
    _auth.authStateChanges().listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    if (user != null) {
      await _syncProfileForCurrentUser();
    } else {
      _profile = null;
      _stopListening();
      _jobs = [];
      _services = [];
      _reports = [];
      _reviews = [];
    }
    notifyListeners();
  }

  void _startListening() {
    _jobsSub?.cancel();
    _servicesSub?.cancel();
    _reportsSub?.cancel();
    _reviewsSub?.cancel();

    _jobsSub = FirestoreService.jobsStream().listen((data) {
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
  }

  void _stopListening() {
    _jobsSub?.cancel();
    _servicesSub?.cancel();
    _reportsSub?.cancel();
    _reviewsSub?.cancel();
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

  Future<String?> loginWithGoogle() async {
    try {
      UserCredential cred;
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        cred = await _auth.signInWithPopup(provider);
      } else {
        final googleSignIn = GoogleSignIn.instance;
        await googleSignIn.initialize();
        // Force account picker each time so testing multiple accounts works.
        try {
          await googleSignIn.signOut();
        } catch (_) {}
        final account = await googleSignIn.authenticate();
        final auth = account.authentication;
        final credential = GoogleAuthProvider.credential(
          idToken: auth.idToken,
        );
        cred = await _auth.signInWithCredential(credential);
      }

      final user = cred.user;
      if (user == null) return 'Google sign in failed: no user returned.';

      await _syncProfileForCurrentUser(
        preferredName: user.displayName,
        authProvider: 'google.com',
        touchLogin: true,
      );
      return null;
    } on GoogleSignInException catch (e) {
      switch (e.code) {
        case GoogleSignInExceptionCode.canceled:
          return 'Google sign-in was canceled.';
        case GoogleSignInExceptionCode.interrupted:
          return 'Google sign-in was interrupted. Try again.';
        case GoogleSignInExceptionCode.uiUnavailable:
          return 'Google sign-in UI is unavailable on this device/emulator.';
        case GoogleSignInExceptionCode.clientConfigurationError:
          return 'Google sign-in client is misconfigured. '
              'Check SHA fingerprints and google-services.json.';
        case GoogleSignInExceptionCode.providerConfigurationError:
          return 'Google Play Services/Google provider is not configured correctly on this device.';
        case GoogleSignInExceptionCode.userMismatch:
          return 'Google account mismatch. Try again and pick the account explicitly.';
        case GoogleSignInExceptionCode.unknownError:
          final desc = e.description?.trim();
          if (desc != null && desc.isNotEmpty) {
            return 'Google sign-in failed: $desc';
          }
          return 'Google sign-in failed (unknown error).';
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'operation-not-allowed' ||
          e.code == 'configuration-not-found') {
        return 'Google sign-in is not enabled/configured in Firebase for this app.';
      }
      return 'Google sign in failed (${e.code}): ${e.message ?? 'Unknown auth error'}';
    } catch (e) {
      return 'Google sign in failed: $e';
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
    if (age != null) _profile!.age = age;
    if (vaultGoal != null) _profile!.vaultGoal = vaultGoal;
    if (vaultTargetAmount != null) _profile!.vaultTargetAmount = vaultTargetAmount;
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

  bool isVerified(String userId) {
    return completedJobCountForUser(userId) >= 5 &&
        averageRatingForUser(userId) >= 3.5;
  }

  double get myRating => averageRatingForUser(currentUserId);
  int get myReviewCount => reviewsForUser(currentUserId).length;
  bool get amVerified => isVerified(currentUserId);

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
      job.applicantNames.add(currentUserName);
      await FirestoreService.updateJob(job);
    }
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
    await FirestoreService.updateJob(job);
  }

  Future<void> completeJob(String jobId, double payment) async {
    final job = _jobs.firstWhere((j) => j.id == jobId);
    job.status = JobStatus.completed;
    job.payment = payment;
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
    await FirestoreService.addService(service);
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

  // ── Conversations ──

  Stream<List<Conversation>> get conversationsStream =>
      FirestoreService.conversationsStream(currentUserId);

  Stream<List<ChatMessage>> messagesStream(String conversationId) =>
      FirestoreService.messagesStream(conversationId);

  Future<Conversation> getOrCreateConversation({
    required String otherUserId,
    required String otherUserName,
    String? contextLabel,
  }) async {
    return FirestoreService.getOrCreateConversation(
      myId: currentUserId,
      myName: currentUserName,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      contextLabel: contextLabel,
    );
  }

  Future<void> sendMessage(String conversationId, String text) async {
    final message = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      senderId: currentUserId,
      senderName: currentUserName,
      text: text,
      timestamp: DateTime.now(),
    );
    await FirestoreService.sendMessage(
      conversationId: conversationId,
      message: message,
    );
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
