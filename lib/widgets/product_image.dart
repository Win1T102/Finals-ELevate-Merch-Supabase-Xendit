import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Network or local merchandise image with transparent background support.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.backgroundColor = Colors.transparent,
    this.fallbackText = 'E',
  });

  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Color backgroundColor;
  final String fallbackText;

  @override
  Widget build(BuildContext context) {
    final fallback = _Fallback(text: fallbackText);

    final trimmed = imageUrl.trim();
    final Widget imageWidget;

    if (trimmed.isEmpty) {
      imageWidget = fallback;
    } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      imageWidget = Image.network(
        trimmed,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => fallback,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return fallback;
        },
      );
    } else {
      var assetPath = trimmed.startsWith('assets/')
          ? trimmed
          : 'assets/images/elevate/$trimmed';

      // Automatically prefer the transparent PNG version if available
      if (assetPath.toLowerCase().endsWith('.jfif')) {
        assetPath = assetPath.replaceAll(
          RegExp(r'\.jfif$', caseSensitive: false),
          '.png',
        );
      }

      imageWidget = Image.asset(
        assetPath,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => fallback,
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: backgroundColor,
        child: Center(child: imageWidget),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Archivo',
              fontSize: 72,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: -4,
              color: AppColors.line,
            ),
          ),
        ),
      ),
    );
  }
}
