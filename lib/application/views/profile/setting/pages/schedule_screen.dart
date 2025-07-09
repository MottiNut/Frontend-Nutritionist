import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart'; // Paquete para el calendario
import '../../../../../configuration/themes/app_colors.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<String>> _holidays = {
    DateTime(DateTime.now().year, 1, 1): ['Año Nuevo'],
    DateTime(DateTime.now().year, 5, 1): ['Día del Trabajo'],
    DateTime(DateTime.now().year, 12, 25): ['Navidad'],
  };

  // Horarios por defecto
  Map<String, Map<String, dynamic>> _weeklySchedule = {
    'Lunes': {'available': true, 'start': '8:00 AM', 'end': '5:00 PM'},
    'Martes': {'available': true, 'start': '8:00 AM', 'end': '5:00 PM'},
    'Miércoles': {'available': true, 'start': '8:00 AM', 'end': '5:00 PM'},
    'Jueves': {'available': true, 'start': '8:00 AM', 'end': '5:00 PM'},
    'Viernes': {'available': true, 'start': '8:00 AM', 'end': '5:00 PM'},
    'Sábado': {'available': true, 'start': '9:00 AM', 'end': '1:00 PM'},
    'Domingo': {'available': false, 'start': 'Cerrado', 'end': ''},
  };

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Gestión de Horarios'),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSchedule,
            tooltip: 'Guardar cambios',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de Calendario
            _buildCalendarSection(),
            const SizedBox(height: 24),

            // Horario del día seleccionado
            if (_selectedDay != null) _buildDaySchedule(_selectedDay!),
            const SizedBox(height: 24),

            // Configuración semanal
            _buildWeeklyScheduleSection(),
            const SizedBox(height: 24),

            // Días festivos
            _buildHolidaysSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              holidayTextStyle: TextStyle(color: Colors.red.shade600),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonDecoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              formatButtonTextStyle: TextStyle(color: Colors.white),
            ),
            holidayPredicate: (day) {
              return _holidays.containsKey(
                  DateTime(day.year, day.month, day.day));
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Selecciona un día para configurar horarios especiales',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySchedule(DateTime day) {
    final isHoliday = _holidays.containsKey(
        DateTime(day.year, day.month, day.day));
    final dayName = _getDayName(day);
    final defaultSchedule = _weeklySchedule[dayName];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Horario para ${_formatDate(day)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (isHoliday)
                Chip(
                  label: const Text('Festivo'),
                  backgroundColor: Colors.red.shade100,
                  labelStyle: const TextStyle(color: Colors.red),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (isHoliday)
            const Text(
              'Día festivo - Consultorio cerrado',
              style: TextStyle(color: Colors.red),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Disponible:'),
                    const SizedBox(width: 16),
                    Switch(
                      value: defaultSchedule?['available'] ?? false,
                      onChanged: (value) {
                        setState(() {
                          _weeklySchedule[dayName]?['available'] = value;
                        });
                      },

                      activeColor: Colors.white,
                      activeTrackColor: AppColors.primary,
                      inactiveThumbColor: Colors.grey,
                      inactiveTrackColor: AppColors.iconPrimary.withOpacity(0.3), // Fondo cuando está apagado
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (defaultSchedule?['available'] ?? false) ...[
                  _buildTimePicker(
                    label: 'Hora de inicio',
                    time: defaultSchedule?['start'] ?? '',
                    onTimeSelected: (time) {
                      setState(() {
                        _weeklySchedule[dayName]?['start'] = time;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTimePicker(
                    label: 'Hora de fin',
                    time: defaultSchedule?['end'] ?? '',
                    onTimeSelected: (time) {
                      setState(() {
                        _weeklySchedule[dayName]?['end'] = time;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _saveSpecialDaySchedule(day);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text('Guardar horario especial'),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildWeeklyScheduleSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuración Semanal Regular',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ..._weeklySchedule.entries.map((entry) {
            final day = entry.key;
            final schedule = entry.value;
            return _buildDayScheduleItem(
              day: day,
              isAvailable: schedule['available'],
              hours: schedule['available']
                  ? '${schedule['start']} - ${schedule['end']}'
                  : 'Cerrado',
              onChanged: (value) {
                setState(() {
                  _weeklySchedule[day]?['available'] = value;
                });
              },
            );
          }).toList(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _editWeeklySchedule,
              child: const Text('Editar Horarios Semanales'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHolidaysSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Días Festivos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (_holidays.isEmpty)
            const Text('No hay días festivos configurados')
          else
            ..._holidays.entries.map((entry) {
              return _buildHolidayItem(
                entry.value.first,
                '${entry.key.day}/${entry.key.month}/${entry.key.year}',
                onDelete: () {
                  setState(() {
                    _holidays.remove(entry.key);
                  });
                },
              );
            }).toList(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _addHoliday,
              child: const Text('Agregar Día Festivo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayScheduleItem({
    required String day,
    required bool isAvailable,
    required String hours,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              day,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: isAvailable,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: AppColors.primary,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: AppColors.iconPrimary.withOpacity(0.3),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              hours,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            onPressed: () {
              _editDaySchedule(day);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHolidayItem(String name, String date, {VoidCallback? onDelete}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            date,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required String time,
    required ValueChanged<String> onTimeSelected,
  }) {
    return Row(
      children: [
        Text('$label:'),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: () async {
              final TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: _parseTime(time),
              );
              if (picked != null) {
                onTimeSelected(_formatTime(picked));
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                time.isEmpty ? 'Seleccionar hora' : time,
                style: TextStyle(
                  color: time.isEmpty ? Colors.grey.shade500 : Colors.black,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Métodos auxiliares
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getDayName(DateTime date) {
    switch (date.weekday) {
      case 1: return 'Lunes';
      case 2: return 'Martes';
      case 3: return 'Miércoles';
      case 4: return 'Jueves';
      case 5: return 'Viernes';
      case 6: return 'Sábado';
      case 7: return 'Domingo';
      default: return '';
    }
  }

  TimeOfDay _parseTime(String time) {
    if (time.isEmpty) return TimeOfDay.now();

    final parts = time.split(' ');
    final timePart = parts[0].split(':');
    final period = parts.length > 1 ? parts[1] : 'AM';

    int hour = int.parse(timePart[0]);
    final minute = int.parse(timePart[1]);

    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;

    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  // Métodos de acción
  void _editWeeklySchedule() {
    // Implementar lógica para editar horario semanal
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Horario Semanal'),
        content: const Text('Aquí puedes editar los horarios para toda la semana.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _editDaySchedule(String day) {
    // Implementar lógica para editar horario de un día específico
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar horario para $day'),
        content: const Text('Configura los horarios para este día.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _addHoliday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      final TextEditingController controller = TextEditingController();
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Agregar día festivo'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nombre del festivo',
              hintText: 'Ej. Día de la Independencia',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _holidays[DateTime(picked.year, picked.month, picked.day)] =
                  [controller.text];
                });
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      );
    }
  }

  void _saveSpecialDaySchedule(DateTime day) {
    // Implementar lógica para guardar horario especial
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Horario especial para ${_formatDate(day)} guardado'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _saveSchedule() {
    // Implementar lógica para guardar toda la configuración
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuración de horarios guardada'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}