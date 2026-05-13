import 'package:flutter/material.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';

class FleetOperationsScreen extends StatelessWidget {
  const FleetOperationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fleet Operations',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
          ),
          const Text('Monitor and manage the university bus fleet.',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 50),
          const Center(
            child: Column(
              children: [
                Icon(Icons.engineering, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('Fleet Management Module is under maintenance.',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
