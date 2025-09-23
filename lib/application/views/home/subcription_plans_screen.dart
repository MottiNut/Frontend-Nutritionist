import 'package:flutter/material.dart';

// Enum declarado a nivel superior
enum SubscriptionType { monthly, annual }

class SubscriptionModal extends StatefulWidget {
  const SubscriptionModal({Key? key}) : super(key: key);

  @override
  _SubscriptionModalState createState() => _SubscriptionModalState();
}

class _SubscriptionModalState extends State<SubscriptionModal> {
  SubscriptionType selectedPlan = SubscriptionType.annual;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 120),
            child: Column(
              children: [
                _buildImageHeader(),
                _buildMainTitles(),
                _buildSubscriptionCards(),
                _buildPaymentNote(),
                _buildMottimutPlusSection(),
                _buildBottomLinks(),
              ],
            ),
          ),

          // Botón fijo
          _buildFixedBottomButton(),
        ],
      ),

    );
  }

  Widget _buildImageHeader() {
    return Container(
      height: 280,
      child: Stack(
        children: [
          // Imagen de fondo
          Container(
            width: double.infinity,
            height: 280,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/diamod.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Gradient overlay
          Container(
            height: 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.7),
                ],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
          ),

          // Botón X (cerrar)
          Positioned(
            top: 45,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),

          // Óvalo decorativo debajo de la imagen
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 30,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.vertical(
                  top: Radius.elliptical(MediaQuery.of(context).size.width, 40),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTitles() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(height: 10),

          // Título principal
          Text(
            'Empezar la prueba gratis',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 8),

          // Subtítulo
          Text(
            'Prueba GRATIS durante 10 días, luego',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCards() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Plan Anual (EL MÁS POPULAR)
          _buildSubscriptionCard(
            type: SubscriptionType.annual,
            title: 'Anualmente',
            color: Color(0xFFFF6B35),
            subtitle: 'Prueba gratis de 7 días',
            originalPrice: 'S/ 250.00',
            price: 'S/ 190.00',
            monthlyPrice: 'S/ 15.99/mes',
            isPopular: true,
          ),

          SizedBox(height: 12),

          // Plan Mensual
          _buildSubscriptionCard(
            type: SubscriptionType.monthly,
            title: 'Mensualmente',
            subtitle: 'Prueba gratis de 3 días',
            price: 'S/ 20.99',
            isPopular: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard({
    required SubscriptionType type,
    required String title,
    String? subtitle,
    String? originalPrice,
    required String price,
    String? monthlyPrice,
    Color? color,
    required bool isPopular,
  }) {
    bool isSelected = selectedPlan == type;
    final mainColor = color ?? Colors.white;

    const double badgeHeight = 28; // altura fija del badge

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPlan = type;
        });
      },
      child: Stack(
        clipBehavior: Clip.none, // permite que el badge sobresalga
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isSelected ? Colors.grey[850] : Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(color: Color(0xFFFF6B35), width: 2)
                  : null,
            ),
            padding: EdgeInsets.only(top: badgeHeight / 2 + 16, left: 20, right: 20, bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Lado izquierdo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: mainColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Lado derecho - precios
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (originalPrice != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            originalPrice,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: Colors.grey[500],
                              decorationThickness: 2,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            price,
                            style: TextStyle(
                              color: mainColor,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        price,
                        style: TextStyle(
                          color: mainColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (monthlyPrice != null)
                      Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Text(
                          monthlyPrice,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Badge flotante centrado
          if (isPopular)
            Positioned(
              top: -badgeHeight / 2,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 5 ),
                  decoration: BoxDecoration(
                    color: mainColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'EL MÁS POPULAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

        ],
      ),
    );
  }


  Widget _buildPaymentNote() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      child: Text(
        'Pago recurrente. Cancela cuando quieras.',
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMottimutPlusSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SizedBox(height: 16),

          // Logo Mottinut Plus
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Mottinut ',
                style: TextStyle(
                  color: Color(0xFF00D4AA),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(0xFF00D4AA),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'PLUS+',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 5),

          // Subtítulo
          Text(
            'Maximiza tu potencial total',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 24),

          // Lista de características con viñetas
          ..._buildFeaturesList(),
        ],
      ),
    );
  }

  List<Widget> _buildFeaturesList() {
    final features = [
      'Planes nutricionales personalizados con IA',
      'Análisis inteligente de alimentos y nutrientes',
      'Seguimiento avanzado de progreso y objetivos',
      'Opciones ilimitadas de planificación de comidas',
      'Recordatorios automáticos para tus planes',
      'Respaldo seguro de tus datos en la nube',
      'Personalización de colores y temas',
      'Gráficos detallados para tu evolución',
    ];

    return features.map((feature) => _buildFeatureItem(feature)).toList();
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Viñeta verde
          Container(
            margin: EdgeInsets.only(top: 2),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Color(0xFF00D4AA),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              color: Colors.black,
              size: 14,
            ),
          ),

          SizedBox(width: 12),

          // Texto de la característica
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomLinks() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildBottomLink('Términos de uso', _showTermsOfUse),

          SizedBox(height: 12),
          _buildBottomLink('Continuar con versión gratis', _continueWithFreeVersion),
        ],
      ),
    );
  }

  Widget _buildBottomLink(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          color: Color(0xFF00D4AA),
          fontSize: 14,
          decoration: TextDecoration.underline,
          height: 1.2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }


  Widget _buildFixedBottomButton() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.black,
        padding: EdgeInsets.fromLTRB(12, 12, 12, 6),
        // espacio arriba y abajo del fondo
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _handleStartTrial,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF00D4AA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
                padding: EdgeInsets.zero,
              ),
              child: Center(
                child: Text(
                  'Comenzar prueba gratis',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleStartTrial() {
    print('🚀 Iniciando prueba gratis con plan: $selectedPlan');
    if (selectedPlan == SubscriptionType.annual) {
      print('💰 Plan Anual: S/ 190.00 (7 días gratis)');
    } else {
      print('💰 Plan Mensual: S/ 20.99');
    }

    SubscriptionService.purchaseSubscription(selectedPlan);
    Navigator.of(context).pop();
  }

  void _showTermsOfUse() {
    print('📋 Mostrar términos de uso');
    // Aquí puedes navegar a una página de términos
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Términos de uso', style: TextStyle(color: Colors.white)),
        content: Text('Aquí van los términos de uso...',
            style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar', style: TextStyle(color: Color(0xFF00D4AA))),
          ),
        ],
      ),
    );
  }

  void _restorePurchase() {
    print('🔄 Restaurar compra');
    SubscriptionService.restorePurchase().then((success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Compra restaurada exitosamente'
              : 'No se encontraron compras'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    });
  }

  void _continueWithFreeVersion() {
    print('✨ Continuar con versión gratis');
    Navigator.of(context).pop();
  }
}

