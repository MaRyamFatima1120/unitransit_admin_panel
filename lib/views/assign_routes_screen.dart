import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/core/services/firebase_service.dart';
import 'package:unitransit_admin/models/driver_model.dart';
import 'package:unitransit_admin/models/bus_schedule_model.dart';
import 'package:unitransit_admin/core/utils/responsive_util.dart';
import 'package:unitransit_admin/view_models/dashboard_view_model.dart';

class AssignRoutesScreen extends StatefulWidget {
  const AssignRoutesScreen({super.key});

  @override
  State<AssignRoutesScreen> createState() => _AssignRoutesScreenState();
}

class _AssignRoutesScreenState extends State<AssignRoutesScreen> {
  BusSchedule? _selectedSchedule;
  String? _selectedDriverId;
  String? _selectedDriverName;
  final TextEditingController _conductorController = TextEditingController();
  bool _isSaving = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _conductorController.dispose();
    super.dispose();
  }

  void _selectSchedule(BusSchedule schedule) {
    setState(() {
      _selectedSchedule = schedule;
      _selectedDriverId = schedule.assignedDriverId;
      _selectedDriverName = schedule.assignedDriverName;
      _conductorController.text = schedule.assignedConductorName ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppResponsiveUtil.isMobile(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            child: _buildHeader(context),
          ),
          Expanded(
            child: isMobile
                ? (_selectedSchedule != null ? _buildAssignmentPanel(context) : _buildSchedulesList(context))
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _buildSchedulesList(context)),
                      Container(width: 1, color: AppColors.borderLight),
                      SizedBox(width: 420, child: _selectedSchedule == null ? _buildPlaceholder() : _buildAssignmentPanel(context)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (AppResponsiveUtil.isMobile(context))
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => context.read<DashboardViewModel>().setSelectedIndex(0),
                icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
              ),
            if (AppResponsiveUtil.isMobile(context)) const SizedBox(width: 12),
            Flexible(
              child: Text('Assign Routes & Crews',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold, color: AppColors.textDark, letterSpacing: -0.5,
                  fontSize: AppResponsiveUtil.isMobile(context) ? 24 : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Select a schedule to assign driver, conductor, bus, time, and route.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildSchedulesList(BuildContext context) {
    final firebaseService = context.read<FirebaseService>();
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase().trim()),
              decoration: InputDecoration(
                hintText: 'Search by route, bus, driver...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.backgroundLight.withOpacity(0.5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderLight)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderLight)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryNavy)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppColors.primaryNavy.withOpacity(0.03),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('ROUTE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
                Expanded(flex: 2, child: Text('BUS / TIME', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
                Expanded(flex: 2, child: Text('DRIVER', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
                Expanded(flex: 2, child: Text('CONDUCTOR', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
                SizedBox(width: 40, child: Text('STATUS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
              ],
            ),
          ),
          const Divider(height: 1),
          // Schedules list
          Expanded(
            child: StreamBuilder<List<BusSchedule>>(
              stream: firebaseService.getBusSchedules(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primaryNavy));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No schedules found. Create schedules first.', style: TextStyle(color: Colors.grey)));
                }
                var schedules = snapshot.data!;
                if (_searchQuery.isNotEmpty) {
                  schedules = schedules.where((s) =>
                    s.route.toLowerCase().contains(_searchQuery) ||
                    (s.busNumber ?? '').toLowerCase().contains(_searchQuery) ||
                    (s.assignedDriverName ?? '').toLowerCase().contains(_searchQuery) ||
                    (s.assignedConductorName ?? '').toLowerCase().contains(_searchQuery)
                  ).toList();
                }
                return ListView.separated(
                  itemCount: schedules.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (context, idx) => _buildScheduleRow(schedules[idx]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(BusSchedule schedule) {
    final isSelected = _selectedSchedule?.id == schedule.id;
    final hasDriver = schedule.assignedDriverId != null && schedule.assignedDriverId!.isNotEmpty;
    final hasConductor = schedule.assignedConductorName != null && schedule.assignedConductorName!.isNotEmpty;
    final isFullyAssigned = hasDriver && hasConductor;

    return InkWell(
      onTap: () => _selectSchedule(schedule),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        color: isSelected ? AppColors.primaryNavy.withOpacity(0.04) : Colors.transparent,
        child: Row(
          children: [
            // Route
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(schedule.route, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(schedule.type, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                ],
              ),
            ),
            // Bus / Time
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.directions_bus, size: 12, color: AppColors.primaryNavy),
                    const SizedBox(width: 4),
                    Text(schedule.busNumber ?? 'TBA', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.access_time, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(schedule.departureTime ?? 'Live', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ]),
                ],
              ),
            ),
            // Driver
            Expanded(
              flex: 2,
              child: Text(
                hasDriver ? schedule.assignedDriverName! : '— Not Assigned',
                style: TextStyle(fontSize: 12, fontWeight: hasDriver ? FontWeight.w600 : FontWeight.normal, color: hasDriver ? AppColors.textDark : Colors.red.shade400),
              ),
            ),
            // Conductor
            Expanded(
              flex: 2,
              child: Text(
                hasConductor ? schedule.assignedConductorName! : '— Not Assigned',
                style: TextStyle(fontSize: 12, fontWeight: hasConductor ? FontWeight.w600 : FontWeight.normal, color: hasConductor ? AppColors.textDark : Colors.red.shade400),
              ),
            ),
            // Status
            SizedBox(
              width: 40,
              child: Icon(
                isFullyAssigned ? Icons.check_circle : Icons.warning_amber_rounded,
                size: 18,
                color: isFullyAssigned ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.primaryNavy.withOpacity(0.05), shape: BoxShape.circle),
              child: const Icon(Icons.assignment_ind_rounded, size: 48, color: AppColors.primaryNavy),
            ),
            const SizedBox(height: 16),
            const Text('No Schedule Selected', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 8),
            const Text('Select a schedule from the left to assign driver, conductor, and crew details.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentPanel(BuildContext context) {
    final schedule = _selectedSchedule!;
    final firebaseService = context.read<FirebaseService>();
    final isMobile = AppResponsiveUtil.isMobile(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _selectedSchedule = null)),
          // Schedule Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primaryNavy, AppColors.primaryNavy.withOpacity(0.85)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SCHEDULE DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white70, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                Text(schedule.route, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Row(children: [
                  _infoChip(Icons.directions_bus, 'Bus ${schedule.busNumber ?? "TBA"}'),
                  const SizedBox(width: 8),
                  _infoChip(Icons.access_time, schedule.departureTime ?? 'Live'),
                ]),
                const SizedBox(height: 8),
                _infoChip(Icons.category, schedule.type),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Assign Driver Section
          const Text('ASSIGN DRIVER', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          StreamBuilder<List<DriverModel>>(
            stream: firebaseService.getDrivers(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final drivers = snapshot.data!.where((d) => !d.isBlocked).toList();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderLight),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('Select a driver...'),
                    value: _selectedDriverId,
                    items: [
                      const DropdownMenuItem<String>(value: '', child: Text('— Unassign Driver —', style: TextStyle(color: Colors.red))),
                      ...drivers.map((d) => DropdownMenuItem<String>(
                        value: d.id,
                        child: Row(children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.primaryNavy.withOpacity(0.1),
                            backgroundImage: d.profileUrl != null ? NetworkImage(d.profileUrl!) : null,
                            child: d.profileUrl == null ? Text(d.name.isNotEmpty ? d.name[0] : 'D', style: const TextStyle(fontSize: 11, color: AppColors.primaryNavy)) : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(d.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              Text(d.phoneNumber, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            ],
                          )),
                        ]),
                      )),
                    ],
                    onChanged: (val) {
                      setState(() {
                        if (val == null || val.isEmpty) {
                          _selectedDriverId = null;
                          _selectedDriverName = null;
                        } else {
                          _selectedDriverId = val;
                          _selectedDriverName = drivers.firstWhere((d) => d.id == val).name;
                        }
                      });
                    },
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          // Conductor
          const Text('ASSIGN CONDUCTOR', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          TextField(
            controller: _conductorController,
            decoration: InputDecoration(
              hintText: 'Enter conductor name...',
              prefixIcon: const Icon(Icons.person_pin_outlined, color: AppColors.primaryNavy),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderLight)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryNavy)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),

          const SizedBox(height: 24),
          // Summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ASSIGNMENT SUMMARY', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                _summaryRow(Icons.map_outlined, 'Route', schedule.route),
                _summaryRow(Icons.directions_bus, 'Bus', schedule.busNumber ?? 'TBA'),
                _summaryRow(Icons.access_time, 'Departure', schedule.departureTime ?? 'Live'),
                _summaryRow(Icons.drive_eta, 'Driver', _selectedDriverName ?? 'Not Assigned'),
                _summaryRow(Icons.person_pin, 'Conductor', _conductorController.text.isNotEmpty ? _conductorController.text : 'Not Assigned'),
              ],
            ),
          ),

          const SizedBox(height: 24),
          // Save buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _selectedSchedule = null),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAssignment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Assignment'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, size: 16, color: AppColors.primaryNavy),
        const SizedBox(width: 10),
        Text('$label: ', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  Future<void> _saveAssignment() async {
    if (_selectedSchedule == null) return;
    setState(() => _isSaving = true);

    try {
      final firebaseService = context.read<FirebaseService>();
      final db = FirebaseFirestore.instance;
      final schedule = _selectedSchedule!;

      // 1. Update schedule document with driver + conductor
      await db.collection('schedules').doc(schedule.id).update({
        'assignedDriverId': _selectedDriverId ?? '',
        'assignedDriverName': _selectedDriverName ?? '',
        'assignedConductorName': _conductorController.text.trim(),
      });

      // 2. Update driver's assignedRoutes list (add this schedule id)
      if (_selectedDriverId != null && _selectedDriverId!.isNotEmpty) {
        final driverDoc = await db.collection('drivers').doc(_selectedDriverId).get();
        if (driverDoc.exists) {
          final currentRoutes = List<String>.from(driverDoc.data()?['assignedRoutes'] ?? []);
          if (!currentRoutes.contains(schedule.id)) {
            currentRoutes.add(schedule.id);
          }
          // Also compile bus numbers from all assigned schedules
          final allScheduleIds = currentRoutes;
          final busNumbers = <String>{};
          for (final sid in allScheduleIds) {
            final sDoc = await db.collection('schedules').doc(sid).get();
            if (sDoc.exists) {
              final bn = sDoc.data()?['busNumber'] ?? '';
              if (bn.toString().isNotEmpty && bn != 'TBA') busNumbers.add(bn);
            }
          }
          await db.collection('drivers').doc(_selectedDriverId).update({
            'assignedRoutes': currentRoutes,
            'assignedBus': busNumbers.join(', '),
          });
        }
      }

      // 3. If previous driver was different, remove this schedule from old driver
      if (schedule.assignedDriverId != null &&
          schedule.assignedDriverId!.isNotEmpty &&
          schedule.assignedDriverId != _selectedDriverId) {
        final oldDriverDoc = await db.collection('drivers').doc(schedule.assignedDriverId).get();
        if (oldDriverDoc.exists) {
          final oldRoutes = List<String>.from(oldDriverDoc.data()?['assignedRoutes'] ?? []);
          oldRoutes.remove(schedule.id);
          await db.collection('drivers').doc(schedule.assignedDriverId).update({
            'assignedRoutes': oldRoutes,
          });
        }
      }

      // Update local state
      setState(() {
        _selectedSchedule = schedule.copyWith(
          assignedDriverId: _selectedDriverId ?? '',
          assignedDriverName: _selectedDriverName ?? '',
          assignedConductorName: _conductorController.text.trim(),
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text('Assignment saved for ${schedule.route}!'),
          ]),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }
}
