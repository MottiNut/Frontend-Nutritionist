import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../../../../configuration/themes/app_colors.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Lista de feriados (ejemplo para 2025)
  final Set<String> _holidays = {
    '2025-01-01', // Año Nuevo
    '2025-04-17', // Jueves Santo
    '2025-04-18', // Viernes Santo
    '2025-05-01', // Día del Trabajo
    '2025-06-29', // San Pedro y San Pablo
    '2025-07-28', // Independencia del Perú
    '2025-07-29', // Independencia del Perú
    '2025-08-30', // Santa Rosa de Lima
    '2025-10-08', // Combate de Angamos
    '2025-11-01', // Todos los Santos
    '2025-12-08', // Inmaculada Concepción
    '2025-12-25', // Navidad
  };

  // Horario laboral base (de 8:00 AM a 5:00 PM, Lunes a Viernes)
  final Map<int, List<String>> _baseWorkSchedule = {
    1: ['08:00', '09:00', '10:00', '11:00', '13:00', '14:00', '15:00', '16:00'], // Lunes (sin 12:00 por almuerzo)
    2: ['08:00', '09:00', '10:00', '11:00', '13:00', '14:00', '15:00', '16:00'], // Martes
    3: ['08:00', '09:00', '10:00', '11:00', '13:00', '14:00', '15:00', '16:00'], // Miércoles
    4: ['08:00', '09:00', '10:00', '11:00', '13:00', '14:00', '15:00', '16:00'], // Jueves
    5: ['08:00', '09:00', '10:00', '11:00', '13:00', '14:00', '15:00', '16:00'], // Viernes
    6: [], // Sábado
    7: [], // Domingo
  };

  // Días libres o bloqueados por el nutricionista
  final Set<String> _blockedDays = {
    '2025-09-25', // Día libre
    '2025-09-26', // Conferencia médica
  };

  // Horarios bloqueados específicos
  final Map<String, Set<String>> _blockedSlots = {
    '2025-09-20': {'12:00', '13:00'}, // Almuerzo extendido
    '2025-09-23': {'08:00', '09:00'}, // Reunión administrativa
  };

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  List<String> _getAvailableSlots(DateTime day) {
    final weekday = day.weekday;
    final dayKey = DateFormat('yyyy-MM-dd').format(day);

    // Si es feriado o día bloqueado, no hay horarios disponibles
    if (_holidays.contains(dayKey) || _blockedDays.contains(dayKey)) return [];

    final baseSlots = _baseWorkSchedule[weekday] ?? [];
    final blockedSlots = _blockedSlots[dayKey] ?? {};

    return baseSlots.where((slot) => !blockedSlots.contains(slot)).toList();
  }

  Set<String> _getBlockedSlots(DateTime day) {
    final dayKey = DateFormat('yyyy-MM-dd').format(day);
    return _blockedSlots[dayKey] ?? {};
  }

  bool _isDayBlocked(DateTime day) {
    final dayKey = DateFormat('yyyy-MM-dd').format(day);
    return _blockedDays.contains(dayKey);
  }

  bool _isHoliday(DateTime day) {
    final dayKey = DateFormat('yyyy-MM-dd').format(day);
    return _holidays.contains(dayKey);
  }

  bool _isWorkDay(DateTime day) {
    final weekday = day.weekday;
    return (_baseWorkSchedule[weekday] ?? []).isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mi Agenda',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Header con información del nutricionista
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.schedule, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Horario Laboral',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Lunes a Viernes: 8:00 AM - 5:00 PM\nAlmuerzo: 12:00 PM - 1:00 PM\nDuración por consulta: 60 minutos',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Calendario
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TableCalendar<String>(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              availableGestures: AvailableGestures.all,
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(color: Colors.red.shade400),
                holidayTextStyle: TextStyle(color: Colors.red.shade400),
                selectedDecoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 1,
                canMarkersOverflow: false,
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
                formatButtonDecoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                formatButtonTextStyle: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: AppColors.primary,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: AppColors.primary,
                ),
                titleTextStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  if (_isHoliday(day)) {
                    return Container(
                      margin: const EdgeInsets.all(4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${day.day}',
                        style: TextStyle(color: Colors.orange.shade800),
                      ),
                    );
                  }
                  if (!_isWorkDay(day)) {
                    return Container(
                      margin: const EdgeInsets.all(4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${day.day}',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    );
                  }
                  if (_isDayBlocked(day)) {
                    return Container(
                      margin: const EdgeInsets.all(4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${day.day}',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    );
                  }
                  return null;
                },
              ),
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
            ),
          ),

          // Agenda del día
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.event, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Agenda ${_selectedDay != null ? DateFormat('dd/MM/yyyy').format(_selectedDay!) : ''}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      if (_selectedDay != null && _isWorkDay(_selectedDay!) && !_isDayBlocked(_selectedDay!) && !_isHoliday(_selectedDay!))
                        IconButton(
                          icon: Icon(Icons.block, color: Colors.red.shade600),
                          onPressed: () => _blockDay(_selectedDay!),
                          tooltip: 'Bloquear día',
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _selectedDay == null
                        ? _buildEmptyState()
                        : _isHoliday(_selectedDay!)
                        ? _buildHoliday()
                        : _isDayBlocked(_selectedDay!)
                        ? _buildBlockedDay()
                        : !_isWorkDay(_selectedDay!)
                        ? _buildNonWorkDay()
                        : _buildScheduleContent(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleContent() {
    final availableSlots = _getAvailableSlots(_selectedDay!);
    final blockedSlots = _getBlockedSlots(_selectedDay!);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (blockedSlots.isNotEmpty) ...[
            _buildSectionTitle('Horarios Bloqueados', Colors.orange, Icons.block),
            const SizedBox(height: 8),
            _buildSlotGrid(blockedSlots.toList(), 'blocked'),
            const SizedBox(height: 16),
          ],
          if (availableSlots.isNotEmpty) ...[
            _buildSectionTitle('Horarios Disponibles', Colors.green, Icons.access_time),
            const SizedBox(height: 8),
            _buildSlotGrid(availableSlots, 'available'),
          ],
          if (availableSlots.isEmpty && blockedSlots.isEmpty) ...[
            _buildEmptyScheduleDay(),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSlotGrid(List<String> slots, String type) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 2.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        return _buildTimeSlot(slots[index], type);
      },
    );
  }

  Widget _buildTimeSlot(String time, String type) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    VoidCallback? onTap;

    switch (type) {
      case 'available':
        backgroundColor = Colors.green.shade50;
        borderColor = Colors.green.shade300;
        textColor = Colors.green.shade700;
        onTap = () => _blockTimeSlot(time);
        break;
      case 'blocked':
        backgroundColor = Colors.orange.shade50;
        borderColor = Colors.orange.shade300;
        textColor = Colors.orange.shade700;
        onTap = () => _unblockTimeSlot(time);
        break;
      default:
        backgroundColor = Colors.grey.shade50;
        borderColor = Colors.grey.shade300;
        textColor = Colors.grey.shade700;
        onTap = null;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            child: Text(
              time,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
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
          Icon(
            Icons.calendar_today,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Selecciona una fecha',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Elige un día del calendario para ver\ntu agenda y horarios',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoliday() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.celebration,
            size: 64,
            color: Colors.orange.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Día Feriado',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.orange.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Este día es feriado nacional.\nNo hay atención.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedDay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.block,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Día Bloqueado',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Has marcado este día como no disponible\npara consultas',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _unblockDay(_selectedDay!),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Desbloquear día', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildNonWorkDay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.weekend,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Día no laboral',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los fines de semana no forman\nparte de tu horario laboral',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyScheduleDay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.free_breakfast,
            size: 64,
            color: Colors.green.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Día libre de citas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.green.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No tienes citas programadas este día.\nTodos los horarios están disponibles.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _blockDay(DateTime day) {
    final dayKey = DateFormat('yyyy-MM-dd').format(day);
    setState(() {
      _blockedDays.add(dayKey);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.block, color: Colors.white),
            SizedBox(width: 8),
            Text('Día bloqueado exitosamente'),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _unblockDay(DateTime day) {
    final dayKey = DateFormat('yyyy-MM-dd').format(day);
    setState(() {
      _blockedDays.remove(dayKey);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Día desbloqueado exitosamente'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _blockTimeSlot(String time) {
    final dayKey = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    setState(() {
      if (_blockedSlots[dayKey] == null) {
        _blockedSlots[dayKey] = {};
      }
      _blockedSlots[dayKey]!.add(time);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.block, color: Colors.white),
            const SizedBox(width: 8),
            Text('Horario $time bloqueado'),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _unblockTimeSlot(String time) {
    final dayKey = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    setState(() {
      _blockedSlots[dayKey]?.remove(time);
      if (_blockedSlots[dayKey]?.isEmpty == true) {
        _blockedSlots.remove(dayKey);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('Horario $time desbloqueado'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}