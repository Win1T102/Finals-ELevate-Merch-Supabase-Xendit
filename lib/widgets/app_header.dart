import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'brand_logo.dart';

/// The shop-wide header: wordmark on the left, actions on the right.
///
/// On wide layouts it carries full text navigation. On narrow layouts the
/// bottom bar handles Home/Cart/Profile and this header keeps orders and cart
/// within reach.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.cartCount,
    required this.currentIndex,
    required this.onHome,
    required this.onCart,
    required this.onOrders,
    required this.onProfile,
  });

  /// 0 = home, 1 = cart, 2 = profile.
  final int currentIndex;
  final int cartCount;
  final VoidCallback onHome;
  final VoidCallback onCart;
  final VoidCallback onOrders;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 820;
        final horizontal = constraints.maxWidth >= 1100 ? 48.0 : 20.0;

        return Padding(
          padding: EdgeInsets.fromLTRB(horizontal, wide ? 22 : 16, horizontal, 14),
          child: Row(
            children: <Widget>[
              InkWell(
                onTap: onHome,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: BrandLogo(size: wide ? 21 : 18),
                ),
              ),
              const Spacer(),
              if (wide) ...<Widget>[
                _HeaderLink(label: 'Shop', onTap: onHome, active: currentIndex == 0),
                const SizedBox(width: 28),
                _HeaderLink(label: 'Orders', onTap: onOrders, active: false),
                const SizedBox(width: 28),
                _HeaderLink(
                  label: 'Cart',
                  count: cartCount,
                  onTap: onCart,
                  active: currentIndex == 1,
                ),
                const SizedBox(width: 28),
                _HeaderLink(
                  label: 'Profile',
                  onTap: onProfile,
                  active: currentIndex == 2,
                ),
              ] else ...<Widget>[
                IconButton(
                  onPressed: onOrders,
                  tooltip: 'Orders',
                  icon: const Icon(Icons.receipt_long_outlined, size: 21),
                ),
                const SizedBox(width: 2),
                IconButton(
                  onPressed: onCart,
                  tooltip: cartCount == 0
                      ? 'Cart'
                      : 'Cart, $cartCount ${cartCount == 1 ? 'item' : 'items'}',
                  icon: _CartIcon(count: cartCount),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _HeaderLink extends StatelessWidget {
  const _HeaderLink({
    required this.label,
    required this.onTap,
    required this.active,
    this.count = 0,
  });

  final String label;
  final VoidCallback onTap;
  final bool active;
  final int count;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        color: active ? AppColors.ink : AppColors.muted,
                      ),
                ),
                if (count > 0) ...<Widget>[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: const BoxDecoration(color: AppColors.ink),
                    child: Text(
                      '$count',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.paper,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 5),
            Container(
              height: 1.2,
              width: active ? (count > 0 ? 48 : 30) : 0,
              color: AppColors.ink,
            ),
          ],
        ),
      ),
    );
  }
}

class _CartIcon extends StatelessWidget {
  const _CartIcon({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          const Align(
            alignment: Alignment.center,
            child: Icon(Icons.shopping_bag_outlined, size: 21),
          ),
          if (count > 0)
            Positioned(
              right: -3,
              top: -3,
              child: Container(
                constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                padding: const EdgeInsets.symmetric(horizontal: 3),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.ink,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.paper,
                        fontSize: 9,
                        height: 1,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
