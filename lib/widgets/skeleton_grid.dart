import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A static loading placeholder — no shimmer, matching the store's quiet feel.
class SkeletonProductGrid extends StatelessWidget {
  const SkeletonProductGrid({
    super.key,
    this.count = 6,
    this.columns = 3,
  });

  final int count;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 24.0;
        final width = constraints.maxWidth;
        final effectiveColumns = width < 560 ? 2 : columns;
        final tileWidth =
            (width - gap * (effectiveColumns - 1)) / effectiveColumns;

        return Wrap(
          spacing: gap,
          runSpacing: 32,
          children: List<Widget>.generate(count, (index) {
            return SizedBox(
              width: tileWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: tileWidth,
                    height: tileWidth,
                    color: AppColors.tile,
                  ),
                  const SizedBox(height: 14),
                  Container(width: tileWidth * 0.35, height: 9, color: AppColors.tile),
                  const SizedBox(height: 9),
                  Container(width: tileWidth * 0.75, height: 13, color: AppColors.tile),
                  const SizedBox(height: 9),
                  Container(width: tileWidth * 0.3, height: 11, color: AppColors.tile),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}
