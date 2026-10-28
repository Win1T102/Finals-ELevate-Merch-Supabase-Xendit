import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
    this.canDecrement = true,
    this.canIncrement = true,
    this.compact = false,
  });

  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final bool canDecrement;
  final bool canIncrement;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _StepButton(
          icon: Icons.remove,
          tooltip: 'Decrease quantity',
          onPressed: canDecrement ? onDecrement : null,
          compact: compact,
        ),
        Container(
          width: compact ? 34 : 44,
          alignment: Alignment.center,
          child: Text(
            '$value',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        _StepButton(
          icon: Icons.add,
          tooltip: 'Increase quantity',
          onPressed: canIncrement ? onIncrement : null,
          compact: compact,
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    required this.compact,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 30.0 : 38.0;
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.paper,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: enabled ? AppColors.ink : AppColors.line),
          borderRadius: BorderRadius.circular(2),
        ),
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              icon,
              size: compact ? 14 : 16,
              color: enabled ? AppColors.ink : AppColors.line,
            ),
          ),
        ),
      ),
    );
  }
}
