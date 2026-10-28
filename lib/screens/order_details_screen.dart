import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/order_model.dart';
import '../services/order_service.dart';
import '../services/payment_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/friendly_error.dart';
import '../utils/layout.dart';
import '../widgets/brand_logo.dart';
import '../widgets/elevate_background.dart';
import '../widgets/empty_state.dart';
import '../widgets/product_image.dart';
import '../widgets/status_chip.dart';
import 'payment_webview_screen.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({
    super.key,
    required this.reference,
    required this.onShop,
    this.guestToken,
    this.notice,
  });

  final String reference;
  final String? guestToken;
  final VoidCallback onShop;
  final String? notice;

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final OrderService _orderService = OrderService();
  final PaymentService _paymentService = PaymentService();

  Order? _order;
  Object? _error;
  bool _loading = true;
  bool _refreshing = false;
  bool _paying = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final order = await _orderService.fetchOrder(
        widget.reference,
        token: widget.guestToken,
      );
      if (!mounted) return;
      setState(() {
        _order = order;
        _loading = false;
        _error = null;
      });
      _syncPolling();
    } catch (error) {
      if (!mounted) return;
      if (silent && _order != null) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _syncPolling() {
    final awaiting = _order?.awaitingPayment ?? false;
    if (!awaiting) {
      _poll?.cancel();
      _poll = null;
      return;
    }
    _poll ??= Timer.periodic(const Duration(seconds: 6), (_) {
      _refreshStatus();
    });
  }

  Future<void> _refreshStatus() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final order = await _orderService.fetchOrder(
        widget.reference,
        token: widget.guestToken,
      );
      if (!mounted) return;
      setState(() => _order = order);
      _syncPolling();
    } catch (_) {
      // Keep the last known state; the next tick or a manual refresh retries.
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _payNow() async {
    if (_paying) return;
    setState(() => _paying = true);
    try {
      final payment = await _paymentService.startPayment(
        reference: widget.reference,
        guestToken: widget.guestToken,
      );
      if (!mounted) return;

      if (payment.isPaid) {
        await _load(silent: true);
        return;
      }
      if (!payment.hasCheckout) {
        throw const FriendlyException(
          'Payment could not be started. Try again in a moment.',
        );
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (paymentContext) => PaymentWebViewScreen(
            checkoutUrl: payment.checkoutUrl!,
            reference: widget.reference,
            guestToken: widget.guestToken,
            onShop: widget.onShop,
            onFinished: () => Navigator.of(paymentContext).pop(),
          ),
        ),
      );
      if (!mounted) return;
      await _load(silent: true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(error))),
      );
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  void _keepShopping() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    widget.onShop();
  }

  Future<void> _copyReference() async {
    await Clipboard.setData(ClipboardData(text: widget.reference));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order reference copied.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevateBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          titleSpacing: 0,
          title: const BrandLogo(size: 18),
          actions: <Widget>[
            IconButton(
              onPressed: _loading ? null : () => _load(silent: true),
              tooltip: 'Refresh order',
              icon: const Icon(Icons.refresh, size: 20),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final padding = Layout.pagePadding(constraints.maxWidth);
            if (_loading && _order == null) {
              return const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            if (_order == null) {
              return EmptyState(
                title: 'This order could not be opened',
                message: friendlyError(
                  _error ?? Exception(),
                  fallback:
                      'Check the reference, or open the order from the device that placed it.',
                ),
                actionLabel: 'Try again',
                onAction: _load,
                icon: Icons.receipt_long_outlined,
              );
            }
            return _OrderBody(
              order: _order!,
              notice: widget.notice,
              paying: _paying,
              padding: padding,
              onPay: _payNow,
              onRefresh: () => _load(silent: true),
              onCopy: _copyReference,
              onShop: _keepShopping,
            );
          },
        ),
      ),
    ),
  );
  }
}

class _OrderBody extends StatelessWidget {
  const _OrderBody({
    required this.order,
    required this.notice,
    required this.paying,
    required this.padding,
    required this.onPay,
    required this.onRefresh,
    required this.onCopy,
    required this.onShop,
  });

