import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final DateTime? reminderTime;
  final bool isCompleted;
  final String userId;
  final DateTime createdAt;
  final int? notificationId;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.userId,
    required this.createdAt,
    this.reminderTime,
    this.isCompleted = false,
    this.notificationId,
  });

  factory TaskModel.fromMap(Map<String, dynamic>? data, String documentId) {
    if (data == null) {
      throw Exception("Task data is null");
    }

    return TaskModel(
      id: documentId,
      title: (data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      userId: (data['userId'] ?? '').toString(),
      isCompleted: data['isCompleted'] ?? false,
      notificationId: data['notificationId'],
      reminderTime: data['reminderTime'] is Timestamp
          ? (data['reminderTime'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'userId': userId,
      'isCompleted': isCompleted,
      'notificationId': notificationId,
      'reminderTime':
      reminderTime != null ? Timestamp.fromDate(reminderTime!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? reminderTime,
    bool? isCompleted,
    String? userId,
    DateTime? createdAt,
    int? notificationId,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      reminderTime: reminderTime ?? this.reminderTime,
      isCompleted: isCompleted ?? this.isCompleted,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      notificationId: notificationId ?? this.notificationId,
    );
  }

  bool get hasReminder => reminderTime != null;

  bool get isOverdue {
    if (reminderTime == null) return false;
    return reminderTime!.isBefore(DateTime.now()) && !isCompleted;
  }

  String get formattedReminder {
    if (reminderTime == null) return "No Reminder";

    final day = reminderTime!.day.toString().padLeft(2, '0');
    final month = reminderTime!.month.toString().padLeft(2, '0');
    final year = reminderTime!.year;

    final hour = reminderTime!.hour.toString().padLeft(2, '0');
    final minute = reminderTime!.minute.toString().padLeft(2, '0');

    return "$day/$month/$year $hour:$minute";
  }
}