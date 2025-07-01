import 'dart:async';
import 'dart:developer' as developer;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

// Configuración de pruebas de velocidad
class SpeedTestConfig {
  final Duration checkInterval;
  final Duration timeout;
  final List<String> testUrls;
  final int maxRetries;
  final Duration initialRetryDelay;
  final double retryBackoffMultiplier;

  const SpeedTestConfig({
    this.checkInterval = const Duration(minutes: 1),
    this.timeout = const Duration(seconds: 10),
    this.testUrls = const [
      'https://www.google.com',
      'https://www.cloudflare.com',
      'https://www.amazon.com',
      'https://www.microsoft.com'
    ],
    this.maxRetries = 3,
    this.initialRetryDelay = const Duration(seconds: 2),
    this.retryBackoffMultiplier = 1.5,
  });
}

class NetworkProvider with ChangeNotifier {
  ConnectivityStatus _previousStatus = ConnectivityStatus.offline;
  ConnectivityStatus _status = ConnectivityStatus.offline;
  ConnectionQuality _quality = ConnectionQuality.none;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _speedTestTimer;
  bool _isFirstCheck = true;
  SpeedTestConfig _config;
  int _currentUrlIndex = 0;

  // Constructor con configuración opcional
  NetworkProvider({SpeedTestConfig? config})
      : _config = config ?? const SpeedTestConfig() {
    //_initConnectivity();
    //_setupConnectivityStream();
    _startSpeedTest();
    _logEvent('NetworkProvider initialized');
  }

  // Getters existentes
  ConnectivityStatus get status => _status;
  ConnectionQuality get quality => _quality;
  bool get isConnected => _status != ConnectivityStatus.offline;
  bool get hasStableConnection => isConnected && quality != ConnectionQuality.low;

  // Nuevo método para actualizar la configuración
  void updateConfig(SpeedTestConfig newConfig) {
    _config = newConfig;
    _restartSpeedTest();
    _logEvent('Configuration updated');
  }

  void _logEvent(String message, {String? error}) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] NetworkProvider: $message';

    if (error != null) {
      developer.log(logMessage, error: error, name: 'NetworkProvider');
    } else {
      developer.log(logMessage, name: 'NetworkProvider');
    }
  }

  /*void _showToast(String message, Color backgroundColor) {
    if (!_isFirstCheck) {
      Fluttertoast.showToast(
          msg: message,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          backgroundColor: backgroundColor,
          textColor: Colors.white,
          fontSize: 16.0
      );
    }
    _isFirstCheck = false;
  }*/

  void _handleConnectivityChange() {
    if (_previousStatus == ConnectivityStatus.offline && _status != ConnectivityStatus.offline) {
      Fluttertoast.showToast(
        msg: 'Conexión restablecida',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.grey.shade800,
        textColor: Colors.white,
        fontSize: 13.0,
      );
      _logEvent('Connection restored');
    } else if (_previousStatus != ConnectivityStatus.offline && _status == ConnectivityStatus.offline) {
      Fluttertoast.showToast(
        msg: 'Sin conexión a Internet',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.grey.shade800,
        textColor: Colors.white,
        fontSize: 13.0,
      );
      _logEvent('Connection lost');
    } else if (_quality == ConnectionQuality.low) {
      Fluttertoast.showToast(
        msg: 'Conexión inestable',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.grey.shade800,
        textColor: Colors.white,
        fontSize: 13.0,
      );
      _logEvent('Unstable connection detected');
    }
    _previousStatus = _status;
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    ConnectivityStatus newStatus;
    switch (result) {
      case ConnectivityResult.wifi:
        newStatus = ConnectivityStatus.wifi;
        _logEvent('WiFi connection detected');
        break;
      case ConnectivityResult.mobile:
        newStatus = ConnectivityStatus.mobile;
        _logEvent('Mobile connection detected');
        break;
      default:
        newStatus = ConnectivityStatus.offline;
        _quality = ConnectionQuality.none;
        _logEvent('No connection detected');
    }

    if (_status != newStatus) {
      _status = newStatus;
      _handleConnectivityChange();
      notifyListeners();
    }
  }

  /* Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      await _updateConnectionStatus(result);
      if (_status != ConnectivityStatus.offline) {
        await _checkConnectionQuality();
      }
    } catch (e) {
      _logEvent('Error initializing connectivity', error: e.toString());
      _status = ConnectivityStatus.offline;
      _quality = ConnectionQuality.none;
      notifyListeners();
    }
  }

  void _setupConnectivityStream() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) async {
      await _updateConnectionStatus(result);
      if (_status != ConnectivityStatus.offline) {
        await _checkConnectionQuality();
      }
    });
  }*/

  void _restartSpeedTest() {
    _speedTestTimer?.cancel();
    _startSpeedTest();
  }

  void _startSpeedTest() {
    _speedTestTimer = Timer.periodic(_config.checkInterval, (_) async {
      if (_status != ConnectivityStatus.offline) {
        await _checkConnectionQuality();
      }
    });
  }

  Future<ConnectionQuality> _testSpeed(String url, int retryCount) async {
    try {
      final stopwatch = Stopwatch()..start();
      final response = await http.get(Uri.parse(url))
          .timeout(_config.timeout);
      stopwatch.stop();

      if (response.statusCode == 200) {
        final speedMbps = (response.bodyBytes.length / stopwatch.elapsedMilliseconds) * 8;
        _logEvent('Speed test completed: $speedMbps Mbps using $url');

        if (speedMbps > 2) return ConnectionQuality.high;
        if (speedMbps > 1) return ConnectionQuality.medium;
        return ConnectionQuality.low;
      }

      throw HttpException('Invalid status code: ${response.statusCode}');
    } catch (e) {
      _logEvent('Speed test failed for $url (attempt ${retryCount + 1})', error: e.toString());

      if (retryCount < _config.maxRetries) {
        final delay = _config.initialRetryDelay.inMilliseconds *
            (_config.retryBackoffMultiplier * retryCount).round();
        await Future.delayed(Duration(milliseconds: delay));
        return _testSpeed(url, retryCount + 1);
      }

      // Si fallaron todos los reintentos, intentar con el siguiente servidor
      _currentUrlIndex = (_currentUrlIndex + 1) % _config.testUrls.length;
      if (_currentUrlIndex != 0) { // Si no hemos probado todos los servidores
        return _testSpeed(_config.testUrls[_currentUrlIndex], 0);
      }

      throw Exception('All speed test servers failed');
    }
  }

  Future<void> _checkConnectionQuality() async {
    try {
      final newQuality = await _testSpeed(_config.testUrls[_currentUrlIndex], 0);

      if (_quality != newQuality) {
        _quality = newQuality;
        _logEvent('Connection quality changed to: $_quality');
        notifyListeners();
      }
    } catch (e) {
      _quality = ConnectionQuality.none;
      _logEvent('Failed to check connection quality', error: e.toString());
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _logEvent('Disposing NetworkProvider');
    _connectivitySubscription?.cancel();
    _speedTestTimer?.cancel();
    super.dispose();
  }
}

