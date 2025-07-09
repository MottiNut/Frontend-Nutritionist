import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../../../../configuration/themes/app_colors.dart';

class DateInputWidget extends StatefulWidget {
  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final bool isFrequentPatient;
  final Function(DateTime?) onDateChanged;
  final Function(TimeOfDay?) onTimeChanged;
  final bool isEditable;

  const DateInputWidget({
    Key? key,
    this.initialDate,
    this.initialTime,
    this.isFrequentPatient = false,
    required this.onDateChanged,
    required this.onTimeChanged,
    this.isEditable = true,
  }) : super(key: key);

  @override
  State<DateInputWidget> createState() => _DateInputWidgetState();
}

class _DateInputWidgetState extends State<DateInputWidget> with TickerProviderStateMixin {
  late TextEditingController _dayController;
  late TextEditingController _monthController;
  late TextEditingController _yearController;
  late TextEditingController _hourController;
  late TextEditingController _minuteController;

  late AnimationController _animationController;
  late AnimationController _expandController;
  late AnimationController _timeExpandController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _timeExpandAnimation;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showTimeInput = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimations();
    _selectedDate = widget.initialDate;
    _selectedTime = widget.initialTime;
    _showTimeInput = widget.initialTime != null;
    _isExpanded = false;
  }

  void _initializeControllers() {
    final date = widget.initialDate;
    final time = widget.initialTime;

    _dayController = TextEditingController(
      text: date != null ? date.day.toString().padLeft(2, '0') : '',
    );
    _monthController = TextEditingController(
      text: date != null ? date.month.toString().padLeft(2, '0') : '',
    );
    _yearController = TextEditingController(
      text: date != null ? date.year.toString() : '',
    );
    _hourController = TextEditingController(
      text: time != null ? time.hour.toString().padLeft(2, '0') : '',
    );
    _minuteController = TextEditingController(
      text: time != null ? time.minute.toString().padLeft(2, '0') : '',
    );

    // Listeners para validación en tiempo real
    _dayController.addListener(_validateDate);
    _monthController.addListener(_validateDate);
    _yearController.addListener(_validateDate);
    _hourController.addListener(_validateTime);
    _minuteController.addListener(_validateTime);
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    // Ajuste 1: Mejorar la animación de cierre de la sección de hora
    _timeExpandController = AnimationController(
      duration: const Duration(milliseconds: 400), // Aumentado de 350 a 400ms
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    ));

    // Ajuste 1: Usar curva más suave para la animación de tiempo
    _timeExpandAnimation = CurvedAnimation(
      parent: _timeExpandController,
      curve: Curves.easeInOutCubic, // Cambio de Curves.easeInOut a Curves.easeInOutCubic
    );
  }

  void _validateDate() {
    final dayText = _dayController.text;
    final monthText = _monthController.text;
    final yearText = _yearController.text;

    if (dayText.isEmpty || monthText.isEmpty || yearText.isEmpty) {
      setState(() {
        _hasError = false;
        _errorMessage = '';
        _selectedDate = null;
      });
      widget.onDateChanged(null);
      return;
    }

    final day = int.tryParse(dayText);
    final month = int.tryParse(monthText);
    final year = int.tryParse(yearText);

    if (day == null || month == null || year == null) {
      _setError('Formato de fecha inválido');
      return;
    }

    if (day < 1 || day > 31) {
      _setError('Día debe estar entre 1 y 31');
      return;
    }

    if (month < 1 || month > 12) {
      _setError('Mes debe estar entre 1 y 12');
      return;
    }

    if (year < 1900 || year > DateTime.now().year + 1) {
      _setError('Año inválido');
      return;
    }

    try {
      final newDate = DateTime(year, month, day);

      // Validar que la fecha no sea futura (excepto hoy)
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);

      if (newDate.isAfter(todayOnly)) {
        _setError('La fecha no puede ser futura');
        return;
      }

      setState(() {
        _hasError = false;
        _errorMessage = '';
        _selectedDate = newDate;
      });

      widget.onDateChanged(newDate);
      _animationController.forward().then((_) {
        _animationController.reverse();
      });

    } catch (e) {
      _setError('Fecha inválida');
    }
  }

  void _validateTime() {
    final hourText = _hourController.text;
    final minuteText = _minuteController.text;

    if (hourText.isEmpty || minuteText.isEmpty) {
      setState(() {
        _selectedTime = null;
      });
      widget.onTimeChanged(null);
      return;
    }

    final hour = int.tryParse(hourText);
    final minute = int.tryParse(minuteText);

    if (hour == null || minute == null) {
      return;
    }

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return;
    }

    final newTime = TimeOfDay(hour: hour, minute: minute);
    setState(() {
      _selectedTime = newTime;
    });
    widget.onTimeChanged(newTime);
  }

  void _setError(String message) {
    setState(() {
      _hasError = true;
      _errorMessage = message;
      _selectedDate = null;
    });
    widget.onDateChanged(null);
  }

  Future<void> _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Localizations(
          locale: const Locale('es', 'ES'),
          delegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primary,
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      _updateControllersWithDate(picked);
    }
  }

  Future<void> _showTimePicker() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _updateControllersWithTime(picked);
    }
  }

  void _updateControllersWithDate(DateTime date) {
    _dayController.text = date.day.toString().padLeft(2, '0');
    _monthController.text = date.month.toString().padLeft(2, '0');
    _yearController.text = date.year.toString();
  }

  void _updateControllersWithTime(TimeOfDay time) {
    _hourController.text = time.hour.toString().padLeft(2, '0');
    _minuteController.text = time.minute.toString().padLeft(2, '0');
  }

  void _setToday() {
    final now = DateTime.now();
    final today = TimeOfDay.now();
    _updateControllersWithDate(now);
    _updateControllersWithTime(today);

    if (!_showTimeInput) {
      _toggleTimeInput();
    }
  }

  void _toggleTimeInput() {
    setState(() {
      _showTimeInput = !_showTimeInput;
    });

    if (_showTimeInput) {
      _timeExpandController.forward();
      if (_selectedTime == null) {
        final now = TimeOfDay.now();
        _updateControllersWithTime(now);
      }
    } else {
      _timeExpandController.reverse();
    }
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  String _formatTimeWithAmPm(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

    return '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                // Ajuste 3: Agregar margen inferior para el botón
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: _hasError
                        ? Colors.red.withOpacity(0.3)
                        : AppColors.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildCollapsedHeader(),
                    // Sección expandible
                    SizeTransition(
                      sizeFactor: _expandAnimation,
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildDateInputRow(),
                          if (_hasError) ...[
                            const SizedBox(height: 8),
                            _buildErrorMessage(),
                          ],
                          // Sección de hora con animación mejorada
                          SizeTransition(
                            sizeFactor: _timeExpandAnimation,
                            child: Column(
                              children: [
                                if (_showTimeInput) ...[
                                  const SizedBox(height: 16),
                                  _buildTimeSection(),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildActionButtons(),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Ajuste 3: Posicionar el botón para que esté mitad dentro, mitad fuera
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: _buildExpandButton(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCollapsedHeader() {
    final labelText = widget.isFrequentPatient ? 'Última atención' : 'Fecha de atención';

    return Column(
      children: [
        Row(
          children: [
            Icon(
              widget.isFrequentPatient ? Icons.history : Icons.calendar_today,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                labelText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (_selectedDate != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatDate(_selectedDate!),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        // Ajuste 2: Agregar margen izquierdo a la hora
        if (_selectedTime != null) ...[

          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(width: 28),
              Icon(
                Icons.access_time,
                size: 12,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: widget.isEditable ? _showTimePicker : null,
                child: Text(
                  _formatTimeWithAmPm(_selectedTime!),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildExpandButton() {
    return Center(
      child: GestureDetector(
        onTap: widget.isEditable ? _toggleExpansion : null,
        child: AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Container(
              width: 27,
              height: 27,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Transform.rotate(
                angle: _rotationAnimation.value * 6.14159,
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimeSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Hora de atención',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: widget.isEditable ? _showTimePicker : null,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.schedule,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTimeInputRow(),
        ],
      ),
    );
  }

  Widget _buildTimeInputRow() {
    return Row(
      children: [
        Expanded(child: _buildTimeField(_hourController, 'HH', 'Hora', 2)),
        _buildTimeSeparator(),
        Expanded(child: _buildTimeField(_minuteController, 'MM', 'Min', 2)),
      ],
    );
  }

  Widget _buildTimeField(TextEditingController controller, String hint, String label, int maxLength) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          textAlign: TextAlign.center,
          enabled: widget.isEditable,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.primary,
                width: 2.5,
              ),
            ),
            disabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(maxLength),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeSeparator() {
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 8, right: 8),
      child: Text(
        ':',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 24,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }

  Widget _buildDateInputRow() {
    return Row(
      children: [
        Expanded(child: _buildDateField(_dayController, 'DD', 'Día', 2)),
        _buildSeparator(),
        Expanded(child: _buildDateField(_monthController, 'MM', 'Mes', 2)),
        _buildSeparator(),
        Expanded(flex: 2, child: _buildDateField(_yearController, 'AAAA', 'Año', 4)),
      ],
    );
  }

  Widget _buildDateField(TextEditingController controller, String hint, String label, int maxLength) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          textAlign: TextAlign.center,
          enabled: widget.isEditable,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: _hasError ? Colors.red : AppColors.primary,
                width: 2,
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: _hasError ? Colors.red : AppColors.primary,
                width: 2.5,
              ),
            ),
            disabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _hasError ? Colors.red : AppColors.primary,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(maxLength),
          ],
        ),
      ],
    );
  }

  Widget _buildSeparator() {
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 8, right: 8),
      child: Text(
        '/',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 24,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.isEditable ? _showDatePicker : null,
            icon: const Icon(Icons.calendar_month, size: 18),
            label: const Text('Calendario'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: widget.isEditable ? _toggleTimeInput : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: _showTimeInput ? Colors.white : AppColors.primary,
            backgroundColor: _showTimeInput ? AppColors.primary : Colors.transparent,
            side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Icon(
            Icons.access_time,
            size: 18,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: widget.isEditable ? _setToday : null,
            icon: const Icon(Icons.today, size: 18),
            label: const Text('Hoy'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    _animationController.dispose();
    _expandController.dispose();
    _timeExpandController.dispose();
    super.dispose();
  }
}