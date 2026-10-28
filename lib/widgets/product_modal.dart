import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../models/product_model.dart';
import '../screens/checkout_screen.dart';
import '../screens/product_details_screen.dart';
import '../services/cart_service.dart';
import '../theme/app_theme.dart';
import '../utils/categories.dart';
import '../utils/formatters.dart';
import 'product_image.dart';
import 'quantity_stepper.dart';
import 'status_chip.dart';

/// Opens an interactive floating modal with an Elevate Red and Black theme.
Future<void> showProductModal({
  required BuildContext context,
  required Product product,
  required CartService cart,
  required VoidCallback onOpenCart,
}) {
  final isWide = MediaQuery.sizeOf(context).width >= 700;

  if (isWide) {
    return showDialog<void>(
      context: context,
      barrierColor: AppColors.elevateBlack.withValues(alpha: 0.65),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: _ProductModalContent(
              product: product,
              cart: cart,
              onOpenCart: onOpenCart,
              isDialog: true,
            ),
          ),
        ),
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.elevateBlack.withValues(alpha: 0.65),
    builder: (ctx) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: _ProductModalContent(
        product: product,
        cart: cart,
        onOpenCart: onOpenCart,
        isDialog: false,
      ),
    ),
  );
}

class _ProductModalContent extends StatefulWidget {
  const _ProductModalContent({
    required this.product,
    required this.cart,
    required this.onOpenCart,
    required this.isDialog,
  });

  final Product product;
  final CartService cart;
  final VoidCallback onOpenCart;
  final bool isDialog;

  @override
  State<_ProductModalContent> createState() => _ProductModalContentState();
}

class _ProductModalContentState extends State<_ProductModalContent> {
  int _quantity = 1;
  bool _adding = false;

  int get _max => widget.product.maxPerOrder;

  void _buyNow() {
    if (!widget.product.isAvailable) return;
    Navigator.of(context).pop();
    final item = CartItem.fromProduct(widget.product, quantity: _quantity);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CheckoutScreen(
          cart: widget.cart,
          onShop: widget.onOpenCart,
          directItem: item,
        ),
      ),
    );
  }

  void _addToCart() {
    if (!widget.product.isAvailable) return;
    setState(() => _adding = true);
    final added = widget.cart.add(widget.product, quantity: _quantity);
    setState(() => _adding = false);

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.elevateBlack,
          content: Text(
            added
                ? '${widget.product.name} added to your cart.'
                : 'That is the most of this piece you can order at once.',
            style: const TextStyle(color: AppColors.paper),
          ),
          action: added
              ? SnackBarAction(
                  label: 'View cart',
                  textColor: AppColors.elevateRed,
                  onPressed: widget.onOpenCart,
                )
              : null,
        ),
      );
  }

  void _openFullDetails() {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailsScreen(
          product: widget.product,
          cart: widget.cart,
          onOpenCart: widget.onOpenCart,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final category =
        ProductCategories.displayLabel(product.category) ?? 'ELEVATE';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(widget.isDialog ? 12 : 16),
        border: Border.all(
          color: AppColors.elevateRed.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.elevateBlack.withValues(alpha: 0.2),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.elevateRed.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Accent red bar at top
            Container(
              height: 4,
              color: AppColors.elevateRed,
            ),
            // Header / Close row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 14, 0),
              child: Row(
                children: <Widget>[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.elevateRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppColors.elevateRed.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      category.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Archivo',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppColors.elevateRed,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: 'Close',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: widget.isDialog
                    ? _buildWideLayout(product)
                    : _buildCompactLayout(product),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideLayout(Product product) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 250,
            height: 250,
            color: AppColors.tile,
            child: ProductImage(imageUrl: product.imageUrl),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildTitleAndPrice(product),
              const SizedBox(height: 12),
              _buildDescription(product),
              const SizedBox(height: 20),
              if (product.isAvailable) ...<Widget>[
                _buildQuantityRow(),
                const SizedBox(height: 20),
                _buildActionButtons(product),
              ] else
                _buildUnavailableMessage(product),
              const SizedBox(height: 14),
              _buildDetailsLink(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactLayout(Product product) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 190,
              height: 190,
              child: ProductImage(imageUrl: product.imageUrl),
            ),
          ),
        ),
        const SizedBox(height: 18),
        _buildTitleAndPrice(product),
        const SizedBox(height: 10),
        _buildDescription(product),
        const SizedBox(height: 18),
        if (product.isAvailable) ...<Widget>[
          _buildQuantityRow(),
          const SizedBox(height: 18),
          _buildActionButtons(product),
        ] else
          _buildUnavailableMessage(product),
        const SizedBox(height: 12),
        Center(child: _buildDetailsLink()),
      ],
    );
  }

  Widget _buildTitleAndPrice(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          product.name,
          style: const TextStyle(
            fontFamily: 'Archivo',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.elevateBlack,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            Text(
              product.hasPrice ? formatPeso(product.price) : 'Price pending',
              style: const TextStyle(
                fontFamily: 'Archivo',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.elevateRed,
              ),
            ),
            const SizedBox(width: 12),
            if (product.stockNote != null)
              StatusChip(
                label: product.stockNote!,
                tone: product.isSoldOut
                    ? StatusTone.negative
                    : product.stock != null && product.stock! <= 3
                        ? StatusTone.pending
                        : StatusTone.positive,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescription(Product product) {
    return Text(
      product.description ??
          'Official ELEVATE merchandise piece made with premium materials for everyday wear.',
      style: const TextStyle(
        fontFamily: 'Archivo',
        fontSize: 13,
        height: 1.55,
        color: AppColors.muted,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildQuantityRow() {
    return Row(
      children: <Widget>[
        const Text(
          'Quantity',
          style: TextStyle(
            fontFamily: 'Archivo',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.elevateBlack,
          ),
        ),
        const Spacer(),
        QuantityStepper(
          value: _quantity,
          canDecrement: _quantity > 1,
          canIncrement: _quantity < _max,
          onDecrement: () => setState(() => _quantity -= 1),
          onIncrement: () => setState(() => _quantity += 1),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Product product) {
    final lineTotal = product.price * _quantity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Buy Now Button in Elevate Red
        FilledButton(
          onPressed: _buyNow,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.elevateRed,
            foregroundColor: AppColors.paper,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: Text(
            'Buy Now · ${formatPeso(lineTotal)}',
            style: const TextStyle(
              fontFamily: 'Archivo',
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Add to Cart Button in Jet Black
        OutlinedButton(
          onPressed: _adding ? null : _addToCart,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.elevateBlack,
            side: const BorderSide(color: AppColors.elevateBlack, width: 1.3),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: _adding
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.add_shopping_cart, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Add to Cart',
                      style: TextStyle(
                        fontFamily: 'Archivo',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildUnavailableMessage(Product product) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.tile,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        product.hasPrice
            ? 'This piece is sold out. Check back soon for the next drop.'
            : 'Not available to order yet.',
        style: const TextStyle(
          fontFamily: 'Archivo',
          fontSize: 12,
          color: AppColors.muted,
        ),
      ),
    );
  }

  Widget _buildDetailsLink() {
    return TextButton(
      onPressed: _openFullDetails,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.muted,
        padding: const EdgeInsets.symmetric(vertical: 6),
      ),
      child: const Text(
        'View full product specifications →',
        style: TextStyle(
          fontFamily: 'Archivo',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
