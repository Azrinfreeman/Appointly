import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';

import 'appointment.dart';
import 'appointment_provider.dart';

class AppointmentForm extends StatefulWidget {
  final Appointment? appointment;
  final DateTime initialDate;

  const AppointmentForm({
    super.key,
    this.appointment,
    required this.initialDate,
  });

  @override
  State<AppointmentForm> createState() => _AppointmentFormState();
}

class _AppointmentFormState extends State<AppointmentForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;

  late RecurrenceType _recurrenceType;
  TimeOfDay? _selectedTime;
  String? _whatsappWarning;
  late DateTime _selectedDate;
  late int _reminderMinutesBefore;
  List<ClientProfile> _nameSuggestions = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.appointment?.clientName ?? '');
    _phoneController = TextEditingController(text: widget.appointment?.phoneNumber ?? '+60');
    _locationController = TextEditingController(text: widget.appointment?.location ?? '');

    _selectedDate = widget.appointment?.date ?? widget.initialDate;
    _recurrenceType = widget.appointment?.recurrenceType ?? RecurrenceType.none;
    _selectedTime = widget.appointment?.hour != null && widget.appointment?.minute != null
        ? TimeOfDay(hour: widget.appointment!.hour!, minute: widget.appointment!.minute!)
        : null;
    _reminderMinutesBefore = widget.appointment?.reminderMinutesBefore ?? 1440;

    // Run initial warning check if editing an existing appointment
    if (_phoneController.text.isNotEmpty) {
      _checkWhatsappWarning(_phoneController.text);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _checkWhatsappWarning(String val) {
    final digits = val.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty || digits == '60') {
      setState(() {
        _whatsappWarning = null;
      });
      return;
    }

    final provider = context.read<AppointmentProvider>();
    if (digits.startsWith('0')) {
      setState(() {
        _whatsappWarning = provider.translate('whatsappWarning');
      });
    } else if (digits.length < 9) {
      setState(() {
        _whatsappWarning = provider.translate('numberVeryShort');
      });
    } else {
      setState(() {
        _whatsappWarning = null;
      });
    }
  }

  void _onNameChanged(String val) {
    if (val.trim().isEmpty) {
      setState(() {
        _nameSuggestions = [];
      });
      return;
    }
    final clients = context.read<AppointmentProvider>().clientProfiles;
    final matches = clients
        .where((c) => c.name.toLowerCase().contains(val.toLowerCase()) && c.name.toLowerCase() != val.toLowerCase())
        .take(3)
        .toList();
    setState(() {
      _nameSuggestions = matches;
    });
  }

  String _formatTime(int? hour, int? minute, bool use24h) {
    if (hour == null || minute == null) return 'No Time';
    if (use24h) {
      final h = hour.toString().padLeft(2, '0');
      final m = minute.toString().padLeft(2, '0');
      return '$h:$m';
    } else {
      final period = hour >= 12 ? 'PM' : 'AM';
      var h = hour % 12;
      if (h == 0) h = 12;
      final m = minute.toString().padLeft(2, '0');
      return '$h:$m $period';
    }
  }

  String _formatDate(DateTime date) {
    final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${weekdayNames[date.weekday - 1]}, ${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppointmentProvider>();
    final use24Hour = provider.use24HourFormat;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.appointment == null ? provider.translate('logClient') : provider.translate('editAppointment'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: provider.translate('clientName'),
                  border: const OutlineInputBorder(),
                ),
                onChanged: _onNameChanged,
                validator: (value) => value == null || value.trim().isEmpty ? provider.translate('enterClientName') : null,
              ),
              if (_nameSuggestions.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: _nameSuggestions.map((client) {
                    return ActionChip(
                      avatar: CircleAvatar(
                        radius: 12,
                        child: Text(client.name[0].toUpperCase(), style: const TextStyle(fontSize: 10)),
                      ),
                      label: Text(client.name, style: const TextStyle(fontSize: 12)),
                      onPressed: () {
                        setState(() {
                          _nameController.text = client.name;
                          _phoneController.text = client.phoneNumber;
                          _checkWhatsappWarning(client.phoneNumber);
                          _nameSuggestions = [];
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: provider.translate('phoneNumber'),
                            hintText: 'e.g. 60123456789',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          onChanged: _checkWhatsappWarning,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return provider.translate('enterPhoneNumber');
                            }
                            final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
                            if (digitsOnly.length < 7) {
                              return provider.translate('validPhoneNumber');
                            }
                            return null;
                          },
                        ),
                        if (_whatsappWarning != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6.0, left: 4.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _whatsappWarning!,
                                    style: const TextStyle(color: Colors.orange, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () async {
                      try {
                        final FlutterNativeContactPicker contactPicker = FlutterNativeContactPicker();
                        final Contact? contact = await contactPicker.selectContact();
                        if (contact != null && contact.phoneNumbers != null && contact.phoneNumbers!.isNotEmpty) {
                          String rawPhone = contact.phoneNumbers!.first;
                          String cleanPhone = rawPhone.replaceAll(RegExp(r'[\s\-()]+'), '');
                          setState(() {
                            _phoneController.text = cleanPhone;
                            _checkWhatsappWarning(cleanPhone);
                            if (_nameController.text.isEmpty && contact.fullName != null) {
                              _nameController.text = contact.fullName!;
                            }
                          });
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to pick contact: $e')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.contact_phone),
                    tooltip: provider.translate('selectFromContacts'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: provider.translate('locationNotes'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty ? provider.translate('enterLocation') : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<RecurrenceType>(
                initialValue: _recurrenceType,
                decoration: InputDecoration(
                  labelText: provider.translate('repeatSchedule'),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: RecurrenceType.none,
                    child: Text(provider.translate('noRepeat')),
                  ),
                  DropdownMenuItem(
                    value: RecurrenceType.weekly,
                    child: Text(provider.translate('weekly')),
                  ),
                  DropdownMenuItem(
                    value: RecurrenceType.monthly,
                    child: Text(provider.translate('monthly')),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _recurrenceType = value ?? RecurrenceType.none;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _reminderMinutesBefore,
                decoration: InputDecoration(
                  labelText: provider.translate('reminderTiming'),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: -1,
                    child: Text(provider.translate('reminderNone')),
                  ),
                  DropdownMenuItem(
                    value: 60,
                    child: Text(provider.translate('reminder1Hour')),
                  ),
                  DropdownMenuItem(
                    value: 120,
                    child: Text(provider.translate('reminder2Hours')),
                  ),
                  DropdownMenuItem(
                    value: 1440,
                    child: Text(provider.translate('reminder1Day')),
                  ),
                  DropdownMenuItem(
                    value: 2880,
                    child: Text(provider.translate('reminder2Days')),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _reminderMinutesBefore = value ?? 1440;
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${provider.translate('selectedDate')}: ${_formatDate(_selectedDate)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(provider.translate('pickDate')),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedTime == null
                        ? provider.translate('noTimeSelected')
                        : '${provider.translate('selectedTime')}: ${_formatTime(_selectedTime!.hour, _selectedTime!.minute, use24Hour)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime ?? TimeOfDay.now(),
                        builder: (context, child) {
                          return MediaQuery(
                            data: MediaQuery.of(context).copyWith(
                              alwaysUse24HourFormat: use24Hour,
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedTime = picked;
                        });
                      }
                    },
                    icon: const Icon(Icons.access_time),
                    label: Text(provider.translate('pickTime')),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final rawPhone = _phoneController.text;
                    final digitsOnly = rawPhone.replaceAll(RegExp(r'\D'), '');

                    final appt = Appointment(
                      id: widget.appointment?.id ?? const Uuid().v4(),
                      date: _selectedDate,
                      clientName: _nameController.text.trim(),
                      phoneNumber: digitsOnly,
                      location: _locationController.text.trim(),
                      hour: _selectedTime?.hour,
                      minute: _selectedTime?.minute,
                      recurrenceType: _recurrenceType,
                      excludedDates: widget.appointment?.excludedDates,
                      reminderMinutesBefore: _reminderMinutesBefore,
                    );

                    await provider.addAppointment(appt);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                child: Text(
                  widget.appointment == null ? provider.translate('saveAppointment') : provider.translate('updateAppointment'),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
