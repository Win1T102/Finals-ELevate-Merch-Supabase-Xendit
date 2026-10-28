import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../models/product_model.dart';
import '../services/cart_service.dart';
import '../theme/app_theme.dart';
import '../utils/categories.dart';
import '../utils/formatters.dart';
import '../utils/layout.dart';
import '../widgets/brand_logo.dart';
import '../widgets/cart_icon_button.dart';
import '../widgets/elevate_background.dart';
import '../widgets/product_image.dart';
import '../widgets/quantity_stepper.dart';
import '../widgets/status_chip.dart';
import 'checkout_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({
    super.key,
    required this.product,
    required this.cart,
    required this.onOpenCart,
  });

  final Product product;
  final CartService cart;
  final VoidCallback onOpenCart;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;
  bool _adding = false;

  int get _max => widget.product.maxPerOrder;

  void _goToCart() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    widget.onOpenCart();
  }

  void _buyNow() {
    if (!widget.product.isAvailable) return;
    final item = CartItem.fromProduct(widget.product, quantity: _quantity);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CheckoutScreen(
          cart: widget.cart,
          onShop: _goToCart,
          directItem: item,
        ),
      ),
    );
  }

  Future<void> _addToCart() async {
    if (!widget.product.isAvailable) return;
    setState(() => _adding = true);
    final added = widget.cart.add(widget.product, quantity: _quantity);
    if (!mounted) return;
    setState(() => _adding = false);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            added
                ? '${widget.product.name} added to your cart.'
                : 'That is the most of this piece you can order at once.',
          ),
          action: added
              ? SnackBarAction(label: 'View cart', onPressed: _goToCart)
              : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return ElevateBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          titleSpacing: 0,
          title: const BrandLogo(size: 18),
          actions: <Widget>[
            ListenableBuilder(
              listenable: widget.cart,
              builder: (context, _) => CartIconButton(
                count: widget.cart.itemCount,
                onPressed: _goToCart,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final padding = Layout.pagePadding(constraints.maxWidth);
            final contentWidth = constraints.maxWidth - padding * 2;
            final wide = contentWidth >= 820;

            final image = AspectRatio(
              aspectRatio: wide ? 0.98 : 1,
              child: ProductImage(imageUrl: product.imageUrl),
            );

            final details = _Details(
              product: product,
              quantity: _quantity,
              max: _max,
              adding: _adding,
              cart: widget.cart,
              onQuantity: (value) {
                if (value < 1 || value > _max) return;
                setState(() => _quantity = value);
              },
              onAdd: _addToCart,
              onBuyNow: _buyNow,
              onViewCart: _goToCart,
            );

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(padding, 8, padding, 56),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(flex: 11, child: image),
                          const SizedBox(width: 52),
                          SizedBox(width: 400, child: details),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          image,
                          const SizedBox(height: 28),
                          details,
                        ],
                      ),
              ),
            );
          },
        ),
      ),
    ),
  );
  }
}

class _Details extends StatelessWidget {
  const _Details({
    required this.product,
    required this.quantity,
    required this.max,
    required this.adding,
    required this.cart,
    required this.onQuantity,
    required this.onAdd,
    required this.onBuyNow,
    required this.onViewCart,
  });

  final Product product;
  final int quantity;
  final int max;
  final bool adding;
  final CartService cart;
  final ValueChanged<int> onQuantity;
  final VoidCallback onAdd;
  final VoidCallback onBuyNow;
  final VoidCallback onViewCart;

  @override
  Widget build(BuildContext context) {
    final category = ProductCategories.displayLabel(product.category) ?? 'ELEVATE';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          category,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          product.name,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontSize: 38,
                letterSpacing: -1.4,
              ),
        ),
        const SizedBox(height: 16),
        Text(
          product.hasPrice ? formatPeso(product.price) : 'Price pending',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 10),
        if (!product.hasPrice)
          const StatusChip(label: 'Not available to order yet')
        else if (product.isSoldOut)
          const StatusChip(label: 'Sold out', tone: StatusTone.negative)
        else if (product.stockNote != null)
          Text(
            product.stockNote!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: product.stock != null && product.stock! <= 3
                      ? AppColors.warning
                      : AppColors.success,
                ),
          ),
        const SizedBox(height: 24),
        Text(
          product.description ??
              'A piece from the ELEVATE collection, made for everyday wear.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
                height: 1.65,
              ),
        ),
        const SizedBox(height: 28),
        if (product.isAvailable) ...<Widget>[
          Row(
            children: <Widget>[
              Text(
                'Quantity',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const Spacer(),
              QuantityStepper(
                value: quantity,
                canDecrement: quantity > 1,
                canIncrement: quantity < max,
                onDecrement: () => onQuantity(quantity - 1),
                onIncrement: () => onQuantity(quantity + 1),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: adding ? null : onAdd,
            child: adding
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.paper,
                    ),
                  )
                : Text('Add to cart · ${formatPeso(product.price * quantity)}'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: adding ? null : onBuyNow,
            child: const Text('Buy Now'),
          ),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: cart,
            builder: (context, _) {
              final inCart = cart.itemFor(product.id);
              if (inCart == null) {
                return Text(
                  'Guest checkout. No account needed.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                );
              }
              return Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${inCart.quantity} in your cart.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: onViewCart,
                    child: const Text('View cart'),
                  ),
                ],
              );
            },
          ),
        ] else ...<Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.tile,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              product.hasPrice
                  ? 'This piece is sold out. Check back soon, or ask the team about the next drop.'
                  : 'This piece is not open for orders yet. Check back soon.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    height: 1.6,
                  ),
            ),
          ),
        ],
        const SizedBox(height: 30),
        const _InfoRow(
          title: 'Payment',
          body: 'GCash, card, and other options through Xendit. '
              'The store never sees your payment details.',
        ),
        const _InfoRow(
          title: 'Delivery',
          body: 'The team arranges delivery after payment. Add your address '
              'and any notes at checkout.',
        ),
        const _InfoRow(
          title: 'Stock',
          body: 'Availability is checked again when the order is placed, '
              'so the total you confirm is the total you pay.',
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 96,
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          Expanded(
            child: Text(
              body,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    height: 1.6,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
