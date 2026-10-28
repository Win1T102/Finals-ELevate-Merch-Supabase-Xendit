import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class StoreBottomBar extends StatelessWidget {
  const StoreBottomBar({
    super.key,
    required this.currentIndex,
    required this.cartCount,
    required this.onSelect,
  });

  final int currentIndex;
  final int cartCount;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.tile.withValues(alpha: 0.96),
        border: const Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: <Widget>[
              _BottomItem(
                label: 'Shop',
                icon: Icons.storefront_outlined,
                selectedIcon: Icons.storefront,
                selected: currentIndex == 0,
                onTap: () => onSelect(0),
              ),
              _BottomItem(
                label: 'Cart',
                icon: Icons.shopping_bag_outlined,
                selectedIcon: Icons.shopping_bag,
                selected: currentIndex == 1,
                badge: cartCount,
                onTap: () => onSelect(1),
              ),
              _BottomItem(
                label: 'Profile',
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                selected: currentIndex == 2,
                onTap: () => onSelect(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.elevateRed : AppColors.muted;

    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                height: 22,
                width: 30,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.center,
                      child: Icon(
                        selected ? selectedIcon : icon,
                        size: 20,
                        color: color,
                      ),
                    ),
                    if (badge > 0)
                      Positioned(
                        right: -1,
                        top: -3,
                        child: Container(
                          constraints:
                              const BoxConstraints(minWidth: 14, minHeight: 14),
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.elevateRed,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            badge > 9 ? '9+' : '$badge',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.paperWhite,
                                  fontSize: 8.5,
                                  height: 1,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
