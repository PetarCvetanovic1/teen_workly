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

  void reportContent({
    required String targetType,
    required String targetId,
    required String reason,
    bool block = false,
    String? userId,
  }) {
    _reports.add(Report(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      targetType: targetType,
      targetId: targetId,
      reason: reason,
      blocked: block,
      createdAt: DateTime.now(),
    ));
    if (block && userId != null) {
      _blockedUserIds.add(userId);
    }
    notifyListeners();
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
      ),
    ]);
  }
}
