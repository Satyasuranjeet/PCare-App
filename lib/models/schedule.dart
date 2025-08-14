enum ScheduleFrequency { once, daily, weekly, monthly }

enum NotificationTone { default_, gentle, urgent, custom }

class Schedule {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime scheduledTime;
  final ScheduleFrequency frequency;
  final NotificationTone notificationTone;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? endDate;
  final List<DateTime> completedDates;
  final bool isCompleted;

  Schedule({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.scheduledTime,
    required this.frequency,
    required this.notificationTone,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    this.endDate,
    required this.completedDates,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'scheduledTime': scheduledTime.toIso8601String(),
      'frequency': frequency.toString(),
      'notificationTone': notificationTone.toString(),
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'completedDates': completedDates.isEmpty
          ? ''
          : completedDates.map((date) => date.toIso8601String()).join(','),
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      description: json['description'],
      scheduledTime: DateTime.parse(json['scheduledTime']),
      frequency: ScheduleFrequency.values.firstWhere(
        (e) => e.toString() == json['frequency'],
      ),
      notificationTone: NotificationTone.values.firstWhere(
        (e) => e.toString() == json['notificationTone'],
      ),
      isActive: (json['isActive'] as int) == 1,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      completedDates:
          json['completedDates'] != null &&
              json['completedDates'].toString().isNotEmpty
          ? json['completedDates']
                .toString()
                .split(',')
                .where((dateStr) => dateStr.trim().isNotEmpty)
                .map((dateStr) => DateTime.parse(dateStr.trim()))
                .toList()
          : [],
      isCompleted: (json['isCompleted'] as int?) == 1,
    );
  }

  Schedule copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? scheduledTime,
    ScheduleFrequency? frequency,
    NotificationTone? notificationTone,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? endDate,
    List<DateTime>? completedDates,
    bool? isCompleted,
  }) {
    return Schedule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      frequency: frequency ?? this.frequency,
      notificationTone: notificationTone ?? this.notificationTone,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      endDate: endDate ?? this.endDate,
      completedDates: completedDates ?? this.completedDates,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
