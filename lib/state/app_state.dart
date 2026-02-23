import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../services/firestore_service.dart';

class AppState extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;

  UserProfile? _profile;
  bool get isLoggedIn => _profile != null;
  UserProfile? get profile => _profile;

  String get currentUserId => _auth.currentUser?.uid ?? 'guest';
  String get currentUserName => _profile?.name ?? 'Guest';

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

  bool get canPostJobs => true;

  AppState() {
    _auth.authStateChanges().listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    if (user != null) {
      _profile = await FirestoreService.getUser(user.uid);
      _startListening();
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

  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    int? age,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;
      final profile = UserProfile(
        id: uid,
        name: name,
        email: email,
        age: age,
      );
      await FirestoreService.createOrUpdateUser(profile);
      _profile = profile;
      _startListening();
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Sign up failed';
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Login failed';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> updateProfile({
    String? name,
    String? location,
    String? bio,
    Set<String>? skills,
    Set<String>? interests,
    String? school,
    int? age,
  }) async {
    if (_profile == null) return;
    if (name != null) _profile!.name = name;
    if (location != null) _profile!.location = location;
    if (bio != null) _profile!.bio = bio;
    if (skills != null) _profile!.skills = skills;
    if (interests != null) _profile!.interests = interests;
    if (school != null) _profile!.school = school;
    if (age != null) _profile!.age = age;
    await FirestoreService.createOrUpdateUser(_profile!);
    notifyListeners();
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
    await FirestoreService.addJob(job);
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
