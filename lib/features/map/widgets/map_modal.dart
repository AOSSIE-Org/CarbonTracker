import 'package:flutter/material.dart';
import 'package:carbon_tracker/core/config/app_constants.dart';

void showMapModal(
  BuildContext context,
  String title,
  double distance,
  String startLocation,
  String endLocation,
  VoidCallback onClose,
  VoidCallback onCompleted,
) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.modalBorderColor),
        ),
        backgroundColor: AppColors.modalBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Start Location",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(startLocation, style: TextStyle(fontSize: 14)),
                        const SizedBox(height: 12),
                        Text(
                          "End Location",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(endLocation, style: TextStyle(fontSize: 14)),
                        const SizedBox(height: 12),
                        Text(
                          "Distance",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${distance.toStringAsFixed(2)} km",
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        onClose();
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.secondaryColor.withValues(
                          alpha: 0.6,
                        ),
                        foregroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text("Completed Trip"),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () {
                        onCompleted();
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.secondaryColor.withValues(
                          alpha: 0.6,
                        ),
                        foregroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text("Cancel Trip"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
