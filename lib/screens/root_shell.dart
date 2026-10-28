import 'package:flutter/material.dart';

import '../services/cart_service.dart';
import '../widgets/app_header.dart';
import '../widgets/elevate_background.dart';
import '../widgets/store_bottom_bar.dart';
import 'cart_screen.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

/// The storefront shell. Opens on the dashboard; no sign-in gate.
class RootShell extends StatefulWidget {
  const RootShell({super.key, required this.cart});

  final CartService cart;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    widget.cart.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    widget.cart.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  void _select(int index) {
    if (!mounted) return;
    setState(() => _index = index);
  }

  void _openOrders() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrdersScreen(onShop: () => _select(0)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 820;
    final cart = widget.cart;

    return ElevateBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              AppHeader(
                cartCount: cart.itemCount,
                currentIndex: _index,
                onHome: () => _select(0),
                onCart: () => _select(1),
                onOrders: _openOrders,
                onProfile: () => _select(2),
              ),
              Expanded(
                child: IndexedStack(
                  index: _index,
                  children: <Widget>[
                    HomeScreen(
                      cart: cart,
                      onOpenCart: () => _select(1),
                    ),
                    CartScreen(
                      cart: cart,
                      onShop: () => _select(0),
                    ),
                    ProfileScreen(
                      onOpenOrders: _openOrders,
                      onShop: () => _select(0),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: wide
            ? null
            : StoreBottomBar(
                currentIndex: _index,
                cartCount: cart.itemCount,
                onSelect: _select,
              ),
      ),
    );
  }
}
