/// Widget de Skeleton Loader para estados de carga.
///
/// Proporciona una animación de shimmer que mejora la percepción
/// de velocidad de carga comparado con un simple spinner.
library;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Widget base para skeleton loading.
class SkeletonLoader extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsets? margin;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[850]!,
      highlightColor: Colors.grey[700]!,
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Skeleton para una tarjeta de evento.
class EventCardSkeleton extends StatelessWidget {
  const EventCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen
          SkeletonLoader(
            width: double.infinity,
            height: 160,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(height: 12),
          // Título
          const SkeletonLoader(
            width: 200,
            height: 20,
          ),
          const SizedBox(height: 8),
          // Subtítulo
          const SkeletonLoader(
            width: 150,
            height: 14,
          ),
          const SizedBox(height: 8),
          // Fecha
          const SkeletonLoader(
            width: 100,
            height: 14,
          ),
        ],
      ),
    );
  }
}

/// Skeleton para una tarjeta de promoción.
class PromotionCardSkeleton extends StatelessWidget {
  const PromotionCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen
          SkeletonLoader(
            width: double.infinity,
            height: 120,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 8),
          // Título
          const SkeletonLoader(
            width: 160,
            height: 16,
          ),
          const SizedBox(height: 6),
          // Descuento
          const SkeletonLoader(
            width: 80,
            height: 14,
          ),
        ],
      ),
    );
  }
}

/// Skeleton para una tarjeta de casino.
class CasinoCardSkeleton extends StatelessWidget {
  const CasinoCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Imagen circular
          SkeletonLoader(
            width: 60,
            height: 60,
            borderRadius: BorderRadius.circular(30),
          ),
          const SizedBox(width: 16),
          // Información
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoader(
                  width: 180,
                  height: 18,
                ),
                const SizedBox(height: 8),
                SkeletonLoader(
                  width: 120,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 6),
                SkeletonLoader(
                  width: 100,
                  height: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton para hero card del casino favorito.
class CasinoHeroSkeleton extends StatelessWidget {
  const CasinoHeroSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      child: Stack(
        children: [
          // Fondo
          SkeletonLoader(
            width: double.infinity,
            height: 200,
            borderRadius: BorderRadius.circular(20),
          ),
          // Contenido superpuesto
          Positioned(
            left: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                  width: 200,
                  height: 24,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                SkeletonLoader(
                  width: 150,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton para lista de restaurantes.
class RestaurantCardSkeleton extends StatelessWidget {
  const RestaurantCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen
          SkeletonLoader(
            width: double.infinity,
            height: 100,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 8),
          // Nombre
          const SkeletonLoader(
            width: 120,
            height: 14,
          ),
          const SizedBox(height: 4),
          // Rating
          const SkeletonLoader(
            width: 60,
            height: 12,
          ),
        ],
      ),
    );
  }
}

/// Skeleton para lista horizontal genérica.
class HorizontalListSkeleton extends StatelessWidget {
  final Widget Function() itemBuilder;
  final int itemCount;
  final double height;

  const HorizontalListSkeleton({
    super.key,
    required this.itemBuilder,
    this.itemCount = 3,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemCount,
        itemBuilder: (context, index) => itemBuilder(),
      ),
    );
  }
}

/// Skeleton para perfil de usuario.
class UserProfileSkeleton extends StatelessWidget {
  const UserProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar
          SkeletonLoader(
            width: 72,
            height: 72,
            borderRadius: BorderRadius.circular(36),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoader(width: 150, height: 20),
                const SizedBox(height: 8),
                SkeletonLoader(
                  width: 100,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 6),
                SkeletonLoader(
                  width: 80,
                  height: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton para estadísticas/métricas.
class StatCardSkeleton extends StatelessWidget {
  const StatCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SkeletonLoader(
            width: 40,
            height: 40,
            borderRadius: BorderRadius.circular(20),
          ),
          const SizedBox(height: 8),
          const SkeletonLoader(width: 60, height: 20),
          const SizedBox(height: 4),
          const SkeletonLoader(width: 50, height: 12),
        ],
      ),
    );
  }
}
