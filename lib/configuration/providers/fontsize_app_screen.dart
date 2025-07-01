import 'package:flutter/cupertino.dart';

class FontSizeProvider with ChangeNotifier {
  static const double extraSmall = 12.0;
  static const double small = 14.0;
  static const double medium = 16.0;
  static const double large = 18.0;

  double _fontSize = extraSmall; // Default size is now extraSmall
  static const double _defaultSize = extraSmall; // Added default size constant

  // Constructor to initialize with default size
  FontSizeProvider() {
    _fontSize = _defaultSize;
  }

  double get fontSize => _fontSize;
  double get iconScale => _fontSize / extraSmall;
  double get mainIconSize => 30.0 * iconScale;
  double get secondaryIconSize => 24.0 * iconScale;
  double get avatarSize => 48.0 * iconScale;
  double get counterTextSize => _fontSize * iconScale;
  double get captionTextSize => _fontSize * iconScale;
  double get usernameTextSize => (_fontSize + 1) * iconScale;
  static const double commentAvatarSize = 32.0;

  void setFontSize(double newSize) {
    _fontSize = newSize;
    notifyListeners();
  }

  // Reset to default size
  void resetToDefault() {
    _fontSize = _defaultSize;
    notifyListeners();
  }
}