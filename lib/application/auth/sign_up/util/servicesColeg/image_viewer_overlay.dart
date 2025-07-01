import 'dart:io';
import 'package:flutter/material.dart';

class ImageViewerOverlay extends StatefulWidget {
  final List<File> images;
  final int initialIndex;
  final Function(int) onImageDelete;
  final VoidCallback onClose;

  const ImageViewerOverlay({
    Key? key,
    required this.images,
    required this.initialIndex,
    required this.onImageDelete,
    required this.onClose,
  }) : super(key: key);

  @override
  _ImageViewerOverlayState createState() => _ImageViewerOverlayState();
}

class _ImageViewerOverlayState extends State<ImageViewerOverlay>
    with TickerProviderStateMixin {
  late int currentImageIndex;
  bool _showPageIndicator = false;
  bool _showSwipeInstructions = true;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    currentImageIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentImageIndex);

    // Ocultar instrucciones después de 3 segundos
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSwipeInstructions = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showPageIndicatorTemporarily() {
    setState(() {
      _showPageIndicator = true;
    });

    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showPageIndicator = false;
        });
      }
    });
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                'Eliminar imagen',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          content: Text(
            '¿Estás seguro de que deseas eliminar esta imagen? Esta acción no se puede deshacer.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                widget.onImageDelete(currentImageIndex);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Eliminar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // PageView para navegación suave entre imágenes
          Center(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: _showPageIndicatorTemporarily,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      currentImageIndex = index;
                    });
                    _showPageIndicatorTemporarily();
                  },
                  itemCount: widget.images.length,
                  itemBuilder: (context, index) {
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Hero(
                          tag: 'image_$index',
                          child: Image.file(
                            widget.images[index],
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Barra superior con botones animados
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Botón eliminar con animación
                TweenAnimationBuilder(
                  duration: Duration(milliseconds: 200),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: GestureDetector(
                        onTap: _showDeleteConfirmation,
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.85),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Botón cerrar con animación
                TweenAnimationBuilder(
                  duration: Duration(milliseconds: 200),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: GestureDetector(
                        onTap: widget.onClose,
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Indicador de página con animación suave
          if (widget.images.length > 1 && _showPageIndicator)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _showPageIndicator ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 300),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 250),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: Offset(0.3, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        '${currentImageIndex + 1} de ${widget.images.length}',
                        key: ValueKey(currentImageIndex),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Indicadores de puntos para navegación visual
          if (widget.images.length > 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    widget.images.length,
                        (index) => AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      width: currentImageIndex == index ? 24 : 8,
                      height: 5,
                      decoration: BoxDecoration(
                        color: currentImageIndex == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Instrucción de deslizamiento
          if (widget.images.length > 1 && _showSwipeInstructions)
            Positioned(
              bottom: 130,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _showSwipeInstructions ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 500),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.swipe_left,
                          color: Colors.white.withOpacity(0.6),
                          size: 14,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Desliza para navegar',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.swipe_right,
                          color: Colors.white.withOpacity(0.6),
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}