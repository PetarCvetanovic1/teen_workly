import 'package:flutter/material.dart';

enum JobStatus { open, inProgress, pendingCompletion, completed }

class UserProfile {
  String id;
  String name;
  String email;
  String? location;
  String? bio;
  Set<String> skills;
  Set<String> interests;
  String? school;
  int? age;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.location,
    this.bio,
    Set<String>? skills,
    Set<String>? interests,
    this.school,
    this.age,
  })  : skills = skills ?? {},
        interests = interests ?? {};

  String get initials => name
      .split(' ')
      .map((w) => w.isEmpty ? '' : w[0])
      .take(2)
      .join()
      .toUpperCase();
}

class Job {
  final String id;
  final String title;
  final String type;
  final String location;
  final String description;
  final Set<String> services;
  final String? otherService;
  final String posterId;
  final String posterName;
  final DateTime createdAt;
  final List<String> applicantIds;
  final List<String> applicantNames;
  String? hiredId;
  String? hiredName;
  JobStatus status;
  double payment;

  Job({
    required this.id,
    required this.title,
    required this.type,
    required this.location,
    required this.description,
    required this.services,
    this.otherService,
    required this.posterId,
    required this.posterName,
    required this.createdAt,
    List<String>? applicantIds,
    List<String>? applicantNames,
    this.hiredId,
    this.hiredName,
    this.status = JobStatus.open,
    this.payment = 0,
  })  : applicantIds = applicantIds ?? [],
        applicantNames = applicantNames ?? [];
}

class Service {
  final String id;
  final String providerName;
  final String location;
  final Set<String> skills;
  final String? otherSkill;
  final Set<String> availableDays;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String bio;
  final String providerId;
  final DateTime createdAt;
  final double minPrice;
  final double maxPrice;

  const Service({
    required this.id,
    required this.providerName,
    required this.location,
    required this.skills,
    this.otherSkill,
    required this.availableDays,
    required this.startTime,
    required this.endTime,
    required this.bio,
    required this.providerId,
    required this.createdAt,
    this.minPrice = 0,
    this.maxPrice = 0,
  });

  String get priceRangeLabel {
    if (minPrice <= 0 && maxPrice <= 0) return '';
    if (minPrice == maxPrice) return '\$${minPrice.toStringAsFixed(0)}/hr';
    return '\$${minPrice.toStringAsFixed(0)} – \$${maxPrice.toStringAsFixed(0)}/hr';
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });
}

class Report {
  final String id;
  final String reporterId;
  final String targetType;
  final String targetId;
  final String? reportedUserId;
  final String reason;
  final bool blocked;
  final DateTime createdAt;

  const Report({
    required this.id,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    this.reportedUserId,
    required this.reason,
    required this.blocked,
    required this.createdAt,
  });
}

class Review {
  final String id;
  final String jobId;
  final String reviewerId;
  final String reviewerName;
  final String workerId;
  final String workerName;
  final int stars;
  final String? comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.jobId,
    required this.reviewerId,
    required this.reviewerName,
    required this.workerId,
    required this.workerName,
    required this.stars,
    this.comment,
    required this.createdAt,
  });
}

enum HuddleAgeGroup { under16, sixteenPlus }

enum HuddleTag { needHelp, advice, collab, justChatting }

extension HuddleTagExt on HuddleTag {
  String get label {
    switch (this) {
      case HuddleTag.needHelp:
        return 'Need Help';
      case HuddleTag.advice:
        return 'Advice';
      case HuddleTag.collab:
        return 'Collab';
      case HuddleTag.justChatting:
        return 'Just Chatting';
    }
  }

  String get emoji {
    switch (this) {
      case HuddleTag.needHelp:
        return '🆘';
      case HuddleTag.advice:
        return '💡';
      case HuddleTag.collab:
        return '🤝';
      case HuddleTag.justChatting:
        return '💬';
    }
  }
}

class HuddleReply {
  final String id;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime createdAt;

  const HuddleReply({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.createdAt,
  });
}

class HuddlePost {
  final String id;
  final String authorId;
  final String authorName;
  final String text;
  final HuddleTag tag;
  final HuddleAgeGroup ageGroup;
  final DateTime createdAt;
  final List<HuddleReply> replies;

  HuddlePost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.tag,
    required this.ageGroup,
    required this.createdAt,
    List<HuddleReply>? replies,
  }) : replies = replies ?? [];
}

class Conversation {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String? contextLabel;
  final List<ChatMessage> messages;

  Conversation({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    this.contextLabel,
    List<ChatMessage>? messages,
  }) : messages = messages ?? [];

  String get lastMessagePreview {
    if (messages.isEmpty) return 'No messages yet';
    return messages.last.text;
  }

  DateTime? get lastMessageTime =>
      messages.isEmpty ? null : messages.last.timestamp;
}
