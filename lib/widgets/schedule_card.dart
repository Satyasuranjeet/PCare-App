import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schedule.dart';
import '../providers/app_provider.dart';

class ScheduleCard extends StatelessWidget {
  final Schedule schedule;

  const ScheduleCard({super.key, required this.schedule});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final isCompleted = _isCompletedToday();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCompleted
              ? [
                  const Color.fromRGBO(76, 175, 80, 0.2),
                  const Color.fromRGBO(76, 175, 80, 0.1),
                ]
              : [const Color(0xFF1E1E1E), const Color(0xFF2A2A2A)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? const Color.fromRGBO(76, 175, 80, 0.5)
              : const Color.fromRGBO(100, 255, 218, 0.3),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getFrequencyColorWithOpacity(),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_getFrequencyIcon(), color: _getFrequencyColor()),
        ),
        title: Text(
          schedule.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              schedule.description,
              style: TextStyle(
                color: Colors.white70,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: const Color(0xFF64FFDA),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTime(schedule.scheduledTime),
                  style: const TextStyle(
                    color: Color(0xFF64FFDA),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.repeat, size: 16, color: Colors.white54),
                const SizedBox(width: 4),
                Text(
                  _getFrequencyText(),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isCompleted)
              IconButton(
                icon: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                ),
                onPressed: () {
                  provider.markScheduleCompleted(schedule.id, DateTime.now());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Schedule marked as completed!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              )
            else
              const Icon(Icons.check_circle, color: Colors.green),
            IconButton(
              icon: Icon(
                Icons.notifications,
                color: schedule.isActive
                    ? const Color(0xFF64FFDA)
                    : Colors.white54,
              ),
              onPressed: () {
                // Toggle notification
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _isCompletedToday() {
    final today = DateTime.now();
    return schedule.completedDates.any((completedDate) {
      return completedDate.year == today.year &&
          completedDate.month == today.month &&
          completedDate.day == today.day;
    });
  }

  Color _getFrequencyColor() {
    switch (schedule.frequency) {
      case ScheduleFrequency.once:
        return Colors.orange;
      case ScheduleFrequency.daily:
        return Colors.blue;
      case ScheduleFrequency.weekly:
        return Colors.purple;
      case ScheduleFrequency.monthly:
        return Colors.red;
    }
  }

  Color _getFrequencyColorWithOpacity() {
    switch (schedule.frequency) {
      case ScheduleFrequency.once:
        return const Color.fromRGBO(255, 152, 0, 0.2);
      case ScheduleFrequency.daily:
        return const Color.fromRGBO(33, 150, 243, 0.2);
      case ScheduleFrequency.weekly:
        return const Color.fromRGBO(156, 39, 176, 0.2);
      case ScheduleFrequency.monthly:
        return const Color.fromRGBO(244, 67, 54, 0.2);
    }
  }

  IconData _getFrequencyIcon() {
    switch (schedule.frequency) {
      case ScheduleFrequency.once:
        return Icons.looks_one;
      case ScheduleFrequency.daily:
        return Icons.today;
      case ScheduleFrequency.weekly:
        return Icons.date_range;
      case ScheduleFrequency.monthly:
        return Icons.calendar_month;
    }
  }

  String _getFrequencyText() {
    switch (schedule.frequency) {
      case ScheduleFrequency.once:
        return 'Once';
      case ScheduleFrequency.daily:
        return 'Daily';
      case ScheduleFrequency.weekly:
        return 'Weekly';
      case ScheduleFrequency.monthly:
        return 'Monthly';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }
}
