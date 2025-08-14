import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as picker;
import '../../models/schedule.dart';
import '../../providers/app_provider.dart';
import '../../services/notification_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/gradient_button.dart';

class AddScheduleScreen extends StatefulWidget {
  const AddScheduleScreen({super.key});

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedTime = DateTime.now();
  ScheduleFrequency _selectedFrequency = ScheduleFrequency.daily;
  NotificationTone _selectedTone = NotificationTone.default_;
  DateTime? _endDate;
  bool _isLoading = false;

  Future<void> _selectTime() async {
    picker.DatePicker.showDateTimePicker(
      context,
      showTitleActions: true,
      minTime: DateTime.now(),
      maxTime: DateTime.now().add(const Duration(days: 365)),
      onConfirm: (date) {
        setState(() {
          _selectedTime = date;
        });
      },
      currentTime: _selectedTime,
      locale: picker.LocaleType.en,
    );
  }

  Future<void> _selectEndDate() async {
    picker.DatePicker.showDatePicker(
      context,
      showTitleActions: true,
      minTime: DateTime.now(),
      maxTime: DateTime.now().add(const Duration(days: 365)),
      onConfirm: (date) {
        setState(() {
          _endDate = date;
        });
      },
      currentTime: _endDate ?? DateTime.now().add(const Duration(days: 30)),
      locale: picker.LocaleType.en,
    );
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<AppProvider>(context, listen: false);
    final user = provider.currentUser;

    if (user != null) {
      final schedule = Schedule(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        scheduledTime: _selectedTime,
        frequency: _selectedFrequency,
        notificationTone: _selectedTone,
        isActive: true,
        createdAt: DateTime.now(),
        completedDates: [],
        endDate: _endDate,
      );

      await provider.addSchedule(schedule);
      await NotificationService.scheduleNotification(schedule);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Schedule'),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create New Schedule',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64FFDA),
                ),
              ),
              const SizedBox(height: 24),

              CustomTextField(
                controller: _titleController,
                label: 'Schedule Title',
                icon: Icons.title,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: _descriptionController,
                label: 'Description',
                icon: Icons.description,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Time Selection
              _buildSectionTitle('Schedule Time'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _selectTime,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF64FFDA).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Color(0xFF64FFDA)),
                      const SizedBox(width: 12),
                      Text(
                        _formatDateTime(_selectedTime),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white54,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Frequency Selection
              _buildSectionTitle('Frequency'),
              const SizedBox(height: 8),
              _buildFrequencySelector(),

              const SizedBox(height: 24),

              // End Date (for recurring schedules)
              if (_selectedFrequency != ScheduleFrequency.once) ...[
                _buildSectionTitle('End Date (Optional)'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _selectEndDate,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF64FFDA).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event, color: Color(0xFF64FFDA)),
                        const SizedBox(width: 12),
                        Text(
                          _endDate != null
                              ? _formatDate(_endDate!)
                              : 'Select end date',
                          style: TextStyle(
                            color: _endDate != null
                                ? Colors.white
                                : Colors.white54,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white54,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Notification Tone
              _buildSectionTitle('Notification Tone'),
              const SizedBox(height: 8),
              _buildNotificationToneSelector(),

              const SizedBox(height: 40),

              GradientButton(
                text: 'Create Schedule',
                onPressed: _isLoading ? null : _saveSchedule,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Widget _buildFrequencySelector() {
    return Column(
      children: ScheduleFrequency.values.map((frequency) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: _selectedFrequency == frequency
                ? const Color(0xFF64FFDA).withOpacity(0.2)
                : const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedFrequency == frequency
                  ? const Color(0xFF64FFDA)
                  : Colors.white.withOpacity(0.2),
            ),
          ),
          child: RadioListTile<ScheduleFrequency>(
            value: frequency,
            groupValue: _selectedFrequency,
            onChanged: (value) {
              setState(() {
                _selectedFrequency = value!;
              });
            },
            title: Text(
              _getFrequencyText(frequency),
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              _getFrequencyDescription(frequency),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            activeColor: const Color(0xFF64FFDA),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotificationToneSelector() {
    return Column(
      children: NotificationTone.values.map((tone) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: _selectedTone == tone
                ? const Color(0xFF64FFDA).withOpacity(0.2)
                : const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedTone == tone
                  ? const Color(0xFF64FFDA)
                  : Colors.white.withOpacity(0.2),
            ),
          ),
          child: RadioListTile<NotificationTone>(
            value: tone,
            groupValue: _selectedTone,
            onChanged: (value) {
              setState(() {
                _selectedTone = value!;
              });
            },
            title: Text(
              _getToneText(tone),
              style: const TextStyle(color: Colors.white),
            ),
            activeColor: const Color(0xFF64FFDA),
          ),
        );
      }).toList(),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} at ${_formatTime(dateTime)}';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
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

  String _getFrequencyDescription(ScheduleFrequency frequency) {
    switch (frequency) {
      case ScheduleFrequency.once:
        return 'Schedule will run only once';
      case ScheduleFrequency.daily:
        return 'Schedule will repeat every day';
      case ScheduleFrequency.weekly:
        return 'Schedule will repeat every week';
      case ScheduleFrequency.monthly:
        return 'Schedule will repeat every month';
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
