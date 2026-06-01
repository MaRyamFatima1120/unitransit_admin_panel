import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/core/utils/responsive_util.dart';
import 'package:unitransit_admin/view_models/dashboard_view_model.dart';

class EmergencyAlertsScreen extends StatefulWidget {
  const EmergencyAlertsScreen({super.key});

  @override
  State<EmergencyAlertsScreen> createState() => _EmergencyAlertsScreenState();
}

class _EmergencyAlertsScreenState extends State<EmergencyAlertsScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  Map<String, dynamic>? _selectedAlert;
  Map<String, dynamic>? _firestoreUserData;
  bool _isLoadingUserData = false;
  String _filter = 'All'; // 'All', 'Active', 'Resolved'
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData(String userId) async {
    if (!mounted) return;
    setState(() {
      _isLoadingUserData = true;
      _firestoreUserData = null;
    });
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      if (doc.exists && mounted) {
        final userData = doc.data();
        if (userData?['role'] == 'Driver') {
          final driverDoc =
              await FirebaseFirestore.instance
                  .collection('drivers')
                  .doc(userId)
                  .get();
          if (driverDoc.exists && mounted) {
            setState(() {
              _firestoreUserData = {
                ...?userData,
                ...?driverDoc.data(),
                'role': 'Driver',
              };
            });
          } else {
            setState(() {
              _firestoreUserData = userData;
            });
          }
        } else {
          setState(() {
            _firestoreUserData = userData;
          });
        }
      } else {
        // Fallback: try drivers collection
        final driverDoc =
            await FirebaseFirestore.instance
                .collection('drivers')
                .doc(userId)
                .get();
        if (driverDoc.exists && mounted) {
          setState(() {
            _firestoreUserData = driverDoc.data();
            _firestoreUserData?['role'] = 'Driver';
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingUserData = false;
        });
      }
    }
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: destZoom,
    );

    final controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  Map<String, dynamic> _getAlertMetadata(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('accident') ||
        msg.contains('collision') ||
        msg.contains('hadsa')) {
      return {
        'category': 'Accident / Collision',
        'icon': Icons.car_crash_rounded,
        'color': Colors.red[800]!,
        'priority': 'CRITICAL',
      };
    } else if (msg.contains('medical') ||
        msg.contains('sick') ||
        msg.contains('faint') ||
        msg.contains('tibb') ||
        msg.contains('pain') ||
        msg.contains('hospital')) {
      return {
        'category': 'Medical Emergency',
        'icon': Icons.medical_services_rounded,
        'color': Colors.redAccent,
        'priority': 'HIGH',
      };
    } else if (msg.contains('harass') ||
        msg.contains('threat') ||
        msg.contains('fight') ||
        msg.contains('security') ||
        msg.contains('rob') ||
        msg.contains('danger')) {
      return {
        'category': 'Security / Harassment',
        'icon': Icons.security_rounded,
        'color': Colors.red[900]!,
        'priority': 'CRITICAL',
      };
    } else if (msg.contains('breakdown') ||
        msg.contains('engine') ||
        msg.contains('puncture') ||
        msg.contains('tire') ||
        msg.contains('kharab') ||
        msg.contains('fuel')) {
      return {
        'category': 'Bus Breakdown / Technical',
        'icon': Icons.build_rounded,
        'color': Colors.amber[800]!,
        'priority': 'MEDIUM',
      };
    }
    return {
      'category': 'General Panic SOS',
      'icon': Icons.warning_amber_rounded,
      'color': AppColors.error,
      'priority': 'HIGH',
    };
  }

  void _showResolveDialog(
    BuildContext context,
    Map<String, dynamic> alert,
    DashboardViewModel viewModel,
  ) {
    final notesController = TextEditingController();
    String actionTaken = 'Dispatched Campus Security';
    final List<String> actions = [
      'Dispatched Campus Security',
      'Sent Ambulance / Medical Help',
      'Sent Maintenance / Replacement Bus',
      'Contacted Student / Driver Directly',
      'False Alarm / Accidentally Clicked',
      'Other Assistance Provided',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.verified_user_rounded,
                    color: Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Resolve Emergency SOS',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Please document the action taken to resolve this panic signal. This will be stored in the emergency logs.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Action Taken',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: actionTaken,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          items:
                              actions
                                  .map(
                                    (act) => DropdownMenuItem(
                                      value: act,
                                      child: Text(
                                        act,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                actionTaken = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Additional Notes (Optional)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'Enter any additional details about the incident response...',
                        hintStyle: const TextStyle(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final noteText = notesController.text.trim();
                    final fullResolutionNotes =
                        '$actionTaken. ${noteText.isNotEmpty ? "Notes: $noteText" : ""}';

                    Navigator.pop(context);

                    await viewModel.resolveEmergencyAlert(
                      alert['id'],
                      notes: fullResolutionNotes,
                      resolvedBy: 'Admin Panel',
                    );

                    if (!mounted) return;
                    setState(() {
                      alert['status'] = 'resolved';
                      alert['resolutionNotes'] = fullResolutionNotes;
                      alert['resolvedBy'] = 'Admin Panel';
                      alert['resolvedAt'] =
                          DateTime.now().millisecondsSinceEpoch;
                    });

                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Alert marked as resolved and logged.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  child: const Text(
                    'Mark Resolved',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDirectoryContact({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryNavy, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.primaryNavy, size: 20),
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppResponsiveUtil.isMobile(context);
    final bool isDesktop = AppResponsiveUtil.isDesktop(context);
    final viewModel = context.watch<DashboardViewModel>();

    // Apply Filter on Alerts
    final List<Map<String, dynamic>> filteredAlerts =
        viewModel.emergencyAlerts.where((alert) {
          if (_filter == 'Active') return alert['status'] == 'active';
          if (_filter == 'Resolved') return alert['status'] == 'resolved';
          return true;
        }).toList();

    // Default select first alert if not selected yet
    if (_selectedAlert == null && filteredAlerts.isNotEmpty) {
      _selectedAlert = filteredAlerts.first;
      if (_selectedAlert!['role'] != null) {
        _firestoreUserData = Map<String, dynamic>.from(_selectedAlert!);
      }
      final userId = _selectedAlert!['userId'];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedAlert != null) {
          final lat = (_selectedAlert!['latitude'] as num).toDouble();
          final lng = (_selectedAlert!['longitude'] as num).toDouble();
          _animatedMapMove(LatLng(lat, lng), 14.5);
          if (userId != null) {
            _fetchUserData(userId);
          }
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterTabs(),
              const SizedBox(height: 20),
              filteredAlerts.isEmpty
                  ? _buildEmptyState()
                  : isDesktop
                  ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: _buildAlertsList(filteredAlerts),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 2,
                        child: _buildDetailPanel(context, viewModel),
                      ),
                    ],
                  )
                  : Column(
                    children: [
                      _buildAlertsList(filteredAlerts),
                      const SizedBox(height: 24),
                      _buildDetailPanel(context, viewModel),
                    ],
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          ['All', 'Active', 'Resolved'].map((tab) {
            final isSelected = _filter == tab;
            return InkWell(
              onTap: () {
                setState(() {
                  _filter = tab;
                  _selectedAlert =
                      null; // Reset selection to trigger auto-select
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.error : AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.error : AppColors.borderLight,
                    width: 1.5,
                  ),
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: AppColors.error.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                          : [],
                ),
                child: Text(
                  tab,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildAlertsList(List<Map<String, dynamic>> alerts) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Alert Logs (${alerts.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final alert = alerts[index];
              final isSelected = _selectedAlert?['id'] == alert['id'];
              final isActive = alert['status'] == 'active';
              final timeStr = alert['timestamp'] != null
                  ? DateFormat('hh:mm a • MMM dd').format(
                      DateTime.fromMillisecondsSinceEpoch(alert['timestamp']))
                  : 'Unknown';

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedAlert = alert;
                    if (alert['role'] != null) {
                      _firestoreUserData = Map<String, dynamic>.from(alert);
                    } else {
                      _firestoreUserData = null; // Clear old data
                    }
                  });
                  final lat = (alert['latitude'] as num).toDouble();
                  final lng = (alert['longitude'] as num).toDouble();
                  _animatedMapMove(LatLng(lat, lng), 15.0);
                  if (alert['userId'] != null) {
                    _fetchUserData(alert['userId']);
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isActive
                            ? AppColors.error.withOpacity(0.08)
                            : AppColors.primaryNavy.withOpacity(0.08))
                        : (isActive
                            ? AppColors.error.withOpacity(0.03)
                            : AppColors.backgroundLight.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? (isActive ? AppColors.error : AppColors.primaryNavy)
                          : (isActive
                              ? AppColors.error.withOpacity(0.2)
                              : AppColors.borderLight),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      (() {
                        final meta = _getAlertMetadata(alert['message'] ?? '');
                        final categoryIcon = meta['icon'] as IconData;
                        final categoryColor = meta['color'] as Color;

                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isActive
                                ? categoryColor.withOpacity(0.1)
                                : AppColors.textSecondary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isActive ? categoryIcon : Icons.check_circle_rounded,
                            color: isActive ? categoryColor : AppColors.textSecondary,
                            size: 20,
                          ),
                        );
                      })(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  alert['userName'] ?? 'Anonymous',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                (() {
                                  final meta = _getAlertMetadata(alert['message'] ?? '');
                                  final categoryColor = meta['color'] as Color;
                                  return isActive
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: categoryColor.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            meta['priority'],
                                            style: TextStyle(
                                              color: categoryColor,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink();
                                })(),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              alert['message'] ?? 'SOS Pressed',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              timeStr,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: (isActive ? AppColors.error : AppColors.textSecondary)
                            .withOpacity(0.5),
                        size: 14,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel(BuildContext context, DashboardViewModel viewModel) {
    if (_selectedAlert == null) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: const Center(
          child: Text('Select an alert from the logs to see details.'),
        ),
      );
    }

    final alert = _selectedAlert!;
    final isActive = alert['status'] == 'active';
    final lat = (alert['latitude'] as num).toDouble();
    final lng = (alert['longitude'] as num).toDouble();
    final timeStr =
        alert['timestamp'] != null
            ? DateFormat(
              'hh:mm:ss a • MMMM dd, yyyy',
            ).format(DateTime.fromMillisecondsSinceEpoch(alert['timestamp']))
            : 'Unknown';

    final meta = _getAlertMetadata(alert['message'] ?? '');
    final categoryIcon = meta['icon'] as IconData;
    final categoryColor = meta['color'] as Color;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Header bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color:
                  isActive
                      ? categoryColor.withOpacity(0.05)
                      : AppColors.primaryNavy.withOpacity(0.05),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage:
                        (_firestoreUserData?['profileImage'] != null &&
                                _firestoreUserData!['profileImage']
                                    .toString()
                                    .isNotEmpty)
                            ? NetworkImage(_firestoreUserData!['profileImage'])
                            : (_firestoreUserData?['profileUrl'] != null &&
                                _firestoreUserData!['profileUrl']
                                    .toString()
                                    .isNotEmpty)
                            ? NetworkImage(_firestoreUserData!['profileUrl'])
                            : null,
                    backgroundColor:
                        isActive
                            ? categoryColor.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                    child:
                        (_firestoreUserData?['profileImage'] == null &&
                                _firestoreUserData?['profileUrl'] == null)
                            ? Icon(
                              isActive
                                  ? categoryIcon
                                  : Icons.check_circle_outline_rounded,
                              color: isActive ? categoryColor : Colors.green,
                            )
                            : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _firestoreUserData?['name'] ??
                                  alert['userName'] ??
                                  'Anonymous',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (_firestoreUserData?['role'] != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _firestoreUserData!['role'] == 'Driver'
                                          ? Colors.purple.withOpacity(0.1)
                                          : Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        _firestoreUserData!['role'] == 'Driver'
                                            ? Colors.purple.withOpacity(0.3)
                                            : Colors.blue.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  _firestoreUserData!['role'].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        _firestoreUserData!['role'] == 'Driver'
                                            ? Colors.purple
                                            : Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          'User ID: ${alert['userId'] ?? 'Unknown'}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    ElevatedButton.icon(
                      onPressed:
                          () => _showResolveDialog(context, alert, viewModel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text(
                        'Resolve Alert',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.done_all, color: Colors.green, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'RESOLVED',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (_isLoadingUserData)
              const LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.error),
                minHeight: 2,
              ),

            // Content Panel: Map on top, details below
            SizedBox(
              height: 200,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(lat, lng),
                      initialZoom: 14.5,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(lat, lng),
                            width: 60,
                            height: 60,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 6,
                                      ),
                                    ],
                                    border: Border.all(
                                      color:
                                          isActive
                                              ? categoryColor
                                              : Colors.grey,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    categoryIcon,
                                    color:
                                        isActive ? categoryColor : Colors.grey,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Map controls overlay
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMapButton(
                          icon: Icons.add,
                          onPressed:
                              () => _mapController.move(
                                _mapController.camera.center,
                                _mapController.camera.zoom + 1,
                              ),
                        ),
                        const SizedBox(height: 8),
                        _buildMapButton(
                          icon: Icons.remove,
                          onPressed:
                              () => _mapController.move(
                                _mapController.camera.center,
                                _mapController.camera.zoom - 1,
                              ),
                        ),
                        const SizedBox(height: 8),
                        _buildMapButton(
                          icon: Icons.my_location,
                          onPressed:
                              () => _animatedMapMove(LatLng(lat, lng), 15.0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Text Info Panel
            Container(
                  padding: const EdgeInsets.all(24),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SOS DETAILS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (_firestoreUserData != null)
                            Text(
                              'PROFILE VERIFIED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color:
                                    _firestoreUserData?['isVerified'] == true
                                        ? Colors.green
                                        : Colors.amber,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.emergency_outlined,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Incident Category',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  alert['message']?.toString().contains(
                                            'Breakdown',
                                          ) ==
                                          true
                                      ? 'Bus Breakdown / Engine failure'
                                      : alert['message']?.toString().contains(
                                            'Accident',
                                          ) ==
                                          true
                                      ? 'Accident / Collision'
                                      : alert['message']?.toString().contains(
                                            'Security',
                                          ) ==
                                          true
                                      ? 'Security / Dispute'
                                      : alert['message']?.toString().contains(
                                            'Medical',
                                          ) ==
                                          true
                                      ? 'Medical Emergency'
                                      : 'General Panic SOS',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: categoryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.error.withOpacity(0.3),
                                ),
                              ),
                              child: const Text(
                                'PRIORITY: HIGH',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Message / Reason',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  alert['message'] ?? 'Emergency help needed.',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),

                      if (_firestoreUserData != null) ...[
                        Text(
                          'SENDER PROFILE DETAILS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildBadgeDetailItem(
                                label: 'Verification Status',
                                badgeColor:
                                    _firestoreUserData?['isVerified'] == true
                                        ? Colors.green
                                        : Colors.amber,
                                badgeText:
                                    _firestoreUserData?['isVerified'] == true
                                        ? 'VERIFIED'
                                        : 'UNVERIFIED',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildBadgeDetailItem(
                                label: 'Account Status',
                                badgeColor:
                                    _firestoreUserData?['isBlocked'] == true
                                        ? Colors.red
                                        : Colors.green,
                                badgeText:
                                    _firestoreUserData?['isBlocked'] == true
                                        ? 'BLOCKED'
                                        : 'ACTIVE',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildBadgeDetailItem(
                                label: 'App Status / Presence',
                                badgeColor:
                                    (_firestoreUserData?['status'] ==
                                                'Online' ||
                                            _firestoreUserData?['status'] ==
                                                'Active')
                                        ? Colors.green
                                        : Colors.grey,
                                badgeText:
                                    (_firestoreUserData?['status'] ?? 'Offline')
                                        .toString()
                                        .toUpperCase(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailCardItem(
                                icon: Icons.person_rounded,
                                label: 'Full Name',
                                value:
                                    _firestoreUserData?['name'] ??
                                    alert['userName'] ??
                                    'Anonymous',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDetailCardItem(
                                icon: Icons.phone_android_rounded,
                                label: 'Phone Number',
                                value:
                                    _firestoreUserData?['phoneNumber'] ??
                                    _firestoreUserData?['phone'] ??
                                    alert['phone'] ??
                                    'N/A',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailCardItem(
                                icon: Icons.email_rounded,
                                label: 'Email Address',
                                value: _firestoreUserData?['email'] ?? 'N/A',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDetailCardItem(
                                icon: Icons.wc_rounded,
                                label: 'Gender',
                                value:
                                    _firestoreUserData?['gender'] ??
                                    _firestoreUserData?['genderPreference'] ??
                                    'N/A',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_firestoreUserData?['role'] == 'Driver') ...[
                          Row(
                            children: [
                              Expanded(
                                child: _buildDetailCardItem(
                                  icon: Icons.directions_bus_rounded,
                                  label: 'Assigned Bus ID',
                                  value:
                                      _firestoreUserData?['assignedBus'] ??
                                      'N/A',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDetailCardItem(
                                  icon: Icons.badge_rounded,
                                  label: 'License Number',
                                  value:
                                      _firestoreUserData?['licenseNumber'] ??
                                      'N/A',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDetailCardItem(
                                  icon: Icons.subtitles_rounded,
                                  label: 'CNIC Number',
                                  value: _firestoreUserData?['cnic'] ?? 'N/A',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDetailCardItem(
                                  icon: Icons.work_history_rounded,
                                  label: 'Experience',
                                  value:
                                      _firestoreUserData?['experience'] != null
                                          ? "${_firestoreUserData?['experience']}"
                                          : 'N/A',
                                ),
                              ),
                            ],
                          ),
                          if (_firestoreUserData?['cnicFrontUrl'] != null ||
                              _firestoreUserData?['cnicBackUrl'] != null ||
                              _firestoreUserData?['licenseImageUrl'] !=
                                  null) ...[
                            const SizedBox(height: 20),
                            Text(
                              'DRIVER DOCUMENTATION',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (_firestoreUserData?['cnicFrontUrl'] !=
                                        null &&
                                    _firestoreUserData!['cnicFrontUrl']
                                        .toString()
                                        .isNotEmpty)
                                  Expanded(
                                    child: _buildDocumentButton(
                                      label: 'View CNIC Front',
                                      imageUrl:
                                          _firestoreUserData!['cnicFrontUrl'],
                                    ),
                                  ),
                                if (_firestoreUserData?['cnicBackUrl'] !=
                                        null &&
                                    _firestoreUserData!['cnicBackUrl']
                                        .toString()
                                        .isNotEmpty) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildDocumentButton(
                                      label: 'View CNIC Back',
                                      imageUrl:
                                          _firestoreUserData!['cnicBackUrl'],
                                    ),
                                  ),
                                ],
                                if (_firestoreUserData?['licenseImageUrl'] !=
                                        null &&
                                    _firestoreUserData!['licenseImageUrl']
                                        .toString()
                                        .isNotEmpty) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildDocumentButton(
                                      label: 'View License Copy',
                                      imageUrl:
                                          _firestoreUserData!['licenseImageUrl'],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: _buildDetailCardItem(
                                  icon: Icons.school_rounded,
                                  label: 'Roll / Student ID',
                                  value:
                                      _firestoreUserData?['studentId'] ??
                                      _firestoreUserData?['rollNo'] ??
                                      'N/A',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDetailCardItem(
                                  icon: Icons.app_registration_rounded,
                                  label: 'Registration Number',
                                  value: _firestoreUserData?['regNo'] ?? 'N/A',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDetailCardItem(
                                  icon: Icons.account_balance_rounded,
                                  label: 'Department',
                                  value:
                                      _firestoreUserData?['department'] ??
                                      'N/A',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDetailCardItem(
                                  icon: Icons.class_rounded,
                                  label: 'Semester',
                                  value:
                                      _firestoreUserData?['semester'] ?? 'N/A',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],

                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Timestamp',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  timeStr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.location_on_rounded,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Coordinates',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                                SelectableText(
                                  '$lat, $lng',
                                  style: GoogleFonts.firaCode(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(
                                  text:
                                      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Google Maps link copied to clipboard.',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.map_outlined, size: 14),
                            label: const Text(
                              'Open in Google Maps',
                              style: TextStyle(fontSize: 11),
                            ),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Resolution Notes Row (if resolved)
                      if (!isActive) ...[
                        const Divider(height: 32),
                        Text(
                          'RESOLUTION DETAILS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.assignment_turned_in_rounded,
                              color: Colors.green,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Action & Log Notes',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    alert['resolutionNotes'] ??
                                        'Marked as resolved by Admin',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Resolved By: ${alert['resolvedBy'] ?? 'Admin Panel'}',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream:
                              FirebaseFirestore.instance
                                  .collection('sos_reviews')
                                  .where('alertId', isEqualTo: alert['id'])
                                  .snapshots(),
                          builder: (context, reviewSnapshot) {
                            if (!reviewSnapshot.hasData ||
                                reviewSnapshot.data!.docs.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            final reviewDoc =
                                reviewSnapshot.data!.docs.first.data()
                                    as Map<String, dynamic>;
                            final rating = reviewDoc['rating'] as int? ?? 5;
                            final comment =
                                reviewDoc['review'] as String? ??
                                'No comment provided';

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(height: 32),
                                Text(
                                  'USER FEEDBACK & SERVICE REVIEW',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.green.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        color: Colors.amber,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  'Service Rating: ',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.textDark,
                                                  ),
                                                ),
                                                Row(
                                                  children: List.generate(5, (
                                                    starIdx,
                                                  ) {
                                                    return Icon(
                                                      starIdx < rating
                                                          ? Icons.star_rounded
                                                          : Icons
                                                              .star_border_rounded,
                                                      color: Colors.amber,
                                                      size: 20,
                                                    );
                                                  }),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'User Review:',
                                              style: TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 11,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '"$comment"',
                                              style: TextStyle(
                                                fontStyle: FontStyle.italic,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                color: AppColors.textDark,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],

                      // Emergency Dispatch Directory Section
                      const Divider(height: 32),
                      Text(
                        'EMERGENCY DISPATCH DIRECTORY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDirectoryContact(
                              title: 'Campus Security',
                              subtitle: 'Ext: 115 / Copy Link',
                              icon: Icons.shield_outlined,
                              onTap: () {
                                Clipboard.setData(
                                  const ClipboardData(text: '051-111-222-333'),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Campus Security contact copied.',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDirectoryContact(
                              title: 'Rescue Ambulance',
                              subtitle: 'Dial 1122',
                              icon: Icons.medical_services_outlined,
                              onTap: () {
                                Clipboard.setData(
                                  const ClipboardData(text: '1122'),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Rescue 1122 contact copied.',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDirectoryContact(
                              title: 'Emergency Police',
                              subtitle: 'Dial 15',
                              icon: Icons.local_police_outlined,
                              onTap: () {
                                Clipboard.setData(
                                  const ClipboardData(text: '15'),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Police 15 contact copied.'),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderLight, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.015),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_rounded,
                size: 60,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'System Safe!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No active emergency alerts recorded.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCardItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primaryNavy, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  value,
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeDetailItem({
    required String label,
    required Color badgeColor,
    required String badgeText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentButton({
    required String label,
    required String imageUrl,
  }) {
    return ElevatedButton.icon(
      onPressed: () => _showImagePreviewDialog(context, label, imageUrl),
      icon: const Icon(Icons.image_rounded, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        foregroundColor: AppColors.primaryNavy,
        backgroundColor: AppColors.primaryNavy.withOpacity(0.05),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  void _showImagePreviewDialog(
    BuildContext context,
    String title,
    String imageUrl,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Container(
              constraints: const BoxConstraints(maxHeight: 400, maxWidth: 500),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder:
                        (context, error, stackTrace) => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text(
                              'Failed to load image. Invalid or expired URL.',
                            ),
                          ),
                        ),
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}