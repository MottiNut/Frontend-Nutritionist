import 'package:flutter/material.dart';
import 'dart:ui';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale;

  LanguageProvider() : _currentLocale = window.locale;

  Locale get currentLocale => _currentLocale;

  String get languageName {
    switch (_currentLocale.languageCode) {
      case 'es':
        return 'Español';
      case 'en':
        return 'Inglés';
      default:
        return 'Español';
    }
  }

  void setLocale(Locale locale) {
    _currentLocale = locale;
    notifyListeners();
  }
}
