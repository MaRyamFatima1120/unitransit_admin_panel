import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/core/services/firebase_service.dart';
import 'package:unitransit_admin/models/student_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unitransit_admin/core/utils/responsive_util.dart';
import 'package:unitransit_admin/view_models/dashboard_view_model.dart';

class StudentsScreen extends StatelessWidget {
  const StudentsScreen({super.key});

  void _showAddStudentDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final studentIdController = TextEditingController();
    final deptController = TextEditingController();
    final phoneController = TextEditingController();
    final routeController = TextEditingController();
    final stopController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Student', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(nameController, 'Full Name', Icons.person),
                _buildTextField(studentIdController, 'Roll Number / ID', Icons.badge),
                _buildTextField(deptController, 'Department', Icons.school),
                _buildTextField(phoneController, 'Phone Number', Icons.phone, keyboardType: TextInputType.phone),
                _buildTextField(routeController, 'Assigned Route', Icons.map),
                _buildTextField(stopController, 'Pick-up/Drop-off Stop', Icons.location_on),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy, foregroundColor: Colors.white),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final firebaseService = Provider.of<FirebaseService>(context, listen: false);
                final id = FirebaseFirestore.instance.collection('students').doc().id;
                
                final newStudent = StudentModel(
                  id: id,
                  name: nameController.text,
                  studentId: studentIdController.text,
                  department: deptController.text,
                  phoneNumber: phoneController.text,
                  route: routeController.text,
                  stop: stopController.text,
                  status: 'Active',
                  createdAt: DateTime.now(),
                );

                await firebaseService.addStudent(newStudent);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add Student'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: AppColors.primaryNavy),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);

    return Padding(
      padding: EdgeInsets.all(AppResponsiveUtil.isMobile(context) ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Students Management',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      fontSize: AppResponsiveUtil.isMobile(context) ? 24 : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('View and manage all registered students.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddStudentDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Student'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: StreamBuilder<List<StudentModel>>(
                stream: firebaseService.getStudents(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No students found. Add your first student!'));
                  }

                  final students = snapshot.data!;
                  final searchQuery = context.watch<DashboardViewModel>().searchQuery;
                  
                  final filteredStudents = students.where((s) {
                    if (searchQuery.isEmpty) return true;
                    final query = searchQuery.toLowerCase();
                    return s.name.toLowerCase().contains(query) || 
                           s.studentId.toLowerCase().contains(query) ||
                           s.department.toLowerCase().contains(query);
                  }).toList();

                  if (filteredStudents.isEmpty) {
                    return const Center(child: Text('No results found for your search.'));
                  }

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Scrollbar(
                      thumbVisibility: true,
                      thickness: 6,
                      radius: const Radius.circular(10),
                      child: ListView.separated(
                        itemCount: filteredStudents.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.borderLight),
                        itemBuilder: (context, index) {
                          final student = filteredStudents[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.1),
                              child: Text(
                                student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                                style: const TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text('ID: ${student.studentId}', style: const TextStyle(fontSize: 12)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!AppResponsiveUtil.isMobile(context))
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      student.status,
                                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                  onPressed: () => firebaseService.deleteStudent(student.id),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
