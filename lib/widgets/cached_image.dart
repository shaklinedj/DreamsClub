/// Widget de imagen cacheada optimizado.
///
/// Wrapper alrededor de CachedNetworkImage con configuración
/// optimizada para Dreams Club y manejo consistente de errores.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:casinoloyalty_flutter/core/constants/app_constants.dart';

/// Imagen de red con caché optimizado.
///
/// Ejemplo:
/// ```dart
/// CachedImage(
///   imageUrl: 'https://example.com/image.jpg',
///   width: 200,
///   height: 150,
///   borderRadius: BorderRadius.circular(12),
/// )
/// ```
class CachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Color? backgroundColor;
  final bool useShimmer;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.backgroundColor,
    this.useShimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: AppConstants.imageCacheMaxWidth,
      maxWidthDiskCache: AppConstants.imageDiskCacheMaxWidth,
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(context),
      errorWidget: (context, url, error) =>
          errorWidget ?? _buildErrorWidget(context),
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
    );

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    if (backgroundColor != null) {
      image = Container(
        color: backgroundColor,
        child: image,
      );
    }

    return image;
  }

  Widget _buildPlaceholder(BuildContext context) {
    if (!useShimmer) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[850],
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white30),
          ),
        ),
      );
    }

    return Shimmer.fromColors(
      baseColor: Colors.grey[850]!,
      highlightColor: Colors.grey[700]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: borderRadius,
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: borderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey[600],
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(
            'Error al cargar',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// Imagen de avatar circular con caché.
class CachedAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final String? fallbackText;
  final Color? backgroundColor;
  final IconData fallbackIcon;

  const CachedAvatar({
    super.key,
    this.imageUrl,
    this.radius = 24,
    this.fallbackText,
    this.backgroundColor,
    this.fallbackIcon = Icons.person,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallback(context);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
        backgroundColor: backgroundColor ?? Colors.grey[800],
      ),
      placeholder: (context, url) => _buildPlaceholder(),
      errorWidget: (context, url, error) => _buildFallback(context),
    );
  }

  Widget _buildPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[850]!,
      highlightColor: Colors.grey[700]!,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[850],
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    final bgColor = backgroundColor ?? Theme.of(context).primaryColor;

    if (fallbackText != null && fallbackText!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: Text(
          fallbackText!.substring(0, 1).toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.8,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Icon(
        fallbackIcon,
        color: Colors.white,
        size: radius,
      ),
    );
  }
}

/// Card de imagen hero con overlay de gradiente.
class CachedHeroImage extends StatelessWidget {
  final String imageUrl;
  final double height;
  final Widget? child;
  final BorderRadius? borderRadius;
  final List<Color>? gradientColors;
  final VoidCallback? onTap;

  const CachedHeroImage({
    super.key,
    required this.imageUrl,
    this.height = 200,
    this.child,
    this.borderRadius,
    this.gradientColors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      fit: StackFit.expand,
      children: [
        // Imagen
        CachedImage(
          imageUrl: imageUrl,
          height: height,
          fit: BoxFit.cover,
          borderRadius: borderRadius,
        ),
        // Gradiente
        Container(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientColors ??
                  [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.8),
                  ],
              stops: const [0.3, 0.6, 1.0],
            ),
          ),
        ),
        // Contenido
        if (child != null) child!,
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: content,
        ),
      );
    }

    return SizedBox(
      height: height,
      child: content,
    );
  }
}