// Clase para manejar la lógica de suscripción
class SubscriptionService {
  // Método para mostrar el modal
  static void showSubscriptionModal(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SubscriptionModal(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: Offset(0.0, 1.0), end: Offset.zero),
            ),
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 300),
        fullscreenDialog: true,
      ),
    );
  }

  // Método para manejar la compra de suscripción
  static Future<bool> purchaseSubscription(SubscriptionType type) async {
    try {
      switch (type) {
        case SubscriptionType.monthly:
          print('💳 Procesando suscripción mensual S/ 20.99...');
          break;
        case SubscriptionType.annual:
          print('💳 Procesando suscripción anual S/ 190.00 (7 días gratis)...');
          break;
      }

      // Simular proceso de pago
      await Future.delayed(Duration(seconds: 2));
      print('✅ Suscripción procesada exitosamente');
      return true;
    } catch (e) {
      print('❌ Error al procesar suscripción: $e');
      return false;
    }
  }

  // Método para verificar estado de suscripción
  static Future<bool> isSubscribed() async {
    // Aquí verificarías con tu backend/store
    return false;
  }

  // Método para cancelar suscripción
  static Future<bool> cancelSubscription() async {
    try {
      print('🚫 Cancelando suscripción...');
      await Future.delayed(Duration(seconds: 1));
      return true;
    } catch (e) {
      print('❌ Error al cancelar suscripción: $e');
      return false;
    }
  }

  // Método para restaurar compra
  static Future<bool> restorePurchase() async {
    try {
      print('🔄 Restaurando compras...');
      await Future.delayed(Duration(seconds: 2));
      print('✅ Compras restauradas');
      return true;
    } catch (e) {
      print('❌ Error al restaurar compra: $e');
      return false;
    }
  }
}

// Widget de ejemplo para probar
class ExampleUsage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text('Mottinut App'),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            SubscriptionService.showSubscriptionModal(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF00D4AA),
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: Text(
            'Ver Suscripción Premium',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
