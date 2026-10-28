import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cart_item.dart';
import '../models/order_model.dart';

/// Result of reading the guest order history saved on this device.
class GuestOrderHistory {
  const GuestOrderHistory({required this.orders, required this.unavailable});

  final List<Order> orders;

  /// Orders saved locally whose server record could not be loaded.
  final int unavailable;
}

/// All order reads and writes go through the database functions, except the
/// device-local list of guest access codes.
class OrderService {
  OrderService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  static const String guestOrdersKey = 'elevate.guest_orders.v1';
  static const String customerKey = 'elevate.customer.v1';

  final SupabaseClient _client;

  bool get isSignedIn => _client.auth.currentUser != null;

  String? get signedInEmail => _client.auth.currentUser?.email;

  Future<CreatedOrder> createOrder({
    required List<CartItem> items,
    required CustomerDetails customer,
    required String idempotencyKey,
    String? guestToken,
  }) async {
    final response = await _client.rpc(
      'create_order',
      params: <String, dynamic>{
        'p_items': items
            .map((item) => <String, dynamic>{
                  'product_id': item.productId,
                  'quantity': item.quantity,
                })
            .toList(growable: false),
        'p_customer': customer.toJson(),
        'p_idempotency_key': idempotencyKey,
        'p_guest_token': guestToken,
      },
    );

    final map = response is Map
        ? Map<String, dynamic>.from(response)
        : <String, dynamic>{};
    final created = CreatedOrder.fromRpc(map);
    if (created.reference.isEmpty) {
      throw StateError('The order was created without a reference.');
    }
    return created;
  }

  Future<Order> fetchOrder(String reference, {String? token}) async {
    final response = await _client.rpc(
      'get_guest_order',
      params: <String, dynamic>{
        'p_reference': reference,
        'p_token': token,
      },
    );
    final map = response is Map
        ? Map<String, dynamic>.from(response)
        : <String, dynamic>{};
    return Order.fromRpc(map);
  }

  Future<List<Order>> fetchMyOrders() async {
    if (_client.auth.currentUser == null) return const <Order>[];

    final rows = await _client
        .from('orders')
        .select(
          'external_id, created_at, total_amount, subtotal, shipping_fee, '
          'payment_status, order_status, product_name, customer_name',
        )
        .order('created_at', ascending: false)
        .limit(100);

    return (rows as List)
        .whereType<Map>()
        .map((row) => Order.fromRow(Map<String, dynamic>.from(row)))
        .where((order) => order.reference.isNotEmpty)
        .toList(growable: false);
  }

  Future<GuestOrderHistory> loadGuestOrderHistory() async {
    final accesses = await loadGuestAccesses();
    if (accesses.isEmpty) {
      return const GuestOrderHistory(orders: <Order>[], unavailable: 0);
    }

    final results = await Future.wait(
      accesses.map((access) async {
        try {
          final order = await fetchOrder(access.reference, token: access.token);
          return order;
        } catch (_) {
          return null;
        }
      }),
    );

    final orders = results.whereType<Order>().toList(growable: false);
    return GuestOrderHistory(
      orders: orders,
      unavailable: results.where((order) => order == null).length,
    );
  }

  Future<List<GuestOrderAccess>> loadGuestAccesses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(guestOrdersKey);
      if (raw == null || raw.isEmpty) return const <GuestOrderAccess>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <GuestOrderAccess>[];
      final seen = <String>{};
      final values = <GuestOrderAccess>[];
      for (final row in decoded.whereType<Map>()) {
        final access =
            GuestOrderAccess.fromJson(Map<String, dynamic>.from(row));
        if (access.reference.isEmpty ||
            access.token.isEmpty ||
            !seen.add(access.reference)) {
          continue;
        }
        values.add(access);
      }
      return values;
    } catch (_) {
      return const <GuestOrderAccess>[];
    }
  }

  Future<void> saveGuestAccess(GuestOrderAccess access) async {
    try {
      final existing = await loadGuestAccesses();
      final merged = <GuestOrderAccess>[
        access,
        ...existing.where((item) => item.reference != access.reference),
      ].take(50).toList(growable: false);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        guestOrdersKey,
        jsonEncode(merged.map((item) => item.toJson()).toList(growable: false)),
      );
    } catch (_) {
      // The order still exists server-side; only this shortcut failed.
    }
  }

  Future<void> removeGuestAccess(String reference) async {
    try {
      final existing = await loadGuestAccesses();
      final remaining = existing
          .where((item) => item.reference != reference)
          .toList(growable: false);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        guestOrdersKey,
        jsonEncode(
          remaining.map((item) => item.toJson()).toList(growable: false),
        ),
      );
    } catch (_) {
      // Ignore.
    }
  }

  Future<CustomerDetails?> loadSavedCustomer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(customerKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);
      final name = (map['name'] ?? '').toString();
      final phone = (map['phone'] ?? '').toString();
      final address = (map['address'] ?? '').toString();
      if (name.isEmpty && phone.isEmpty && address.isEmpty) return null;
      return CustomerDetails(
        name: name,
        phone: phone,
        address: address,
        email: (map['email'] ?? '').toString(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCustomer(CustomerDetails customer) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = customer.toJson()..remove('notes');
      await prefs.setString(customerKey, jsonEncode(json));
    } catch (_) {
      // Not important enough to interrupt checkout.
    }
  }
}
