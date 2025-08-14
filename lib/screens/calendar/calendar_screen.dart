import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../models/schedule.dart';
import '../../providers/app_provider.dart';
import '../../widgets/schedule_card.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar & Progress'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: Icon(
              _calendarFormat == CalendarFormat.month
                  ? Icons.view_week
                  : Icons.view_module,
            ),
            onPressed: () {
              setState(() {
                _calendarFormat = _calendarFormat == CalendarFormat.month
                    ? CalendarFormat.week
                    : CalendarFormat.month;
              });
            },
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Calendar Widget
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF64FFDA).withOpacity(0.3),
                  ),
                ),
                child: TableCalendar<Schedule>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  eventLoader: (day) {
                    return provider.getSchedulesForDate(day);
                  },
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    weekendTextStyle: const TextStyle(color: Colors.white70),
                    holidayTextStyle: const TextStyle(color: Colors.white70),
                    defaultTextStyle: const TextStyle(color: Colors.white),
                    todayDecoration: BoxDecoration(
                      color: const Color(0xFF64FFDA).withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Color(0xFF7C4DFF),
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: Color(0xFF64FFDA),
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 3,
                    canMarkersOverflow: true,
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      color: Color(0xFF64FFDA),
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: Color(0xFF64FFDA),
                    ),
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekendStyle: TextStyle(color: Colors.white54),
                    weekdayStyle: TextStyle(color: Colors.white70),
                  ),
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    if (!isSameDay(_selectedDay, selectedDay)) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    }
                  },
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    }
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                ),
              ),

              // Progress Section
              if (_selectedDay != null) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress for ${_formatDate(_selectedDay!)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64FFDA),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildProgressBar(provider, _selectedDay!),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Schedules for Selected Day
              Expanded(
                child: _selectedDay != null
                    ? _buildSchedulesForDay(provider, _selectedDay!)
                    : const SizedBox(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressBar(AppProvider provider, DateTime day) {
    final progress = provider.getProgressForDate(day);
    final schedulesCount = provider.getSchedulesForDate(day).length;
    final completedCount = (progress * schedulesCount).round();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$completedCount of $schedulesCount completed',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                color: Color(0xFF64FFDA),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearPercentIndicator(
          width: MediaQuery.of(context).size.width - 64,
          lineHeight: 8.0,
          percent: progress,
          backgroundColor: Colors.white24,
          progressColor: const Color(0xFF64FFDA),
          barRadius: const Radius.circular(4),
        ),
      ],
    );
  }

  Widget _buildSchedulesForDay(AppProvider provider, DateTime day) {
    final schedules = provider.getSchedulesForDate(day);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Schedules for ${_formatDate(day)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: schedules.isEmpty
                ? _buildEmptySchedules(day)
                : ListView.builder(
                    itemCount: schedules.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ScheduleCard(schedule: schedules[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySchedules(DateTime day) {
    final isToday = isSameDay(day, DateTime.now());
    final isFuture = day.isAfter(DateTime.now());

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isToday
                ? Icons.event_available
                : isFuture
                ? Icons.event_note
                : Icons.event_busy,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            isToday
                ? 'No schedules for today'
                : isFuture
                ? 'No schedules planned'
                : 'No schedules were set',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isToday || isFuture
                ? 'Add a new schedule to get started'
                : 'This day had no scheduled activities',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          if (isToday || isFuture) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/add-schedule'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF64FFDA),
                foregroundColor: Colors.black,
              ),
              child: const Text('Add Schedule'),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) {
      return 'Today';
    } else if (targetDate == yesterday) {
      return 'Yesterday';
    } else if (targetDate == tomorrow) {
      return 'Tomorrow';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