// Enums existentes
enum ConnectivityStatus {
  wifi,
  mobile,
  offline
}

enum ConnectionQuality {
  high,    // > 2 Mbps
  medium,  // 1-2 Mbps
  low,     // < 1 Mbps
  none
}

class HttpException implements Exception {
  final String message;
  HttpException(this.message);
  @override
  String toString() => message;
}

// Widget para manejar medios colocaren video e imagnes
class CustomMediaWidget extends StatefulWidget {
  final String mediaUrl;
  final MediaType type;
  final double? width;
  final double? height;
  final Widget Function(String url)? customVideoPlayer;

  const CustomMediaWidget({
    Key? key,
    required this.mediaUrl,
    required this.type,
    this.width,
    this.height,
    this.customVideoPlayer,
  }) : super(key: key);

  @override
  State<CustomMediaWidget> createState() => _CustomMediaWidgetState();
}

class _CustomMediaWidgetState extends State<CustomMediaWidget> {
  bool _shouldLoadMedia = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkProvider>(
      builder: (context, network, child) {
        // Resetear la carga si no hay conexión
        if (!network.isConnected) {
          _shouldLoadMedia = false;
        }

        // Widget para cuando no hay conexión
        if (!network.isConnected) {
          return _buildOfflineWidget();
        }

        // Widget para conexión inestable
        if (network.quality == ConnectionQuality.low) {
          return _buildUnstableWidget();
        }

        // Si tenemos conexión estable pero aún no se ha intentado cargar el medio
        if (!_shouldLoadMedia) {
          return _buildPreloadWidget();
        }

        // Cargar el medio optimizado
        return _buildOptimizedMedia(network);
      },
    );
  }

  Widget _buildOfflineWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.signal_wifi_off, size: 40),
          SizedBox(height: 8),
          Text('Sin conexión a Internet',
              style: TextStyle(fontSize: 16)),
          Text('Toca para intentar cargar\ncuando haya conexión',
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildUnstableWidget() {
    return GestureDetector(
      onTap: () {
        setState(() => _shouldLoadMedia = true);
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[300],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.speed, size: 40),
            SizedBox(height: 8),
            Text('Conexión inestable',
                style: TextStyle(fontSize: 16)),
            Text('Toca para intentar cargar\nde todos modos',
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildPreloadWidget() {
    return GestureDetector(
      onTap: () {
        setState(() => _shouldLoadMedia = true);
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[300],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                widget.type == MediaType.video ? Icons.play_circle : Icons.image,
                size: 40
            ),
            const SizedBox(height: 8),
            const Text('Toca para cargar el contenido',
                style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizedMedia(NetworkProvider network) {
    String optimizedUrl = widget.mediaUrl;

    // Optimizar URL según calidad de conexión
    if (network.quality != ConnectionQuality.high) {
      optimizedUrl = widget.type == MediaType.video
          ? '${widget.mediaUrl}?quality=480p'
          : '${widget.mediaUrl}?quality=medium';
    }

    if (widget.type == MediaType.image) {
      return Image.network(
        optimizedUrl,
        width: widget.width,
        height: widget.height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingWidget(loadingProgress);
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      );
    } else if (widget.customVideoPlayer != null) {
      return widget.customVideoPlayer!(optimizedUrl);
    } else {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.black,
        child: const Center(
          child: Text('Video Player',
              style: TextStyle(color: Colors.white)),
        ),
      );
    }
  }

  Widget _buildLoadingWidget(ImageChunkEvent loadingProgress) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[300],
      child: Center(
        child: CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded /
              loadingProgress.expectedTotalBytes!
              : null,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[300],
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 40),
          SizedBox(height: 8),
          Text('Error al cargar el contenido'),
        ],
      ),
    );
  }
}

enum MediaType {
  image,
  video
}