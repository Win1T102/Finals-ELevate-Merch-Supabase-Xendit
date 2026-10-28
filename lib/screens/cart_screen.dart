import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../services/cart_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/layout.dart';
import '../widgets/empty_state.dart';
import '../widgets/product_image.dart';
import '../widgets/quantity_stepper.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({
    super.key,
    required this.cart,
    required this.onShop,
  });

  final CartService cart;
  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final padding = Layout.pagePadding(constraints.maxWidth);
            final contentWidth = constraints.maxWidth - padding * 2;
            final wide = contentWidth >= 900;

            if (cart.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(padding, 24, padding, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Your cart',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 30),
                    EmptyState(
                      title: 'Your cart is empty',
                      message:
                          'Pieces you add stay on this device until you check '
                          'out or clear them.',
                      actionLabel: 'Shop the collection',
                      onAction: onShop,
                      icon: Icons.shopping_bag_outlined,
                    ),
                  ],
                ),
              );
            }

            final list = _CartList(
              cart: cart,
              onClear: () => _confirmClear(context),
              onBrowse: onShop,
            );
            final summary = _Summary(
              cart: cart,
              onCheckout: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CheckoutScreen(cart: cart, onShop: onShop),
                  ),
                );
              },
              onShop: onShop,
            );

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(padding, 24, padding, 56),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        'Your cart',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(width: 14),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          formatItemCount(cart.itemCount),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: list),
                        const SizedBox(width: 56),
                        SizedBox(width: 340, child: summary),
                      ],
                    )
                  else ...<Widget>[
                    list,
                    const SizedBox(height: 36),
                    summary,
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear the cart?'),
        content: const Text(
          'Every piece will be removed from this device. This cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep cart'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear cart'),
          ),
        ],
      ),
    );
    if (confirmed == true) cart.clear();
  }
}

class _CartList extends StatelessWidget {
  const _CartList({
    required this.cart,
    required this.onClear,
    required this.onBrowse,
  });

  final CartService cart;
  final VoidCallback onClear;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: Column(
            children: cart.items
                .map(
                  (item) => _CartRow(
                    item: item,
                    onIncrement: () => cart.increment(item.productId),
                    onDecrement: () => cart.decrement(item.productId),
                    onRemove: () => cart.remove(item.productId),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: <Widget>[
            TextButton(
              onPressed: onBrowse,
              child: const Text('Continue shopping'),
            ),
            const Spacer(),
            TextButton(
              onPressed: onClear,
              style: TextButton.styleFrom(foregroundColor: AppColors.muted),
              child: const Text('Clear cart'),
            ),
          ],
        ),
      ],
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 84,
            height: 84,
            child: ProductImage(imageUrl: item.imageUrl),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: <Widget>[
                    Text(
                      formatPeso(item.price),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      formatPeso(item.lineTotal),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    QuantityStepper(
                      value: item.quantity,
                      compact: true,
                      canDecrement: true,
                      canIncrement: item.canIncrement,
                      onDecrement: onDecrement,
                      onIncrement: onIncrement,
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: onRemove,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.muted,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 30),
                      ),
                      child: const Text('Remove'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.cart,
    required this.onCheckout,
    required this.onShop,
  });

  final CartService cart;
  final VoidCallback onCheckout;
  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Summary',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 18),
          _SummaryRow(
            label: 'Subtotal',
            value: formatPeso(cart.subtotal),
          ),
          const SizedBox(height: 10),
          const _SummaryRow(
            label: 'Delivery',
            value: 'Arranged after payment',
            mutedValue: true,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Divider(),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                'Total',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                formatPeso(cart.subtotal),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onCheckout,
            child: const Text('Checkout'),
          ),
          const SizedBox(height: 14),
          Text(
            'Prices and stock are checked again when the order is placed. '
            'Payment is completed on Xendit.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  height: 1.55,
                ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.mutedValue = false,
  });

  final String label;
  final String value;
  final bool mutedValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                  color: mutedValue ? AppColors.muted : AppColors.ink,
                  fontWeight: mutedValue ? FontWeight.w400 : FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}
