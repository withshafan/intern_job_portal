import 'package:cloud_firestore/cloud_firestore.dart';

class TaskComment {
  final String id;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime createdAt;

  TaskComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.createdAt,
  });

  factory TaskComment.fromMap(Map<String, dynamic> map, String id) {
    return TaskComment(
      id: id,
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? 'Unknown',
      text: map['text'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'text': text,
      'createdAt': createdAt,
    };
  }
}

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime deadline;
  final String status; // 'pending', 'in_progress', 'completed'
  final String assignedTo; // user id of the intern
  final String assignedBy; // user id of the admin/creator
  final DateTime createdAt;
  final String? assignedToName; // denormalized for display

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.status,
    required this.assignedTo,
    required this.assignedBy,
    required this.createdAt,
    this.assignedToName,
  });

  factory Task.fromMap(Map<String, dynamic> map, String id) {
    return Task(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      deadline: (map['deadline'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
      assignedTo: map['assignedTo'] ?? '',
      assignedBy: map['assignedBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      assignedToName: map['assignedToName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'deadline': deadline,
      'status': status,
      'assignedTo': assignedTo,
      'assignedBy': assignedBy,
      'createdAt': createdAt,
      if (assignedToName != null) 'assignedToName': assignedToName,
    };
  }

  Task copyWith({String? status}) {
    return Task(
      id: id,
      title: title,
      description: description,
      deadline: deadline,
      status: status ?? this.status,
      assignedTo: assignedTo,
      assignedBy: assignedBy,
      createdAt: createdAt,
      assignedToName: assignedToName,
    );
  }

  bool get isOverdue =>
      deadline.isBefore(DateTime.now()) && status != 'completed';
}
