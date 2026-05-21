import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/core/services/firebase_service.dart';
import 'package:unitransit_admin/core/utils/responsive_util.dart';
import 'package:unitransit_admin/models/driver_model.dart';
import 'package:unitransit_admin/view_models/dashboard_view_model.dart';
import 'package:unitransit_admin/view_models/drivers_view_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:unitransit_admin/models/bus_schedule_model.dart';

class DriversScreen extends StatefulWidget {
  const DriversScreen({super.key});

  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  // Optimization: Controllers initialized once and disposed properly
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  final List<String> _tabs = const ['All', 'Available', 'un-Available', 'Verified', 'Non-Verified'];

  @override
  Widget build(BuildContext context) {
    // Optimization: Using Selector to only rebuild when search or tab changes
    return Column(
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
              border: Border(top: BorderSide(color: AppColors.borderLight.withOpacity(0.5))),
            ),
            child: Column(
              children: [
                _buildToolbar(context),
                Expanded(child: _buildDriversTable(context)),
              ],
            ),
          ),
        ),
      ],
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
                    'Driver Management',
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
                'Manage, verify, and view all registered transit drivers.',
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

  Widget _buildToolbar(BuildContext context) {
    final viewModel = context.watch<DriversViewModel>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _tabs.map((tab) => _buildTab(tab, viewModel)).toList(),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildAddDriverButton(context, viewModel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, DriversViewModel viewModel) {
    final bool isSelected = viewModel.selectedTab == label;
    return InkWell(
      onTap: () => viewModel.setSelectedTab(label),
      child: Container(
        margin: const EdgeInsets.only(right: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDriversTable(BuildContext context) {
    final firebaseService = context.read<FirebaseService>();
    final viewModel = context.watch<DriversViewModel>();
    final dashboardViewModel = context.watch<DashboardViewModel>();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          controller: _horizontalScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: Container(
              width: constraints.maxWidth > 1750 + 48 ? constraints.maxWidth - 48 : 1750,
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
          child: Column(
            children: [
              _buildTableHeader(),
              const Divider(height: 1),
              StreamBuilder<List<BusSchedule>>(
                stream: firebaseService.getBusSchedules(),
                builder: (context, scheduleSnapshot) {
                  final allSchedules = scheduleSnapshot.data ?? [];
                  return StreamBuilder<List<DriverModel>>(
                    stream: firebaseService.getDrivers(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const SizedBox(height: 300, child: Center(child: Text('No drivers found.', style: TextStyle(color: Colors.grey))));
                      }

                      var drivers = snapshot.data!;
                      if (viewModel.selectedTab != 'All') {
                        drivers = drivers.where((d) {
                          if (viewModel.selectedTab == 'Available') return d.status == 'Online' || d.status == 'Available';
                          if (viewModel.selectedTab == 'un-Available') return d.status == 'Offline' || d.status == 'Busy';
                          if (viewModel.selectedTab == 'Verified') return d.isVerified;
                          if (viewModel.selectedTab == 'Non-Verified') return !d.isVerified;
                          return true;
                        }).toList();
                      }

                      final searchQuery = dashboardViewModel.searchQuery;
                      if (searchQuery.isNotEmpty) {
                        drivers = drivers.where((d) =>
                          d.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                          d.email.toLowerCase().contains(searchQuery.toLowerCase()) ||
                          d.phoneNumber.contains(searchQuery)).toList();
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: drivers.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                        itemBuilder: (context, index) => _buildDriverRow(drivers[index], viewModel, allSchedules),
                      );
                    },
                  );
                }
              ),
            ],
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
        color: AppColors.primaryNavy.withOpacity(0.02),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('DRIVER INFO', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
          Expanded(flex: 2, child: Text('PHONE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
          Expanded(flex: 2, child: Text('CNIC', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
          Expanded(flex: 2, child: Text('LICENSE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
          Expanded(flex: 2, child: Text('EXPIRY', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
          Expanded(flex: 1, child: Text('BUS #', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
          Expanded(flex: 2, child: Text('ASSIGNED ROUTES', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
          Expanded(flex: 1, child: Text('EXP', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
          Expanded(flex: 2, child: Text('DOCS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
          Expanded(flex: 2, child: Text('STATUS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
          Expanded(flex: 1, child: Text('VERIFIED', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
          Expanded(flex: 3, child: Text('ACTIONS', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
        ],
      ),
    );
  }

  Widget _buildDriverRow(DriverModel driver, DriversViewModel viewModel, List<BusSchedule> allSchedules) {
    final firebaseService = context.read<FirebaseService>();
    final expiryDate = "${driver.licenseExpiry.day}/${driver.licenseExpiry.month}/${driver.licenseExpiry.year}";
    
    final driverSchedules = allSchedules.where((s) {
      final sBus = (s.busNumber ?? '').toLowerCase().trim();
      final dBus = driver.assignedBus.toLowerCase().trim();
      if (sBus == dBus) return true;
      final parts = sBus.split(',').map((e) => e.trim());
      if (parts.contains(dBus)) return true;
      if (sBus.contains(dBus) || dBus.contains(sBus)) return true;
      return false;
    }).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
            // Driver Info
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderLight),
                      image: driver.profileUrl != null 
                        ? DecorationImage(image: CachedNetworkImageProvider(driver.profileUrl!), fit: BoxFit.cover)
                        : null,
                    ),
                    child: driver.profileUrl == null ? const Icon(Icons.person, size: 20, color: Colors.grey) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(driver.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark)),
                        Text(driver.email, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Phone
            Expanded(flex: 2, child: Text(driver.phoneNumber, style: const TextStyle(fontSize: 12))),
            // CNIC
            Expanded(flex: 2, child: Text(driver.cnic, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            // License
            Expanded(flex: 2, child: Text(driver.licenseNumber, style: const TextStyle(fontSize: 12))),
            // Expiry
            Expanded(flex: 2, child: Text(expiryDate, style: TextStyle(fontSize: 12, color: driver.licenseExpiry.isBefore(DateTime.now()) ? Colors.red : Colors.green))),
            // Bus #
            Expanded(flex: 1, child: Text(driver.assignedBus, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryNavy))),
            // Assigned Routes
            Expanded(
              flex: 2,
              child: driverSchedules.isEmpty
                ? const Text('None', style: TextStyle(fontSize: 12, color: Colors.grey))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: driverSchedules.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 2.0),
                      child: Tooltip(
                        message: "${s.departureTime ?? 'Live'} • ${s.stops.join(' ➔ ')}",
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryNavy.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            s.route,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
            ),
            // Exp
            Expanded(flex: 1, child: Text(driver.experience, style: const TextStyle(fontSize: 12))),
            // Docs
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  if (driver.cnicFrontUrl != null) _buildMiniDoc(context, driver.cnicFrontUrl!),
                  if (driver.cnicFrontUrl != null) const SizedBox(width: 4),
                  if (driver.cnicBackUrl != null) _buildMiniDoc(context, driver.cnicBackUrl!),
                  if (driver.cnicBackUrl != null) const SizedBox(width: 4),
                  if (driver.licenseImageUrl != null) _buildMiniDoc(context, driver.licenseImageUrl!),
                ],
              ),
            ),
            // Status
            Expanded(
              flex: 2,
              child: _buildStatusBadge(
                isBlocked: driver.isBlocked,
                status: driver.status,
                isDriver: true,
              ),
            ),
            // Verified
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Transform.scale(
                  scale: 0.9,
                  child: Checkbox(
                    value: driver.isVerified,
                    activeColor: Colors.blue,
                    onChanged: (val) {
                      if (val != null) {
                        viewModel.updateDriver(driver.copyWith(isVerified: val));
                      }
                    },
                  ),
                ),
              ),
            ),
            // Actions
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildIconButton(Icons.edit_outlined, AppColors.primaryNavy, () => _showEditDriverDialog(context, viewModel, driver), tooltip: 'Edit Driver'),
                  const SizedBox(width: 4),
                  _buildIconButton(Icons.add_road_rounded, AppColors.primaryNavy, () {
                    context.read<DashboardViewModel>().setSelectedIndex(13);
                  }, tooltip: 'Assign Routes'),
                  const SizedBox(width: 4),
                  _buildIconButton(Icons.lock_reset, Colors.orange, () {
                    firebaseService.resetDriverPassword(driver.email);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent.')));
                  }, tooltip: 'Reset Password'),
                  const SizedBox(width: 4),
                  _buildIconButton(
                    driver.isBlocked ? Icons.lock_open_outlined : Icons.block_outlined, 
                    driver.isBlocked ? Colors.green : Colors.red, 
                    () => viewModel.updateDriver(driver.copyWith(isBlocked: !driver.isBlocked)),
                    tooltip: driver.isBlocked ? 'Unblock Driver' : 'Block Driver',
                  ),
                  const SizedBox(width: 4),
                  _buildIconButton(Icons.message_outlined, Colors.blue, () => _showSendNotificationDialog(context, driver.id, driver.name), tooltip: 'Send Notification'),
                  const SizedBox(width: 4),
                  _buildIconButton(Icons.delete_outline, Colors.red, () => _showDeleteConfirmation(context, viewModel, driver), tooltip: 'Delete Driver'),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onTap, {String? tooltip}) {
    Widget button = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
    if (tooltip != null) {
      button = Tooltip(message: tooltip, child: button);
    }
    return button;
  }

  Widget _buildStatusBadge({required bool isBlocked, required String status, bool isDriver = false}) {
    final Color bgColor;
    final Color textColor;
    final Color dotColor;
    final String label;
    final IconData dotIcon;

    if (isBlocked) {
      bgColor = Colors.red.withOpacity(0.1);
      textColor = Colors.red.shade700;
      dotColor = Colors.red;
      label = 'Blocked';
      dotIcon = Icons.block_rounded;
    } else if (status == 'Online' || status == 'Active' || status == 'Available') {
      bgColor = Colors.green.withOpacity(0.1);
      textColor = Colors.green.shade700;
      dotColor = Colors.green;
      label = status == 'Available' ? 'Available' : 'Online';
      dotIcon = Icons.circle;
    } else if (isDriver && status == 'Busy') {
      bgColor = Colors.orange.withOpacity(0.1);
      textColor = Colors.orange.shade700;
      dotColor = Colors.orange;
      label = 'Busy';
      dotIcon = Icons.circle;
    } else {
      bgColor = Colors.grey.withOpacity(0.1);
      textColor = Colors.grey.shade600;
      dotColor = Colors.grey.shade400;
      label = 'Offline';
      dotIcon = Icons.circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dotColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(dotIcon, size: 8, color: dotColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
          ),
        ],
      ),
    );
  }


  void _showDeleteConfirmation(BuildContext context, DriversViewModel viewModel, DriverModel driver) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            const Text("Delete Driver?", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "Are you sure you want to permanently delete the account for ${driver.name}? This action cannot be undone and will immediately revoke their access to the app.",
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
            child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              viewModel.deleteDriver(driver.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Driver deleted successfully.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Delete Permanently"),
          ),
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
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Send Notification to $userName', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleController,
                      enabled: !isSending,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: messageController,
                      enabled: !isSending,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Message',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Message is required' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSending ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSending ? null : () async {
                    if (formKey.currentState!.validate()) {
                      setModalState(() => isSending = true);
                      final navigator = Navigator.of(dialogContext);
                      final messenger = ScaffoldMessenger.of(context);
                      final firebaseService = context.read<FirebaseService>();
                      try {
                        await firebaseService.sendUserNotification(
                          userId: userId,
                          title: titleController.text.trim(),
                          message: messageController.text.trim(),
                          type: 'info',
                        );
                        navigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Notification sent successfully!'), backgroundColor: Colors.green),
                        );
                      } catch (e) {
                        setModalState(() => isSending = false);
                        messenger.showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                  ),
                  child: isSending
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Send'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMiniDoc(BuildContext context, String url) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: url,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
              ),
            ),
          ),
        );
      },
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.borderLight),
          image: DecorationImage(
            image: CachedNetworkImageProvider(url),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  // Rest of methods (Add/Edit Dialogs) kept optimized with ValueNotifiers...
  // I will just implement the core pattern for one dialog to show the optimization
  void _showAddDriverDialog(BuildContext context, DriversViewModel viewModel) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final cnicController = TextEditingController();
    final licenseController = TextEditingController();
    final experienceController = TextEditingController();
    final busController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    final ValueNotifier<DateTime> expiryNotifier = ValueNotifier(DateTime.now().add(const Duration(days: 365)));
    final ValueNotifier<Uint8List?> profileImageNotifier = ValueNotifier(null);
    final ValueNotifier<Uint8List?> cnicFrontNotifier = ValueNotifier(null);
    final ValueNotifier<Uint8List?> cnicBackNotifier = ValueNotifier(null);
    final ValueNotifier<Uint8List?> licenseImageNotifier = ValueNotifier(null);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add New Driver', style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 600,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildImagePickersRow(profileImageNotifier, cnicFrontNotifier, cnicBackNotifier, licenseImageNotifier),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTextField(
                          nameController, 
                          'Full Name', 
                          Icons.person,
                          validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: IntlPhoneField(
                          initialCountryCode: 'PK',
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (phone) {
                            phoneController.text = phone.completeNumber;
                          },
                          validator: (phone) {
                            if (phone == null || phone.completeNumber.isEmpty) {
                              return 'Phone number required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTextField(
                          emailController, 
                          'Email Address', 
                          Icons.email,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Email is required';
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                              return 'Enter valid email';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          passwordController, 
                          'Password', 
                          Icons.lock, 
                          isPassword: true,
                          validator: (val) => val == null || val.isEmpty ? 'Password is required' : (val.length < 6 ? 'Min 6 characters' : null),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTextField(
                          cnicController, 
                          'CNIC Number', 
                          Icons.badge,
                          validator: (val) => val == null || val.trim().isEmpty ? 'CNIC is required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          licenseController, 
                          'License Number', 
                          Icons.description,
                          validator: (val) => val == null || val.trim().isEmpty ? 'License number is required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ValueListenableBuilder(
                          valueListenable: expiryNotifier,
                          builder: (context, date, _) => _buildDatePicker(context, 'License Expiry', date, (d) => expiryNotifier.value = d),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          busController, 
                          'Assigned Bus #', 
                          Icons.directions_bus,
                          validator: (val) => val == null || val.trim().isEmpty ? 'Bus is required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    experienceController, 
                    'Experience (e.g. 5 Years)', 
                    Icons.work,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Experience is required' : null,
                  ),
                  
                  Consumer<DriversViewModel>(
                    builder: (context, vm, _) => vm.dialogError != null 
                      ? Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(vm.dialogError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                        )
                      : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          Consumer<DriversViewModel>(
            builder: (context, vm, _) => ElevatedButton(
              onPressed: vm.isUploading ? null : () async {
                if (formKey.currentState!.validate()) {
                  try {
                    await vm.addDriver(
                      name: nameController.text,
                      phone: phoneController.text,
                      email: emailController.text,
                      password: passwordController.text,
                      cnic: cnicController.text,
                      license: licenseController.text,
                      expiry: expiryNotifier.value,
                      bus: busController.text,
                      assignedRoutes: const [],
                      experience: experienceController.text,
                      profileImage: profileImageNotifier.value,
                      frontImage: cnicFrontNotifier.value,
                      backImage: cnicBackNotifier.value,
                      licenseImage: licenseImageNotifier.value,
                    );
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                     // Error handled by ViewModel
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy),
              child: vm.isUploading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save Driver'),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDriverDialog(BuildContext context, DriversViewModel viewModel, DriverModel driver) {
    final nameController = TextEditingController(text: driver.name);
    final phoneController = TextEditingController(text: driver.phoneNumber);
    final cnicController = TextEditingController(text: driver.cnic);
    final licenseController = TextEditingController(text: driver.licenseNumber);
    final experienceController = TextEditingController(text: driver.experience);
    final busController = TextEditingController(text: driver.assignedBus);
    final ValueNotifier<DateTime> expiryNotifier = ValueNotifier(driver.licenseExpiry);
    final formKey = GlobalKey<FormState>();

    // Parse country code for PK (+92)
    String initialCountryCode = 'PK';
    String initialPhoneNumber = driver.phoneNumber;
    if (initialPhoneNumber.startsWith('+92')) {
      initialCountryCode = 'PK';
      initialPhoneNumber = initialPhoneNumber.substring(3);
    } else if (initialPhoneNumber.startsWith('03')) {
      initialCountryCode = 'PK';
      initialPhoneNumber = initialPhoneNumber.substring(1);
    }
    
    // ValueNotifiers for new images if selected
    final ValueNotifier<Uint8List?> profileImageNotifier = ValueNotifier(null);
    final ValueNotifier<Uint8List?> cnicFrontNotifier = ValueNotifier(null);
    final ValueNotifier<Uint8List?> cnicBackNotifier = ValueNotifier(null);
    final ValueNotifier<Uint8List?> licenseImageNotifier = ValueNotifier(null);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Edit Driver Details', style: TextStyle(fontWeight: FontWeight.bold)),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
          ],
        ),
        content: SizedBox(
          width: 700,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildEditImageRow(driver, profileImageNotifier, cnicFrontNotifier, cnicBackNotifier, licenseImageNotifier),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTextField(
                          nameController, 
                          'Full Name', 
                          Icons.person,
                          validator: (val) => val == null || val.trim().isEmpty ? 'Name required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: IntlPhoneField(
                          initialCountryCode: initialCountryCode,
                          initialValue: initialPhoneNumber,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (phone) {
                            phoneController.text = phone.completeNumber;
                          },
                          validator: (phone) {
                            if (phone == null || phone.completeNumber.isEmpty) {
                              return 'Phone required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTextField(
                          cnicController, 
                          'CNIC Number', 
                          Icons.badge,
                          validator: (val) => val == null || val.trim().isEmpty ? 'CNIC required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          licenseController, 
                          'License Number', 
                          Icons.description,
                          validator: (val) => val == null || val.trim().isEmpty ? 'License required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ValueListenableBuilder(
                          valueListenable: expiryNotifier,
                          builder: (context, date, _) => _buildDatePicker(context, 'License Expiry', date, (d) => expiryNotifier.value = d),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          busController, 
                          'Assigned Bus #', 
                          Icons.directions_bus,
                          validator: (val) => val == null || val.trim().isEmpty ? 'Bus required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    experienceController, 
                    'Experience', 
                    Icons.work,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Experience required' : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          Consumer<DriversViewModel>(
            builder: (context, vm, _) => ElevatedButton(
              onPressed: vm.isUploading ? null : () async {
                if (formKey.currentState!.validate()) {
                  await vm.updateDriver(
                    driver.copyWith(
                      name: nameController.text,
                      phoneNumber: phoneController.text,
                      cnic: cnicController.text,
                      licenseNumber: licenseController.text,
                      licenseExpiry: expiryNotifier.value,
                      assignedBus: busController.text,
                      assignedRoutes: driver.assignedRoutes,
                      experience: experienceController.text,
                    ),
                    newProfileImage: profileImageNotifier.value,
                    newFrontImage: cnicFrontNotifier.value,
                    newBackImage: cnicBackNotifier.value,
                    newLicenseImage: licenseImageNotifier.value,
                  );
                  if (context.mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy),
              child: vm.isUploading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditImageRow(DriverModel driver, ValueNotifier<Uint8List?> profile, ValueNotifier<Uint8List?> front, ValueNotifier<Uint8List?> back, ValueNotifier<Uint8List?> license) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildEditImageItem('Profile', driver.profileUrl, profile, Icons.account_circle),
        _buildEditImageItem('CNIC Front', driver.cnicFrontUrl, front, Icons.badge),
        _buildEditImageItem('CNIC Back', driver.cnicBackUrl, back, Icons.badge_outlined),
        _buildEditImageItem('License', driver.licenseImageUrl, license, Icons.contact_page),
      ],
    );
  }

  Widget _buildEditImageItem(String label, String? networkUrl, ValueNotifier<Uint8List?> notifier, IconData icon) {
    return Column(
      children: [
        ValueListenableBuilder(
          valueListenable: notifier,
          builder: (context, bytes, _) => InkWell(
            onTap: () async {
              final picker = ImagePicker();
              final xFile = await picker.pickImage(source: ImageSource.gallery);
              if (xFile != null) {
                notifier.value = await xFile.readAsBytes();
              }
            },
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight, width: 2),
                image: bytes != null 
                    ? DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover)
                    : (networkUrl != null 
                        ? DecorationImage(image: CachedNetworkImageProvider(networkUrl), fit: BoxFit.cover)
                        : null),
              ),
              child: (bytes == null && networkUrl == null) ? Icon(icon, color: AppColors.textSecondary) : null,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildImagePickersRow(
    ValueNotifier<Uint8List?> profile, 
    ValueNotifier<Uint8List?> front, 
    ValueNotifier<Uint8List?> back, 
    ValueNotifier<Uint8List?> license
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildImagePickerItem('Profile', profile, Icons.account_circle),
        _buildImagePickerItem('CNIC Front', front, Icons.badge),
        _buildImagePickerItem('CNIC Back', back, Icons.badge_outlined),
        _buildImagePickerItem('License', license, Icons.contact_page),
      ],
    );
  }

  Widget _buildImagePickerItem(String label, ValueNotifier<Uint8List?> notifier, IconData icon) {
    return Column(
      children: [
        ValueListenableBuilder(
          valueListenable: notifier,
          builder: (context, bytes, _) => InkWell(
            onTap: () async {
              final picker = ImagePicker();
              final xFile = await picker.pickImage(source: ImageSource.gallery);
              if (xFile != null) {
                notifier.value = await xFile.readAsBytes();
              }
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
                image: bytes != null ? DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover) : null,
              ),
              child: bytes == null ? Icon(icon, color: AppColors.textSecondary) : null,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String label, 
    IconData icon, {
    bool isPassword = false,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      readOnly: readOnly,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppColors.primaryNavy),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, String label, DateTime selectedDate, Function(DateTime) onPick) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime.now().subtract(const Duration(days: 3650)),
          lastDate: DateTime.now().add(const Duration(days: 3650)),
        );
        if (date != null) onPick(date);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today, size: 20, color: AppColors.primaryNavy),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Text(
          "${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}",
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildTotalCountBadge() {
    final firebaseService = context.read<FirebaseService>();
    return StreamBuilder<List<DriverModel>>(
      stream: firebaseService.getDrivers(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.length : 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), border: Border.all(color: AppColors.borderLight)),
          child: Text('Total: $count', style: const TextStyle(fontWeight: FontWeight.bold)),
        );
      },
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }
  
  Widget _buildAddDriverButton(BuildContext context, DriversViewModel viewModel) {
    return ElevatedButton(
      onPressed: () => _showAddDriverDialog(context, viewModel),
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy, foregroundColor: Colors.white),
      child: const Text('Add Driver'),
    );
  }
}
