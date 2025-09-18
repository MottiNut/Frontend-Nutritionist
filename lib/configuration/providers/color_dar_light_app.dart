import 'package:flutter/material.dart';

class DarkModeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  // Este método retorna el color del texto basado en el modo oscuro o claro
  Color get textColor => _isDarkMode ? Colors.white : Colors.black;

  // Este método retorna el color de fondo basado en el modo oscuro o claro
  Color get backgroundColor => _isDarkMode ? Colors.black : Colors.white;

  // Este método retorna el color del ícono basado en el modo oscuro o claro
  Color get iconColor => _isDarkMode ? Colors.white : Colors.black;

  set isDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }
}
