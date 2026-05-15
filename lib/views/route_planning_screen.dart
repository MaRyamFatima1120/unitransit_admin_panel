import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/core/services/firebase_service.dart';
import 'package:unitransit_admin/models/bus_schedule_model.dart';
import 'package:unitransit_admin/models/hub_model.dart';
import 'package:unitransit_admin/core/utils/responsive_util.dart';
import 'package:unitransit_admin/view_models/route_planning_view_model.dart';

class RoutePlanningScreen extends StatefulWidget {
  const RoutePlanningScreen({super.key});

  @override
  State<RoutePlanningScreen> createState() => _RoutePlanningScreenState();
}

class _RoutePlanningScreenState extends State<RoutePlanningScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppResponsiveUtil.isMobile(context);
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildTabBar(),
          const SizedBox(height: 24),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                HubsManagerSection(),
                RouteDefinitionSection(),
                PolylineUploaderSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isMobile = AppResponsiveUtil.isMobile(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryNavy.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.map_rounded, color: AppColors.primaryNavy, size: isMobile ? 20 : 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Route & Map',
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 20 : 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                  letterSpacing: -0.5,
                ),
              ),
              if (!isMobile)
                Text(
                  'Configure campuses, define routes, and manage map paths.',
                  style: GoogleFonts.poppins(color: AppColors.textSecondary.withValues(alpha: 0.7), fontSize: 13),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        indicator: BoxDecoration(
          color: AppColors.primaryNavy,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: const [
          Tab(text: 'Hubs'),
          Tab(text: 'Routes'),
          Tab(text: 'Paths'),
        ],
      ),
    );
  }
}

