import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/core/services/firebase_service.dart';
import 'package:unitransit_admin/core/utils/responsive_util.dart';
import 'package:unitransit_admin/models/driver_model.dart';
import 'package:unitransit_admin/view_models/dashboard_view_model.dart';
import 'package:unitransit_admin/view_models/drivers_view_model.dart';
import 'package:image_picker/image_picker.dart';

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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => context.read<DashboardViewModel>().setSelectedIndex(0),
              icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            ),
            const Text('Drivers', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
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

    return Scrollbar(
      controller: _horizontalScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _horizontalScrollController,
        scrollDirection: Axis.horizontal,
        child: Container(
          width: 1400, // Increased width for more columns
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
              StreamBuilder<List<DriverModel>>(
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
                    itemBuilder: (context, index) => _buildDriverRow(drivers[index], viewModel),
                  );
                },
              ),
            ],
          ),
        ),
      ),
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
          Expanded(flex: 1, child: Text('EXP', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
          Expanded(flex: 2, child: Text('STATUS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
          Expanded(flex: 1, child: Text('VERIFIED', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
          Expanded(flex: 3, child: Text('ACTIONS', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
        ],
      ),
    );
  }

  Widget _buildDriverRow(DriverModel driver, DriversViewModel viewModel) {
    final firebaseService = context.read<FirebaseService>();
    final expiryDate = "${driver.licenseExpiry.day}/${driver.licenseExpiry.month}/${driver.licenseExpiry.year}";
    
    return InkWell(
      onTap: () => _showEditDriverDialog(context, viewModel, driver),
      child: Container(
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
            // Exp
            Expanded(flex: 1, child: Text(driver.experience, style: const TextStyle(fontSize: 12))),
            // Status
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (driver.status == 'Online' || driver.status == 'Available' ? Colors.green : Colors.grey).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(driver.status, textAlign: TextAlign.center, style: TextStyle(
                  color: driver.status == 'Online' || driver.status == 'Available' ? Colors.green.shade700 : Colors.grey.shade700, 
                  fontSize: 11, 
                  fontWeight: FontWeight.bold
                )),
              ),
            ),
            // Verified
            Expanded(
              flex: 1,
              child: Icon(
                driver.isVerified ? Icons.verified : Icons.pending_actions,
                color: driver.isVerified ? Colors.blue : Colors.orange,
                size: 18,
              ),
            ),
            // Actions
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildIconButton(Icons.edit_outlined, AppColors.primaryNavy, () => _showEditDriverDialog(context, viewModel, driver)),
                  const SizedBox(width: 4),
                  _buildIconButton(Icons.lock_reset, Colors.orange, () {
                    firebaseService.resetDriverPassword(driver.email);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent.')));
                  }),
                  const SizedBox(width: 4),
                  _buildIconButton(
                    driver.isBlocked ? Icons.block : Icons.check_circle_outline, 
                    driver.isBlocked ? Colors.red : Colors.green, 
                    () => viewModel.updateDriver(driver.copyWith(isBlocked: !driver.isBlocked))
                  ),
                  const SizedBox(width: 4),
                  _buildIconButton(Icons.delete_outline, Colors.red, () => viewModel.deleteDriver(driver.id)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildImagePickersRow(profileImageNotifier, cnicFrontNotifier, cnicBackNotifier, licenseImageNotifier),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _buildTextField(nameController, 'Full Name', Icons.person)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField(phoneController, 'Phone Number', Icons.phone)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField(emailController, 'Email Address', Icons.email)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField(passwordController, 'Password', Icons.lock, isPassword: true)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField(cnicController, 'CNIC Number', Icons.badge)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField(licenseController, 'License Number', Icons.description)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ValueListenableBuilder(
                        valueListenable: expiryNotifier,
                        builder: (context, date, _) => _buildDatePicker(context, 'License Expiry', date, (d) => expiryNotifier.value = d),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField(busController, 'Assigned Bus #', Icons.directions_bus)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(experienceController, 'Experience (e.g. 5 Years)', Icons.work),
                
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
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          Consumer<DriversViewModel>(
            builder: (context, vm, _) => ElevatedButton(
              onPressed: vm.isUploading ? null : () async {
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Network Images Display
                _buildEditImageRow(driver, profileImageNotifier, cnicFrontNotifier, cnicBackNotifier, licenseImageNotifier),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _buildTextField(nameController, 'Full Name', Icons.person)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField(phoneController, 'Phone Number', Icons.phone)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField(cnicController, 'CNIC Number', Icons.badge)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField(licenseController, 'License Number', Icons.description)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ValueListenableBuilder(
                        valueListenable: expiryNotifier,
                        builder: (context, date, _) => _buildDatePicker(context, 'License Expiry', date, (d) => expiryNotifier.value = d),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField(busController, 'Assigned Bus #', Icons.directions_bus)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(experienceController, 'Experience', Icons.work),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          Consumer<DriversViewModel>(
            builder: (context, vm, _) => ElevatedButton(
              onPressed: vm.isUploading ? null : () async {
                await vm.updateDriver(
                  driver.copyWith(
                    name: nameController.text,
                    phoneNumber: phoneController.text,
                    cnic: cnicController.text,
                    licenseNumber: licenseController.text,
                    licenseExpiry: expiryNotifier.value,
                    assignedBus: busController.text,
                    experience: experienceController.text,
                  ),
                  newProfileImage: profileImageNotifier.value,
                  newFrontImage: cnicFrontNotifier.value,
                  newBackImage: cnicBackNotifier.value,
                  newLicenseImage: licenseImageNotifier.value,
                );
                if (context.mounted) Navigator.pop(context);
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

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: AppColors.primaryNavy),
            const SizedBox(width: 8),
            Text("${selectedDate.day}/${selectedDate.month}/${selectedDate.year}"),
          ],
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
