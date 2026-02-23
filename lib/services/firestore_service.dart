import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // ── Collections ──
  static final _usersCol = _db.collection('users');
  static final _jobsCol = _db.collection('jobs');
  static final _servicesCol = _db.collection('services');
  static final _conversationsCol = _db.collection('conversations');
  static final _reportsCol = _db.collection('reports');
  static final _reviewsCol = _db.collection('reviews');
  static final _huddleCol = _db.collection('huddle_posts');

  // ── Users ──

  static Future<void> createOrUpdateUser(UserProfile profile) async {
    await _usersCol.doc(profile.id).set({
      'name': profile.name,
      'email': profile.email,
      'location': profile.location,
      'bio': profile.bio,
      'skills': profile.skills.toList(),
      'interests': profile.interests.toList(),
      'school': profile.school,
      'age': profile.age,
    }, SetOptions(merge: true));
  }

  static Future<UserProfile?> getUser(String uid) async {
    final doc = await _usersCol.doc(uid).get();
    if (!doc.exists) return null;
    final d = doc.data()!;
    return UserProfile(
      id: doc.id,
      name: d['name'] ?? '',
      email: d['email'] ?? '',
      location: d['location'],
      bio: d['bio'],
      skills: Set<String>.from(d['skills'] ?? []),
      interests: Set<String>.from(d['interests'] ?? []),
      school: d['school'],
      age: d['age'],
    );
  }

  // ── Jobs ──

  static Stream<List<Job>> jobsStream() {
    return _jobsCol
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_jobFromDoc).toList());
  }

  static Future<void> addJob(Job job) async {
    await _jobsCol.doc(job.id).set(_jobToMap(job));
  }

  static Future<void> updateJob(Job job) async {
    await _jobsCol.doc(job.id).update(_jobToMap(job));
  }

  static Future<void> deleteJob(String jobId) async {
    await _jobsCol.doc(jobId).delete();
  }

  static Map<String, dynamic> _jobToMap(Job job) => {
        'title': job.title,
        'type': job.type,
        'location': job.location,
        'description': job.description,
        'services': job.services.toList(),
        'otherService': job.otherService,
        'posterId': job.posterId,
        'posterName': job.posterName,
        'createdAt': Timestamp.fromDate(job.createdAt),
        'applicantIds': job.applicantIds,
        'applicantNames': job.applicantNames,
        'hiredId': job.hiredId,
        'hiredName': job.hiredName,
        'status': job.status.name,
        'payment': job.payment,
      };

  static Job _jobFromDoc(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Job(
      id: doc.id,
      title: d['title'] ?? '',
      type: d['type'] ?? '',
      location: d['location'] ?? '',
      description: d['description'] ?? '',
      services: Set<String>.from(d['services'] ?? []),
      otherService: d['otherService'],
      posterId: d['posterId'] ?? '',
      posterName: d['posterName'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      applicantIds: List<String>.from(d['applicantIds'] ?? []),
      applicantNames: List<String>.from(d['applicantNames'] ?? []),
      hiredId: d['hiredId'],
      hiredName: d['hiredName'],
      status: JobStatus.values.firstWhere(
        (s) => s.name == d['status'],
        orElse: () => JobStatus.open,
      ),
      payment: (d['payment'] ?? 0).toDouble(),
    );
  }

  // ── Services ──

  static Stream<List<Service>> servicesStream() {
    return _servicesCol
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_serviceFromDoc).toList());
  }

  static Future<void> addService(Service service) async {
    await _servicesCol.doc(service.id).set(_serviceToMap(service));
  }

  static Future<void> deleteService(String serviceId) async {
    await _servicesCol.doc(serviceId).delete();
  }

  static Map<String, dynamic> _serviceToMap(Service service) => {
        'providerName': service.providerName,
        'location': service.location,
        'skills': service.skills.toList(),
        'otherSkill': service.otherSkill,
        'availableDays': service.availableDays.toList(),
        'startHour': service.startTime.hour,
        'startMinute': service.startTime.minute,
        'endHour': service.endTime.hour,
        'endMinute': service.endTime.minute,
        'bio': service.bio,
        'providerId': service.providerId,
        'createdAt': Timestamp.fromDate(service.createdAt),
        'minPrice': service.minPrice,
        'maxPrice': service.maxPrice,
      };

  static Service _serviceFromDoc(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Service(
      id: doc.id,
      providerName: d['providerName'] ?? '',
      location: d['location'] ?? '',
      skills: Set<String>.from(d['skills'] ?? []),
      otherSkill: d['otherSkill'],
      availableDays: Set<String>.from(d['availableDays'] ?? []),
      startTime: TimeOfDay(
          hour: d['startHour'] ?? 9, minute: d['startMinute'] ?? 0),
      endTime: TimeOfDay(
          hour: d['endHour'] ?? 17, minute: d['endMinute'] ?? 0),
      bio: d['bio'] ?? '',
      providerId: d['providerId'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      minPrice: (d['minPrice'] ?? 0).toDouble(),
      maxPrice: (d['maxPrice'] ?? 0).toDouble(),
    );
  }

  // ── Reviews ──

  static Stream<List<Review>> reviewsStream() {
    return _reviewsCol
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final d = doc.data();
              return Review(
                id: doc.id,
                jobId: d['jobId'] ?? '',
                reviewerId: d['reviewerId'] ?? '',
                reviewerName: d['reviewerName'] ?? '',
                workerId: d['workerId'] ?? '',
                workerName: d['workerName'] ?? '',
                stars: d['stars'] ?? 0,
                comment: d['comment'],
                createdAt:
                    (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              );
            }).toList());
  }

  static Future<void> addReview(Review review) async {
    await _reviewsCol.doc(review.id).set({
      'jobId': review.jobId,
      'reviewerId': review.reviewerId,
      'reviewerName': review.reviewerName,
      'workerId': review.workerId,
      'workerName': review.workerName,
      'stars': review.stars,
      'comment': review.comment,
      'createdAt': Timestamp.fromDate(review.createdAt),
    });
  }

  // ── Reports ──

  static Stream<List<Report>> reportsStream() {
    return _reportsCol.snapshots().map((snap) => snap.docs.map((doc) {
          final d = doc.data();
          return Report(
            id: doc.id,
            reporterId: d['reporterId'] ?? '',
            targetType: d['targetType'] ?? '',
            targetId: d['targetId'] ?? '',
            reportedUserId: d['reportedUserId'],
            reason: d['reason'] ?? '',
            blocked: d['blocked'] ?? false,
            createdAt:
                (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
        }).toList());
  }

  static Future<void> addReport(Report report) async {
    await _reportsCol.doc(report.id).set({
      'reporterId': report.reporterId,
      'targetType': report.targetType,
      'targetId': report.targetId,
      'reportedUserId': report.reportedUserId,
      'reason': report.reason,
      'blocked': report.blocked,
      'createdAt': Timestamp.fromDate(report.createdAt),
    });
  }

  // ── Conversations ──

  static Stream<List<Conversation>> conversationsStream(String userId) {
    return _conversationsCol
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final d = doc.data();
              final participants = List<String>.from(d['participants'] ?? []);
              final names = Map<String, String>.from(d['participantNames'] ?? {});
              final otherId = participants.firstWhere(
                (id) => id != userId,
                orElse: () => '',
              );
              return Conversation(
                id: doc.id,
                otherUserId: otherId,
                otherUserName: names[otherId] ?? 'Unknown',
                contextLabel: d['contextLabel'],
              );
            }).toList());
  }

  static Future<Conversation> getOrCreateConversation({
    required String myId,
    required String myName,
    required String otherUserId,
    required String otherUserName,
    String? contextLabel,
  }) async {
    final existing = await _conversationsCol
        .where('participants', arrayContains: myId)
        .get();

    for (final doc in existing.docs) {
      final participants = List<String>.from(doc.data()['participants'] ?? []);
      if (participants.contains(otherUserId)) {
        final d = doc.data();
        return Conversation(
          id: doc.id,
          otherUserId: otherUserId,
          otherUserName: otherUserName,
          contextLabel: d['contextLabel'],
        );
      }
    }

    final docRef = _conversationsCol.doc();
    await docRef.set({
      'participants': [myId, otherUserId],
      'participantNames': {myId: myName, otherUserId: otherUserName},
      'contextLabel': contextLabel,
      'lastMessageAt': Timestamp.now(),
    });

    return Conversation(
      id: docRef.id,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      contextLabel: contextLabel,
    );
  }

  static Stream<List<ChatMessage>> messagesStream(String conversationId) {
    return _conversationsCol
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final d = doc.data();
              return ChatMessage(
                id: doc.id,
                senderId: d['senderId'] ?? '',
                senderName: d['senderName'] ?? '',
                text: d['text'] ?? '',
                timestamp:
                    (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
              );
            }).toList());
  }

  static Future<void> sendMessage({
    required String conversationId,
    required ChatMessage message,
  }) async {
    final batch = _db.batch();
    final msgRef = _conversationsCol
        .doc(conversationId)
        .collection('messages')
        .doc(message.id);
    batch.set(msgRef, {
      'senderId': message.senderId,
      'senderName': message.senderName,
      'text': message.text,
      'timestamp': Timestamp.fromDate(message.timestamp),
    });
    batch.update(_conversationsCol.doc(conversationId), {
      'lastMessageAt': Timestamp.fromDate(message.timestamp),
    });
    await batch.commit();
  }

  // ── The Huddle ──

  static Stream<List<HuddlePost>> huddleStream(HuddleAgeGroup ageGroup) {
    return _huddleCol
        .where('ageGroup', isEqualTo: ageGroup.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final d = doc.data();
              return HuddlePost(
                id: doc.id,
                authorId: d['authorId'] ?? '',
                authorName: d['authorName'] ?? '',
                text: d['text'] ?? '',
                tag: HuddleTag.values.firstWhere(
                  (t) => t.name == d['tag'],
                  orElse: () => HuddleTag.justChatting,
                ),
                ageGroup: ageGroup,
                createdAt: (d['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
              );
            }).toList());
  }

  static Future<void> addHuddlePost(HuddlePost post) async {
    await _huddleCol.doc(post.id).set({
      'authorId': post.authorId,
      'authorName': post.authorName,
      'text': post.text,
      'tag': post.tag.name,
      'ageGroup': post.ageGroup.name,
      'createdAt': Timestamp.fromDate(post.createdAt),
    });
  }

  static Future<void> deleteHuddlePost(String postId) async {
    await _huddleCol.doc(postId).delete();
  }

  static Stream<List<HuddleReply>> huddleRepliesStream(String postId) {
    return _huddleCol
        .doc(postId)
        .collection('replies')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final d = doc.data();
              return HuddleReply(
                id: doc.id,
                authorId: d['authorId'] ?? '',
                authorName: d['authorName'] ?? '',
                text: d['text'] ?? '',
                createdAt: (d['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
              );
            }).toList());
  }

  static Future<void> addHuddleReply(String postId, HuddleReply reply) async {
    await _huddleCol.doc(postId).collection('replies').doc(reply.id).set({
      'authorId': reply.authorId,
      'authorName': reply.authorName,
      'text': reply.text,
      'createdAt': Timestamp.fromDate(reply.createdAt),
    });
  }

  // ── User suspension data ──

  static Future<void> setUserSuspension(
      String userId, DateTime? expiresAt) async {
    await _usersCol.doc(userId).set({
      'postingSuspendedUntil': expiresAt != null
          ? Timestamp.fromDate(expiresAt)
          : null,
    }, SetOptions(merge: true));
  }

  static Future<void> addDeleteStrike(String userId) async {
    await _usersCol.doc(userId).update({
      'deleteStrikes': FieldValue.arrayUnion([Timestamp.now()]),
    });
  }
}
