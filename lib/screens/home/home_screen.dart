import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../providers/app_provider.dart';
import '../../services/mongodb_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/schedule_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isBackingUp = false;
  bool _permissionsGranted = true;

  final List<IconData> _iconList = [
    Icons.home,
    Icons.calendar_today,
    Icons.add_circle,
    Icons.list_alt,
  ];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final granted = await NotificationService.arePermissionsGranted();
    if (mounted) {
      setState(() {
        _permissionsGranted = granted;
      });
    }
  }

  Future<void> _backupData() async {
    setState(() {
      _isBackingUp = true;
    });

    final provider = Provider.of<AppProvider>(context, listen: false);
    final user = provider.currentUser;
    final schedules = provider.schedules;

    if (user != null) {
      final success = await MongoDBService.backupUserData(user, schedules);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Data backed up successfully!'
                  : 'Backup failed. Please try again.',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isBackingUp = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Care'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final provider = Provider.of<AppProvider>(context, listen: false);
              await provider.logout();
              Navigator.pushReplacementNamed(context, '/login');
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF64FFDA), Color(0xFF7C4DFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${provider.currentUser?.name ?? 'User'}!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Take care of yourself today',
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Permission Banner
                if (!_permissionsGranted) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_off,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Notifications Disabled',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              const Text(
                                'Enable notifications to receive schedule reminders',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await NotificationService.initialize();
                            _checkPermissions();
                          },
                          child: const Text('Enable'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 8),

                // Today's Progress
                Row(
                  children: [
                    Expanded(
                      child: _buildProgressCard(
                        'Today\'s Progress',
                        provider.getProgressForDate(DateTime.now()),
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildProgressCard(
                        'Weekly Progress',
                        _calculateWeeklyProgress(provider),
                        Colors.blue,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Quick Actions
                Row(
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        _isBackingUp ? Icons.sync : Icons.cloud_upload,
                        color: const Color(0xFF64FFDA),
                      ),
                      onPressed: _isBackingUp ? null : _backupData,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: GradientButton(
                        text: 'Add Schedule',
                        onPressed: () =>
                            Navigator.pushNamed(context, '/add-schedule'),
                        height: 48,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GradientButton(
                        text: 'View Calendar',
                        onPressed: () =>
                            Navigator.pushNamed(context, '/calendar'),
                        height: 48,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Today's Schedules
                const Text(
                  'Today\'s Schedules',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),

                _buildTodaySchedules(provider),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: AnimatedBottomNavigationBar(
        icons: _iconList,
        activeIndex: _selectedIndex,
        gapLocation: GapLocation.none,
        backgroundColor: const Color(0xFF1E1E1E),
        activeColor: const Color(0xFF64FFDA),
        inactiveColor: Colors.white54,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });

          switch (index) {
            case 0:
              // Home - already here
              break;
            case 1:
              Navigator.pushNamed(context, '/calendar');
              break;
            case 2:
              Navigator.pushNamed(context, '/add-schedule');
              break;
            case 3:
              Navigator.pushNamed(context, '/manage-schedule');
              break;
          }
        },
      ),
    );
  }

  Widget _buildProgressCard(String title, double progress, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          CircularPercentIndicator(
            radius: 30.0,
            lineWidth: 4.0,
            percent: progress,
            center: Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.white,
              ),
            ),
            progressColor: color,
            backgroundColor: Colors.white24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySchedules(AppProvider provider) {
    final todaySchedules = provider.getSchedulesForDate(DateTime.now());

    if (todaySchedules.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.event_available, size: 48, color: Colors.white54),
              SizedBox(height: 16),
              Text(
                'No schedules for today',
                style: TextStyle(fontSize: 16, color: Colors.white54),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: todaySchedules
          .map(
            (schedule) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ScheduleCard(schedule: schedule),
            ),
          )
          .toList(),
    );
  }

  double _calculateWeeklyProgress(AppProvider provider) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    double totalProgress = 0;
    int days = 0;

    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      if (date.isBefore(now.add(const Duration(days: 1)))) {
        totalProgress += provider.getProgressForDate(date);
        days++;
      }
    }

    return days > 0 ? totalProgress / days : 0;
  }
}
