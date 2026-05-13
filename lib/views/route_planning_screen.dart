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

class RoutePlanningScreen extends StatefulWidget {
  const RoutePlanningScreen({super.key});

  @override
  State<RoutePlanningScreen> createState() => _RoutePlanningScreenState();
}

class _RoutePlanningScreenState extends State<RoutePlanningScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

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
              children: [
                const HubsManagerSection(),
                const RouteDefinitionSection(),
                const PolylineUploaderSection(),
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
class HubsManagerSection extends StatefulWidget {
  const HubsManagerSection({super.key});

  @override
  State<HubsManagerSection> createState() => _HubsManagerSectionState();
}

class _HubsManagerSectionState extends State<HubsManagerSection> {
  final _nameController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  bool _isSaving = false;
  String? _editingHubName;

  void _resetForm() {
    _nameController.clear();
    _latController.clear();
    _lngController.clear();
    setState(() {
      _editingHubName = null;
    });
  }

  Future<void> _saveHub() async {
    if (_nameController.text.isNotEmpty && _latController.text.isNotEmpty && _lngController.text.isNotEmpty) {
      setState(() => _isSaving = true);
      try {
        final hub = HubModel(
          name: _nameController.text.trim(),
          latitude: double.parse(_latController.text),
          longitude: double.parse(_lngController.text),
        );
        
        final service = Provider.of<FirebaseService>(context, listen: false);
        
        if (_editingHubName != null) {
          await service.updateHub(hub, _editingHubName!);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Campus/Stop Updated!'), backgroundColor: Colors.blue),
            );
          }
        } else {
          await service.addHub(hub);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Campus/Stop Added!'), backgroundColor: Colors.green),
            );
          }
        }
        _resetForm();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FirebaseService>(context);
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
                  _editingHubName != null ? 'Edit Campus/Stop' : 'Add New Campus/Stop', 
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 20),
                _buildTextField(_nameController, 'Campus or Stop Name (e.g. Abbasia Campus)', Icons.business_rounded),
                const SizedBox(height: 16),
                _buildTextField(_latController, 'Latitude', Icons.location_on_outlined, isNumber: true),
                const SizedBox(height: 16),
                _buildTextField(_lngController, 'Longitude', Icons.location_on_outlined, isNumber: true),
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (_editingHubName != null)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: OutlinedButton(
                            onPressed: _resetForm,
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
                        onPressed: _isSaving ? null : _saveHub,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _editingHubName != null ? Colors.blue[800] : AppColors.primaryNavy,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              _editingHubName != null ? 'Update Stop' : 'Save Hub', 
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
                  height: 500, // Fixed height for list area to avoid infinite height issues in scroll view
                  child: StreamBuilder<List<HubModel>>(
                    stream: service.getHubs(),
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
                                  onPressed: () {
                                    setState(() {
                                      _editingHubName = hub.name;
                                      _nameController.text = hub.name;
                                      _latController.text = hub.latitude.toString();
                                      _lngController.text = hub.longitude.toString();
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () => service.deleteHub(hub.name),
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
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        if (isNumber && double.tryParse(v) == null) return 'Invalid number';
        return null;
      },
    );
  }
}

// --- Section B: Route Definition ---
class RouteDefinitionSection extends StatefulWidget {
  const RouteDefinitionSection({super.key});

  @override
  State<RouteDefinitionSection> createState() => _RouteDefinitionSectionState();
}

class _RouteDefinitionSectionState extends State<RouteDefinitionSection> {
  final _formKey = GlobalKey<FormState>();
  final _routeNameController = TextEditingController();
  String? _fromHub;
  String? _toHub;
  bool _isSaving = false;
  String? _editingDocId;
  String? _originalRouteName;

  void _resetForm() {
    _routeNameController.clear();
    setState(() {
      _fromHub = null;
      _toHub = null;
      _editingDocId = null;
      _originalRouteName = null;
    });
  }

  Future<void> _saveRoute() async {
    if (_formKey.currentState!.validate()) {
      if (_fromHub == _toHub) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Starting and Destination points cannot be the same.'), backgroundColor: Colors.red),
        );
        return;
      }

      setState(() => _isSaving = true);
      try {
        final service = Provider.of<FirebaseService>(context, listen: false);
        
        final schedule = BusSchedule(
          id: _editingDocId ?? '',
          route: _routeNameController.text,
          from: _fromHub!,
          to: _toHub!,
          stops: [_fromHub!, _toHub!],
          type: 'Combined',
        );

        if (_editingDocId != null) {
          await service.updateBusSchedule(_editingDocId!, schedule, _originalRouteName!);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Route Updated Successfully!'), backgroundColor: Colors.blue),
            );
          }
        } else {
          await service.addBusSchedule(schedule);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Route Created Successfully!'), backgroundColor: Colors.green),
            );
          }
        }
        _resetForm();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving route: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FirebaseService>(context);
    final isMobile = AppResponsiveUtil.isMobile(context);

    return StreamBuilder<List<HubModel>>(
      stream: service.getHubs(),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: AppColors.borderLight),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _editingDocId != null ? 'Edit Bus Route' : 'Define New Bus Route', 
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _routeNameController,
                          decoration: InputDecoration(
                            labelText: 'Bus Route Name (e.g. Abbasia ➔ Baghdad)',
                            prefixIcon: const Icon(Icons.edit_road_rounded, color: AppColors.primaryNavy),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _fromHub,
                          decoration: InputDecoration(
                            labelText: 'Starting Point',
                            prefixIcon: const Icon(Icons.start_rounded, color: Colors.green),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: hubs.map((h) => DropdownMenuItem<String>(value: h.name, child: Text(h.name))).toList(),
                          onChanged: (v) => setState(() => _fromHub = v),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _toHub,
                          decoration: InputDecoration(
                            labelText: 'Destination Point',
                            prefixIcon: const Icon(Icons.location_on_rounded, color: Colors.red),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: hubs.map((h) => DropdownMenuItem<String>(value: h.name, child: Text(h.name))).toList(),
                          onChanged: (v) => setState(() => _toHub = v),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            if (_editingDocId != null)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: OutlinedButton(
                                    onPressed: _resetForm,
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
                                onPressed: _isSaving ? null : _saveRoute,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _editingDocId != null ? Colors.blue[800] : AppColors.primaryNavy,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isSaving 
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text(
                                      _editingDocId != null ? 'Update Route' : 'Save Route', 
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
            ),
            if (!isMobile) const SizedBox(width: 24),
            if (isMobile) const SizedBox(height: 24),
            Expanded(
              flex: isMobile ? 0 : 3,
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: AppColors.borderLight),
                ),
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
                                leading: const Icon(Icons.alt_route, color: AppColors.primaryNavy),
                                title: Text(route.route, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                subtitle: Text('${route.from} ➔ ${route.to}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                      onPressed: () {
                                        setState(() {
                                          _editingDocId = route.id;
                                          _originalRouteName = route.route;
                                          _routeNameController.text = route.route;
                                          _fromHub = route.from;
                                          _toHub = route.to;
                                        });
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                                      onPressed: () => service.deleteBusSchedule(route.id, route.route),
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
class PolylineUploaderSection extends StatefulWidget {
  const PolylineUploaderSection({super.key});

  @override
  State<PolylineUploaderSection> createState() => _PolylineUploaderSectionState();
}

class _PolylineUploaderSectionState extends State<PolylineUploaderSection> {
  final _jsonController = TextEditingController();
  String? _selectedRoute;
  bool _isSaving = false;

  Future<void> _uploadPolyline() async {
    if (_selectedRoute == null || _jsonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a route and paste JSON data.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Validate JSON
      final List<dynamic> coordinates = jsonDecode(_jsonController.text);
      
      // Basic check for lat/lng keys
      for (var coord in coordinates) {
        if (coord is! Map || !coord.containsKey('lat') || !coord.containsKey('lng')) {
          throw 'Invalid coordinate format. Each object must have "lat" and "lng" keys.';
        }
      }

      final service = Provider.of<FirebaseService>(context, listen: false);
      await service.savePolyline(_selectedRoute!, coordinates);
      
      _jsonController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Polyline Uploaded Successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FirebaseService>(context);
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppColors.borderLight),
            ),
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
                        value: _selectedRoute,
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
                        onChanged: (v) => setState(() => _selectedRoute = v),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: TextFormField(
                      controller: _jsonController,
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
                      onPressed: _isSaving ? null : _uploadPolyline,
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppColors.borderLight),
            ),
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
                    stream: service.getPolylinesStatus(),
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
                              final name = data['route'] ?? 'Unknown';
                              final hasPath = polylines.containsKey(name);
                              final pointCount = hasPath ? (polylines[name] as List).length : 0;

                              return ListTile(
                                leading: Icon(
                                  hasPath ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                                  color: hasPath ? Colors.green : Colors.orange,
                                ),
                                title: Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  hasPath ? '$pointCount coordinates uploaded' : 'No map path uploaded yet',
                                  style: TextStyle(fontSize: 12, color: hasPath ? Colors.green[700] : Colors.orange[700]),
                                ),
                                trailing: hasPath ? TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedRoute = name;
                                      _jsonController.text = jsonEncode(polylines[name]);
                                    });
                                  },
                                  child: const Text('Edit'),
                                ) : null,
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
