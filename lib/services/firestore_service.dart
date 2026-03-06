import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;
  static final _functions = FirebaseFunctions.instance;
  // Low-cost mode: avoid callable endpoints unless explicitly turned on.
  static const bool _useCallableBackend = false;

  // ── Collections ──
  static final _usersCol = _db.collection('users');
  static final _jobsCol = _db.collection('jobs');
  static final _servicesCol = _db.collection('services');
  static final _conversationsCol = _db.collection('conversations');
  static final _reportsCol = _db.collection('reports');
  static final _reviewsCol = _db.collection('reviews');
  static final _huddleCol = _db.collection('huddle_posts');

  static bool _isFunctionsUnavailable(Object error) {
    if (error is! FirebaseFunctionsException) return false;
    const fallbackCodes = {
      'not-found',
      'unavailable',
      'deadline-exceeded',
      'failed-precondition',
      'internal',
      'resource-exhausted',
    };
    return fallbackCodes.contains(error.code);
  }

  // ── Users ──

  static Future<void> createOrUpdateUser(
    UserProfile profile, {
    String? authProvider,
    bool touchLogin = false,
  }) async {
    final data = <String, dynamic>{
      'name': profile.name,
      'email': profile.email.trim().toLowerCase(),
      'location': profile.location,
      'bio': profile.bio,
      'skills': profile.skills.toList(),
      'interests': profile.interests.toList(),
      'school': profile.school,
      'age': profile.age,
      'ageLastUpdatedAt': profile.ageLastUpdatedAt != null
          ? Timestamp.fromDate(profile.ageLastUpdatedAt!)
          : null,
      'vaultGoal': profile.vaultGoal,
      'vaultTargetAmount': profile.vaultTargetAmount,
      'termsAcceptedAt': profile.termsAcceptedAt != null
          ? Timestamp.fromDate(profile.termsAcceptedAt!)
          : null,
      'termsAcceptedVersion': profile.termsAcceptedVersion,
      'liabilityWaiverAcceptedAt': profile.liabilityWaiverAcceptedAt != null
          ? Timestamp.fromDate(profile.liabilityWaiverAcceptedAt!)
          : null,
      'riskAcknowledgedAt': profile.riskAcknowledgedAt != null
          ? Timestamp.fromDate(profile.riskAcknowledgedAt!)
          : null,
      'guardianConsentAt': profile.guardianConsentAt != null
          ? Timestamp.fromDate(profile.guardianConsentAt!)
          : null,
      'huddleRepliesSeenAt': profile.huddleRepliesSeenAt != null
          ? Timestamp.fromDate(profile.huddleRepliesSeenAt!)
          : null,
      'hiddenJobIds': profile.hiddenJobIds.toList(),
      'hiddenServiceIds': profile.hiddenServiceIds.toList(),
      'hiddenHuddlePostIds': profile.hiddenHuddlePostIds.toList(),
      'privacyBubbleEnabled': profile.privacyBubbleEnabled,
      'shadowBanned': profile.shadowBanned,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (authProvider != null && authProvider.isNotEmpty) {
      data['authProvider'] = authProvider;
    }
    if (touchLogin) {
      data['lastLoginAt'] = FieldValue.serverTimestamp();
    }
    await _usersCol.doc(profile.id).set(data, SetOptions(merge: true));
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
      ageLastUpdatedAt: (d['ageLastUpdatedAt'] as Timestamp?)?.toDate(),
      vaultGoal: d['vaultGoal'],
      vaultTargetAmount: (d['vaultTargetAmount'] as num?)?.toDouble(),
      termsAcceptedAt: (d['termsAcceptedAt'] as Timestamp?)?.toDate(),
      termsAcceptedVersion: d['termsAcceptedVersion'],
      liabilityWaiverAcceptedAt:
          (d['liabilityWaiverAcceptedAt'] as Timestamp?)?.toDate(),
      riskAcknowledgedAt: (d['riskAcknowledgedAt'] as Timestamp?)?.toDate(),
      guardianConsentAt: (d['guardianConsentAt'] as Timestamp?)?.toDate(),
      huddleRepliesSeenAt: (d['huddleRepliesSeenAt'] as Timestamp?)?.toDate(),
      hiddenJobIds: Set<String>.from(d['hiddenJobIds'] ?? const <String>[]),
      hiddenServiceIds:
          Set<String>.from(d['hiddenServiceIds'] ?? const <String>[]),
      hiddenHuddlePostIds:
          Set<String>.from(d['hiddenHuddlePostIds'] ?? const <String>[]),
      privacyBubbleEnabled: d['privacyBubbleEnabled'] != false,
      shadowBanned: d['shadowBanned'] == true,
    );
  }

  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    final snap = await _usersCol
        .where('email', isEqualTo: normalized)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final d = snap.docs.first.data();
    return {
      'id': snap.docs.first.id,
      'authProvider': d['authProvider'],
      'email': d['email'],
      'name': d['name'],
    };
  }

  // ── Jobs ──

  static Stream<List<Job>> jobsStream() {
    return _jobsCol
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_jobFromDoc).toList());
  }

  static Future<void> addJob(Job job) async {
    final callable = _functions.httpsCallable('createJob');
    try {
      await callable.call({
        'job': {
          'id': job.id,
          'title': job.title,
          'type': job.type,
          'location': job.location,
          'description': job.description,
          'services': job.services.toList(),
          'otherService': job.otherService,
          'posterId': job.posterId,
          'posterName': job.posterName,
          'isMinorPoster': job.isMinorPoster,
          'publicLocation': job.publicLocation,
          'publicLat': job.publicLat,
          'publicLng': job.publicLng,
          'publicRadiusMeters': job.publicRadiusMeters,
          'createdAtMs': job.createdAt.millisecondsSinceEpoch,
          'payment': job.payment,
        },
      }).timeout(const Duration(seconds: 12));
      return;
    } catch (e) {
      if (!_isFunctionsUnavailable(e)) rethrow;
    }
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
        // Store privacy-safe location for public reads.
        'location': job.displayLocation,
        'description': job.description,
        'services': job.services.toList(),
        'otherService': job.otherService,
        'posterId': job.posterId,
        'posterName': job.posterName,
        'isMinorPoster': job.isMinorPoster,
        'publicLocation': job.publicLocation,
        'publicLat': job.publicLat,
        'publicLng': job.publicLng,
        'publicRadiusMeters': job.publicRadiusMeters,
        'createdAt': Timestamp.fromDate(job.createdAt),
        'applicantIds': job.applicantIds,
        'applicantNames': job.applicantNames,
        'hiredId': job.hiredId,
        'hiredName': job.hiredName,
        'status': job.status.name,
        'payment': job.payment,
        'completedAt':
            job.completedAt != null ? Timestamp.fromDate(job.completedAt!) : null,
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
      isMinorPoster: d['isMinorPoster'] ?? false,
      publicLocation: d['publicLocation'],
      publicLat: (d['publicLat'] as num?)?.toDouble(),
      publicLng: (d['publicLng'] as num?)?.toDouble(),
      publicRadiusMeters: (d['publicRadiusMeters'] as num?)?.toDouble() ?? 500,
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
      completedAt: (d['completedAt'] as Timestamp?)?.toDate(),
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
    final callable = _functions.httpsCallable('createService');
    try {
      await callable.call({
        'service': {
          'id': service.id,
          'providerName': service.providerName,
          'location': service.location,
          'isMinorProvider': service.isMinorProvider,
          'publicLocation': service.publicLocation,
          'publicLat': service.publicLat,
          'publicLng': service.publicLng,
          'publicRadiusMeters': service.publicRadiusMeters,
          'skills': service.skills.toList(),
          'otherSkill': service.otherSkill,
          'availableDays': service.availableDays.toList(),
          'startHour': service.startTime.hour,
          'startMinute': service.startTime.minute,
          'endHour': service.endTime.hour,
          'endMinute': service.endTime.minute,
          'bio': service.bio,
          'providerId': service.providerId,
          'createdAtMs': service.createdAt.millisecondsSinceEpoch,
          'workRadiusKm': service.workRadiusKm,
          'minPrice': service.minPrice,
          'maxPrice': service.maxPrice,
        },
      });
      return;
    } catch (e) {
      // Web can throw non-FirebaseFunctionsException on CORS/OPTIONS failures.
      // In low-cost mode, fall back to direct Firestore writes.
      if (e is FirebaseFunctionsException && !_isFunctionsUnavailable(e)) {
        rethrow;
      }
    }
    await _servicesCol.doc(service.id).set({
      'providerName': service.providerName,
      'location': service.displayLocation,
      'isMinorProvider': service.isMinorProvider,
      'publicLocation': service.publicLocation,
      'publicLat': service.publicLat,
      'publicLng': service.publicLng,
      'publicRadiusMeters': service.publicRadiusMeters,
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
      'workRadiusKm': service.workRadiusKm,
      'minPrice': service.minPrice,
      'maxPrice': service.maxPrice,
    });
  }

  static Future<void> updateService(Service service) async {
    final callable = _functions.httpsCallable('updateServiceSecure');
    try {
      await callable.call({
        'service': {
          'id': service.id,
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
          'createdAtMs': service.createdAt.millisecondsSinceEpoch,
          'workRadiusKm': service.workRadiusKm,
          'minPrice': service.minPrice,
          'maxPrice': service.maxPrice,
        },
      });
      return;
    } catch (e) {
      if (!_isFunctionsUnavailable(e)) rethrow;
    }
    await _servicesCol.doc(service.id).set({
      'providerName': service.providerName,
      'location': service.displayLocation,
      'isMinorProvider': service.isMinorProvider,
      'publicLocation': service.publicLocation,
      'publicLat': service.publicLat,
      'publicLng': service.publicLng,
      'publicRadiusMeters': service.publicRadiusMeters,
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
      'workRadiusKm': service.workRadiusKm,
      'minPrice': service.minPrice,
      'maxPrice': service.maxPrice,
    }, SetOptions(merge: true));
  }

  static Future<void> deleteService(String serviceId) async {
    await _servicesCol.doc(serviceId).delete();
  }

  static Service _serviceFromDoc(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Service(
      id: doc.id,
      providerName: d['providerName'] ?? '',
      location: d['location'] ?? '',
      isMinorProvider: d['isMinorProvider'] ?? false,
      publicLocation: d['publicLocation'],
      publicLat: (d['publicLat'] as num?)?.toDouble(),
      publicLng: (d['publicLng'] as num?)?.toDouble(),
      publicRadiusMeters: (d['publicRadiusMeters'] as num?)?.toDouble() ?? 500,
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
      workRadiusKm: (d['workRadiusKm'] ?? 5).toDouble(),
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
    final callable = _functions.httpsCallable('reportSafetyIncident');
    try {
      await callable.call({
        'report': {
          'id': report.id,
          'reporterId': report.reporterId,
          'targetType': report.targetType,
          'targetId': report.targetId,
          'reportedUserId': report.reportedUserId,
          'reason': report.reason,
          'blocked': report.blocked,
          'createdAtMs': report.createdAt.millisecondsSinceEpoch,
        },
      });
      return;
    } catch (e) {
      if (!_isFunctionsUnavailable(e)) rethrow;
    }
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

  static Map<String, bool> _typingByFromMap(dynamic raw) {
    if (raw is! Map) return const {};
    final out = <String, bool>{};
    for (final entry in raw.entries) {
      final key = entry.key?.toString();
      if (key == null || key.isEmpty) continue;
      out[key] = entry.value == true;
    }
    return out;
  }

  static Map<String, DateTime> _lastSeenByFromMap(dynamic raw) {
    if (raw is! Map) return const {};
    final out = <String, DateTime>{};
    for (final entry in raw.entries) {
      final key = entry.key?.toString();
      if (key == null || key.isEmpty) continue;
      final value = entry.value;
      if (value is Timestamp) {
        out[key] = value.toDate();
      } else if (value is DateTime) {
        out[key] = value;
      }
    }
    return out;
  }

  static Stream<List<Conversation>> conversationsStream(String userId) {
    return _conversationsCol
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snap) {
          final items = snap.docs.map((doc) {
              final d = doc.data();
              final participants = List<String>.from(d['participants'] ?? []);
              final names = Map<String, String>.from(d['participantNames'] ?? {});
              final otherId = participants.firstWhere(
                (id) => id != userId,
                orElse: () => '',
              );
              final ts = d['lastMessageAt'] as Timestamp?;
              return Conversation(
                id: doc.id,
                otherUserId: otherId,
                otherUserName: names[otherId] ?? 'Unknown',
                contextLabel: d['contextLabel'],
                lastMessageText: d['lastMessageText'],
                lastMessageAt: ts?.toDate(),
                typingBy: _typingByFromMap(d['typingBy']),
                lastSeenBy: _lastSeenByFromMap(d['lastSeenBy']),
              );
            }).toList();
          items.sort((a, b) {
            final aMs = a.lastMessageTime?.millisecondsSinceEpoch ?? 0;
            final bMs = b.lastMessageTime?.millisecondsSinceEpoch ?? 0;
            return bMs.compareTo(aMs);
          });
          return items;
        });
  }

  static Future<Conversation> getOrCreateConversation({
    required String myId,
    required String myName,
    required String otherUserId,
    required String otherUserName,
    String? contextLabel,
    String? scopeKey,
  }) async {
    final existing = await _conversationsCol
        .where('participants', arrayContains: myId)
        .get();

    for (final doc in existing.docs) {
      final d = doc.data();
      final participants = List<String>.from(d['participants'] ?? []);
      if (participants.contains(otherUserId)) {
        final existingScope = (d['scopeKey'] ?? '').toString();
        final requestedScope = (scopeKey ?? '').trim();
        if (requestedScope.isNotEmpty && existingScope != requestedScope) {
          continue;
        }
        return Conversation(
          id: doc.id,
          otherUserId: otherUserId,
          otherUserName: otherUserName,
          contextLabel: d['contextLabel'],
          typingBy: _typingByFromMap(d['typingBy']),
          lastSeenBy: _lastSeenByFromMap(d['lastSeenBy']),
        );
      }
    }

    final docRef = _conversationsCol.doc();
    await docRef.set({
      'participants': [myId, otherUserId],
      'participantNames': {myId: myName, otherUserId: otherUserName},
      'contextLabel': contextLabel,
      'scopeKey': scopeKey,
      'lastMessageAt': Timestamp.now(),
      'lastMessageText': '',
      'typingBy': {myId: false, otherUserId: false},
      'lastSeenBy': {myId: Timestamp.now(), otherUserId: Timestamp.now()},
    });

    return Conversation(
      id: docRef.id,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      contextLabel: contextLabel,
      typingBy: {myId: false, otherUserId: false},
      lastSeenBy: {myId: DateTime.now(), otherUserId: DateTime.now()},
    );
  }

  static Stream<Conversation?> conversationStream(
    String conversationId,
    String myUserId,
  ) {
    return _conversationsCol.doc(conversationId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final d = doc.data()!;
      final participants = List<String>.from(d['participants'] ?? []);
      final names = Map<String, String>.from(d['participantNames'] ?? {});
      final otherId = participants.firstWhere(
        (id) => id != myUserId,
        orElse: () => '',
      );
      final ts = d['lastMessageAt'] as Timestamp?;
      return Conversation(
        id: doc.id,
        otherUserId: otherId,
        otherUserName: names[otherId] ?? 'Unknown',
        contextLabel: d['contextLabel'],
        lastMessageText: d['lastMessageText'],
        lastMessageAt: ts?.toDate(),
        typingBy: _typingByFromMap(d['typingBy']),
        lastSeenBy: _lastSeenByFromMap(d['lastSeenBy']),
      );
    });
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
                isDeleted: d['isDeleted'] == true || d['deletedAt'] != null,
                deletedById: d['deletedById'],
                deletedByName: d['deletedByName'],
              );
            }).toList());
  }

  static Future<void> sendMessage({
    required String conversationId,
    required ChatMessage message,
  }) async {
    if (_useCallableBackend) {
      final callable = _functions.httpsCallable('sendConversationMessage');
      try {
        await callable.call({
          'conversationId': conversationId,
          'message': {
            'id': message.id,
            'senderId': message.senderId,
            'senderName': message.senderName,
            'text': message.text,
            'timestampMs': message.timestamp.millisecondsSinceEpoch,
          },
        });
        return;
      } catch (_) {
        // Fall back to Firestore write below.
      }
    }
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
      'isDeleted': false,
      'deletedById': null,
      'deletedByName': null,
      'deletedAt': null,
    });
    batch.set(_conversationsCol.doc(conversationId), {
      'lastMessageAt': Timestamp.fromDate(message.timestamp),
      'lastMessageText': message.text,
      'typingBy': {message.senderId: false},
      'lastSeenBy': {message.senderId: Timestamp.fromDate(message.timestamp)},
    }, SetOptions(merge: true));
    await batch.commit();
  }

  static Future<void> deleteMessageForEveryone({
    required String conversationId,
    required String messageId,
    required String deletedById,
    required String deletedByName,
  }) async {
    final msgRef = _conversationsCol
        .doc(conversationId)
        .collection('messages')
        .doc(messageId);
    await msgRef.set({
      'isDeleted': true,
      'deletedById': deletedById,
      'deletedByName': deletedByName,
      'deletedAt': FieldValue.serverTimestamp(),
      'text': '$deletedByName deleted this message',
    }, SetOptions(merge: true));

    final latest = await _conversationsCol
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    if (latest.docs.isNotEmpty && latest.docs.first.id == messageId) {
      await _conversationsCol.doc(conversationId).set({
        'lastMessageText': '$deletedByName deleted a message',
      }, SetOptions(merge: true));
    }
  }

  static Future<void> setConversationTyping({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) async {
    final ref = _conversationsCol.doc(conversationId);
    try {
      await ref.update({
        'typingBy.$userId': isTyping,
      });
    } on FirebaseException catch (e) {
      if (e.code != 'not-found') rethrow;
      await ref.set({
        'typingBy': {userId: isTyping},
      }, SetOptions(merge: true));
    }
  }

  static Future<void> markConversationSeen({
    required String conversationId,
    required String userId,
    required DateTime seenAt,
  }) async {
    final ref = _conversationsCol.doc(conversationId);
    try {
      await ref.update({
        'lastSeenBy.$userId': Timestamp.fromDate(seenAt),
        'typingBy.$userId': false,
      });
    } on FirebaseException catch (e) {
      if (e.code != 'not-found') rethrow;
      await ref.set({
        'lastSeenBy': {userId: Timestamp.fromDate(seenAt)},
        'typingBy': {userId: false},
      }, SetOptions(merge: true));
    }
  }

  static Future<void> deleteConversation(String conversationId) async {
    final messagesRef = _conversationsCol.doc(conversationId).collection('messages');
    final messagesSnap = await messagesRef.get();
    final batch = _db.batch();
    for (final doc in messagesSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_conversationsCol.doc(conversationId));
    await batch.commit();
  }

  // ── The Huddle ──

  static Stream<List<HuddlePost>> huddleStream(HuddleAgeGroup ageGroup) {
    return _huddleCol
        .where('ageGroup', isEqualTo: ageGroup.name)
        .snapshots()
        .map((snap) {
          final posts = snap.docs.map((doc) {
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
                lastReplyAt: (d['lastReplyAt'] as Timestamp?)?.toDate(),
                lastReplyAuthorId: d['lastReplyAuthorId'],
                replyCount: d['replyCount'] ?? 0,
              );
            }).toList();
          posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return posts;
        });
  }

  static Future<void> addHuddlePost(HuddlePost post) async {
    final callable = _functions.httpsCallable('createHuddlePost');
    try {
      await callable.call({
        'post': {
          'id': post.id,
          'authorId': post.authorId,
          'authorName': post.authorName,
          'text': post.text,
          'tag': post.tag.name,
          'ageGroup': post.ageGroup.name,
          'createdAtMs': post.createdAt.millisecondsSinceEpoch,
        },
      });
      return;
    } catch (e) {
      if (!_isFunctionsUnavailable(e)) rethrow;
    }
    await _huddleCol.doc(post.id).set({
      'authorId': post.authorId,
      'authorName': post.authorName,
      'text': post.text,
      'tag': post.tag.name,
      'ageGroup': post.ageGroup.name,
      'createdAt': Timestamp.fromDate(post.createdAt),
      'lastReplyAt': null,
      'lastReplyAuthorId': null,
      'replyCount': 0,
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
    final callable = _functions.httpsCallable('createHuddleReply');
    try {
      await callable.call({
        'postId': postId,
        'reply': {
          'id': reply.id,
          'authorId': reply.authorId,
          'authorName': reply.authorName,
          'text': reply.text,
          'createdAtMs': reply.createdAt.millisecondsSinceEpoch,
        },
      });
      return;
    } catch (e) {
      if (!_isFunctionsUnavailable(e)) rethrow;
    }
    await _huddleCol.doc(postId).collection('replies').doc(reply.id).set({
      'authorId': reply.authorId,
      'authorName': reply.authorName,
      'text': reply.text,
      'createdAt': Timestamp.fromDate(reply.createdAt),
    });
    await _huddleCol.doc(postId).set({
      'lastReplyAt': Timestamp.fromDate(reply.createdAt),
      'lastReplyAuthorId': reply.authorId,
      'replyCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
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

  static Future<void> deleteMyAccountData() async {
    final callable = _functions.httpsCallable('deleteMyAccountData');
    await callable.call();
  }
}
