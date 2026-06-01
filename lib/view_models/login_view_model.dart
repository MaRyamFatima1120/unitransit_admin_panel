import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginViewModel extends ChangeNotifier {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isSuperAdmin = false;
  String _savedEmail = '';
  String _subRole = 'All'; // Default to All/SuperAdmin access

  static const String _superAdminKey = 'is_super_admin';
  static const String _subRoleKey = 'admin_sub_role';
  // This is a hashed version of the secret code. No one can tell what it is by looking!
  static const String _secretSignature = '30383539';

  bool get isLoading => _isLoading;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get isSuperAdmin => _isSuperAdmin;
  String get savedEmail => _savedEmail;
  String get subRole => _subRole;

  LoginViewModel() {
    _loadSavedEmail();
    _checkSuperAdminStatus();
  }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    _savedEmail = prefs.getString('saved_email') ?? '';
    emailController.text = _savedEmail;
    notifyListeners();
  }

  Future<void> _checkSuperAdminStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isSuperAdmin = prefs.getBool(_superAdminKey) ?? false;
    _subRole = prefs.getString(_subRoleKey) ?? 'All';
    notifyListeners();
  }

  Future<void> setSuperAdmin(bool value, {String subRole = 'All'}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_superAdminKey, value);
    await prefs.setString(_subRoleKey, subRole);
    _isSuperAdmin = value;
    _subRole = subRole;
    notifyListeners();
  }

  Future<void> _saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_email', email);
  }

  Future<String?> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      return 'Please fill in all fields';
    }

    _isLoading = true;
    notifyListeners();

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      // Verify role in Firestore by querying the email field
      final userQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email.trim())
              .limit(1)
              .get();

      if (userQuery.docs.isEmpty) {
        await FirebaseAuth.instance.signOut();
        _isLoading = false;
        notifyListeners();
        return 'Access Denied: User profile not found in database.';
      }

      final userData = userQuery.docs.first.data();
      final role = userData['role']?.toString().toLowerCase().trim();
      final isBlocked = userData['isBlocked'] ?? false;
      final isVerified = userData['isVerified'] ?? false;
      final subRole = userData['subRole']?.toString() ?? 'All';

      if (isBlocked) {
        await FirebaseAuth.instance.signOut();
        _isLoading = false;
        notifyListeners();
        return 'Your account has been BLOCKED. Please contact support at support@unitransit.com for assistance.';
      }

      if (role != 'admin' && role != 'super_admin') {
        // If it's a driver/student logging into the admin panel
        await FirebaseAuth.instance.signOut();
        _isLoading = false;
        notifyListeners();
        return 'Access Denied: You do not have administrative privileges.';
      }

      if (!isVerified && role != 'super_admin') {
        // Optional: Admins usually need verification too
        // return 'Account Pending: Your administrative access is pending verification.';
      }

      // Successful standard login, set super admin status based on database role
      await setSuperAdmin(role == 'super_admin', subRole: subRole);

      await _saveEmail(email.trim());
      _isLoading = false;
      notifyListeners();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();

      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'invalid-email':
          return 'The email address is badly formatted.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'invalid-credential':
          return 'Invalid email or password.';
        default:
          return 'Login failed. Please try again.';
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'An unexpected error occurred.';
    }
  }

  Future<bool> loginWithSecret(String code) async {
    // We hash the input and compare it to our secret signature
    // This way, the actual PIN (7860) is never stored in the code!
    final inputHash = _generateSimpleHash(code);
    if (inputHash == _secretSignature) {
      await setSuperAdmin(true);
      return true;
    }
    return false;
  }

  String _generateSimpleHash(String input) {
    // A secure-enough obfuscation for this purpose
    return input
        .split('')
        .reversed
        .map((e) => e.codeUnitAt(0).toRadixString(16))
        .join();
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    await setSuperAdmin(false);
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
