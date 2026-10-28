import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../theme/app_theme.dart';
import '../utils/categories.dart';
import '../utils/formatters.dart';
import 'product_image.dart';

/// A catalogue card: photograph, category, name, price, and a quick add.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onAdd,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final canAdd = product.isAvailable && onAdd != null;
    final category =
        ProductCategories.displayLabel(product.category) ?? 'ELEVATE';

    return Semantics(
      button: true,
      label:
          '${product.name}, ${product.hasPrice ? formatPeso(product.price) : 'price pending'}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        splashColor: AppColors.elevateRed.withValues(alpha: 0.1),
        highlightColor: AppColors.elevateRed.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.tile,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.line, width: 1),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: ProductImage(
                          imageUrl: product.imageUrl,
                          fit: BoxFit.contain,
                        ),
                      ),
                      if (product.isSoldOut)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.elevateBlack,
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(
                                color: AppColors.elevateRed.withValues(alpha: 0.4),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: const Text(
                              'Sold out',
                              style: TextStyle(
                                fontFamily: 'Archivo',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.paperWhite,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.elevateRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      category.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Archivo',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.elevateRed,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 38,
                child: Text(
                  product.name,
                  style: const TextStyle(
                    fontFamily: 'Archivo',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: AppColors.ink,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      product.hasPrice
                          ? formatPeso(product.price)
                          : 'Price pending',
                      style: TextStyle(
                        fontFamily: 'Archivo',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: product.hasPrice
                            ? AppColors.ink
                            : AppColors.muted,
                      ),
                    ),
                  ),
                  _QuickAdd(enabled: canAdd, onPressed: canAdd ? onAdd : null),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAdd extends StatelessWidget {
  const _QuickAdd({required this.enabled, this.onPressed});

  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: enabled ? 'Add to cart' : 'Unavailable',
      child: Material(
        color: enabled ? AppColors.elevateRed : AppColors.tile,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: enabled ? AppColors.elevateRed : AppColors.line,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          splashColor: Colors.white.withValues(alpha: 0.2),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(
              Icons.add_shopping_cart,
              size: 16,
              color: enabled ? AppColors.paperWhite : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
