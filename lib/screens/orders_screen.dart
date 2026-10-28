import 'package:flutter/material.dart';

import '../models/order_model.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/friendly_error.dart';
import '../utils/layout.dart';
import '../widgets/brand_logo.dart';
import '../widgets/elevate_background.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_chip.dart';
import 'order_details_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, required this.onShop});

  final VoidCallback onShop;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderService _orderService = OrderService();

  List<_Entry> _entries = const <_Entry>[];
  bool _loading = true;
  bool _partial = false;
  Object? _error;
  int _unavailable = 0;
  bool _signedIn = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _partial = false;
    });

    final signedIn = _orderService.isSignedIn;
    final entries = <_Entry>[];
    var partial = false;

    final accesses = await _orderService.loadGuestAccesses();
    final tokens = <String, String>{
      for (final access in accesses) access.reference: access.token,
    };

    if (signedIn) {
      try {
        final accountOrders = await _orderService.fetchMyOrders();
        entries.addAll(
          accountOrders.map((order) => _Entry(order, tokens[order.reference])),
        );
      } catch (_) {
        partial = true;
      }
    }

    final guest = await _orderService.loadGuestOrderHistory();
    entries.addAll(
      guest.orders.map((order) => _Entry(order, tokens[order.reference])),
    );

    final seen = <String>{};
    final merged = entries
        .where((entry) => entry.order.reference.isNotEmpty)
        .where((entry) => seen.add(entry.order.reference))
        .toList()
      ..sort((a, b) => b.order.createdAt.compareTo(a.order.createdAt));

    if (!mounted) return;
    setState(() {
      _entries = merged;
      _signedIn = signedIn;
      _partial = partial;
      _unavailable = guest.unavailable;
      _loading = false;
      if (merged.isEmpty && partial) {
        _error = Exception('account orders unavailable');
      }
    });
  }

  void _open(_Entry entry) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderDetailsScreen(
          reference: entry.order.reference,
          guestToken: entry.token,
          onShop: widget.onShop,
        ),
      ),
    );
  }

  void _keepShopping() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    widget.onShop();
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
              onPressed: _loading ? null : _load,
              tooltip: 'Refresh orders',
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

            if (_loading) {
              return const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }

            if (_error != null || _entries.isEmpty) {
              if (_entries.isEmpty && _error != null) {
                return EmptyState(
                  title: 'Orders could not load',
                  message: friendlyError(
                    _error!,
                    fallback: 'Check your connection and try again.',
                  ),
                  actionLabel: 'Try again',
                  onAction: _load,
                  icon: Icons.receipt_long_outlined,
                );
              }
              return EmptyState(
                title: 'No orders yet',
                message: _signedIn
                    ? 'Orders placed while signed in will appear here, along '
                        'with any guest orders saved on this device.'
                    : 'Guest orders placed on this device are kept here. '
                        'Ordering does not require an account.',
                actionLabel: 'Shop the collection',
                onAction: _keepShopping,
                icon: Icons.receipt_long_outlined,
              );
            }

            return RefreshIndicator(
              onRefresh: _load,
              color: AppColors.ink,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(padding, 16, padding, 56),
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        'Orders',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(width: 14),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          '${_entries.length}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.muted,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _signedIn
                        ? 'Account orders and guest orders saved on this device.'
                        : 'Guest orders are saved on this device. Keep the '
                            'reference if you need help with one.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                  ),
                  if (_partial) ...<Widget>[
                    const SizedBox(height: 14),
                    _Note(
                      text: 'Some account orders could not be loaded. '
                          'Pull to refresh or check your connection.',
                    ),
                  ],
                  if (_unavailable > 0) ...<Widget>[
                    const SizedBox(height: 14),
                    _Note(
                      text: '$_unavailable saved '
                          '${_unavailable == 1 ? 'order' : 'orders'} could not '
                          'be found on the server.',
                    ),
                  ],
                  const SizedBox(height: 24),
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.line)),
                    ),
                    child: Column(
                      children: _entries
                          .map(
                            (entry) => _OrderRow(
                              entry: entry,
                              onTap: () => _open(entry),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton(
                      onPressed: _keepShopping,
                      child: const Text('Keep shopping'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
  }
}

class _Entry {
  const _Entry(this.order, this.token);

  final Order order;
  final String? token;
}

class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningSurface,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.warning,
              height: 1.5,
            ),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.entry, required this.onTap});

  final _Entry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final order = entry.order;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        order.reference,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        formatOrderDate(order.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.muted,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                StatusChip.forPayment(order.paymentStatus),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              order.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    height: 1.55,
                  ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Text(
                  order.itemCount > 0
                      ? formatItemCount(order.itemCount)
                      : 'View order',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.muted,
                      ),
                ),
                const Spacer(),
                Text(
                  formatPeso(order.total),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
