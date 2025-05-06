import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth_check.dart';
// import 'dart:io' show Platform;
// import 'package:flutter/foundation.dart' show kDebugMode;
import 'utils/logger_util.dart';
import 'services/auth_service.dart';
import 'services/connectivity_service.dart';
import 'widgets/no_internet_dialog.dart';
// import 'screens/login_screen.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  try {
    LoggerUtil.info('Initializing Firebase...');
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyDCu_xwxG4_grimF6C5UX0E4QcJrizuLnQ',
        appId: '1:563465632369:android:bf99bf9472ae89b9ee39d0',
        messagingSenderId: '563465632369',
        projectId: 'campuscart-473e1',
        storageBucket: 'campuscart-473e1.appspot.com',
      ),
    );
    LoggerUtil.info('Firebase initialized successfully');

    // Create admin user if it doesn't exist
    try {
      LoggerUtil.info('Attempting to create admin user...');
      final authService = AuthService();

      // First check if admin exists
      final adminExists = await authService.isAdmin();
      LoggerUtil.info('Admin exists check: $adminExists');

      if (!adminExists) {
        LoggerUtil.info('Creating new admin user...');
        await authService.createAdminUser(
          'admin@store.com',
          'Admin@123',
          'Store Admin',
        );
        LoggerUtil.info('Admin user created successfully');
      } else {
        LoggerUtil.info('Admin user already exists');
      }

      LoggerUtil.info('Admin user setup completed');
    } catch (e) {
      LoggerUtil.error('Error in admin setup', e);
      LoggerUtil.error('Detailed admin creation error: ${e.toString()}');
    }
  } catch (e) {
    LoggerUtil.error('Error initializing Firebase', e);
    LoggerUtil.error('Firebase initialization error: ${e.toString()}');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ConnectivityService _connectivityService;
  bool _showNoInternetDialog = false;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _connectivityService = ConnectivityService();
    _checkInitialConnection();
    _listenToConnectivityChanges();
  }

  Future<void> _checkInitialConnection() async {
    final hasConnection = await _connectivityService.checkConnection();
    setState(() {
      _showNoInternetDialog = !hasConnection;
    });
  }

  void _listenToConnectivityChanges() {
    _connectivityService.connectivityStream.listen((hasConnection) {
      setState(() {
        _showNoInternetDialog = !hasConnection;
        if (hasConnection) {
          _isRetrying = false;
        }
      });
    });
  }

  Future<void> _retryConnection() async {
    setState(() {
      _isRetrying = true;
    });

    // Wait for 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    final hasConnection = await _connectivityService.checkConnection();

    if (mounted) {
      setState(() {
        _showNoInternetDialog = !hasConnection;
        _isRetrying = false;
      });
    }
  }

  @override
  void dispose() {
    _connectivityService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Cart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D3250)),
        useMaterial3: true,
      ),
      home: Stack(
        children: [
          const AuthCheck(),
          if (_showNoInternetDialog)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: NoInternetDialog(
                    onRetry: _retryConnection,
                    isRetrying: _isRetrying,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