// --- Section A: Hubs Manager ---
class HubsManagerSection extends StatelessWidget {
  const HubsManagerSection({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RoutePlanningViewModel>();
    final firebaseService = context.read<FirebaseService>();
    final isDesktop = AppResponsiveUtil.isDesktop(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Flex(
          direction: isDesktop ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: isDesktop ? 380 : double.infinity,
              child: _buildFormPanel(viewModel),
            ),
            if (isDesktop) const SizedBox(width: 24),
            if (!isDesktop) const SizedBox(height: 24),
            if (isDesktop)
              Expanded(child: _buildListPanel(firebaseService, viewModel))
            else
              _buildListPanel(firebaseService, viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildFormPanel(RoutePlanningViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            viewModel.editingHubName != null ? 'Edit Hub' : 'Create Hub',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 24),
          _buildFieldLabel('Location Name'),
          _buildModernField(viewModel.nameController, 'e.g. Baghdad Campus', Icons.business_rounded),
          const SizedBox(height: 16),
          _buildFieldLabel('Latitude'),
          _buildModernField(viewModel.latController, 'e.g. 29.37', Icons.gps_fixed_rounded, isNumber: true),
          const SizedBox(height: 16),
          _buildFieldLabel('Longitude'),
          _buildModernField(viewModel.lngController, 'e.g. 71.72', Icons.gps_fixed_rounded, isNumber: true),
          const SizedBox(height: 32),
          Row(
            children: [
              if (viewModel.editingHubName != null)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: OutlinedButton(
                      onPressed: () => viewModel.setEditingHub(null),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: viewModel.isHubSaving ? null : () => viewModel.saveHub(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: viewModel.isHubSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(viewModel.editingHubName != null ? 'Update' : 'Save Hub', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListPanel(FirebaseService firebaseService, RoutePlanningViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('All Hubs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          StreamBuilder<List<HubModel>>(
            stream: firebaseService.getHubs(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
              final hubs = snapshot.data ?? [];
              if (hubs.isEmpty) return _buildEmptyState('No hubs defined.');

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: hubs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final hub = hubs[index];
                  return _buildHubCard(context, hub, viewModel);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHubCard(BuildContext context, HubModel hub, RoutePlanningViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_rounded, color: Colors.green.withValues(alpha: 0.7), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hub.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('${hub.latitude}, ${hub.longitude}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          _buildActionMenu(context, 
            onEdit: () => viewModel.setEditingHub(hub),
            onDelete: () => viewModel.deleteHub(hub.name),
            deleteMsg: 'Delete this hub?'
          ),
        ],
      ),
    );
  }
}

// --- Section B: Route Definition ---
class RouteDefinitionSection extends StatelessWidget {
  const RouteDefinitionSection({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RoutePlanningViewModel>();
    final firebaseService = context.read<FirebaseService>();
    final isDesktop = AppResponsiveUtil.isDesktop(context);

    return StreamBuilder<List<HubModel>>(
      stream: firebaseService.getHubs(),
      builder: (context, hubSnapshot) {
        final hubs = hubSnapshot.data ?? [];
        
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Flex(
              direction: isDesktop ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: isDesktop ? 380 : double.infinity,
                  child: _buildRouteForm(viewModel, hubs),
                ),
                if (isDesktop) const SizedBox(width: 24),
                if (!isDesktop) const SizedBox(height: 24),
                if (isDesktop)
                  Expanded(child: _buildRouteList(viewModel))
                else
                  _buildRouteList(viewModel),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRouteForm(RoutePlanningViewModel viewModel, List<HubModel> hubs) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Route Builder', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildFieldLabel('Route Name'),
          _buildModernField(viewModel.routeNameController, 'e.g. Route A', Icons.edit_road_rounded),
          const SizedBox(height: 16),
          _buildFieldLabel('From'),
          _buildModernDropdown(viewModel.fromHub, hubs.map((h) => h.name).toList(), 'Start Hub', Icons.start_rounded, Colors.green, (v) => viewModel.setFromHub(v)),
          const SizedBox(height: 16),
          _buildFieldLabel('To'),
          _buildModernDropdown(viewModel.toHub, hubs.map((h) => h.name).toList(), 'Destination Hub', Icons.location_on_rounded, Colors.red, (v) => viewModel.setToHub(v)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: viewModel.isRouteSaving ? null : () => viewModel.saveRoute(),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: viewModel.isRouteSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(viewModel.editingRouteId != null ? 'Update Route' : 'Create Route', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteList(RoutePlanningViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Active Routes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('schedules').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) return _buildEmptyState('No routes defined.');

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final route = BusSchedule.fromMap(docs[index].id, data);
                  return _buildRouteCard(context, route, viewModel);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(BuildContext context, BusSchedule route, RoutePlanningViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(route.route, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(route.from, style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                    const Icon(Icons.arrow_right_alt, size: 16, color: AppColors.textSecondary),
                    Text(route.to, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          _buildActionMenu(context, 
            onEdit: () => viewModel.setEditingRoute(route),
            onDelete: () => viewModel.deleteRoute(route.id, route.route),
            deleteMsg: 'Delete this route?'
          ),
        ],
      ),
    );
  }
}

// --- Section C: Polyline Uploader ---
class PolylineUploaderSection extends StatelessWidget {
  const PolylineUploaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RoutePlanningViewModel>();
    final firebaseService = context.read<FirebaseService>();
    final isDesktop = AppResponsiveUtil.isDesktop(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Flex(
          direction: isDesktop ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: isDesktop ? 380 : double.infinity,
              child: _buildPolylineForm(viewModel),
            ),
            if (isDesktop) const SizedBox(width: 24),
            if (!isDesktop) const SizedBox(height: 24),
            if (isDesktop)
              Expanded(child: _buildPolylineStatus(firebaseService))
            else
              _buildPolylineStatus(firebaseService),
          ],
        ),
      ),
    );
  }

  Widget _buildPolylineForm(RoutePlanningViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Path Sync', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildFieldLabel('Select Route'),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('schedules').snapshots(),
            builder: (context, snapshot) {
              final routes = snapshot.data?.docs ?? [];
              return _buildModernDropdown(
                viewModel.selectedRouteForPolyline, 
                routes.map((d) => (d.data() as Map)['route'].toString()).toList(), 
                'Route', Icons.alt_route_rounded, AppColors.primaryNavy, (v) => viewModel.setSelectedRouteForPolyline(v)
              );
            },
          ),
          const SizedBox(height: 16),
          _buildFieldLabel('Coordinates (JSON)'),
          Container(
            height: 120,
            decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: viewModel.jsonController,
              maxLines: null,
              expands: true,
              style: GoogleFonts.firaCode(fontSize: 10),
              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(12)),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: viewModel.isPolylineSaving ? null : () => viewModel.uploadPolyline(),
              icon: const Icon(Icons.sync_rounded),
              label: const Text('Sync Path', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolylineStatus(FirebaseService firebaseService) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          StreamBuilder<Map<String, dynamic>>(
            stream: firebaseService.getPolylinesStatus(),
            builder: (context, polylineSnapshot) {
              final polylines = polylineSnapshot.data ?? {};
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('schedules').snapshots(),
                builder: (context, routeSnapshot) {
                  final routes = routeSnapshot.data?.docs ?? [];
                  if (routes.isEmpty) return _buildEmptyState('No routes.');

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: routes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final data = routes[index].data() as Map<String, dynamic>;
                      final routeName = data['route'] ?? 'Unknown';
                      final hasPolyline = polylines.containsKey(routeName);

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: hasPolyline ? Colors.green.withValues(alpha: 0.05) : Colors.orange.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(hasPolyline ? Icons.check_circle : Icons.error_outline, color: hasPolyline ? Colors.green : Colors.orange, size: 18),
                            const SizedBox(width: 12),
                            Expanded(child: Text(routeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                            Text(hasPolyline ? 'Live' : 'Missing', style: TextStyle(color: hasPolyline ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// --- SHARED HELPER WIDGETS ---

Widget _buildFieldLabel(String label) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6.0),
    child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
  );
}

Widget _buildModernField(TextEditingController controller, String hint, IconData icon, {bool isNumber = false}) {
  return TextField(
    controller: controller,
    keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
    style: const TextStyle(fontSize: 13),
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primaryNavy, size: 18),
      filled: true,
      fillColor: AppColors.backgroundLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
  );
}

Widget _buildModernDropdown(String? value, List<String> items, String hint, IconData icon, Color iconColor, Function(String?) onChanged) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(10)),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        hint: Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 10),
            Text(hint, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 18),
        items: items.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: onChanged,
      ),
    ),
  );
}

Widget _buildActionMenu(BuildContext context, {required VoidCallback onEdit, required VoidCallback onDelete, required String deleteMsg}) {
  return PopupMenuButton<String>(
    onSelected: (v) {
      if (v == 'edit') onEdit();
      if (v == 'delete') {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm'),
            content: Text(deleteMsg),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
              TextButton(onPressed: () { onDelete(); Navigator.pop(context); }, child: const Text('Yes')),
            ],
          ),
        );
      }
    },
    icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
    itemBuilder: (context) => [
      const PopupMenuItem(value: 'edit', child: Text('Edit')),
      const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
    ],
  );
}

Widget _buildEmptyState(String msg) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(msg, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
    ),
  );
}
