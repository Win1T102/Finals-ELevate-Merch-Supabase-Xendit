import '../utils/json_values.dart';

enum PaymentStatus {
  pending,
  paid,
  failed,
  expired,
  cancelled,
  unknown;

  static PaymentStatus fromRaw(Object? value) {
    switch (asString(value).toLowerCase().trim()) {
      case 'pending':
        return PaymentStatus.pending;
      case 'paid':
      case 'settled':
      case 'completed':
        return PaymentStatus.paid;
      case 'failed':
        return PaymentStatus.failed;
      case 'expired':
        return PaymentStatus.expired;
      case 'cancelled':
      case 'canceled':
        return PaymentStatus.cancelled;
      default:
        return PaymentStatus.unknown;
    }
  }

  String get label {
    switch (this) {
      case PaymentStatus.pending:
        return 'Awaiting payment';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.failed:
        return 'Payment failed';
      case PaymentStatus.expired:
        return 'Payment expired';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.unknown:
        return 'Pending';
    }
  }

  bool get isOpen => this == PaymentStatus.pending || this == PaymentStatus.unknown;

  bool get isPaid => this == PaymentStatus.paid;
}

enum OrderStatus {
  pendingPayment,
  processing,
  completed,
  cancelled,
  unknown;

  static OrderStatus fromRaw(Object? value) {
    switch (asString(value).toLowerCase().trim()) {
      case 'pending_payment':
      case 'pending':
        return OrderStatus.pendingPayment;
      case 'processing':
        return OrderStatus.processing;
      case 'completed':
      case 'fulfilled':
        return OrderStatus.completed;
      case 'cancelled':
      case 'canceled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.unknown;
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.pendingPayment:
        return 'Awaiting payment';
      case OrderStatus.processing:
        return 'Preparing';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.unknown:
        return 'Pending';
    }
  }

  bool get isComplete => this == OrderStatus.completed;
}

/// One line on a placed order, as stored by the database.
class OrderLine {
  const OrderLine({
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
    this.productId,
    this.imageUrl,
  });

  final int? productId;
  final String name;
  final String? imageUrl;
  final double unitPrice;
  final int quantity;
  final double subtotal;

  factory OrderLine.fromMap(Map<String, dynamic> map) {
    return OrderLine(
      productId: asIntOrNull(map['product_id']),
      name: asString(map['product_name'], fallback: 'Item').trim(),
      imageUrl: asStringOrNull(map['product_image_url']),
      unitPrice: asDouble(map['unit_price']),
      quantity: asInt(map['quantity']),
      subtotal: asDouble(map['subtotal']),
    );
  }
}

/// Customer-entered delivery details. Sent to the checkout function, which
/// validates them again server-side.
class CustomerDetails {
  const CustomerDetails({
    required this.name,
    required this.phone,
    required this.address,
    this.email,
    this.notes,
  });

  final String name;
  final String phone;
  final String address;
  final String? email;
  final String? notes;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name.trim(),
        'phone': phone.trim(),
        'address': address.trim(),
        'email': (email ?? '').trim(),
        'notes': (notes ?? '').trim(),
      };
}

/// The keys saved on this device so a guest can reopen an order.
class GuestOrderAccess {
  const GuestOrderAccess({
    required this.reference,
    required this.token,
    required this.createdAt,
    required this.total,
    required this.summary,
  });

  final String reference;
  final String token;
  final DateTime createdAt;
  final double total;
  final String summary;

  factory GuestOrderAccess.fromJson(Map<String, dynamic> map) {
    final created = asDate(map['created_at']) ?? DateTime.now();
    return GuestOrderAccess(
      reference: asString(map['reference']).trim(),
      token: asString(map['token']).trim(),
      createdAt: created,
      total: asDouble(map['total']),
      summary: asString(map['summary'], fallback: 'Order'),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'reference': reference,
        'token': token,
        'created_at': createdAt.toIso8601String(),
        'total': total,
        'summary': summary,
      };
}

/// A placed order, from either the guest RPC or the customer's account rows.
class Order {
  const Order({
    required this.reference,
    required this.createdAt,
    required this.total,
    required this.subtotal,
    required this.shippingFee,
    required this.paymentStatus,
    required this.orderStatus,
    required this.items,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.deliveryAddress,
    this.notes,
    this.paymentUrl,
    this.paymentExpiresAt,
    this.paidAt,
    this.summaryOverride,
  });

