import 'package:flutter/material.dart';
import 'package:carbon_tracker/core/config/app_constants.dart';

Future<void> showWatchModal(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: AppColors.modalBorderColor),
        ),
        backgroundColor: AppColors.modalBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.60,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Record Activities on the Go",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 12),

                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20.0),
                          child: Image.asset(
                            'assets/images/watch-onboarding.png',
                            fit: BoxFit.contain,
                            width: MediaQuery.of(context).size.width * 0.4,
                            semanticLabel:
                                "Watch onboarding image representing eco-friendliness and sustainability",
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '''Install the Carbon Tracker companion watch app and the Google Pixel Watch app on your Android smartwatch to start tracking activities directly from your wrist. Your activities will automatically sync with Carbon Tracker, where you can view your activity history and see the estimated carbon footprint associated with each activity.
                      Your privacy comes first. All activity data collected from your watch is stored locally on your devices and is never uploaded to or stored on our servers. You remain in control of your data at all times.
                      Stay active, stay informed, and let’s make more carbon-conscious choices together.''',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.subtitleText,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