  final Order order;
  final String? notice;
  final bool paying;
  final double padding;
  final VoidCallback onPay;
  final VoidCallback onRefresh;
  final VoidCallback onCopy;
  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 860;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.ink,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(padding, 16, padding, 56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 14,
              runSpacing: 8,
              children: <Widget>[
                Text(
                  'Order ${order.reference}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                      ),
                ),
                StatusChip.forPayment(order.paymentStatus),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              order.paymentStatus.isPaid ? 'Thank you.' : 'Your order.',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 6),
            Text(
              formatOrderDate(order.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
            ),
            const SizedBox(height: 18),
            Text(
              formatPeso(order.total),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontSize: 40,
                  ),
            ),
            if ((notice ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.tile,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  notice!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        height: 1.55,
                      ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            _PaymentPanel(
              order: order,
              paying: paying,
              onPay: onPay,
              onShop: onShop,
            ),
            const SizedBox(height: 36),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(flex: 6, child: _ItemsPanel(order: order)),
                  const SizedBox(width: 48),
                  Expanded(flex: 4, child: _DeliveryPanel(order: order)),
                ],
              )
            else ...<Widget>[
              _ItemsPanel(order: order),
              const SizedBox(height: 34),
              _DeliveryPanel(order: order),
            ],
            const SizedBox(height: 34),
            Row(
              children: <Widget>[
                OutlinedButton(
                  onPressed: onShop,
                  child: const Text('Keep shopping'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onCopy,
                  child: const Text('Copy reference'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Keep this reference if you need help with the order. '
              'The team only treats an order as paid after Xendit confirms it.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    height: 1.6,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentPanel extends StatelessWidget {
  const _PaymentPanel({
    required this.order,
    required this.paying,
    required this.onPay,
    required this.onShop,
  });

  final Order order;
  final bool paying;
  final VoidCallback onPay;
  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    final (title, body) = _copy();
    final canPay = order.awaitingPayment;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (order.awaitingPayment)
                Text(
                  'Checks automatically',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.muted,
                      ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  height: 1.6,
                ),
          ),
          if (order.paidAt != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              'Paid ${formatOrderDate(order.paidAt!)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
            ),
          ],
          if (canPay) ...<Widget>[
            const SizedBox(height: 18),
            FilledButton(
              onPressed: paying ? null : onPay,
              child: paying
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.paper,
                      ),
                    )
                  : const Text('Pay now'),
            ),
          ],
          if (!order.awaitingPayment &&
              !order.paymentStatus.isPaid &&
              order.paymentStatus != PaymentStatus.unknown) ...<Widget>[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onShop,
              child: const Text('Start a new order'),
            ),
          ],
        ],
      ),
    );
  }

  (String, String) _copy() {
    switch (order.paymentStatus) {
      case PaymentStatus.paid:
        return (
          'Payment confirmed',
          'Xendit confirmed the payment. The team is preparing your order and '
              'will arrange delivery using the details below.'
        );
      case PaymentStatus.failed:
        return (
          'The payment did not go through',
          'No payment was recorded for this order. Place a new order to try '
              'again, or show this reference to the team.'
        );
      case PaymentStatus.expired:
        return (
          'This payment expired',
          'The checkout window closed before payment was confirmed. Place a '
              'new order to try again.'
        );
      case PaymentStatus.cancelled:
        return (
          'This order was cancelled',
          'This order is closed. Place a new order when you are ready.'
        );
      case PaymentStatus.pending:
      case PaymentStatus.unknown:
        return (
          'Waiting for payment',
          'This page checks Xendit every few seconds. If you have not paid '
              'yet, use Pay now. Keep the confirmation from Xendit for your '
              'records.'
        );
    }
  }
}

class _ItemsPanel extends StatelessWidget {
  const _ItemsPanel({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Items',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 14),
        Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: Column(
            children: <Widget>[
              ...order.items.map(
                (item) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.line),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                        width: 58,
                        height: 58,
                        child: ProductImage(imageUrl: item.imageUrl ?? ''),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              item.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${item.quantity} × ${formatPeso(item.unitPrice)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        formatPeso(item.subtotal),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _TotalLine(label: 'Subtotal', value: formatPeso(order.subtotal)),
        const SizedBox(height: 8),
        _TotalLine(
          label: 'Delivery',
          value: order.shippingFee > 0
              ? formatPeso(order.shippingFee)
              : 'Arranged after payment',
          muted: order.shippingFee <= 0,
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Text(
              'Total',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            Text(
              formatPeso(order.total),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TotalLine extends StatelessWidget {
  const _TotalLine({
    required this.label,
    required this.value,
    this.muted = false,
  });

  final String label;
  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
              ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: muted ? AppColors.muted : AppColors.ink,
                  fontWeight: muted ? FontWeight.w400 : FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _DeliveryPanel extends StatelessWidget {
  const _DeliveryPanel({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Delivery details',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 14),
        Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: Column(
            children: <Widget>[
              _DetailLine(label: 'Name', value: order.customerName ?? '—'),
              _DetailLine(label: 'Mobile', value: order.customerPhone ?? '—'),
              if ((order.customerEmail ?? '').isNotEmpty)
                _DetailLine(
                  label: 'Email',
                  value: order.customerEmail!,
                ),
              _DetailLine(
                label: 'Address',
                value: order.deliveryAddress ?? '—',
              ),
              if ((order.notes ?? '').isNotEmpty)
                _DetailLine(label: 'Notes', value: order.notes!),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 74,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.55,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