  final String reference;
  final DateTime createdAt;
  final double total;
  final double subtotal;
  final double shippingFee;
  final PaymentStatus paymentStatus;
  final OrderStatus orderStatus;
  final List<OrderLine> items;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? deliveryAddress;
  final String? notes;
  final String? paymentUrl;
  final DateTime? paymentExpiresAt;
  final DateTime? paidAt;

  factory Order.fromRpc(Map<String, dynamic> map) {
    final rawItems = map['items'];
    return Order(
      reference: asString(map['reference']).trim(),
      createdAt: asDate(map['created_at']) ?? DateTime.now(),
      total: asDouble(map['total_amount']),
      subtotal: asDouble(map['subtotal']),
      shippingFee: asDouble(map['shipping_fee']),
      paymentStatus: PaymentStatus.fromRaw(map['payment_status']),
      orderStatus: OrderStatus.fromRaw(map['order_status']),
      customerName: asStringOrNull(map['customer_name']),
      customerEmail: asStringOrNull(map['customer_email']),
      customerPhone: asStringOrNull(map['customer_phone']),
      deliveryAddress: asStringOrNull(map['delivery_address']),
      notes: asStringOrNull(map['notes']),
      paymentUrl: asStringOrNull(map['payment_url']),
      paymentExpiresAt: asDate(map['payment_expires_at']),
      paidAt: asDate(map['paid_at']),
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) => OrderLine.fromMap(Map<String, dynamic>.from(item)))
              .toList(growable: false)
          : const <OrderLine>[],
    );
  }

  /// A row from the `orders` table (used for signed-in customers' history).
  factory Order.fromRow(Map<String, dynamic> map) {
    final reference = asString(map['external_id']).trim();
    final summary = asString(map['product_name'], fallback: 'Order');
    return Order(
      reference: reference,
      createdAt: asDate(map['created_at']) ?? DateTime.now(),
      total: asDouble(map['total_amount']),
      subtotal: asDouble(map['subtotal']),
      shippingFee: asDouble(map['shipping_fee']),
      paymentStatus: PaymentStatus.fromRaw(map['payment_status']),
      orderStatus: OrderStatus.fromRaw(map['order_status']),
      customerName: asStringOrNull(map['customer_name']),
      customerEmail: asStringOrNull(map['customer_email']),
      customerPhone: asStringOrNull(map['customer_phone']),
      deliveryAddress: asStringOrNull(map['delivery_address']),
      notes: asStringOrNull(map['notes']),
      paymentUrl: asStringOrNull(map['payment_url']),
      paymentExpiresAt: asDate(map['payment_expires_at']),
      paidAt: asDate(map['paid_at']),
      items: const <OrderLine>[],
      // `product_name` is a human-readable summary written at checkout.
      summaryOverride: summary,
    );
  }

  /// The row factory carries the legacy summary; orders from the RPC have
  /// their line items instead.
  final String? summaryOverride;

  int get itemCount => items.fold<int>(0, (sum, item) => sum + item.quantity);

  String get summary {
    if (items.isNotEmpty) {
      return items.map((item) => '${item.name} × ${item.quantity}').join(', ');
    }
    return summaryOverride ?? 'Order $reference';
  }

  bool get awaitingPayment => paymentStatus.isOpen && orderStatus != OrderStatus.cancelled;

  /// Called after the order changes on the server.
  Order withStatus({
    required PaymentStatus paymentStatus,
    required OrderStatus orderStatus,
    DateTime? paidAt,
  }) {
    return Order(
      reference: reference,
      createdAt: createdAt,
      total: total,
      subtotal: subtotal,
      shippingFee: shippingFee,
      paymentStatus: paymentStatus,
      orderStatus: orderStatus,
      items: items,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      deliveryAddress: deliveryAddress,
      notes: notes,
      paymentUrl: paymentUrl,
      paymentExpiresAt: paymentExpiresAt,
      paidAt: paidAt ?? this.paidAt,
      summaryOverride: summaryOverride,
    );
  }
}

/// Result of `create_order`. The totals here are authoritative.
class CreatedOrder {
  const CreatedOrder({
    required this.reference,
    required this.total,
    required this.subtotal,
    required this.shippingFee,
  });

  final String reference;
  final double total;
  final double subtotal;
  final double shippingFee;

  factory CreatedOrder.fromRpc(Map<String, dynamic> map) {
    return CreatedOrder(
      reference: asString(map['reference']).trim(),
      total: asDouble(map['total']),
      subtotal: asDouble(map['subtotal']),
      shippingFee: asDouble(map['shipping_fee']),
    );
  }
}
