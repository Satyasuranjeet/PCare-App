import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schedule.dart';
import '../providers/app_provider.dart';

class DemoDataService {
  static Future<void> createDemoSchedules(BuildContext context) async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final user = provider.currentUser;

    if (user == null) return;

    final demoSchedules = [
      Schedule(
        id: '1',
        userId: user.id,
        title: 'Morning Exercise',
        description: 'Start the day with 30 minutes of exercise',
        scheduledTime: DateTime.now().add(const Duration(hours: 1)),
        frequency: ScheduleFrequency.daily,
        notificationTone: NotificationTone.gentle,
        isActive: true,
        createdAt: DateTime.now(),
        completedDates: [],
      ),
      Schedule(
        id: '2',
        userId: user.id,
        title: 'Take Vitamins',
        description: 'Daily vitamin supplements',
        scheduledTime: DateTime.now().add(const Duration(hours: 2)),
        frequency: ScheduleFrequency.daily,
        notificationTone: NotificationTone.default_,
        isActive: true,
        createdAt: DateTime.now(),
        completedDates: [],
      ),
      Schedule(
        id: '3',
        userId: user.id,
        title: 'Skin Care Routine',
        description: 'Evening skincare routine',
        scheduledTime: DateTime.now().add(const Duration(hours: 8)),
        frequency: ScheduleFrequency.daily,
        notificationTone: NotificationTone.gentle,
        isActive: true,
        createdAt: DateTime.now(),
        completedDates: [],
      ),
    ];

    for (final schedule in demoSchedules) {
      await provider.addSchedule(schedule);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demo schedules created!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
