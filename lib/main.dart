import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unitransit_admin/core/theme/app_theme.dart';
import 'package:unitransit_admin/firebase_options.dart';
import 'package:unitransit_admin/core/services/firebase_service.dart';
import 'package:unitransit_admin/view_models/dashboard_view_model.dart';
import 'package:unitransit_admin/view_models/route_planning_view_model.dart';
import 'package:unitransit_admin/view_models/drivers_view_model.dart';
import 'package:unitransit_admin/view_models/students_view_model.dart';
import 'package:unitransit_admin/view_models/gender_config_view_model.dart';
import 'package:unitransit_admin/view_models/support_view_model.dart';
import 'package:unitransit_admin/view_models/app_settings_view_model.dart';
import 'package:unitransit_admin/view_models/login_view_model.dart';
import 'package:unitransit_admin/view_models/notifications_view_model.dart';
import 'package:unitransit_admin/view_models/fleet_operations_view_model.dart';
import 'package:unitransit_admin/view_models/buses_view_model.dart';
import 'package:unitransit_admin/views/login_screen.dart';
import 'package:unitransit_admin/views/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Upload initial "About" info to Firebase if it doesn't exist
  FirebaseService().uploadInitialAppInfo();

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => FirebaseService()),
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => DashboardViewModel()),
        ChangeNotifierProvider(
          create:
              (context) => RoutePlanningViewModel(
                Provider.of<FirebaseService>(context, listen: false),
              ),
        ),
        ChangeNotifierProvider(
          create:
              (context) => DriversViewModel(
                Provider.of<FirebaseService>(context, listen: false),
              ),
        ),
        ChangeNotifierProvider(
          create:
              (context) => StudentsViewModel(
                Provider.of<FirebaseService>(context, listen: false),
              ),
        ),
        ChangeNotifierProvider(
          create:
              (context) => GenderConfigViewModel(
                Provider.of<FirebaseService>(context, listen: false),
              ),
        ),
        ChangeNotifierProvider(
          create:
              (context) => SupportViewModel(
                Provider.of<FirebaseService>(context, listen: false),
              ),
        ),
        ChangeNotifierProvider(
          create:
              (context) => AppSettingsViewModel(
                Provider.of<FirebaseService>(context, listen: false),
              ),
        ),
        ChangeNotifierProvider(
          create:
              (context) => NotificationsViewModel(
                Provider.of<FirebaseService>(context, listen: false),
              ),
        ),
        ChangeNotifierProvider(create: (_) => FleetOperationsViewModel()),
        ChangeNotifierProvider(create: (_) => BusesViewModel()),
      ],
      child: const AdminPanelApp(),
    ),
  );
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

class AdminPanelApp extends StatelessWidget {
  const AdminPanelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SessionTimeoutWrapper(
      child: Consumer<AppSettingsViewModel>(
        builder: (context, viewModel, child) {
          return MaterialApp(
            title: 'Uni-Transit Admin',
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            scrollBehavior: MyCustomScrollBehavior(),
            theme: AppTheme.createTheme(
              primaryHex: viewModel.adminPrimaryColor,
              accentHex: viewModel.adminAccentColor,
              backgroundHex: viewModel.adminBackgroundColor,
              cardHex: viewModel.adminCardColor,
              textPrimaryHex: viewModel.adminTextPrimaryColor,
              textSecondaryHex: viewModel.adminTextSecondaryColor,
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

class SessionTimeoutWrapper extends StatefulWidget {
  final Widget child;
  const SessionTimeoutWrapper({super.key, required this.child});

  @override
  State<SessionTimeoutWrapper> createState() => _SessionTimeoutWrapperState();
}

class _SessionTimeoutWrapperState extends State<SessionTimeoutWrapper> {
  Timer? _timer;
  static const _timeoutDuration = Duration(minutes: 30);

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(_timeoutDuration, _handleTimeout);
  }

  void _handleTimeout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseAuth.instance.signOut();
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      // Show a snackbar or dialog if possible (optional)
    }
  }

  void _handleUserInteraction([_]) {
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handleUserInteraction,
      onPointerMove: _handleUserInteraction,
      onPointerHover: _handleUserInteraction,
      onPointerSignal: _handleUserInteraction,
      child: widget.child,
    );
  }
}
