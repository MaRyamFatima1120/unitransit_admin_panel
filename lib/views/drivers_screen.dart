import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/core/services/firebase_service.dart';
import 'package:unitransit_admin/core/utils/responsive_util.dart';
import 'package:unitransit_admin/models/driver_model.dart';
import 'package:unitransit_admin/view_models/dashboard_view_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class DriversScreen extends StatefulWidget {
  const DriversScreen({super.key});

  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  String _selectedTab = 'All';
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  final List<String> _tabs = ['All', 'Available', 'un-Available', 'Verified', 'Non-Verified'];

  void _showAddDriverDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final cnicController = TextEditingController();
    final licenseController = TextEditingController();
    final busController = TextEditingController();
    final experienceController = TextEditingController();
    DateTime? selectedExpiry;
    
    Uint8List? profileImageBytes;
    Uint8List? frontImageBytes;
    Uint8List? backImageBytes;
    Uint8List? licenseImageBytes;
    bool isUploading = false;
    String? dialogError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Professional Driver', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            controller: ScrollController(),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Profile Picture Picker
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.backgroundLight,
                          backgroundImage: profileImageBytes != null ? MemoryImage(profileImageBytes!) : null,
                          child: profileImageBytes == null ? const Icon(Icons.person, size: 50, color: AppColors.textSecondary) : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: () async {
                              final picker = ImagePicker();
                              final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
                              if (image != null) {
                                final bytes = await image.readAsBytes();
                                setState(() => profileImageBytes = bytes);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: AppColors.primaryNavy, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildTextField(nameController, 'Full Name', Icons.person),
                  _buildTextField(phoneController, 'Phone Number', Icons.phone, keyboardType: TextInputType.phone),
                  _buildTextField(emailController, 'Email Address', Icons.email, keyboardType: TextInputType.emailAddress),
                  _buildTextField(passwordController, 'Password', Icons.lock, isPassword: true),
                  _buildTextField(cnicController, 'CNIC (National ID)', Icons.badge),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('CNIC Images (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildImagePicker(
                          label: 'Front Side',
                          imageBytes: frontImageBytes,
                          onTap: () async {
                            final picker = ImagePicker();
                            final image = await picker.pickImage(source: ImageSource.gallery);
                            if (image != null) {
                              final bytes = await image.readAsBytes();
                              setState(() => frontImageBytes = bytes);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildImagePicker(
                          label: 'Back Side',
                          imageBytes: backImageBytes,
                          onTap: () async {
                            final picker = ImagePicker();
                            final image = await picker.pickImage(source: ImageSource.gallery);
                            if (image != null) {
                              final bytes = await image.readAsBytes();
                              setState(() => backImageBytes = bytes);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(licenseController, 'Driving License Number', Icons.card_membership),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(selectedExpiry == null 
                      ? 'License Expiry Date' 
                      : 'Expiry: ${selectedExpiry!.day}/${selectedExpiry!.month}/${selectedExpiry!.year}'),
                    trailing: const Icon(Icons.calendar_today, color: AppColors.primaryNavy),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 365)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (picked != null) setState(() => selectedExpiry = picked);
                    },
                  ),
                  _buildTextField(busController, 'Assigned Bus Number', Icons.directions_bus),
                  _buildTextField(experienceController, 'Years of Experience', Icons.history),
                  const SizedBox(height: 16),
                  
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Driving License Document', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  const SizedBox(height: 8),
                  _buildLicensePicker(
                    imageBytes: licenseImageBytes,
                    onTap: () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                      if (image != null) {
                        final bytes = await image.readAsBytes();
                        setState(() => licenseImageBytes = bytes);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  if (dialogError != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                      child: Text(dialogError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: isUploading ? null : () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy, foregroundColor: Colors.white),
              onPressed: isUploading ? null : () async {
                if (formKey.currentState!.validate() && selectedExpiry != null) {
                  setState(() {
                    isUploading = true;
                    dialogError = null;
                  });
                  try {
                    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
                    final driverId = FirebaseFirestore.instance.collection('drivers').doc().id;
                    
                    String? profileUrl;
                    String? frontUrl;
                    String? backUrl;
                    String? licenseUrl;

                    if (profileImageBytes != null) {
                      profileUrl = await firebaseService.uploadImage(profileImageBytes!, 'drivers/$driverId/profile.jpg');
                    }
                    if (frontImageBytes != null) {
                      frontUrl = await firebaseService.uploadImage(frontImageBytes!, 'drivers/$driverId/cnic_front.jpg');
                    }
                    if (backImageBytes != null) {
                      backUrl = await firebaseService.uploadImage(backImageBytes!, 'drivers/$driverId/cnic_back.jpg');
                    }
                    if (licenseImageBytes != null) {
                      licenseUrl = await firebaseService.uploadImage(licenseImageBytes!, 'drivers/$driverId/license.jpg');
                    }

                    // 1. Create Driver Auth Account
                    print("Attempting to create Auth account for: ${emailController.text}");
                    await firebaseService.createDriverAuth(emailController.text, passwordController.text);
                    print("Auth account created successfully.");

                    // 2. Save Driver Data to Firestore
                    print("Saving driver data to Firestore...");
                    final newDriver = DriverModel(
                      id: driverId,
                      name: nameController.text,
                      phoneNumber: phoneController.text,
                      email: emailController.text,
                      cnic: cnicController.text,
                      licenseNumber: licenseController.text,
                      licenseExpiry: selectedExpiry!,
                      assignedBus: busController.text,
                      experience: experienceController.text,
                      status: 'Offline',
                      profileUrl: profileUrl,
                      cnicFrontUrl: frontUrl,
                      cnicBackUrl: backUrl,
                      licenseImageUrl: licenseUrl,
                      isVerified: false,
                      createdAt: DateTime.now(),
                    );

                    await firebaseService.addDriver(newDriver);
                    print("Driver added to Firestore 'drivers' collection.");

                    // 3. Save to main 'users' collection for login role management
                    print("Saving to main 'users' collection...");
                    await FirebaseFirestore.instance.collection('users').doc(driverId).set({
                      'uid': driverId,
                      'name': nameController.text,
                      'email': emailController.text,
                      'role': 'driver',
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    print("User added to 'users' collection successfully.");

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Driver Added Successfully!'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    print("CRITICAL ERROR adding driver: $e");
                    String friendlyMessage = e.toString();
                    
                    if (friendlyMessage.contains('weak-password')) {
                      friendlyMessage = "The password is too weak. Please use at least 6 characters.";
                    } else if (friendlyMessage.contains('email-already-in-use')) {
                      friendlyMessage = "This email is already registered to another driver.";
                    } else if (friendlyMessage.contains('invalid-email')) {
                      friendlyMessage = "The email address format is invalid.";
                    } else if (friendlyMessage.contains('unauthorized')) {
                      friendlyMessage = "Permission Denied: Please update your Firebase Storage Rules.";
                    }

                    setState(() => dialogError = friendlyMessage);
                  } finally {
                    setState(() => isUploading = false);
                  }
                } else if (selectedExpiry == null) {
                  setState(() => dialogError = 'Please select license expiry date');
                }
              },
              child: isUploading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Text('Add Driver'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker({required String label, Uint8List? imageBytes, String? imageUrl, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: imageBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(imageBytes, fit: BoxFit.cover),
              )
            : imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(imageUrl, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo_outlined, color: AppColors.textSecondary),
                      const SizedBox(height: 4),
                      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType, bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: AppColors.primaryNavy),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Required';
          if (isPassword && value.length < 6) return 'Password must be at least 6 characters';
          return null;
        },
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
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.read<DashboardViewModel>().setSelectedIndex(0),
                  icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                ),
                Text(
                  'Drivers',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            _buildTotalCountBadge(firebaseService),
          ],
        ),
        const SizedBox(height: 24),
        
        // Main Content Card
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                // Tabs & Search
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _tabs.map((tab) => _buildTab(tab)).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildAddDriverButton(context),
                        ],
                      ),
                    ],
                  ),
                ),

                // Table Header & Content
                Expanded(
                  child: Scrollbar(
                    controller: _horizontalScrollController,
                    thumbVisibility: true,
                    thickness: 6,
                    radius: const Radius.circular(10),
                    child: SingleChildScrollView(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 1000,
                        child: Column(
                          children: [
                            // Table Header
                            Container(
                              color: AppColors.primaryNavy.withOpacity(0.05),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              child: const Row(
                                children: [
                                  Expanded(flex: 2, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryNavy))),
                                  Expanded(flex: 3, child: Text('Contact Info', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryNavy))),
                                  Expanded(flex: 2, child: Text('Availability', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryNavy))),
                                  Expanded(flex: 1, child: Text('Verification', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryNavy))),
                                  Expanded(flex: 4, child: Text('', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryNavy))),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            // Table Content
                            Expanded(
                              child: StreamBuilder<List<DriverModel>>(
                                stream: firebaseService.getDrivers(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                    return const Center(child: Text('No drivers found.'));
                                  }

                                  var drivers = snapshot.data!;
                                  
                                  // Apply Filters
                                  if (_selectedTab != 'All') {
                                    drivers = drivers.where((d) {
                                      if (_selectedTab == 'Available') return d.status == 'Online' || d.status == 'Available';
                                      if (_selectedTab == 'un-Available') return d.status == 'Offline' || d.status == 'Busy';
                                      if (_selectedTab == 'Verified') return d.isVerified;
                                      if (_selectedTab == 'Non-Verified') return !d.isVerified;
                                      return true;
                                    }).toList();
                                  }

                                  // Apply Search
                                  final searchQuery = context.watch<DashboardViewModel>().searchQuery;
                                  if (searchQuery.isNotEmpty) {
                                    drivers = drivers.where((d) => 
                                      d.name.toLowerCase().contains(searchQuery.toLowerCase()) || 
                                      d.email.toLowerCase().contains(searchQuery.toLowerCase()) ||
                                      d.phoneNumber.contains(searchQuery)
                                    ).toList();
                                  }

                                  return ListView.separated(
                                    controller: _verticalScrollController,
                                    primary: false,
                                    itemCount: drivers.length,
                                    separatorBuilder: (context, index) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final driver = drivers[index];
                                      return _buildDriverRow(driver, firebaseService);
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildTotalCountBadge(FirebaseService firebaseService) {
    return StreamBuilder<List<DriverModel>>(
      stream: firebaseService.getDrivers(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.length : 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people, color: Colors.purple.shade300, size: 20),
              const SizedBox(width: 8),
              Text(
                'Total drivers: ',
                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
              Text(
                '$count',
                style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchButton() {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      ),
      child: const Text('Search'),
    );
  }

  Widget _buildAddDriverButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _showAddDriverDialog(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      ),
      child: const Text('Add Driver'),
    );
  }

  Widget _buildTab(String label) {
    bool isSelected = _selectedTab == label;
    return InkWell(
      onTap: () => setState(() => _selectedTab = label),
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

  Widget _buildDriverRow(DriverModel driver, FirebaseService firebaseService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.backgroundLight),
                  child: ClipOval(
                    child: driver.profileUrl != null
                        ? Image.network(
                            driver.profileUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print("Image load error: $error");
                              return const Icon(Icons.person, size: 20, color: AppColors.textSecondary);
                            },
                          )
                        : const Icon(Icons.person, size: 20, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 12),
                Text(driver.name, style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Expanded(flex: 3, child: Text(driver.email.isEmpty ? driver.phoneNumber : driver.email, style: TextStyle(color: Colors.grey.shade600))),
          Expanded(
            flex: 2,
            child: Text(
              driver.isBlocked ? 'Blocked' : driver.status,
              style: TextStyle(
                color: driver.isBlocked ? Colors.red : ((driver.status == 'Online' || driver.status == 'Available') ? Colors.green : Colors.grey),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Checkbox(
              value: driver.isVerified,
              activeColor: AppColors.primaryNavy,
              onChanged: (val) {
                final updated = DriverModel(
                  id: driver.id,
                  name: driver.name,
                  phoneNumber: driver.phoneNumber,
                  email: driver.email,
                  cnic: driver.cnic,
                  licenseNumber: driver.licenseNumber,
                  licenseExpiry: driver.licenseExpiry,
                  assignedBus: driver.assignedBus,
                  experience: driver.experience,
                  status: driver.status,
                  cnicFrontUrl: driver.cnicFrontUrl,
                  cnicBackUrl: driver.cnicBackUrl,
                  isVerified: val ?? false,
                  createdAt: driver.createdAt,
                );
                firebaseService.updateDriver(updated);
              },
            ),
          ),
          Expanded(
            flex: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionButton('Edit', AppColors.actionView, () => _showEditDriverDialog(context, driver)),
                const SizedBox(width: 8),
                _buildActionButton(
                  driver.isBlocked ? 'Unblock' : 'Block', 
                  driver.isBlocked ? Colors.green : AppColors.actionBlock, 
                  () {
                    final updated = DriverModel(
                      id: driver.id,
                      name: driver.name,
                      phoneNumber: driver.phoneNumber,
                      email: driver.email,
                      cnic: driver.cnic,
                      licenseNumber: driver.licenseNumber,
                      licenseExpiry: driver.licenseExpiry,
                      assignedBus: driver.assignedBus,
                      experience: driver.experience,
                      status: driver.status,
                      profileUrl: driver.profileUrl,
                      cnicFrontUrl: driver.cnicFrontUrl,
                      cnicBackUrl: driver.cnicBackUrl,
                      licenseImageUrl: driver.licenseImageUrl,
                      isVerified: driver.isVerified,
                      isBlocked: !driver.isBlocked,
                      createdAt: driver.createdAt,
                    );
                    firebaseService.updateDriver(updated);
                  }
                ),
                const SizedBox(width: 8),
                _buildActionButton('Delete', AppColors.actionDelete, () => firebaseService.deleteDriver(driver.id)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDriverDialog(BuildContext context, DriverModel driver) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: driver.name);
    final phoneController = TextEditingController(text: driver.phoneNumber);
    final emailController = TextEditingController(text: driver.email);
    final cnicController = TextEditingController(text: driver.cnic);
    final licenseController = TextEditingController(text: driver.licenseNumber);
    final busController = TextEditingController(text: driver.assignedBus);
    final experienceController = TextEditingController(text: driver.experience);
    DateTime? selectedExpiry = driver.licenseExpiry;
    
    Uint8List? profileImageBytes;
    Uint8List? frontImageBytes;
    Uint8List? backImageBytes;
    Uint8List? licenseImageBytes;
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Driver Profile', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            controller: ScrollController(),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Profile Picture
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.backgroundLight,
                          backgroundImage: profileImageBytes != null 
                              ? MemoryImage(profileImageBytes!) 
                              : (driver.profileUrl != null ? NetworkImage(driver.profileUrl!) : null) as ImageProvider?,
                          child: profileImageBytes == null && driver.profileUrl == null 
                              ? const Icon(Icons.person, size: 50, color: AppColors.textSecondary) 
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: () async {
                              final picker = ImagePicker();
                              final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
                              if (image != null) {
                                final bytes = await image.readAsBytes();
                                setState(() => profileImageBytes = bytes);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: AppColors.primaryNavy, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildTextField(nameController, 'Full Name', Icons.person),
                  _buildTextField(phoneController, 'Phone Number', Icons.phone, keyboardType: TextInputType.phone),
                  _buildTextField(emailController, 'Email Address', Icons.email, keyboardType: TextInputType.emailAddress),
                  _buildTextField(cnicController, 'CNIC (National ID)', Icons.badge),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('CNIC Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryNavy)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildImagePicker(
                          label: 'CNIC Front',
                          imageBytes: frontImageBytes,
                          imageUrl: driver.cnicFrontUrl,
                          onTap: () async {
                            final picker = ImagePicker();
                            final image = await picker.pickImage(source: ImageSource.gallery);
                            if (image != null) {
                              final bytes = await image.readAsBytes();
                              setState(() => frontImageBytes = bytes);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildImagePicker(
                          label: 'CNIC Back',
                          imageBytes: backImageBytes,
                          imageUrl: driver.cnicBackUrl,
                          onTap: () async {
                            final picker = ImagePicker();
                            final image = await picker.pickImage(source: ImageSource.gallery);
                            if (image != null) {
                              final bytes = await image.readAsBytes();
                              setState(() => backImageBytes = bytes);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildTextField(licenseController, 'Driving License Number', Icons.card_membership),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Driving License Document', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryNavy)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildLicensePicker(
                    imageBytes: licenseImageBytes,
                    imageUrl: driver.licenseImageUrl,
                    onTap: () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                      if (image != null) {
                        final bytes = await image.readAsBytes();
                        setState(() => licenseImageBytes = bytes);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('License Expiry Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryNavy)),
                    subtitle: Text('${selectedExpiry!.day}/${selectedExpiry!.month}/${selectedExpiry!.year}', style: const TextStyle(fontSize: 16)),
                    trailing: const Icon(Icons.calendar_today, color: AppColors.primaryNavy),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedExpiry!,
                        firstDate: DateTime.now().subtract(const Duration(days: 3650)),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (picked != null) setState(() => selectedExpiry = picked);
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Vehicle Assignment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryNavy)),
                    ),
                  ),
                  _buildTextField(busController, 'Assigned Bus Number', Icons.directions_bus),
                  _buildTextField(experienceController, 'Years of Experience', Icons.history),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: isUploading ? null : () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy, foregroundColor: Colors.white),
              onPressed: isUploading ? null : () async {
                if (formKey.currentState!.validate()) {
                  setState(() => isUploading = true);
                  try {
                    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
                    
                    String? profileUrl = driver.profileUrl;
                    String? frontUrl = driver.cnicFrontUrl;
                    String? backUrl = driver.cnicBackUrl;
                    String? licenseUrl = driver.licenseImageUrl;

                    if (profileImageBytes != null) {
                      profileUrl = await firebaseService.uploadImage(profileImageBytes!, 'drivers/${driver.id}/profile.jpg');
                    }
                    if (frontImageBytes != null) {
                      frontUrl = await firebaseService.uploadImage(frontImageBytes!, 'drivers/${driver.id}/cnic_front.jpg');
                    }
                    if (backImageBytes != null) {
                      backUrl = await firebaseService.uploadImage(backImageBytes!, 'drivers/${driver.id}/cnic_back.jpg');
                    }
                    if (licenseImageBytes != null) {
                      licenseUrl = await firebaseService.uploadImage(licenseImageBytes!, 'drivers/${driver.id}/license.jpg');
                    }

                    final updatedDriver = DriverModel(
                      id: driver.id,
                      name: nameController.text,
                      phoneNumber: phoneController.text,
                      email: emailController.text,
                      cnic: cnicController.text,
                      licenseNumber: licenseController.text,
                      licenseExpiry: selectedExpiry!,
                      assignedBus: busController.text,
                      experience: experienceController.text,
                      status: driver.status,
                      profileUrl: profileUrl,
                      cnicFrontUrl: frontUrl,
                      cnicBackUrl: backUrl,
                      licenseImageUrl: licenseUrl,
                      isVerified: driver.isVerified,
                      isBlocked: driver.isBlocked,
                      createdAt: driver.createdAt,
                    );

                    await firebaseService.updateDriver(updatedDriver);
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
                    }
                  } finally {
                    setState(() => isUploading = false);
                  }
                }
              },
              child: isUploading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Text('Update Driver'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildLicensePicker({Uint8List? imageBytes, String? imageUrl, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight, width: 2),
        ),
        child: imageBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(imageBytes, fit: BoxFit.cover),
              )
            : imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(imageUrl, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.document_scanner_outlined, size: 40, color: AppColors.primaryNavy.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      const Text(
                        'Tap to Upload Driving License',
                        style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
      ),
    );
  }
}
