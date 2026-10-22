import 'package:carbon_tracker/core/config/app_constants.dart';
import 'package:carbon_tracker/features/fitness/models/health_permission_status.dart';
import 'package:flutter/material.dart';

class HealthPermissionBanner extends StatelessWidget {
  const HealthPermissionBanner({
    super.key,
    required this.statusResult,
    required this.onDismiss,
    required this.onAction,
  });

  final HealthPermissionResult statusResult;
  final VoidCallback onDismiss;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    if (statusResult.isGranted) {
      return const SizedBox.shrink();
    }

    final isUnavailable = statusResult.isUnavailable;
    final isPartial = statusResult.isPartial;

    final Color bgColor;
    final Color borderColor;
    final Color iconColor;
    final IconData icon;
    final String title;
    final String message;
    final String actionLabel;

    if (isUnavailable) {
      bgColor = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFDE68A);
      iconColor = const Color(0xFFD97706);
      icon = Icons.warning_amber_rounded;
      title = 'Health Connect Not Installed';
      message =
          'Install Health Connect to enable fitness metrics and activity tracking.';
      actionLabel = 'Install Health Connect';
    } else if (isPartial) {
      bgColor = const Color(0xFFEFF6FF);
      borderColor = const Color(0xFFBFDBFE);
      iconColor = const Color(0xFF2563EB);
      icon = Icons.info_outline_rounded;
      title = 'Partial Health Permissions';
      message =
          'Some health permissions were denied. Grant remaining permissions to enable all fitness features.';
      actionLabel = 'Grant Permission';
    } else {
      bgColor = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFFECACA);
      iconColor = const Color(0xFFDC2626);
      icon = Icons.health_and_safety_outlined;
      title = 'Health Permission Denied';
      message =
          'Health permissions are required to display your steps, distance, calories, and activity data.';
      actionLabel = 'Grant Permission';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.subtitleText,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('dismiss_permission_banner'),
                icon: const Icon(Icons.close, size: 18),
                color: Colors.grey.shade600,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Dismiss',
                onPressed: onDismiss,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              key: const Key('permission_banner_action_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: iconColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}
