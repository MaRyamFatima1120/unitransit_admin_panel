import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/views/dashboard_screen.dart';
import 'package:unitransit_admin/views/forgot_password_screen.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:unitransit_admin/view_models/login_view_model.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _handleLogin(BuildContext context, LoginViewModel viewModel) async {
    final errorMessage = await viewModel.login();
    if (errorMessage != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } else {
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    }
  }

  void _showSecretLogin(BuildContext context, LoginViewModel viewModel) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Master Access'),
        content: TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) async {
            final success = await viewModel.loginWithSecret(pinController.text);
            if (context.mounted) {
              Navigator.pop(context);
              if (success) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const DashboardScreen()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid PIN')),
                );
              }
            }
          },
          decoration: const InputDecoration(hintText: 'Enter Secret PIN'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final success = await viewModel.loginWithSecret(pinController.text);
              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const DashboardScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid PIN')),
                  );
                }
              }
            },
            child: const Text('Access'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LoginViewModel>();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: ResponsiveBuilder(
        builder: (context, sizingInformation) {
          if (sizingInformation.isDesktop) return _buildDesktopLayout(context, viewModel);
          if (sizingInformation.isTablet) return _buildTabletLayout(context, viewModel);
          return _buildMobileLayout(context, viewModel);
        },
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, LoginViewModel viewModel) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Container(
            color: theme.primaryColor,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_bus_rounded, size: 80, color: theme.colorScheme.secondary),
                  const SizedBox(height: 24),
                  const Text('Uni-Transit', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: SingleChildScrollView(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 40), child: _buildLoginForm(context, viewModel))),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, LoginViewModel viewModel) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: Container(
            color: theme.primaryColor,
            child: Stack(
              children: [
                Positioned(
                  top: -100, left: -100,
                  child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05))),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(24)),
                        child: Icon(Icons.directions_bus_rounded, size: 100, color: theme.colorScheme.secondary),
                      ),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onLongPress: () => _showSecretLogin(context, viewModel),
                        child: const Text('Uni-Transit Admin', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(height: 16),
                      Text('Manage your fleet, routes, and users\nall in one powerful dashboard.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 18)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 80), child: _buildLoginForm(context, viewModel)),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, LoginViewModel viewModel) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const SizedBox(height: 60),
            Icon(Icons.directions_bus_rounded, size: 64, color: theme.primaryColor),
            const SizedBox(height: 24),
            GestureDetector(
              onLongPress: () => _showSecretLogin(context, viewModel),
              child: const Text('Welcome Back', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            ),
            const SizedBox(height: 40),
            _buildLoginForm(context, viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, LoginViewModel viewModel) {
    final theme = Theme.of(context);
    return AutofillGroup(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Login', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 8),
          const Text('Please enter your credentials to access the panel.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          const SizedBox(height: 48),
          const Text('Email Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: viewModel.emailController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: 'name@company.com',
              prefixIcon: const Icon(Icons.email_outlined),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ForgotPasswordScreen())),
                child: Text('Forgot Password?', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: viewModel.passwordController,
            obscureText: !viewModel.isPasswordVisible,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleLogin(context, viewModel),
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(icon: Icon(viewModel.isPasswordVisible ? Icons.visibility_off : Icons.visibility), onPressed: viewModel.togglePasswordVisibility),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: viewModel.isLoading ? null : () => _handleLogin(context, viewModel),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: viewModel.isLoading
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
