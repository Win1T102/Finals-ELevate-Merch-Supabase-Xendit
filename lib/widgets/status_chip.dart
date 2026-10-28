import 'package:flutter/material.dart';

import '../models/order_model.dart';
import '../theme/app_theme.dart';

enum StatusTone { pending, positive, negative, neutral }

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
  });

  final String label;
  final StatusTone tone;

  factory StatusChip.forPayment(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return const StatusChip(label: 'Paid', tone: StatusTone.positive);
      case PaymentStatus.pending:
      case PaymentStatus.unknown:
        return const StatusChip(
          label: 'Awaiting payment',
          tone: StatusTone.pending,
        );
      case PaymentStatus.failed:
        return const StatusChip(
          label: 'Payment failed',
          tone: StatusTone.negative,
        );
      case PaymentStatus.expired:
        return const StatusChip(label: 'Expired', tone: StatusTone.negative);
      case PaymentStatus.cancelled:
        return const StatusChip(label: 'Cancelled', tone: StatusTone.neutral);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      StatusTone.pending => (AppColors.warningSurface, AppColors.warning),
      StatusTone.positive => (AppColors.successSurface, AppColors.success),
      StatusTone.negative => (AppColors.dangerSurface, AppColors.danger),
      StatusTone.neutral => (AppColors.tile, AppColors.muted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
