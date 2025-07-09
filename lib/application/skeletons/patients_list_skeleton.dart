import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class PatientsListSkeleton extends StatelessWidget {
  const PatientsListSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: _buildShimmerContainer(24, 24, BorderRadius.circular(4)),
        title: _buildShimmerContainer(140, 20, BorderRadius.circular(6)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: _buildShimmerContainer(32, 24, BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFiltersSkeleton(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 10,
              itemBuilder: (context, index) {
                return _buildPatientCardSkeleton(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFiltersSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE9ECEF),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Barra de búsqueda skeleton
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE9ECEF),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                _buildShimmerContainer(20, 20, BorderRadius.circular(4)),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildShimmerContainer(200, 16, BorderRadius.circular(4)),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Filtros skeleton
          Row(
            children: [
              _buildFilterChipSkeleton(60),
              const SizedBox(width: 8),
              _buildFilterChipSkeleton(100),
              const SizedBox(width: 8),
              _buildFilterChipSkeleton(90),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChipSkeleton(double width) {
    return Container(
      width: width,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE9ECEF),
          width: 1,
        ),
      ),
      child: Center(
        child: _buildShimmerContainer(width - 20, 12, BorderRadius.circular(4)),
      ),
    );
  }

  Widget _buildPatientCardSkeleton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE9ECEF),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar skeleton
          _buildShimmerContainer(60, 60, BorderRadius.circular(30)),
          const SizedBox(width: 16),
          // Información skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre
                _buildShimmerContainer(double.infinity, 16, BorderRadius.circular(4)),
                const SizedBox(height: 8),
                // Email
                _buildShimmerContainer(MediaQuery.of(context).size.width * 0.5, 14, BorderRadius.circular(4)),
                const SizedBox(height: 12),
                // Chips
                Row(
                  children: [
                    _buildShimmerContainer(60, 20, BorderRadius.circular(12)),
                    const SizedBox(width: 8),
                    _buildShimmerContainer(80, 20, BorderRadius.circular(12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Flecha skeleton
          _buildShimmerContainer(16, 16, BorderRadius.circular(2)),
        ],
      ),
    );
  }

  Widget _buildShimmerContainer(double width, double height, BorderRadius borderRadius) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE9ECEF),
      highlightColor: const Color(0xFFF8F9FA),
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE9ECEF),
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}