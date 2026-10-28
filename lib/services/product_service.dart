import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product_model.dart';

/// Reads the public, active catalogue.
/// Combines remote Supabase records with the official ELEVATE merchandise collection.
class ProductService {
  ProductService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _columns =
      'id, name, price, image_url, category, description, stock, is_active, created_at';

  static const List<Product> officialCatalog = <Product>[
    Product(
      id: 4,
      name: 'Elevate Pin',
      price: 25.0,
      imageUrl: 'elevate pin.png',
      category: 'Pins',
      description:
          'The signature ELEVATE metallic badge pin for everyday wear on caps, bags, and jackets.',
      stock: 100,
    ),
    Product(
      id: 5,
      name: 'Set an Example Pin',
      price: 35.0,
      imageUrl: 'elevatepin2.png',
      category: 'Pins',
      description:
          '1 Timothy 4:12 commemorative pin: "Set an example in speech, in conduct, in love, in faith, and in purity."',
      stock: 80,
    ),
    Product(
      id: 6,
      name: 'Light & Salt Pin',
      price: 35.0,
      imageUrl: 'elevatepin3.png',
      category: 'Pins',
      description:
          'Matthew 5:13-14 enamel pin reminding you to be the light of the world and the salt of the earth.',
      stock: 75,
    ),
    Product(
      id: 7,
      name: 'Overcomer Pin',
      price: 35.0,
      imageUrl: 'elevatepin4.png',
      category: 'Pins',
      description:
          'John 16:33 pin: "In this world you will have trouble. But take heart! I have overcome the world."',
      stock: 60,
    ),
    Product(
      id: 8,
      name: 'Called & Chosen Pin',
      price: 35.0,
      imageUrl: 'elevatepin5.png',
      category: 'Pins',
      description:
          '1 Peter 2:9 badge pin celebrating royal priesthood and true identity in Christ.',
      stock: 90,
    ),
    Product(
      id: 9,
      name: 'Bold Witness Pin',
      price: 35.0,
      imageUrl: 'elevatepin6.png',
      category: 'Pins',
      description:
          'Romans 1:16 bold enamel pin for the ELEVATE community: unashamed of the Gospel.',
      stock: 70,
    ),
    Product(
      id: 10,
      name: 'ELEVATE Shirt',
      price: 350.0,
      imageUrl: 'elevate shirt.png',
      category: 'T-shirts',
      description:
          'Heavyweight breathable cotton crewneck shirt with the iconic ELEVATE wordmark across the chest.',
      stock: 50,
    ),
    Product(
      id: 11,
      name: 'ELEVATE Long Sleeve',
      price: 450.0,
      imageUrl: 'longsleeve.png',
      category: 'Long sleeves',
      description:
          'Premium ribbed cuffed long-sleeve tee tailored for comfort, movement, and cool days.',
      stock: 40,
    ),
    Product(
      id: 12,
      name: 'ELEVATE Lanyard',
      price: 95.0,
      imageUrl: 'lanyard.png',
      category: 'Lanyards',
      description:
          'High-density satin woven lanyard with heavy-duty metal clasp and safety breakaway buckle.',
      stock: 120,
    ),
    Product(
      id: 13,
      name: 'ELEVATE Strap Lanyard',
      price: 95.0,
      imageUrl: 'lanyard2.png',
      category: 'Lanyards',
      description:
          'Minimalist dual-tone lanyard strap featuring repeated ELEVATE typography in red and black.',
      stock: 110,
    ),
    Product(
      id: 14,
      name: 'Ruth Bible Bookmark',
      price: 45.0,
      imageUrl: 'elevatebm.png',
      category: 'Bookmarks',
      description:
          'Durable matte laminated Bible bookmark featuring Ruth 1:16 loyalty and devotion scripture.',
      stock: 150,
    ),
    Product(
      id: 15,
      name: 'Jesus Bible Bookmark',
      price: 45.0,
      imageUrl: 'elevatebm2.png',
      category: 'Bookmarks',
      description:
          'The Way, the Truth, and the Life Bible bookmark with gold cord accent and clear protective coat.',
      stock: 150,
    ),
    Product(
      id: 16,
      name: 'Faith Bible Bookmark',
      price: 45.0,
      imageUrl: 'elevatebm3.png',
      category: 'Bookmarks',
      description:
          'Hebrews 11:1 scripture bookmark printed on heavy-weight textured cardstock with velvet ribbon.',
      stock: 130,
    ),
    Product(
      id: 17,
      name: 'Grace Bible Bookmark',
      price: 45.0,
      imageUrl: 'elevatebm4.png',
      category: 'Bookmarks',
      description:
          'Ephesians 2:8 inspirational bookmark for daily scripture reading and devotional reflection.',
      stock: 140,
    ),
    Product(
      id: 18,
      name: 'Hope Bible Bookmark',
      price: 45.0,
      imageUrl: 'elevatebm5.png',
      category: 'Bookmarks',
      description:
          'Romans 15:13 May the God of Hope fill you with all joy and peace devotional bookmark.',
      stock: 140,
    ),
    Product(
      id: 19,
      name: 'Love Bible Bookmark',
      price: 45.0,
      imageUrl: 'elevatebm6.png',
      category: 'Bookmarks',
      description:
          '1 Corinthians 13:13 Faith, Hope, and Love bookmark with elegant typography and tassel.',
      stock: 140,
    ),
  ];

  Future<List<Product>> fetchActiveProducts() async {
    try {
      final rows = await _client
          .from('products')
          .select(_columns)
          .eq('is_active', true)
          .order('id', ascending: true);

      final remoteProducts = (rows as List)
          .whereType<Map>()
          .map((row) => Product.fromMap(Map<String, dynamic>.from(row)))
          .toList(growable: false);

      if (remoteProducts.length >= officialCatalog.length) {
        return remoteProducts;
      }

      final merged = <Product>[];
      final seenNames = <String>{};

      for (final p in remoteProducts) {
        merged.add(p);
        seenNames.add(p.name.toLowerCase().trim());
      }

      for (final p in officialCatalog) {
        if (!seenNames.contains(p.name.toLowerCase().trim())) {
          merged.add(p);
          seenNames.add(p.name.toLowerCase().trim());
        }
      }

      return merged;
    } catch (_) {
      return officialCatalog;
    }
  }
}
