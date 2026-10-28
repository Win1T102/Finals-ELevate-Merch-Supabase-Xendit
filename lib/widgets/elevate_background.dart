import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Renders the atmospheric ELEVATE dark crimson smoke and obsidian black
/// gradient background across screens.
class ElevateBackground extends StatelessWidget {
  const ElevateBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: AppColors.elevateGradient,
      ),
      child: child,
    );
  }
}

