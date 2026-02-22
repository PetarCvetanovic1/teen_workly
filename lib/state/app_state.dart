import 'package:flutter/material.dart';
import '../models/models.dart';

class AppState extends ChangeNotifier {
  static const _guestId = 'current_user';

  UserProfile? _profile;
  bool get isLoggedIn => _profile != null;
  UserProfile? get profile => _profile;

  String get currentUserId => _profile?.id ?? _guestId;
  String get currentUserName => _profile?.name ?? 'Guest';

  void login(String email, String password) {
    _profile = UserProfile(
      id: 'user_${email.hashCode.abs()}',
      name: email.split('@').first,
      email: email,
    );
    notifyListeners();
  }

  void signUp({
    required String name,
    required String email,
    required String password,
  }) {
    _profile = UserProfile(
      id: 'user_${email.hashCode.abs()}',
      name: name,
      email: email,
    );
    notifyListeners();
  }

  void logout() {
    _profile = null;
    notifyListeners();
  }

  void updateProfile({
    String? name,
    String? location,
    String? bio,
    Set<String>? skills,
    Set<String>? interests,
    String? school,
    int? age,
  }) {
    if (_profile == null) return;
    if (name != null) _profile!.name = name;
    if (location != null) _profile!.location = location;
    if (bio != null) _profile!.bio = bio;
    if (skills != null) _profile!.skills = skills;
    if (interests != null) _profile!.interests = interests;
    if (school != null) _profile!.school = school;
    if (age != null) _profile!.age = age;
    notifyListeners();
  }

  final List<Job> _jobs = [];
  final List<Service> _services = [];
  final List<Conversation> _conversations = [];
  final List<Report> _reports = [];
  final List<Review> _reviews = [];
  final Set<String> _blockedUserIds = {};

  final List<DateTime> _deleteStrikes = [];
  DateTime? _postingSuspendedUntil;

  String _userLocationText = '';
  String get userLocationText => _userLocationText;
  void setUserLocation(String location) {
    _userLocationText = location;
    notifyListeners();
  }

  List<Report> get reports => List.unmodifiable(_reports);
  List<Review> get reviews => List.unmodifiable(_reviews);
  Set<String> get blockedUserIds => Set.unmodifiable(_blockedUserIds);

  List<Job> get jobs => List.unmodifiable(_jobs);
  List<Service> get services => List.unmodifiable(_services);
  List<Conversation> get conversations => List.unmodifiable(_conversations);

  // --- Stats ---

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

  // --- Limits ---

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

  // --- Deletion strike / suspension system ---

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

