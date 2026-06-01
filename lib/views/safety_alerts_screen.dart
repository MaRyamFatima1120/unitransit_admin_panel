import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/core/utils/responsive_util.dart';
import 'package:unitransit_admin/core/utils/animations.dart';
import 'package:unitransit_admin/core/services/firebase_service.dart';
import 'package:unitransit_admin/view_models/dashboard_view_model.dart';

class SafetyAlertsScreen extends StatefulWidget {
  const SafetyAlertsScreen({super.key});

  @override
  State<SafetyAlertsScreen> createState() => _SafetyAlertsScreenState();
}

class _SafetyAlertsScreenState extends State<SafetyAlertsScreen> {
  // Local UI state for sliders/switches (synced from Firebase)
  double _speedLimit = 60.0;
  bool _geofencingEnabled = true;
  bool _overspeedingEnabled = true;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppResponsiveUtil.isMobile(context);
    final firebaseService = context.read<FirebaseService>();

    return FadeInSlide(
      duration: const Duration(milliseconds: 600),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: StreamBuilder<Map<String, dynamic>>(
          stream: firebaseService.getSafetyConfig(),
          builder: (context, snapshot) {
            // Sync local state from Firebase without disturbing ongoing drag
            if (snapshot.hasData && !_isSaving) {
              final data = snapshot.data!;
              _speedLimit = (data['speedLimit'] as double?) ?? 60.0;
              _geofencingEnabled = data['geofencingEnabled'] ?? true;
              _overspeedingEnabled = data['overspeedingEnabled'] ?? true;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView(
                    children: [
                      // ── Geofencing Section ────────────────────────────
                      _buildSafetySection('Geofencing Policies', [
                        ListTile(
                          title: const Text('Route Deviation Alert'),
                          subtitle: const Text(
                              'Notify admin if a bus moves more than 200m away from the planned route.'),
                          trailing: const Icon(Icons.location_on_rounded,
                              color: Colors.blue),
                        ),
                        SwitchListTile(
                          title: const Text('Enable Geofencing Alerts'),
                          value: _geofencingEnabled,
                          onChanged: (v) async {
                            setState(() => _geofencingEnabled = v);
                            await _saveConfig(firebaseService);
                          },
                          activeColor: AppColors.primaryNavy,
                        ),
                      ]),
                      const SizedBox(height: 24),

                      // ── Speed Monitoring ──────────────────────────────
                      _buildSafetySection('Speed Monitoring', [
                        ListTile(
                          title: const Text('Maximum Speed Limit'),
                          subtitle: Text(
                              'Current Limit: ${_speedLimit.toInt()} km/h'),
                          trailing: const Icon(Icons.speed_rounded,
                              color: Colors.orange),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Slider(
                            value: _speedLimit,
                            min: 40,
                            max: 100,
                            divisions: 12,
                            label: '${_speedLimit.toInt()} km/h',
                            onChanged: (v) =>
                                setState(() => _speedLimit = v),
                            onChangeEnd: (v) async {
                              // Save to Firebase only when slider is released
                              await _saveConfig(firebaseService);
                            },
                            activeColor: AppColors.primaryNavy,
                          ),
                        ),
                        SwitchListTile(
                          title: const Text('Overspeeding Alerts'),
                          subtitle: Text(
                              'Notify admin if a bus exceeds ${_speedLimit.toInt()} km/h.'),
                          value: _overspeedingEnabled,
                          onChanged: (v) async {
                            setState(() => _overspeedingEnabled = v);
                            await _saveConfig(firebaseService);
                          },
                          activeColor: AppColors.primaryNavy,
                        ),
                      ]),
                      const SizedBox(height: 24),

                      // ── Save Config Button ────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _buildSaveRow(firebaseService),
                      ),
                      const SizedBox(height: 32),

                      // ── Recent Violations ─────────────────────────────
                      _buildRecentAlerts(context),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSaveRow(FirebaseService firebaseService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.primaryNavy.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_done_rounded,
              color: AppColors.primaryNavy, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Settings auto-save when you toggle switches. Tap "Save Now" to force-save slider values.',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isSaving
                ? null
                : () => _saveConfig(firebaseService),
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save_rounded, size: 16),
            label: const Text('Save Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveConfig(FirebaseService firebaseService) async {
    setState(() => _isSaving = true);
    try {
      await firebaseService.updateSafetyConfig({
        'speedLimit': _speedLimit,
        'geofencingEnabled': _geofencingEnabled,
        'overspeedingEnabled': _overspeedingEnabled,
        'geofenceRadiusMeters': 200,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text('Safety configuration saved!'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Safety & Speed Control',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
                fontSize: AppResponsiveUtil.isMobile(context) ? 24 : null,
              ),
        ),
        Text(
            'Configure real-time safety triggers and geofencing boundaries. Settings are saved to Firebase.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }

  Widget _buildSafetySection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primaryNavy)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRecentAlerts(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 12),
              Text('Active SOS / Safety Violations',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.red)),
            ],
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final alerts =
                  context.watch<DashboardViewModel>().emergencyAlerts;
              if (alerts.isEmpty) {
                return Padding(
                  padding: EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: Colors.green, size: 18),
                      SizedBox(width: 8),
                      Text('No active violations. System is safe.',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }

              return Column(
                children: alerts.take(5).map((a) {
                  final time = a['timestamp'] != null
                      ? DateFormat('dd MMM, hh:mm a').format(
                          DateTime.fromMillisecondsSinceEpoch(a['timestamp']))
                      : 'Just now';
                  final status = a['status'] ?? 'active';
                  final isActive = status == 'active';
                  return _buildViolationItem(
                    driverName: a['driverName'] ?? 'Driver',
                    busNumber: a['busNumber'] ?? 'N/A',
                    message: a['message'] ?? 'Emergency SOS',
                    time: time,
                    isActive: isActive,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildViolationItem({
    required String driverName,
    required String busNumber,
    required String message,
    required String time,
    required bool isActive,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.red.withValues(alpha: 0.07)
            : Colors.green.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? Colors.red.withValues(alpha: 0.2)
              : Colors.green.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.crisis_alert_rounded : Icons.check_circle_rounded,
            color: isActive ? Colors.red : Colors.green,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$driverName — Bus #$busNumber',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(message,
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.red.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isActive ? 'ACTIVE' : 'RESOLVED',
                  style: TextStyle(
                      color: isActive ? Colors.red : Colors.green,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5),
                ),
              ),
              const SizedBox(height: 4),
              Text(time,
                  style: TextStyle(
                      fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}