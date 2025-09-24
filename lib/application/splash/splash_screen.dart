import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'dart:io';
import 'package:mottinutnutriotinist/configuration/themes/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/services/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _retryCount = 0;
  bool _isCheckingConnection = false;
  bool _isInitializing = false;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    _initializeLocalNotifications();
    _initializeNotifications();
    _checkInternetConnection();
  }

  void _initializeLocalNotifications() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Tapped on notification: ${response.payload}');
      },
    );
  }

  Future<void> _initializeNotifications() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? fcmToken = await _firebaseMessaging.getToken();

        if (fcmToken != null) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          authProvider.setFcmToken(fcmToken);
          debugPrint('FCM Token: $fcmToken');
        }

        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
      }
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
    _showLocalNotification(message);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.loadNotificationHistory();
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    debugPrint('Background message: ${message.notification?.title}');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.loadNotificationHistory();
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'channel_id',
      'Notificaciones',
      channelDescription: 'Canal de notificaciones de la app',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
      color: Color(0xFF2EC4B6),
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(''),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title ?? 'Notificación',
      message.notification?.body ?? '',
      notificationDetails,
      payload: message.data['payload'] ?? '',
    );
  }

  Future<void> _checkInternetConnection() async {
    setState(() {
      _isCheckingConnection = true;
    });

    var connectivityResult = await (Connectivity().checkConnectivity());

    setState(() {
      _isCheckingConnection = false;
    });

    if (connectivityResult == ConnectivityResult.none) {
      _retryCount++;
      if (_retryCount < 3) {
        _showNoInternetDialog();
      } else {
        exit(0);
      }
    } else {
      await _initializeApp();
    }
  }

  Future<void> _initializeApp() async {
    if (_isInitializing) return;

    setState(() {
      _isInitializing = true;
    });

    try {
      // Esperar un poco para mostrar el splash
      await Future.delayed(const Duration(milliseconds: 2000));

      // ✅ FLUJO CORREGIDO: PRIMERO VERIFICAR ONBOARDING LOCAL
      final prefs = await SharedPreferences.getInstance();
      final onboardingSeen = prefs.getBool('onboarding_seen') ?? false;

      if (!onboardingSeen) {
        debugPrint('📱 Primera vez - Mostrando onboarding...');
        // Primera vez - mostrar onboarding
        Navigator.pushReplacementNamed(context, '/onboarding');
        return;
      }

      // ✅ ONBOARDING YA VISTO - VERIFICAR AUTENTICACIÓN
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.isAuthenticated) {
        debugPrint('✅ Usuario autenticado, navegando al home...');
        // Usuario ya está autenticado - ir directo al home
        Navigator.pushReplacementNamed(context, '/button_navigation');
      } else {
        debugPrint('🔐 Usuario no autenticado, navegando al login...');
        // Usuario no autenticado - ir al login
        Navigator.pushReplacementNamed(context, '/login');
      }

    } catch (e) {
      debugPrint('❌ Error en _initializeApp: $e');
      // En caso de error, mostrar onboarding por defecto
      Navigator.pushReplacementNamed(context, '/onboarding');
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  void _showNoInternetDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7.0),
        ),
        title: Text(
          'Sin Conexión de Internet',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.errorText,
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, color: AppColors.errorIcon, size: 50),
            SizedBox(height: 20),
            Text(
              'Por favor, verifica tu conexión a\n internet e intenta nuevamente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _checkInternetConnection();
            },
            style: TextButton.styleFrom(
              side: BorderSide(color: AppColors.primary, width: 2.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            ),
            child: Text(
              'Reintentar',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: AppColors.backgroundplash,
        systemNavigationBarIconBrightness: Brightness.light,
        statusBarColor: AppColors.backgroundplash,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.backgroundplash,
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/images/logos/mottinut_logo.svg',
                    width: 130,
                    height: 130,
                  ),
                ],
              ),
            ),
            if (_isInitializing || _isCheckingConnection)
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        _isCheckingConnection ? 'Verificando conexión...' : 'Inicializando...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}