import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/schedule.dart';
import '../../providers/app_provider.dart';
import '../../services/notification_service.dart';
import '../../widgets/schedule_card.dart';
import '../../widgets/gradient_button.dart';

class ManageScheduleScreen extends StatefulWidget {
  const ManageScheduleScreen({super.key});

  @override
  State<ManageScheduleScreen> createState() => _ManageScheduleScreenState();
}

class _ManageScheduleScreenState extends State<ManageScheduleScreen> {
  String _searchQuery = '';
  String _filterType = 'all'; // all, active, completed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Schedules'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: ScheduleSearchDelegate());
            },
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF64FFDA)),
            );
          }

          final filteredSchedules = _getFilteredSchedules(provider.schedules);

          return Column(
            children: [
              // Filter Tabs
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildFilterTab('All', 'all'),
                    _buildFilterTab('Active', 'active'),
                    _buildFilterTab('Completed', 'completed'),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search schedules...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF64FFDA),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Schedules List
              Expanded(
                child: filteredSchedules.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredSchedules.length,
                        itemBuilder: (context, index) {
                          final schedule = filteredSchedules[index];
                          return Dismissible(
                            key: Key(schedule.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              return await _showDeleteConfirmation(
                                context,
                                schedule,
                              );
                            },
                            onDismissed: (direction) {
                              provider.deleteSchedule(schedule.id);
                              NotificationService.cancelNotification(
                                schedule.id,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Schedule deleted'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            },
                            child: GestureDetector(
                              onTap: () =>
                                  _showScheduleDetails(context, schedule),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ScheduleCard(schedule: schedule),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-schedule'),
        backgroundColor: const Color(0xFF64FFDA),
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterTab(String title, String type) {
    final isSelected = _filterType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _filterType = type;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF64FFDA) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule, size: 64, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No schedules found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first schedule to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          GradientButton(
            text: 'Add Schedule',
            onPressed: () => Navigator.pushNamed(context, '/add-schedule'),
            width: 200,
          ),
        ],
      ),
    );
  }

  List<Schedule> _getFilteredSchedules(List<Schedule> schedules) {
    var filtered = schedules;

    // Apply type filter
    switch (_filterType) {
      case 'active':
        filtered = filtered.where((s) => s.isActive).toList();
        break;
      case 'completed':
        filtered = filtered.where((s) => s.completedDates.isNotEmpty).toList();
        break;
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((s) {
        return s.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            s.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  Future<bool?> _showDeleteConfirmation(
    BuildContext context,
    Schedule schedule,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Delete Schedule',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to delete "${schedule.title}"? This action cannot be undone.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showScheduleDetails(BuildContext context, Schedule schedule) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ScheduleDetailsBottomSheet(schedule: schedule);
      },
    );
  }
}

class ScheduleSearchDelegate extends SearchDelegate<String> {
  @override
  String get searchFieldLabel => 'Search schedules';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white54),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final results = provider.schedules.where((schedule) {
          return schedule.title.toLowerCase().contains(query.toLowerCase()) ||
              schedule.description.toLowerCase().contains(query.toLowerCase());
        }).toList();

        return Container(
          color: const Color(0xFF121212),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            itemBuilder: (context, index) {
              return ScheduleCard(schedule: results[index]);
            },
          ),
        );
      },
    );
  }
}

class ScheduleDetailsBottomSheet extends StatelessWidget {
  final Schedule schedule;

  const ScheduleDetailsBottomSheet({super.key, required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  schedule.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64FFDA),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            schedule.description,
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 24),
          _buildDetailRow(
            'Scheduled Time',
            _formatDateTime(schedule.scheduledTime),
          ),
          _buildDetailRow('Frequency', _getFrequencyText(schedule.frequency)),
          _buildDetailRow(
            'Notification Tone',
            _getToneText(schedule.notificationTone),
          ),
          _buildDetailRow('Status', schedule.isActive ? 'Active' : 'Inactive'),
          _buildDetailRow(
            'Completed',
            '${schedule.completedDates.length} times',
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  text: 'Edit',
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to edit screen
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GradientButton(
                  text: schedule.isActive ? 'Deactivate' : 'Activate',
                  onPressed: () {
                    // Toggle schedule status
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${_formatTime(dateTime)}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  String _getFrequencyText(ScheduleFrequency frequency) {
    switch (frequency) {
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

  String _getToneText(NotificationTone tone) {
    switch (tone) {
      case NotificationTone.default_:
        return 'Default';
      case NotificationTone.gentle:
        return 'Gentle';
      case NotificationTone.urgent:
        return 'Urgent';
      case NotificationTone.custom:
        return 'Custom';
    }
  }
}
