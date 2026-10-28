import '../utils/json_values.dart';

/// A single item in the storefront catalogue.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.category,
    this.description,
    this.stock,
    this.isActive = true,
    this.createdAt,
  });

  final int id;
  final String name;
  final double price;
  final String imageUrl;
  final String? category;
  final String? description;

  /// `null` means stock is not tracked for this product.
  final int? stock;
  final bool isActive;
  final DateTime? createdAt;

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: asInt(map['id']),
      name: asString(map['name'], fallback: 'Untitled piece').trim(),
      price: asDouble(map['price']),
      imageUrl: asString(map['image_url']).trim(),
      category: asStringOrNull(map['category']),
      description: asStringOrNull(map['description']),
      stock: asIntOrNull(map['stock']),
      isActive: asBool(map['is_active'], fallback: true),
      createdAt: asDate(map['created_at']),
    );
  }

  bool get hasPrice => price > 0;

  bool get isSoldOut => stock != null && stock! <= 0;

  /// Whether the piece can be added to a cart at all.
  bool get isAvailable => isActive && hasPrice && !isSoldOut;

  /// The per-line maximum the checkout function accepts (20), limited by stock.
  int get maxPerOrder {
    if (stock == null) return 20;
    if (stock! <= 0) return 0;
    return stock! < 20 ? stock! : 20;
  }

  /// A quiet stock note for cards and detail pages, or null when untracked.
  String? get stockNote {
    if (stock == null) return null;
    if (stock! <= 0) return 'Sold out';
    if (stock! <= 3) return 'Only ${stock!} left';
    return 'In stock';
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'price': price,
        'image_url': imageUrl,
        'category': category,
        'description': description,
        'stock': stock,
        'is_active': isActive,
      };
}
