import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'dart:io';

import 'package:mottinutnutriotinist/configuration/themes/app_colors.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _retryCount = 0;
  bool _isCheckingConnection = false;

  @override
  void initState() {
    super.initState();

    // Configuración para barras transparentes con iconos negros
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      // Barra de navegación transparente con iconos negros
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      // Barra de estado transparente con iconos negros
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Hacer que la app se extienda detrás de las barras del sistema
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );

    _checkInternetConnection();
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
      _navigateToLogin();
    }
  }

  void _showNoInternetDialog() {
    showDialog(
      context: context,
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

  void _navigateToLogin() {
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundplash,
      // Extender el contenido detrás de las barras del sistema
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: SafeArea(
        // Si quieres que el contenido no se sobreponga con las barras
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/images/logos/mottinut_logo.svg',
                  ),
                ],
              ),
            ),
            if (_isCheckingConnection)
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Center(
                  child: Lottie.asset(
                    'assets/loading/infinity_cyan.json',
                    width: 60,
                    height: 60,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}