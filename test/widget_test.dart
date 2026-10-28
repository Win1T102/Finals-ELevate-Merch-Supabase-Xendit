import 'package:flutter_test/flutter_test.dart';
import 'package:elevate_merch/models/product_model.dart';
import 'package:elevate_merch/services/cart_service.dart';
import 'package:elevate_merch/services/product_service.dart';

class _InMemoryCartStorage implements CartStorage {
  String? _data;

  @override
  Future<String?> read() async => _data;

  @override
  Future<void> write(String value) async {
    _data = value;
  }
}

void main() {
  group('ELEVATE MERCH Unit Tests', () {
    test('Product.fromMap parses Supabase record correctly', () {
      final map = {
        'id': 4,
        'name': 'Elevate Pin',
        'price': 25.0,
        'image_url': 'https://example.com/pin.jpg',
        'category': 'Pins',
        'description': 'Official Elevate pin',
        'stock': 50,
        'is_active': true,
      };

      final product = Product.fromMap(map);

      expect(product.id, 4);
      expect(product.name, 'Elevate Pin');
      expect(product.price, 25.0);
      expect(product.category, 'Pins');
      expect(product.isAvailable, isTrue);
      expect(product.maxPerOrder, 20);
    });

    test('CartService calculates quantities and subtotals accurately', () async {
      final storage = _InMemoryCartStorage();
      final cart = CartService(storage: storage);
      await cart.load();

      const product = Product(
        id: 4,
        name: 'Elevate Pin',
        price: 25.0,
        imageUrl: 'https://example.com/pin.jpg',
        category: 'Pins',
        stock: 50,
      );

      final added = cart.add(product, quantity: 2);
      expect(added, isTrue);
      expect(cart.itemCount, 2);
      expect(cart.subtotal, 50.0);

      // Increment
      cart.increment(4);
      expect(cart.itemCount, 3);
      expect(cart.subtotal, 75.0);

      // Decrement
      cart.decrement(4);
      expect(cart.itemCount, 2);
      expect(cart.subtotal, 50.0);

      // Remove
      cart.remove(4);
      expect(cart.isEmpty, isTrue);
      expect(cart.itemCount, 0);
      expect(cart.subtotal, 0.0);
    });

    test('ProductService contains 16 official ELEVATE items across all categories', () {
      final items = ProductService.officialCatalog;
      expect(items.length, 16);

      final categories = items.map((i) => i.category).toSet();
      expect(categories.contains('Pins'), isTrue);
      expect(categories.contains('T-shirts'), isTrue);
      expect(categories.contains('Long sleeves'), isTrue);
      expect(categories.contains('Lanyards'), isTrue);
      expect(categories.contains('Bookmarks'), isTrue);
    });
  });
}
