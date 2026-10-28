import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// App-bar cart action with a compact count badge.
class CartIconButton extends StatelessWidget {
  const CartIconButton({
    super.key,
    required this.count,
    required this.onPressed,
  });

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: count == 0
          ? 'Cart'
          : 'Cart, $count ${count == 1 ? 'item' : 'items'}',
      icon: SizedBox(
        width: 26,
        height: 26,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            const Align(
              alignment: Alignment.center,
              child: Icon(Icons.shopping_bag_outlined, size: 21),
            ),
            if (count > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 15, minHeight: 15),
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
      ),
    );
  }
}
