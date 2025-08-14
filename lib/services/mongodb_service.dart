import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/schedule.dart';
import '../models/user.dart';

class MongoDBService {
  static const String baseUrl =
      'https://p-care-api.vercel.app'; // Replace with your Python API URL

  static Future<bool> backupUserData(
    User user,
    List<Schedule> schedules,
  ) async {
    try {
      final userData = {
        'user': user.toJson(),
        'schedules': schedules.map((schedule) => schedule.toJson()).toList(),
        'backupDate': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/backup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error backing up data: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> restoreUserData(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/restore/$userId'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Error restoring data: $e');
    }
    return null;
  }

  static Future<bool> syncSchedule(Schedule schedule) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/schedules'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(schedule.toJson()),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error syncing schedule: $e');
      return false;
    }
  }

  static Future<bool> deleteScheduleFromCloud(String scheduleId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/schedules/$scheduleId'),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting schedule from cloud: $e');
      return false;
    }
  }

  static Future<List<Schedule>?> getSchedulesFromCloud(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/schedules/$userId'));

      if (response.statusCode == 200) {
        final List<dynamic> schedulesJson = json.decode(response.body);
        return schedulesJson.map((json) => Schedule.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error getting schedules from cloud: $e');
    }
    return null;
  }
}
