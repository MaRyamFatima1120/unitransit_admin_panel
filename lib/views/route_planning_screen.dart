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
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Route & Map Management',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        Text(
          'Configure hubs, define official routes, and upload map polylines.',
          style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primaryNavy,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppColors.primaryNavy,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
        tabs: const [
          Tab(text: '1. Hubs Manager', icon: Icon(Icons.location_on_rounded)),
          Tab(text: '2. Route Definition', icon: Icon(Icons.route_rounded)),
          Tab(text: '3. Polyline Uploader', icon: Icon(Icons.map_rounded)),
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
    final isMobile = AppResponsiveUtil.isMobile(context);

    Widget content = Flex(
      direction: isMobile ? Axis.vertical : Axis.horizontal,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Form
        SizedBox(
          width: isMobile ? double.infinity : 400,
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  viewModel.editingHubName != null ? 'Edit Campus/Stop' : 'Add New Campus/Stop', 
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 20),
                _buildTextField(viewModel.nameController, 'Campus or Stop Name', Icons.business_rounded),
                const SizedBox(height: 16),
                _buildTextField(viewModel.latController, 'Latitude', Icons.location_on_outlined, isNumber: true),
                const SizedBox(height: 16),
                _buildTextField(viewModel.lngController, 'Longitude', Icons.location_on_outlined, isNumber: true),
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (viewModel.editingHubName != null)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: OutlinedButton(
                            onPressed: () => viewModel.setEditingHub(null),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                      ),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: viewModel.isHubSaving ? null : () async {
                          await viewModel.saveHub();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Operation Successful!'), backgroundColor: Colors.green),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: viewModel.editingHubName != null ? Colors.blue[800] : AppColors.primaryNavy,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: viewModel.isHubSaving 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              viewModel.editingHubName != null ? 'Update Stop' : 'Save Hub', 
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (!isMobile) const SizedBox(width: 24),
        if (isMobile) const SizedBox(height: 24),
        // List
        Expanded(
          flex: isMobile ? 0 : 2,
          child: Container(
            constraints: BoxConstraints(minHeight: isMobile ? 400 : 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: isMobile ? MainAxisSize.min : MainAxisSize.max,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('Existing Campuses/Stops', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 1),
                SizedBox(
                  height: 500,
                  child: StreamBuilder<List<HubModel>>(
                    stream: firebaseService.getHubs(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final hubs = snapshot.data ?? [];
                      if (hubs.isEmpty) return const Center(child: Text('No hubs found.'));

                      return ListView.separated(
                        shrinkWrap: true,
                        itemCount: hubs.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final hub = hubs[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryNavy.withOpacity(0.1),
                              child: const Icon(Icons.location_on, color: AppColors.primaryNavy, size: 20),
                            ),
                            title: Text(hub.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                            subtitle: Text('Lat: ${hub.latitude}, Lng: ${hub.longitude}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                  onPressed: () => viewModel.setEditingHub(hub),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () => viewModel.deleteHub(hub.name),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: content,
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryNavy),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
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
    final isMobile = AppResponsiveUtil.isMobile(context);

    return StreamBuilder<List<HubModel>>(
      stream: firebaseService.getHubs(),
      builder: (context, hubSnapshot) {
        final hubs = hubSnapshot.data ?? [];
        
        Widget content = Flex(
          direction: isMobile ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: isMobile ? double.infinity : 400,
              child: Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        viewModel.editingRouteId != null ? 'Edit Bus Route' : 'Define New Bus Route', 
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: viewModel.routeNameController,
                        decoration: InputDecoration(
                          labelText: 'Bus Route Name',
                          prefixIcon: const Icon(Icons.edit_road_rounded, color: AppColors.primaryNavy),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: viewModel.fromHub,
                        decoration: InputDecoration(
                          labelText: 'Starting Point',
                          prefixIcon: const Icon(Icons.start_rounded, color: Colors.green),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: hubs.map((h) => DropdownMenuItem<String>(value: h.name, child: Text(h.name))).toList(),
                        onChanged: (v) => viewModel.setFromHub(v),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: viewModel.toHub,
                        decoration: InputDecoration(
                          labelText: 'Destination Point',
                          prefixIcon: const Icon(Icons.location_on_rounded, color: Colors.red),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: hubs.map((h) => DropdownMenuItem<String>(value: h.name, child: Text(h.name))).toList(),
                        onChanged: (v) => viewModel.setToHub(v),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: viewModel.selectedGender,
                        decoration: InputDecoration(
                          labelText: 'Service Type (Gender)',
                          prefixIcon: Icon(
                            viewModel.selectedGender == 'Girls' 
                                ? Icons.female_rounded 
                                : viewModel.selectedGender == 'Boys' 
                                    ? Icons.male_rounded 
                                    : Icons.people_rounded, 
                            color: viewModel.selectedGender == 'Girls' 
                                ? Colors.pinkAccent 
                                : viewModel.selectedGender == 'Boys' 
                                    ? Colors.blueAccent 
                                    : AppColors.primaryNavy,
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: ['Combined', 'Girls', 'Boys'].map((g) => DropdownMenuItem<String>(
                          value: g, 
                          child: Text(g)
                        )).toList(),
                        onChanged: (v) => viewModel.setSelectedGender(v),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          if (viewModel.editingRouteId != null)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: OutlinedButton(
                                  onPressed: () => viewModel.setEditingRoute(null),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),
                            ),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: viewModel.isRouteSaving ? null : () async {
                                await viewModel.saveRoute();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Route Saved!'), backgroundColor: Colors.green),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: viewModel.editingRouteId != null ? Colors.blue[800] : AppColors.primaryNavy,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: viewModel.isRouteSaving 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(
                                    viewModel.editingRouteId != null ? 'Update Route' : 'Save Route', 
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (!isMobile) const SizedBox(width: 24),
            if (isMobile) const SizedBox(height: 24),
            Expanded(
              flex: isMobile ? 0 : 3,
              child: Card(
                elevation: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: isMobile ? MainAxisSize.min : MainAxisSize.max,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text('Current Routes', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const Divider(height: 1),
                    SizedBox(
                      height: 500,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('schedules').snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final docs = snapshot.data?.docs ?? [];
                          return ListView.separated(
                            shrinkWrap: true,
                            itemCount: docs.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final data = docs[index].data() as Map<String, dynamic>;
                              final route = BusSchedule.fromMap(docs[index].id, data);
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: route.type == 'Girls' 
                                      ? Colors.pinkAccent.withOpacity(0.1) 
                                      : route.type == 'Boys' 
                                          ? Colors.blueAccent.withOpacity(0.1) 
                                          : AppColors.primaryNavy.withOpacity(0.1),
                                  child: Icon(
                                    route.type == 'Girls' 
                                        ? Icons.female_rounded 
                                        : route.type == 'Boys' 
                                            ? Icons.male_rounded 
                                            : Icons.people_rounded,
                                    color: route.type == 'Girls' 
                                        ? Colors.pinkAccent 
                                        : route.type == 'Boys' 
                                            ? Colors.blueAccent 
                                            : AppColors.primaryNavy,
                                    size: 20,
                                  ),
                                ),
                                title: Text(route.route, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                subtitle: Row(
                                  children: [
                                    Text('${route.from} ➔ ${route.to}', style: const TextStyle(fontSize: 12)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        route.type.toUpperCase(),
                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                      onPressed: () => viewModel.setEditingRoute(route),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                                      onPressed: () => viewModel.deleteRoute(route.id, route.route),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: content,
        );
      },
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
    final isMobile = AppResponsiveUtil.isMobile(context);

    Widget content = Flex(
      direction: isMobile ? Axis.vertical : Axis.horizontal,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Side: Upload Form
        SizedBox(
          width: isMobile ? double.infinity : 400,
          child: Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Upload Map Path', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Paste JSON array of coordinates.',
                    style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('schedules').snapshots(),
                    builder: (context, snapshot) {
                      final routes = snapshot.data?.docs ?? [];
                      return DropdownButtonFormField<String>(
                        value: viewModel.selectedRouteForPolyline,
                        decoration: InputDecoration(
                          labelText: 'Select Route',
                          prefixIcon: const Icon(Icons.route_outlined, color: AppColors.primaryNavy),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: routes.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name = data['route'] ?? 'Unknown';
                          return DropdownMenuItem<String>(value: name, child: Text(name));
                        }).toList(),
                        onChanged: (v) => viewModel.setSelectedRouteForPolyline(v),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: TextFormField(
                      controller: viewModel.jsonController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: GoogleFonts.firaCode(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: '[{"lat": ...}]',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: viewModel.isPolylineSaving ? null : () async {
                        await viewModel.uploadPolyline();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Polyline Uploaded!'), backgroundColor: Colors.green),
                          );
                        }
                      },
                      icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 20),
                      label: const Text('Save Path', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isMobile) const SizedBox(width: 24),
        if (isMobile) const SizedBox(height: 24),
        // Right Side: Status List
        Expanded(
          flex: isMobile ? 0 : 3,
          child: Card(
            elevation: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: isMobile ? MainAxisSize.min : MainAxisSize.max,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('Map Path Status', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 1),
                SizedBox(
                  height: 500,
                  child: StreamBuilder<Map<String, dynamic>>(
                    stream: firebaseService.getPolylinesStatus(),
                    builder: (context, polylineSnapshot) {
                      final polylines = polylineSnapshot.data ?? {};
                      
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('schedules').snapshots(),
                        builder: (context, routeSnapshot) {
                          if (routeSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final routes = routeSnapshot.data?.docs ?? [];
                          if (routes.isEmpty) return const Center(child: Text('No routes defined.'));

                          return ListView.separated(
                            shrinkWrap: true,
                            itemCount: routes.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final data = routes[index].data() as Map<String, dynamic>;
                              final routeName = data['route'] ?? 'Unknown';
                              final hasPolyline = polylines.containsKey(routeName);

                              return ListTile(
                                leading: Icon(
                                  hasPolyline ? Icons.check_circle_rounded : Icons.pending_rounded,
                                  color: hasPolyline ? Colors.green : Colors.orange,
                                ),
                                title: Text(routeName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                subtitle: Text(hasPolyline ? 'Path Uploaded' : 'No Path Found'),
                                trailing: hasPolyline 
                                  ? const Icon(Icons.map_outlined, color: Colors.blue)
                                  : const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: content,
    );
  }
}
