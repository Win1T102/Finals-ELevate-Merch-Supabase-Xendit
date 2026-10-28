import '../utils/json_values.dart';
import 'product_model.dart';

/// A cart line. The cached price is used for display only; the database
/// recalculates every price and total when the order is created.
class CartItem {
  const CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    this.category,
    this.stock,
  });

  final int productId;
  final String name;
  final double price;
  final String imageUrl;
  final int quantity;
  final String? category;

  /// `null` means stock is not tracked.
  final int? stock;

  factory CartItem.fromProduct(Product product, {int quantity = 1}) {
    return CartItem(
      productId: product.id,
      name: product.name,
      price: product.price,
      imageUrl: product.imageUrl,
      quantity: quantity,
      category: product.category,
      stock: product.stock,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> map) {
    return CartItem(
      productId: asInt(map['product_id']),
      name: asString(map['name'], fallback: 'Item').trim(),
      price: asDouble(map['price']),
      imageUrl: asString(map['image_url']).trim(),
      quantity: asInt(map['quantity'], fallback: 1),
      category: asStringOrNull(map['category']),
      stock: asIntOrNull(map['stock']),
    );
  }

  double get lineTotal => price * quantity;

  int get maxQuantity {
    if (stock == null) return 20;
    if (stock! <= 0) return 0;
    return stock! < 20 ? stock! : 20;
  }

  bool get canIncrement => quantity < maxQuantity;

  CartItem copyWith({
    int? productId,
    String? name,
    double? price,
    String? imageUrl,
    int? quantity,
    String? category,
    int? stock,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      stock: stock ?? this.stock,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'product_id': productId,
        'name': name,
        'price': price,
        'image_url': imageUrl,
        'quantity': quantity,
        'category': category,
        'stock': stock,
      };
}
