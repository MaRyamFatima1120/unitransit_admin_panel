import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/core/utils/responsive_util.dart';
import 'package:unitransit_admin/core/utils/animations.dart';
import 'package:unitransit_admin/view_models/buses_view_model.dart';

class BusesScreen extends StatefulWidget {
  const BusesScreen({super.key});

  @override
  State<BusesScreen> createState() => _BusesScreenState();
}

class _BusesScreenState extends State<BusesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditBusDialog({Map<String, dynamic>? bus}) {
    final isEditing = bus != null;
    final busNumberCtrl = TextEditingController(text: isEditing ? bus['busNumber'] : '');
    final plateNumberCtrl = TextEditingController(text: isEditing ? bus['plateNumber'] : '');
    final capacityCtrl = TextEditingController(text: isEditing ? bus['capacity']?.toString() : '');
    String selectedStatus = isEditing ? (bus['status'] ?? 'Active') : 'Active';
    String selectedType = isEditing ? (bus['type'] ?? 'Standard') : 'Standard';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.cardWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            isEditing ? 'Edit Bus Details' : 'Add New Bus',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
          ),
          content: SingleChildScrollView(
            child: Container(
              width: 400,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: busNumberCtrl,
                    decoration: InputDecoration(
                      labelText: 'Bus Number',
                      hintText: 'e.g., 42',
                      prefixIcon: const Icon(Icons.directions_bus_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: plateNumberCtrl,
                    decoration: InputDecoration(
                      labelText: 'License Plate',
                      hintText: 'e.g., ABC-123',
                      prefixIcon: const Icon(Icons.pin_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: capacityCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Passenger Capacity',
                      hintText: 'e.g., 60',
                      prefixIcon: const Icon(Icons.people_alt_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: InputDecoration(
                      labelText: 'Bus Type',
                      prefixIcon: const Icon(Icons.category_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['Standard', 'Coaster', 'Mini Bus', 'Luxury'].map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedType = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Operational Status',
                      prefixIcon: const Icon(Icons.info_outline_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['Active', 'Maintenance', 'Out of Service'].map((status) {
                      return DropdownMenuItem(value: status, child: Text(status));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedStatus = val);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final busData = {
                  'busNumber': busNumberCtrl.text.trim(),
                  'plateNumber': plateNumberCtrl.text.trim(),
                  'capacity': int.tryParse(capacityCtrl.text.trim()) ?? 0,
                  'type': selectedType,
                  'status': selectedStatus,
                };
                final vm = context.read<BusesViewModel>();
                if (isEditing) {
                  vm.updateBus(bus['id'], busData);
                } else {
                  vm.addBus(busData);
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(isEditing ? 'Save Changes' : 'Add Bus', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bus'),
        content: const Text('Are you sure you want to remove this bus? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<BusesViewModel>().deleteBus(id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppResponsiveUtil.isMobile(context);
    final vm = context.watch<BusesViewModel>();
    
    final filteredBuses = vm.buses.where((bus) {
      final query = _searchQuery.toLowerCase();
      final number = (bus['busNumber'] ?? '').toString().toLowerCase();
      final plate = (bus['plateNumber'] ?? '').toString().toLowerCase();
      return number.contains(query) || plate.contains(query);
    }).toList();

    return FadeInSlide(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              if (!isMobile)
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _showAddEditBusDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Bus'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              
              // Search & Add Mobile
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search by Bus Number or Plate...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: AppColors.cardWhite,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  if (isMobile) ...[
                    const SizedBox(width: 12),
                    FloatingActionButton(
                      onPressed: _showAddEditBusDialog,
                      backgroundColor: AppColors.primaryNavy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      child: const Icon(Icons.add),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              
              // Content
              vm.isLoading
                  ? Center(child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(color: AppColors.primaryNavy),
                    ))
                  : filteredBuses.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.directions_bus_outlined, size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text('No buses found.', style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 16)),
                              ],
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: AppColors.cardWhite,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - (isMobile ? 32 : 344)),
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(AppColors.backgroundLight),
                                  columns: const [
                                    DataColumn(label: Text('Bus Number', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('License Plate', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Capacity', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                  rows: filteredBuses.map((bus) {
                                    final status = bus['status'] ?? 'Active';
                                    Color statusColor = Colors.green;
                                    if (status == 'Maintenance') statusColor = Colors.orange;
                                    if (status == 'Out of Service') statusColor = Colors.red;
 
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(
                                          '#${bus['busNumber']}',
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        )),
                                        DataCell(Text(bus['plateNumber'] ?? 'N/A')),
                                        DataCell(Text(bus['type'] ?? 'Standard')),
                                        DataCell(Text('${bus['capacity'] ?? 0} seats')),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              status,
                                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.edit_rounded, color: AppColors.primaryNavy),
                                                onPressed: () => _showAddEditBusDialog(bus: bus),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                                                onPressed: () => _confirmDelete(bus['id']),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
            ],
          ),
        ),
      ),
    );
  }
}