import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/schedule.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class AppProvider extends ChangeNotifier {
  User? _currentUser;
  List<Schedule> _schedules = [];
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  List<Schedule> get schedules => _schedules;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _currentUser = await AuthService.getCurrentUser();
    if (_currentUser != null) {
      await loadSchedules();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final success = await AuthService.login(email, password);
    if (success) {
      _currentUser = await AuthService.getCurrentUser();
      await loadSchedules();
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> register(String email, String name, String password) async {
    _isLoading = true;
    notifyListeners();

    final success = await AuthService.register(email, name, password);
    if (success) {
      _currentUser = await AuthService.getCurrentUser();
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> logout() async {
    await AuthService.logout();
    _currentUser = null;
    _schedules = [];
    notifyListeners();
  }

  Future<void> loadSchedules() async {
    if (_currentUser != null) {
      _schedules = await DatabaseService.getSchedules(_currentUser!.id);
      notifyListeners();
    }
  }

  Future<void> addSchedule(Schedule schedule) async {
    await DatabaseService.insertSchedule(schedule);
    _schedules.add(schedule);
    notifyListeners();
  }

  Future<void> updateSchedule(Schedule schedule) async {
    await DatabaseService.updateSchedule(schedule);
    final index = _schedules.indexWhere((s) => s.id == schedule.id);
    if (index != -1) {
      _schedules[index] = schedule;
      notifyListeners();
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    await DatabaseService.deleteSchedule(scheduleId);
    _schedules.removeWhere((s) => s.id == scheduleId);
    notifyListeners();
  }

  Future<void> markScheduleCompleted(
    String scheduleId,
    DateTime completedDate,
  ) async {
    await DatabaseService.markScheduleCompleted(scheduleId, completedDate);
    await loadSchedules();
  }

  List<Schedule> getSchedulesForDate(DateTime date) {
    return _schedules.where((schedule) {
      if (!schedule.isActive) return false;

      final scheduledDate = DateTime(
        schedule.scheduledTime.year,
        schedule.scheduledTime.month,
        schedule.scheduledTime.day,
      );

      final targetDate = DateTime(date.year, date.month, date.day);

      switch (schedule.frequency) {
        case ScheduleFrequency.once:
          return scheduledDate == targetDate;
        case ScheduleFrequency.daily:
          return scheduledDate.isBefore(targetDate) ||
              scheduledDate == targetDate;
        case ScheduleFrequency.weekly:
          final daysDifference = targetDate.difference(scheduledDate).inDays;
          return daysDifference >= 0 && daysDifference % 7 == 0;
        case ScheduleFrequency.monthly:
          return scheduledDate.day == targetDate.day &&
              (targetDate.isAfter(scheduledDate) ||
                  targetDate == scheduledDate);
      }
    }).toList();
  }

  double getProgressForDate(DateTime date) {
    final schedulesForDate = getSchedulesForDate(date);
    if (schedulesForDate.isEmpty) return 0.0;

    final completedCount = schedulesForDate.where((schedule) {
      return schedule.completedDates.any((completedDate) {
        final completed = DateTime(
          completedDate.year,
          completedDate.month,
          completedDate.day,
        );
        final target = DateTime(date.year, date.month, date.day);
        return completed == target;
      });
    }).length;

    return completedCount / schedulesForDate.length;
  }
}
