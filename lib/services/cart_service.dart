import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_item.dart';
import '../models/product_model.dart';

/// Storage seam so the cart can be tested without platform plugins.
abstract class CartStorage {
  Future<String?> read();
  Future<void> write(String value);
}

class SharedPreferencesCartStorage implements CartStorage {
  static const String key = 'elevate.cart.v1';

  @override
  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<void> write(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }
}

/// A guest cart that survives reloads and app restarts.
///
/// Prices are cached only for display. The server recalculates every price,
/// stock check, and total in `create_order` when checkout happens.
class CartService extends ChangeNotifier {
  CartService({CartStorage? storage})
      : _storage = storage ?? SharedPreferencesCartStorage();

  static const int maxPerLine = 20;

  final CartStorage _storage;
  List<CartItem> _items = <CartItem>[];
  bool _loaded = false;

  List<CartItem> get items => List<CartItem>.unmodifiable(_items);

  bool get isLoaded => _loaded;

  bool get isEmpty => _items.isEmpty;

  int get itemCount => _items.fold<int>(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      _items.fold<double>(0, (sum, item) => sum + item.lineTotal);

  CartItem? itemFor(int productId) {
    for (final item in _items) {
      if (item.productId == productId) return item;
    }
    return null;
  }

  Future<void> load() async {
    try {
      final raw = await _storage.read();
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final seen = <int>{};
          _items = decoded
              .whereType<Map>()
              .map((row) => CartItem.fromJson(Map<String, dynamic>.from(row)))
              .where((item) =>
                  item.productId > 0 &&
                  item.quantity > 0 &&
                  item.quantity <= maxPerLine &&
                  seen.add(item.productId))
              .toList();
        }
      }
    } catch (_) {
      // A damaged cache should never stop the store from opening.
      _items = <CartItem>[];
    }
    _loaded = true;
    notifyListeners();
  }

  bool add(Product product, {int quantity = 1}) {
    if (!product.isAvailable || quantity < 1) return false;
    final index = _items.indexWhere((item) => item.productId == product.id);
    if (index == -1) {
      final max = product.maxPerOrder;
      if (max < 1) return false;
      _items = <CartItem>[
        ..._items,
        CartItem.fromProduct(
          product,
          quantity: quantity > max ? max : quantity,
        ),
      ];
    } else {
      final current = _items[index];
      final max = current.maxQuantity;
      final next = (current.quantity + quantity).clamp(1, max).toInt();
      if (next == current.quantity) return false;
      _items = List<CartItem>.from(_items)
        ..[index] = current.copyWith(quantity: next);
    }
    _commit();
    return true;
  }

  bool increment(int productId) {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index == -1) return false;
    final item = _items[index];
    if (!item.canIncrement) return false;
    _items = List<CartItem>.from(_items)
      ..[index] = item.copyWith(quantity: item.quantity + 1);
    _commit();
    return true;
  }

  /// Decreases by one. Dropping below one removes the line.
  bool decrement(int productId) {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index == -1) return false;
    final item = _items[index];
    if (item.quantity <= 1) {
      return remove(productId);
    }
    _items = List<CartItem>.from(_items)
      ..[index] = item.copyWith(quantity: item.quantity - 1);
    _commit();
    return true;
  }

  bool setQuantity(int productId, int quantity) {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index == -1) return false;
    if (quantity < 1) return remove(productId);
    final item = _items[index];
    final max = item.maxQuantity;
    final next = quantity.clamp(1, max).toInt();
    if (next == item.quantity) return false;
    _items = List<CartItem>.from(_items)
      ..[index] = item.copyWith(quantity: next);
    _commit();
    return true;
  }

  bool remove(int productId) {
    final next = _items
        .where((item) => item.productId != productId)
        .toList(growable: false);
    if (next.length == _items.length) return false;
    _items = next;
    _commit();
    return true;
  }

  void clear() {
    if (_items.isEmpty) return;
    _items = <CartItem>[];
    _commit();
  }

  void _commit() {
    notifyListeners();
    unawaited(_persist());
  }

  Future<void> _persist() async {
    try {
      final payload = jsonEncode(
        _items.map((item) => item.toJson()).toList(growable: false),
      );
      await _storage.write(payload);
    } catch (_) {
      // Persistence is best effort; the in-memory cart still works.
    }
  }
}
