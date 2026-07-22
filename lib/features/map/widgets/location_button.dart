import 'package:carbon_tracker/core/config/app_constants.dart';
import 'package:flutter/material.dart';

class LocateButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isShowingMap;

  const LocateButton({required this.onPressed, required this.isLoading, required this.isShowingMap});

  @override
  Widget build(BuildContext context) {
    return isShowingMap ? SizedBox.shrink() : ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        backgroundColor: AppColors.primaryColor,
        disabledBackgroundColor: AppColors.primaryColor,
        disabledForegroundColor: AppColors.secondaryColor.withValues(
          alpha: 0.4,
        ),
        foregroundColor: AppColors.secondaryColor,
        minimumSize: const Size(56, 56),
      ),

      child: isLoading
          ? SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          color: AppColors.secondaryColor,
          strokeWidth: 2,
        ),
      )
          : const Icon(
        Icons.check_rounded,
        size: 30,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
