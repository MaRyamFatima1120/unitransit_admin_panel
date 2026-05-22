import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/core/services/firebase_service.dart';
import 'package:unitransit_admin/models/student_model.dart';
import 'package:unitransit_admin/core/utils/responsive_util.dart';
import 'package:unitransit_admin/view_models/dashboard_view_model.dart';
import 'package:unitransit_admin/view_models/students_view_model.dart';
import 'package:unitransit_admin/core/utils/animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final ScrollController _horizontalScrollController = ScrollController();
  final List<String> _tabs = const ['All', 'Active', 'Inactive', 'Blocked'];

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeInSlide(
      duration: const Duration(milliseconds: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(AppResponsiveUtil.isMobile(context) ? 16 : 32),
            child: _buildHeader(context),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.borderLight.withValues(alpha: 0.5))),
              ),
              child: Column(
                children: [
                  _buildToolbar(context),
                  Expanded(child: _buildStudentsTable(context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        Column(
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
                if (AppResponsiveUtil.isMobile(context))
                  const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Students Management',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          letterSpacing: -0.5,
                          fontSize: AppResponsiveUtil.isMobile(context) ? 24 : null,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.only(left: AppResponsiveUtil.isMobile(context) ? 36 : 0),
              child: const Text(
                'View, edit, and manage all registered transit students.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        _buildTotalCountBadge(),
      ],
    );
  }

  Widget _buildTotalCountBadge() {
    final firebaseService = context.read<FirebaseService>();
    return StreamBuilder<List<StudentModel>>(
      stream: firebaseService.getStudents(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.length : 0;
        return FadeInSlide(
          direction: FadeInDirection.rightToLeft,
          delay: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryNavy.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryNavy.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_outline_rounded, size: 16, color: AppColors.primaryNavy),
                const SizedBox(width: 8),
                Text(
                  '$count Students',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryNavy, fontSize: 13),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final viewModel = context.watch<StudentsViewModel>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          FadeInSlide(
            direction: FadeInDirection.leftToRight,
            delay: const Duration(milliseconds: 300),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _tabs.map((tab) => _buildTab(tab, viewModel)).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          AppResponsiveUtil.isMobile(context)
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FadeInSlide(
                      direction: FadeInDirection.leftToRight,
                      delay: Duration(milliseconds: 400),
                      child: Text(
                        'All Registered Students',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeInSlide(
                      direction: FadeInDirection.rightToLeft,
                      delay: const Duration(milliseconds: 400),
                      child: SizedBox(
                        width: double.infinity,
                        child: _buildAddStudentButton(context, viewModel),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const FadeInSlide(
                      direction: FadeInDirection.leftToRight,
                      delay: Duration(milliseconds: 400),
                      child: Text(
                        'All Registered Students',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                      ),
                    ),
                    FadeInSlide(
                      direction: FadeInDirection.rightToLeft,
                      delay: const Duration(milliseconds: 400),
                      child: _buildAddStudentButton(context, viewModel),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, StudentsViewModel viewModel) {
    final bool isSelected = viewModel.selectedTab == label;
    return _HoverTab(
      label: label,
      isSelected: isSelected,
      onTap: () => viewModel.setSelectedTab(label),
    );
  }

  Widget _buildAddStudentButton(BuildContext context, StudentsViewModel viewModel) {
    return ElevatedButton.icon(
      onPressed: () => _showAddStudentDialog(context, viewModel),
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Add Student'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 2,
        shadowColor: AppColors.primaryNavy.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildStudentsTable(BuildContext context) {
    final firebaseService = context.read<FirebaseService>();
    final viewModel = context.watch<StudentsViewModel>();
    final dashboardViewModel = context.watch<DashboardViewModel>();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          controller: _horizontalScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: FadeInSlide(
                direction: FadeInDirection.bottomToTop,
                delay: const Duration(milliseconds: 500),
                child: Container(
                  width: constraints.maxWidth > 1550 + 48 ? constraints.maxWidth - 48 : 1550,
                  margin: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildTableHeader(),
                      const Divider(height: 1),
                      StreamBuilder<List<StudentModel>>(
                        stream: firebaseService.getStudents(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const SizedBox(height: 300, child: Center(child: Text('No students found.', style: TextStyle(color: Colors.grey))));
                          }

                          var students = snapshot.data!;
                          if (viewModel.selectedTab != 'All') {
                            students = students.where((s) {
                              if (viewModel.selectedTab == 'Active') return (s.status == 'Online' || s.status == 'Active') && !s.isBlocked;
                              if (viewModel.selectedTab == 'Inactive') return (s.status == 'Offline' || s.status == 'Inactive') && !s.isBlocked;
                              if (viewModel.selectedTab == 'Blocked') return s.isBlocked;
                              return true;
                            }).toList();
                          }

                          final searchQuery = dashboardViewModel.searchQuery;
                          if (searchQuery.isNotEmpty) {
                            students = students.where((s) =>
                              s.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                              s.email.toLowerCase().contains(searchQuery.toLowerCase()) ||
                              s.studentId.toLowerCase().contains(searchQuery.toLowerCase()) ||
                              s.regNo.toLowerCase().contains(searchQuery.toLowerCase()) ||
                              s.department.toLowerCase().contains(searchQuery.toLowerCase()) ||
                              s.phoneNumber.contains(searchQuery)).toList();
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: students.length,
                            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                            itemBuilder: (context, index) => _StudentRow(
                              student: students[index], 
                              viewModel: viewModel,
                              onView: (s) => _showViewStudentDialog(context, s),
                              onEdit: (s) => _showEditStudentDialog(context, viewModel, s),
                              onDelete: (s) => _showDeleteConfirmation(context, viewModel, s),
                              onSendNotification: (s) => _showSendNotificationDialog(context, s.id, s.name),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy.withValues(alpha: 0.02),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('STUDENT INFO', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
          Expanded(flex: 2, child: Text('ROLL NUMBER', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
          Expanded(flex: 2, child: Text('REG. NUMBER', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
          Expanded(flex: 2, child: Text('DEPARTMENT', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
          Expanded(flex: 2, child: Text('PHONE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
          Expanded(flex: 2, child: Text('STATUS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
          Expanded(flex: 3, child: Text('ACTIONS', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
        ],
      ),
    );
  }

  void _showViewStudentDialog(BuildContext context, StudentModel student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(32),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.1),
                    backgroundImage: student.profileImage.isNotEmpty ? NetworkImage(student.profileImage) : null,
                    child: student.profileImage.isEmpty
                        ? Text(
                            student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                            style: const TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold, fontSize: 28),
                          )
                        : null,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name.isNotEmpty ? student.name : 'Unknown Student',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryNavy.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "IUB ENROLLED STUDENT",
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primaryNavy, letterSpacing: 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildSectionTitle("ACADEMIC IDENTITY"),
              const SizedBox(height: 16),
              _buildDetailTile(Icons.school_rounded, "University Department", student.department),
              _buildDetailTile(Icons.badge_rounded, "Roll Number / ID", student.studentId),
              _buildDetailTile(Icons.assignment_ind_rounded, "Registration Number", student.regNo),
              _buildDetailTile(Icons.layers_rounded, "Semester", student.semester),
              const SizedBox(height: 24),
              _buildSectionTitle("COMMUNICATION"),
              const SizedBox(height: 16),
              _buildDetailTile(Icons.email_rounded, "Academic Email", student.email.isNotEmpty ? student.email : "Not Provided"),
              _buildDetailTile(Icons.phone_android_rounded, "Phone Number", student.phoneNumber),
              const SizedBox(height: 24),
              _buildSectionTitle("STATUS & SECURITY"),
              const SizedBox(height: 16),
              _buildDetailTile(Icons.online_prediction_rounded, "Account Status", student.isBlocked ? "Suspended" : student.status, valueColor: student.isBlocked ? Colors.red : (student.status == 'Online' || student.status == 'Active' ? Colors.green : Colors.grey)),
              _buildDetailTile(Icons.block_rounded, "Access Status", student.isBlocked ? "Blocked" : "Active", valueColor: student.isBlocked ? Colors.red : Colors.green),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primaryNavy,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryNavy, letterSpacing: 1.5),
        ),
      ],
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryNavy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryNavy, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  value, 
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: valueColor ?? AppColors.textDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  final List<String> _departments = const [
    'BS Computer Science', 'BS Software Engineering', 'BS Information Technology',
    'BS Electrical Engineering', 'BS Mechanical Engineering', 'BS Civil Engineering',
    'BBA (Business Administration)', 'BS Mathematics', 'BS Physics', 'BS Chemistry', 'Other'
  ];

  final List<String> _semesters = const [
    '1st Semester', '2nd Semester', '3rd Semester', '4th Semester',
    '5th Semester', '6th Semester', '7th Semester', '8th Semester',
  ];

  void _showAddStudentDialog(BuildContext context, StudentsViewModel viewModel) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final studentIdController = TextEditingController();
    final regNoController = TextEditingController();
    final phoneController = TextEditingController();
    String? selectedDept;
    String? selectedSemester;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add New Student', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(nameController, 'Full Name', Icons.person),
                  _buildTextField(emailController, 'Academic Email', Icons.email, keyboardType: TextInputType.emailAddress),
                  _buildTextField(studentIdController, 'Roll Number / ID', Icons.badge),
                  _buildTextField(regNoController, 'Registration Number', Icons.assignment_ind),
                  _buildDropdownField(label: 'Program / Department', value: selectedDept, icon: Icons.school, baseItems: _departments, onChanged: (val) => setDialogState(() => selectedDept = val)),
                  _buildDropdownField(label: 'Semester', value: selectedSemester, icon: Icons.layers, baseItems: _semesters, onChanged: (val) => setDialogState(() => selectedSemester = val)),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: IntlPhoneField(
                      initialCountryCode: 'PK',
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: const Icon(Icons.phone, size: 20, color: AppColors.primaryNavy),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (phone) => phoneController.text = phone.completeNumber,
                    ),
                  ),
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
                  await viewModel.addStudent(name: nameController.text, email: emailController.text, studentId: studentIdController.text, regNo: regNoController.text, department: selectedDept ?? '', semester: selectedSemester ?? '', phone: phoneController.text);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Add Student'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditStudentDialog(BuildContext context, StudentsViewModel viewModel, StudentModel student) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: student.name);
    final emailController = TextEditingController(text: student.email);
    final studentIdController = TextEditingController(text: student.studentId);
    final regNoController = TextEditingController(text: student.regNo);
    final phoneController = TextEditingController(text: student.phoneNumber);
    String? selectedDept = student.department;
    String? selectedSemester = student.semester;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Student Profile', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(nameController, 'Full Name', Icons.person),
                  _buildTextField(emailController, 'Academic Email', Icons.email, keyboardType: TextInputType.emailAddress),
                  _buildTextField(studentIdController, 'Roll Number / ID', Icons.badge),
                  _buildTextField(regNoController, 'Registration Number', Icons.assignment_ind),
                  _buildDropdownField(label: 'Program / Department', value: selectedDept, icon: Icons.school, baseItems: _departments, onChanged: (val) => setDialogState(() => selectedDept = val)),
                  _buildDropdownField(label: 'Semester', value: selectedSemester, icon: Icons.layers, baseItems: _semesters, onChanged: (val) => setDialogState(() => selectedSemester = val)),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: IntlPhoneField(
                      initialCountryCode: 'PK',
                      initialValue: student.phoneNumber.replaceFirst('+92', ''),
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: const Icon(Icons.phone, size: 20, color: AppColors.primaryNavy),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (phone) => phoneController.text = phone.completeNumber,
                    ),
                  ),
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
                  await viewModel.updateStudent(student.copyWith(name: nameController.text, email: emailController.text, studentId: studentIdController.text, regNo: regNoController.text, department: selectedDept ?? '', semester: selectedSemester ?? '', phoneNumber: phoneController.text));
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, StudentsViewModel viewModel, StudentModel student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [Icon(Icons.warning_rounded, color: Colors.red, size: 28), SizedBox(width: 12), Text("Delete Student?", style: TextStyle(fontWeight: FontWeight.bold))]),
        content: Text("Are you sure you want to permanently delete the profile for ${student.name}? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(onPressed: () { viewModel.deleteStudent(student.id); Navigator.pop(ctx); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text("Delete Permanently")),
        ],
      ),
    );
  }

  void _showSendNotificationDialog(BuildContext context, String userId, String userName) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Send Notification to $userName'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(titleController, 'Title', Icons.title),
                _buildTextField(messageController, 'Message', Icons.message, action: TextInputAction.done),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSending ? null : () async {
                if (formKey.currentState!.validate()) {
                  setModalState(() => isSending = true);
                  try {
                    await context.read<FirebaseService>().sendUserNotification(userId: userId, title: titleController.text.trim(), message: messageController.text.trim(), type: 'info');
                    if (context.mounted) Navigator.pop(dialogContext);
                  } catch (e) { setModalState(() => isSending = false); }
                }
              },
              child: isSending ? const CircularProgressIndicator() : const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType, TextInputAction action = TextInputAction.next}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: action,
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

  Widget _buildDropdownField({required String label, required String? value, required IconData icon, required List<String> baseItems, required ValueChanged<String?> onChanged}) {
    final Set<String> itemsSet = Set.from(baseItems);
    if (value != null && value.isNotEmpty) itemsSet.add(value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20, color: AppColors.primaryNavy), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
        items: itemsSet.map((val) => DropdownMenuItem<String>(value: val, child: Text(val))).toList(),
        onChanged: onChanged,
        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }
}

class _HoverTab extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _HoverTab({required this.label, required this.isSelected, required this.onTap});
  @override
  State<_HoverTab> createState() => _HoverTabState();
}

class _HoverTabState extends State<_HoverTab> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 24),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: widget.isSelected ? AppColors.primaryNavy : (_isHovered ? AppColors.primaryNavy.withValues(alpha: 0.05) : Colors.transparent), borderRadius: BorderRadius.circular(8)),
          child: Text(widget.label, style: TextStyle(color: widget.isSelected ? Colors.white : (_isHovered ? AppColors.primaryNavy : Colors.grey.shade600), fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }
}

class _StudentRow extends StatefulWidget {
  final StudentModel student;
  final StudentsViewModel viewModel;
  final Function(StudentModel) onView, onEdit, onDelete, onSendNotification;
  const _StudentRow({required this.student, required this.viewModel, required this.onView, required this.onEdit, required this.onDelete, required this.onSendNotification});
  @override
  State<_StudentRow> createState() => _StudentRowState();
}

class _StudentRowState extends State<_StudentRow> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(color: _isHovered ? AppColors.primaryNavy.withValues(alpha: 0.02) : Colors.transparent),
        child: Row(
          children: [
            Expanded(flex: 3, child: Row(children: [AnimatedScale(scale: _isHovered ? 1.1 : 1.0, duration: const Duration(milliseconds: 200), child: CircleAvatar(radius: 20, backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.1), backgroundImage: s.profileImage.isNotEmpty ? NetworkImage(s.profileImage) : null, child: s.profileImage.isEmpty ? Text(s.name.isNotEmpty ? s.name[0].toUpperCase() : '?', style: const TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold)) : null)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.name, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _isHovered ? AppColors.primaryNavy : AppColors.textDark)), Text(s.email, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))]))])),
            Expanded(flex: 2, child: Text(s.studentId, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            Expanded(flex: 2, child: Text(s.regNo, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
            Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.department, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)), Text(s.semester, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))])),
            Expanded(flex: 2, child: Text(s.phoneNumber, style: const TextStyle(fontSize: 12))),
            Expanded(flex: 2, child: _buildStatusBadge(isBlocked: s.isBlocked, status: s.status)),
            Expanded(flex: 3, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              _ActionIconButton(icon: Icons.visibility_outlined, color: AppColors.primaryNavy, onTap: () => widget.onView(s), tooltip: 'View'),
              const SizedBox(width: 4),
              _ActionIconButton(icon: Icons.edit_outlined, color: AppColors.primaryNavy, onTap: () => widget.onEdit(s), tooltip: 'Edit'),
              const SizedBox(width: 4),
              _ActionIconButton(icon: Icons.lock_reset, color: Colors.orange, onTap: () => context.read<FirebaseService>().resetStudentPassword(s.email), tooltip: 'Reset'),
              const SizedBox(width: 4),
              _ActionIconButton(icon: s.isBlocked ? Icons.lock_open : Icons.block, color: s.isBlocked ? Colors.green : Colors.red, onTap: () => widget.viewModel.updateStudent(s.copyWith(isBlocked: !s.isBlocked)), tooltip: s.isBlocked ? 'Unblock' : 'Block'),
              const SizedBox(width: 4),
              _ActionIconButton(icon: Icons.message, color: Colors.blue, onTap: () => widget.onSendNotification(s), tooltip: 'Notify'),
              const SizedBox(width: 4),
              _ActionIconButton(icon: Icons.delete_outline, color: Colors.red, onTap: () => widget.onDelete(s), tooltip: 'Delete'),
            ])),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge({required bool isBlocked, required String status}) {
    final isOnline = status == 'Online' || status == 'Active';
    final Color color = isBlocked ? Colors.red : (isOnline ? Colors.green : Colors.grey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(isBlocked ? Icons.block : Icons.circle, size: 8, color: color), const SizedBox(width: 5), Text(isBlocked ? 'Blocked' : (isOnline ? 'Online' : 'Offline'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color))]),
    );
  }
}

class _ActionIconButton extends StatefulWidget {
  final IconData icon; final Color color; final VoidCallback onTap; final String? tooltip;
  const _ActionIconButton({required this.icon, required this.color, required this.onTap, this.tooltip});
  @override
  State<_ActionIconButton> createState() => _ActionIconButtonState();
}

class _ActionIconButtonState extends State<_ActionIconButton> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    Widget b = MouseRegion(onEnter: (_) => setState(() => _isHovered = true), onExit: (_) => setState(() => _isHovered = false), child: InkWell(onTap: widget.onTap, borderRadius: BorderRadius.circular(8), child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _isHovered ? widget.color : widget.color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)), child: Icon(widget.icon, size: 18, color: _isHovered ? Colors.white : widget.color))));
    return widget.tooltip != null ? Tooltip(message: widget.tooltip, child: b) : b;
  }
}