  /// Returns a warning message if applicable, or null.
  /// If 3rd strike → suspends the user.
  String? deleteJobWithStrike(String jobId) {
    final job = _jobs.cast<Job?>().firstWhere(
          (j) => j!.id == jobId,
          orElse: () => null,
        );
    if (job == null) return null;

    final hadApplicants = job.applicantIds.isNotEmpty;
    _jobs.removeWhere((j) => j.id == jobId);

    if (!hadApplicants) {
      notifyListeners();
      return null;
    }

    _deleteStrikes.add(DateTime.now());

    String? warning;
    if (_recentStrikes.length >= _maxStrikesBeforeBan) {
      _postingSuspendedUntil = DateTime.now().add(_suspensionDuration);
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

  // --- Jobs ---

  void addJob(Job job) {
    _jobs.insert(0, job);
    notifyListeners();
  }

  void applyToJob(String jobId) {
    final job = _jobs.firstWhere((j) => j.id == jobId);
    if (!job.applicantIds.contains(currentUserId)) {
      job.applicantIds.add(currentUserId);
      job.applicantNames.add(currentUserName);
      notifyListeners();
    }
  }

  void hireApplicant(String jobId, String applicantId, String applicantName) {
    final job = _jobs.firstWhere((j) => j.id == jobId);
    job.hiredId = applicantId;
    job.hiredName = applicantName;
    job.status = JobStatus.inProgress;
    final conv = getOrCreateConversation(
      otherUserId: applicantId,
      otherUserName: applicantName,
      contextLabel: 'Job: ${job.title}',
    );
    conv.messages.add(ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      senderId: currentUserId,
      senderName: currentUserName,
      text: 'Hey $applicantName! You\'re hired for "${job.title}". Let\'s chat about the details!',
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  void requestCompletion(String jobId) {
    final job = _jobs.firstWhere((j) => j.id == jobId);
    job.status = JobStatus.pendingCompletion;
    notifyListeners();
  }

  void confirmCompletion(String jobId, double payment) {
    final job = _jobs.firstWhere((j) => j.id == jobId);
    job.status = JobStatus.completed;
    job.payment = payment;
    notifyListeners();
  }

  void completeJob(String jobId, double payment) {
    final job = _jobs.firstWhere((j) => j.id == jobId);
    job.status = JobStatus.completed;
    job.payment = payment;
    notifyListeners();
  }

  void addReview({
    required String jobId,
    required String workerId,
    required String workerName,
    required int stars,
    String? comment,
  }) {
    _reviews.add(Review(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      jobId: jobId,
      reviewerId: currentUserId,
      reviewerName: currentUserName,
      workerId: workerId,
      workerName: workerName,
      stars: stars,
      comment: comment,
      createdAt: DateTime.now(),
    ));
    notifyListeners();
  }

  void deleteJob(String jobId) {
    _jobs.removeWhere((j) => j.id == jobId);
    notifyListeners();
  }

  void withdrawApplication(String jobId) {
    final job = _jobs.firstWhere((j) => j.id == jobId);
    final idx = job.applicantIds.indexOf(currentUserId);
    if (idx != -1) {
      job.applicantIds.removeAt(idx);
      job.applicantNames.removeAt(idx);
      notifyListeners();
    }
  }

  // --- Services ---

  void addService(Service service) {
    _services.insert(0, service);
    notifyListeners();
  }

  void deleteService(String serviceId) {
    _services.removeWhere((s) => s.id == serviceId);
    notifyListeners();
  }

  // --- Report / Block ---

  // Map of userId → suspension expiry
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

  void reportContent({
    required String targetType,
    required String targetId,
    required String reason,
    bool block = false,
    String? userId,
  }) {
    _reports.add(Report(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      reporterId: currentUserId,
      targetType: targetType,
      targetId: targetId,
      reportedUserId: userId,
      reason: reason,
      blocked: block,
      createdAt: DateTime.now(),
    ));
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

  // --- Conversations ---

  Conversation getOrCreateConversation({
    required String otherUserId,
    required String otherUserName,
    String? contextLabel,
  }) {
    final existing = _conversations.where((c) => c.otherUserId == otherUserId);
    if (existing.isNotEmpty) return existing.first;

    final conv = Conversation(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      contextLabel: contextLabel,
    );
    _conversations.insert(0, conv);
    notifyListeners();
    return conv;
  }

  void sendMessage(String conversationId, String text) {
    final conv = _conversations.firstWhere((c) => c.id == conversationId);
    conv.messages.add(ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      senderId: currentUserId,
      senderName: currentUserName,
      text: text,
      timestamp: DateTime.now(),
    ));

    // Move conversation to top
    _conversations.remove(conv);
    _conversations.insert(0, conv);

    notifyListeners();
  }

  // --- Seed demo data ---

  void seedDemoData() {
    if (_jobs.isNotEmpty || _services.isNotEmpty) return;

    _services.addAll([
      Service(
        id: 'svc_1',
        providerName: 'Emma Rodriguez',
        location: 'Westdale, Hamilton',
        skills: {'Dog Walking', 'Pet Sitting'},
        availableDays: {'Mon', 'Wed', 'Fri', 'Sat'},
        startTime: const TimeOfDay(hour: 15, minute: 0),
        endTime: const TimeOfDay(hour: 20, minute: 0),
        bio: 'Animal lover with 3 years of pet sitting experience. '
            'I have a big backyard and love taking dogs on long walks!',
        providerId: 'user_emma',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        minPrice: 12,
        maxPrice: 18,
      ),
      Service(
        id: 'svc_2',
        providerName: 'Marcus Chen',
        location: 'Waterloo, ON',
        skills: {'Tutoring', 'Tech Help'},
        availableDays: {'Tue', 'Thu', 'Sat', 'Sun'},
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 18, minute: 0),
        bio: 'Straight-A student specializing in math and computer science. '
            'Can also help with phone/computer setup and troubleshooting.',
        providerId: 'user_marcus',
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        minPrice: 15,
        maxPrice: 25,
      ),
      Service(
        id: 'svc_3',
        providerName: 'Ava Thompson',
        location: 'Burlington, ON',
        skills: {'Lawn Care', 'Cleaning', 'Errands'},
        availableDays: {'Mon', 'Tue', 'Wed', 'Thu', 'Fri'},
        startTime: const TimeOfDay(hour: 8, minute: 0),
        endTime: const TimeOfDay(hour: 16, minute: 0),
        bio: 'Hard worker who loves staying busy! I do lawn care, house '
            'cleaning, and can run errands around town. Very reliable.',
        providerId: 'user_ava',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        minPrice: 10,
        maxPrice: 20,
      ),
    ]);

    _jobs.addAll([
      Job(
        id: 'job_1',
        title: 'Weekend Dog Walker Needed',
        type: 'Part-time',
        location: 'Westdale, Hamilton',
        description: 'Looking for a responsible teen to walk my two golden '
            'retrievers every Saturday and Sunday morning.',
        services: {'Pet Care', 'Outdoor'},
        posterId: 'user_sarah',
        posterName: 'Sarah Miller',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        payment: 30,
      ),
      Job(
        id: 'job_2',
        title: 'Math Tutor for Grade 8',
        type: 'Part-time',
        location: 'Kitchener, ON',
        description: 'My son needs help with algebra and geometry. '
            'Looking for someone patient who can explain concepts clearly.',
        services: {'Tutoring'},
        posterId: 'user_david',
        posterName: 'David Park',
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        payment: 20,
      ),
      Job(
        id: 'job_3',
        title: 'Backyard Cleanup',
        type: 'One-time',
        location: 'Burlington, ON',
        description: 'Need help cleaning up leaves and trimming hedges. '
            'Should take about 3-4 hours. Paying \$60.',
        services: {'Outdoor', 'Housework'},
        posterId: 'user_linda',
        posterName: 'Linda Garcia',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        payment: 60,
      ),
    ]);
  }
}
