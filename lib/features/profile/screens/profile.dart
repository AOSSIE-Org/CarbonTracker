import 'package:carbon_tracker/core/config/app_constants.dart';
import 'package:carbon_tracker/core/data/tracking_options.dart';
import 'package:carbon_tracker/core/data/transport_preferences.dart';
import 'package:carbon_tracker/core/providers/trips_provider.dart';
import 'package:carbon_tracker/core/widgets/modal.dart';
import 'package:carbon_tracker/database/models/user.dart';
import 'package:carbon_tracker/core/providers/user_provider.dart';
import 'package:carbon_tracker/features/profile/services/export_data_service.dart';
import 'package:carbon_tracker/features/profile/data/trips_delete_modal_data.dart';
import 'package:carbon_tracker/features/profile/widgets/section_header.dart';
import 'package:carbon_tracker/features/profile/widgets/tracking_option_tile.dart';
import 'package:carbon_tracker/features/profile/widgets/transport_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const _redColor = Color(0xFFB00020);
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _sustainabilityController =
      TextEditingController();
  bool _controllerInitialized = false;
  bool _myDataExpanded = false;

  Future<void> saveData() async {
    final user = ref.read(userProvider);
    if (user != null) {
      final weight = double.tryParse(_weightController.text) ?? user.weight;
      await ref
          .read(userProvider.notifier)
          .updateUser(
            user.copyWith(
              weight: weight < 1 || weight > 500 ? user.weight : weight,
              sustainabilityThoughts: _sustainabilityController.text,
            ),
          );
    }
  }

  Future<void> onTransportSelection(bool selected, String label) async {
    final user = ref.read(userProvider);
    if (user != null) {
      await ref
          .read(userProvider.notifier)
          .updateUser(
            user.copyWith(
              preferredTransports: selected
                  ? user.preferredTransports.where((e) => e != label).toList()
                  : [...user.preferredTransports, label],
            ),
          );
    }
  }

  Future<void> onTrackingSelection(TrackingOption type) async {
    {
      await ref
          .read(userProvider.notifier)
          .updateUser(
            ref.read(userProvider)!.copyWith(trackingMode: type.name),
          );
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _sustainabilityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    if (user != null && !_controllerInitialized) {
      _weightController.text = user.weight.toString();
      _sustainabilityController.text = user.sustainabilityThoughts ?? '';
      _controllerInitialized = true;
    }
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(user),
                const SizedBox(height: 28),
                const Text(
                  'Preferences',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                _buildPreferencesCard(
                  user,
                  _weightController,
                  _sustainabilityController,
                ),
                const SizedBox(height: 16),
                _buildMyDataCard(),
                const SizedBox(height: 24),
                _buildSignOut(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(User? user) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              // Placeholder avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueGrey.shade200, // placeholder color
                  border: Border.all(color: AppColors.secondaryColor, width: 2),
                ),
                child: const Icon(Icons.person, size: 48, color: Colors.white),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.eco, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            user?.name ?? '',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Conscious Commuter',
            style: TextStyle(fontSize: 13, color: AppColors.subtitleText),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard(
    User? user,
    TextEditingController weightController,
    TextEditingController sustainabilityController,
  ) {
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.metricsBackgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.directions_car,
            title: 'Transport Preferences',
            iconColor: AppColors.greenIcon,
            bgColor: AppColors.greenIconBg,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: transportPreferences.map((el) {
              final selected = user.preferredTransports.contains(el["label"]);
              return TransportChip(
                label: el["label"],
                selected: selected,
                onTransportSelection: () =>
                    onTransportSelection(selected, el['label']),
              );
            }).toList(),
          ),
          const Divider(height: 40, thickness: 0.5),
          SectionHeader(
            icon: Icons.location_on_outlined,
            title: 'Tracking Mode',
            iconColor: AppColors.greyIcon,
            bgColor: AppColors.greyIconBg,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TrackingOptionTile(
                selected: user.trackingMode == TrackingOption.refresh.name,
                icon: Icons.refresh,
                label: 'Refresh',
                onTap: () => onTrackingSelection(TrackingOption.refresh),
              ),
              const SizedBox(width: 10),
              TrackingOptionTile(
                selected: user.trackingMode == TrackingOption.high.name,
                icon: Icons.bolt,
                label: 'High',
                onTap: () => onTrackingSelection(TrackingOption.high),
              ),
              const SizedBox(width: 10),
              TrackingOptionTile(
                selected: user.trackingMode == TrackingOption.eco.name,
                icon: Icons.energy_savings_leaf,
                label: 'Eco',
                onTap: () => onTrackingSelection(TrackingOption.eco),
              ),
            ],
          ),
          const Divider(height: 40, thickness: 0.5),
          _weightRow(weightController),
          const Divider(height: 40, thickness: 0.5),
          _sustainabilityThoughtsRow(sustainabilityController),
        ],
      ),
    );
  }

  Widget _weightRow(TextEditingController controller) {
    return Row(
      children: [
        SectionHeader(
          icon: Icons.monitor_weight_outlined,
          title: 'Weight',
          iconColor: AppColors.greenIcon,
          bgColor: AppColors.greenIconBg,
        ),
        const Spacer(),
        SizedBox(
          width: 40,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(child: const Icon(Icons.edit_outlined, size: 18)),
      ],
    );
  }

  Widget _sustainabilityThoughtsRow(TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SectionHeader(
              icon: Icons.format_quote,
              title: 'Sustainability Thoughts',
              iconColor: AppColors.greyIcon,
              bgColor: AppColors.greyIconBg,
            ),
            GestureDetector(child: const Icon(Icons.edit_outlined, size: 18)),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.greenBorder,
              style: BorderStyle.solid,
            ),
          ),
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, height: 1.4),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Share your thoughts on sustainability...',
              hintStyle: TextStyle(
                fontSize: 13,
                color: AppColors.minisculeText,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyDataCard() {
    return Material(
      color: AppColors.metricsBackgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.metricsBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    size: 18,
                    color: Color(0xFF2F6F66),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'My Data',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () =>
                      setState(() => _myDataExpanded = !_myDataExpanded),
                  child: Icon(
                    _myDataExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                ),
              ],
            ),
          ),

          if (_myDataExpanded) ...[
            const Divider(height: 1, thickness: 0.5),
            Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text(
                    'Export Data',
                    style: TextStyle(fontSize: 14),
                  ),
                  onTap: () async {
                    await ExportDataService.shareFile();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: _redColor),
                  title: const Text(
                    'Clear Stored Trips',
                    style: TextStyle(fontSize: 14, color: _redColor),
                  ),
                  onTap: () {
                    showInfoModal(
                      context,
                      TripsDeleteDialogStrings.clearTripHistoryTitle,
                      TripsDeleteDialogStrings.clearTripHistoryContent,
                      'Continue',
                      () => ref.read(tripProvider.notifier).deleteTrips(),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildSignOut() {
    return Center(
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: saveData,
              child: const Text(
                'SAVE CHANGES',
                style: TextStyle(
                  color: AppColors.secondaryColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          Expanded(
            child: TextButton(
              onPressed: () {
                ref.read(userProvider.notifier).deleteUser();
                ref.read(tripProvider.notifier).deleteTrips();
                context.goNamed('onboarding');
              },
              child: const Text(
                'SIGN OUT',
                style: TextStyle(
                  color: _redColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
