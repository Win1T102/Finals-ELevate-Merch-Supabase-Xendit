import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Available visual styles for the ELEVATE MERCH logo.
enum BrandLogoVariant {
  /// Signature Elevate Black badge with subtle red border, white ELEVATE text,
  /// and vibrant Elevate Red MERCH pill.
  darkBadge,

  /// Soft warm red surface badge with dark ELEVATE text and Elevate Red MERCH pill.
  lightRedBadge,

  /// Clean minimalist text without background container.
  plain,
}

/// The official ELEVATE MERCH wordmark with complementary theme background.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 22,
    this.color,
    this.variant = BrandLogoVariant.darkBadge,
    this.withBadge = true,
  });

  /// Type size of the word ELEVATE.
  final double size;

  /// Custom text color (used primarily when [withBadge] is false or [variant] is plain).
  final Color? color;

  /// The badge container styling.
  final BrandLogoVariant variant;

  /// Whether to render inside a complementary background badge. Defaults to true.
  final bool withBadge;

  @override
  Widget build(BuildContext context) {
    if (!withBadge || variant == BrandLogoVariant.plain) {
      final textColor = color ?? AppColors.ink;
      return Semantics(
        label: 'ELEVATE MERCH',
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              'ELEVATE',
              style: TextStyle(
                fontFamily: 'Archivo',
                fontSize: size,
                height: 0.92,
                fontWeight: FontWeight.w900,
                letterSpacing: -size * 0.055,
                color: textColor,
              ),
            ),
            SizedBox(width: size * 0.28),
            Padding(
              padding: EdgeInsets.only(bottom: size * 0.03),
              child: Text(
                'MERCH',
                style: TextStyle(
                  fontFamily: 'Archivo',
                  fontSize: size * 0.38,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  letterSpacing: size * 0.075,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isDark = variant == BrandLogoVariant.darkBadge;
    final backgroundColor = isDark ? AppColors.tile : AppColors.elevateRedSurface;
    final borderColor = isDark
        ? AppColors.elevateRed.withValues(alpha: 0.38)
        : AppColors.elevateRed.withValues(alpha: 0.25);

    return Semantics(
      label: 'ELEVATE MERCH',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: size * 0.44,
          vertical: size * 0.22,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(size * 0.32),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: isDark
                  ? AppColors.elevateRed.withValues(alpha: 0.20)
                  : Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'Archivo',
                  fontSize: size,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -size * 0.05,
                ),
                children: const <TextSpan>[
                  TextSpan(
                    text: 'ELEV',
                    style: TextStyle(color: AppColors.paperWhite),
                  ),
                  TextSpan(
                    text: 'A',
                    style: TextStyle(color: AppColors.elevateRed),
                  ),
                  TextSpan(
                    text: 'TE',
                    style: TextStyle(color: AppColors.paperWhite),
                  ),
                ],
              ),
            ),
            SizedBox(width: size * 0.28),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: size * 0.26,
                vertical: size * 0.12,
              ),
              decoration: BoxDecoration(
                color: AppColors.elevateRed,
                borderRadius: BorderRadius.circular(size * 0.18),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.elevateRed.withValues(alpha: 0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                'MERCH',
                style: TextStyle(
                  fontFamily: 'Archivo',
                  fontSize: size * 0.38,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: size * 0.08,
                  color: AppColors.paperWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A larger wordmark used as artwork in empty states and the hero fallback.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 56,
    this.color = AppColors.ink,
    this.showTagline = false,
    this.withComplement = true,
  });

  final double size;
  final Color color;
  final bool showTagline;
  final bool withComplement;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'ELEVATE',
          style: TextStyle(
            fontFamily: 'Archivo',
            fontSize: size,
            height: 0.86,
            fontWeight: FontWeight.w900,
            letterSpacing: -size * 0.06,
            color: color,
          ),
        ),
        SizedBox(height: size * 0.1),
        if (withComplement)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: size * 0.18,
              vertical: size * 0.06,
            ),
            decoration: BoxDecoration(
              color: AppColors.elevateRed,
              borderRadius: BorderRadius.circular(size * 0.08),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.elevateRed.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'MERCH',
              style: TextStyle(
                fontFamily: 'Archivo',
                fontSize: size * 0.22,
                height: 1,
                fontWeight: FontWeight.w800,
                letterSpacing: size * 0.14,
                color: AppColors.paperWhite,
              ),
            ),
          )
        else
          Text(
            'MERCH',
            style: TextStyle(
              fontFamily: 'Archivo',
              fontSize: size * 0.2,
              height: 1.1,
              fontWeight: FontWeight.w600,
              letterSpacing: size * 0.16,
              color: color,
            ),
          ),
        if (showTagline) ...<Widget>[
          SizedBox(height: size * 0.22),
          Text(
            'Pins, shirts, and bookmarks for the ELEVATE community.',
            style: TextStyle(
              fontFamily: 'Archivo',
              fontSize: size * 0.22,
              height: 1.5,
              color: color == AppColors.ink
                  ? AppColors.muted
                  : color.withValues(alpha: 0.72),
            ),
          ),
        ],
      ],
    );
  }
}
