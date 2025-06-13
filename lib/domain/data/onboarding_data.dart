import 'dart:ui';

class OnboardingData {
  final String title;
  final String description;
  final String svgPath;
  final Color backgroundColor;
  final List<Color> gradientColors;

  OnboardingData({
    required this.title,
    required this.description,
    required this.svgPath,
    required this.backgroundColor,
    required this.gradientColors,
  });
}
