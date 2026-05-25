import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/core/utils/responsive_util.dart';
import 'package:unitransit_admin/core/utils/animations.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  @override
  Widget build(BuildContext context) {
    final isMobile = AppResponsiveUtil.isMobile(context);

    return FadeInSlide(
      duration: const Duration(milliseconds: 600),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('buses').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final buses = snapshot.data?.docs ?? [];
                  if (buses.isEmpty) {
                    return const Center(child: Text('No buses found to track maintenance.'));
                  }

                  return ListView.builder(
                    itemCount: buses.length,
                    itemBuilder: (context, index) {
                      final bus = buses[index].data() as Map<String, dynamic>;
                      return _buildBusMaintenanceCard(bus, buses[index].id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fleet Maintenance',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
        ),
        const Text('Track bus service dates, fuel logs, and operational health.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }

  Widget _buildBusMaintenanceCard(Map<String, dynamic> bus, String docId) {
    final busNumber = bus['busNumber'] ?? 'N/A';
    final plateNumber = bus['plateNumber'] ?? 'N/A';
    final lastService = bus['lastServiceDate'] ?? 'Not Recorded';
    final nextService = bus['nextServiceDate'] ?? 'TBA';
    final fuelAvg = bus['fuelAverage'] ?? '0.0';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primaryNavy.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.build_circle_rounded, color: AppColors.primaryNavy, size: 32),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bus #$busNumber ($plateNumber)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 24,
                  children: [
                    _buildInfoItem('Last Service', lastService),
                    _buildInfoItem('Next Service', nextService, isHighlight: true),
                    _buildInfoItem('Fuel Avg', '$fuelAvg km/l'),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showUpdateMaintenanceDialog(context, docId, bus),
            child: const Text('Update Logs'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isHighlight ? Colors.orange : AppColors.textDark)),
      ],
    );
  }

  void _showUpdateMaintenanceDialog(BuildContext context, String docId, Map<String, dynamic> bus) {
    final fuelController = TextEditingController(text: bus['fuelAverage']?.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Bus #${bus['busNumber']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: fuelController,
              decoration: const InputDecoration(labelText: 'New Fuel Average (km/l)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('buses').doc(docId).update({
                  'fuelAverage': fuelController.text,
                  'lastServiceDate': DateTime.now().toString().split(' ')[0],
                  'nextServiceDate': DateTime.now().add(const Duration(days: 90)).toString().split(' ')[0],
                });
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Confirm Maintenance'),
            ),
          ],
        ),
      ),
    );
  }
}
