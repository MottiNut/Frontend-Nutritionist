
// Enums de carnet
import 'package:flutter/material.dart';

enum ValidationState { initializing, processing, success, failed }
enum StepStatus { pending, processing, completed, failed }

class ValidationStep {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  StepStatus status;

  ValidationStep({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.status = StepStatus.pending,
  });
}

class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final Map<String, dynamic> analysisData;

  ValidationResult({
    required this.isValid,
    this.errorMessage,
    required this.analysisData,
  });
}