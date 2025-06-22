import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../configuration/themes/app_colors.dart';

class HomeScreenSkeleton extends StatelessWidget {
  const HomeScreenSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A), // Fondo negro azulado profesional
      body: Stack(
        children: [
          // Gradiente sutil oscuro
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.9, -0.9),
                  radius: 1.2,
                  colors: [
                    const Color(0xFF1A2332).withOpacity(0.4),
                    const Color(0xFF0F1419).withOpacity(0.2),
                    const Color(0xFF0A0E1A).withOpacity(0.1),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // Contenido del skeleton
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSkeleton(),
                  const SizedBox(height: 15),
                  _buildNameSkeleton(),
                  const SizedBox(height: 10),
                  _buildCalendarSkeleton(),
                  const SizedBox(height: 30),
                  _buildAgendaSkeleton(),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      Expanded(child: _buildPacientesActivosSkeleton()),
                      const SizedBox(width: 15),
                      Expanded(child: _buildUrgenteSkeleton()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSkeleton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildShimmerContainer(36, 36, BorderRadius.circular(8)),
        _buildShimmerContainer(73.406, 55.14, BorderRadius.circular(30)),
        _buildShimmerContainer(25.305, 30.278, BorderRadius.circular(6)),
      ],
    );
  }

  Widget _buildNameSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildShimmerContainer(60, 25, BorderRadius.circular(6)),
        const SizedBox(height: 8),
        _buildShimmerContainer(140, 32, BorderRadius.circular(8)),
      ],
    );
  }

  Widget _buildCalendarSkeleton() {
    return Column(
      children: [
        // Mes en la esquina
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildShimmerContainer(70, 16, BorderRadius.circular(6)),
          ],
        ),
        const SizedBox(height: 20),
        // Días de la semana
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) {
            final isSelected = index == 2; // Simula día seleccionado
            return Container(
              width: 42,
              height: 75.865,
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2A3441)
                      : const Color(0xFF1A2332),
                  width: 1,
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(25),
                  top: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 43,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2A3441)
                          : const Color(0xFF1A2332),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: _buildShimmerContainer(16, 16, BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildShimmerContainer(24, 14, BorderRadius.circular(4)),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAgendaSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildShimmerContainer(100, 22, BorderRadius.circular(6)),
        const SizedBox(height: 12),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2332).withOpacity(0.6),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: const Color(0xFF2A3441),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  _buildAgendaItemSkeleton(),
                  const SizedBox(height: 24),
                  _buildAgendaItemSkeleton(),
                ],
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A3441),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF3A4551),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: _buildShimmerContainer(20, 20, BorderRadius.circular(4)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAgendaItemSkeleton() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShimmerContainer(90, 16, BorderRadius.circular(4)),
              const SizedBox(height: 6),
              _buildShimmerContainer(70, 16, BorderRadius.circular(4)),
            ],
          ),
        ),
        Container(
          width: 1,
          height: 39,
          margin: const EdgeInsets.symmetric(horizontal: 15),
          color: const Color(0xFF3A4551),
        ),
        Expanded(
          flex: 2,
          child: _buildShimmerContainer(110, 16, BorderRadius.circular(4)),
        ),
      ],
    );
  }

  Widget _buildPacientesActivosSkeleton() {
    return Container(
      height: 200,
      width: 158.83,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        gradient: LinearGradient(
          begin: const Alignment(-0.5, -1.0),
          end: const Alignment(0.5, 1.0),
          colors: [
            const Color(0xFF1A2332).withOpacity(0.8),
            const Color(0xFF2A3441).withOpacity(0.6),
            const Color(0xFF1A2332).withOpacity(0.4),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF3A4551),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildShimmerContainer(80, 14, BorderRadius.circular(4)),
          const SizedBox(height: 6),
          _buildShimmerContainer(70, 22, BorderRadius.circular(6)),
          const SizedBox(height: 16),
          _buildShimmerContainer(60, 50, BorderRadius.circular(12)),
          const SizedBox(height: 16),
          _buildShimmerContainer(100, 14, BorderRadius.circular(4)),
          const SizedBox(height: 4),
          _buildShimmerContainer(90, 14, BorderRadius.circular(4)),
        ],
      ),
    );
  }

  Widget _buildUrgenteSkeleton() {
    return Container(
      height: 200,
      width: 158.83,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF2A1A1A).withOpacity(0.7),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xFF4A2A2A),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 21, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShimmerContainer(80, 22, BorderRadius.circular(6)),
                  const SizedBox(height: 8),
                  _buildShimmerContainer(130, 16, BorderRadius.circular(4)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(3, (index) => _buildUrgenteItemSkeleton()),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF4A2A2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF5A3A3A),
                  width: 1,
                ),
              ),
              child: Center(
                child: _buildShimmerContainer(16, 16, BorderRadius.circular(4)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgenteItemSkeleton() {
    return Container(
      height: 18,
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: _buildShimmerContainer(85, 14, BorderRadius.circular(4)),
          ),
          Container(
            width: 1,
            height: 12,
            color: const Color(0xFF4A2A2A),
            margin: const EdgeInsets.symmetric(horizontal: 6),
          ),
          Expanded(
            flex: 4,
            child: _buildShimmerContainer(60, 14, BorderRadius.circular(4)),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerContainer(double width, double height, BorderRadius borderRadius) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2A3441),
      highlightColor: const Color(0xFF3A4551),
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF2A3441),
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}