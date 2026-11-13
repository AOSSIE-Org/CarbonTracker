import 'dart:async';
import 'package:carbon_tracker/core/config/app_constants.dart';
import 'package:flutter/material.dart';

/// Displays a themed floating [SnackBar] with an optional action button.
void showAppSnackBar(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  final controller = messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: duration,
      backgroundColor: AppColors.modalBackgroundColor,
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.modalBorderColor),
      ),
      content: Text(
        message,
        style: const TextStyle(
          color: AppColors.textDark,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      action: (actionLabel != null && onAction != null)
          ? SnackBarAction(
              label: actionLabel,
              textColor: AppColors.secondaryColor,
              onPressed: onAction,
            )
          : null,
    ),
  );

  // Guarantee auto-dismissal even when action buttons prevent Android from timing out
  Timer(duration, () {
    try {
      controller.close();
    } catch (_) {}
  });
}


