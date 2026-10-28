import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../utils/friendly_error.dart';
import '../utils/json_values.dart';

class PaymentResult {
  const PaymentResult({
    required this.reference,
    required this.status,
    this.checkoutUrl,
    this.expiresAt,
  });

  final String reference;
  final String status;
  final String? checkoutUrl;
  final DateTime? expiresAt;

  bool get isPaid => status == 'paid';

  bool get hasCheckout => (checkoutUrl ?? '').isNotEmpty;
}

/// Starts a Xendit Payment Session through the trusted Edge Function.
///
/// The client never sends an amount: the function reads the order total from
/// the database. The Xendit secret key stays in Supabase function secrets.
class PaymentService {
  PaymentService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<PaymentResult> startPayment({
    required String reference,
    String? guestToken,
  }) async {
    try {
      final response = await _client.functions.invoke(
        AppConfig.createPaymentFunction,
        body: <String, dynamic>{
          'reference': reference,
          if ((guestToken ?? '').isNotEmpty) 'token': guestToken,
        },
      );

      final data = response.data;
      if (data is! Map) {
        throw const FriendlyException(
          'Payment could not be started. Your order is saved.',
        );
      }
      final map = Map<String, dynamic>.from(data);
      final error = asStringOrNull(map['error']);
      if (error != null) {
        throw FriendlyException(friendlyError(
          FriendlyException(_messageFor(error)),
        ));
      }

      return PaymentResult(
        reference: asString(map['reference'], fallback: reference),
        status: asString(map['status'], fallback: 'pending'),
        checkoutUrl: asStringOrNull(map['checkout_url']),
        expiresAt: asDate(map['expires_at']),
      );
    } on FriendlyException {
      rethrow;
    } catch (error) {
      throw FriendlyException(friendlyError(error));
    }
  }

  String _messageFor(String code) {
    switch (code) {
      case 'PAYMENT_NOT_CONFIGURED':
        return 'Payment is not configured yet. Your order is saved.';
      case 'ORDER_CLOSED':
        return 'This payment has closed. Place a new order to try again.';
      case 'PAYMENT_FAILED':
        return 'The payment did not go through. You can try again from the order.';
      case 'ORDER_NOT_FOUND':
        return 'We could not find that order.';
      case 'PAYMENT_PROVIDER_ERROR':
        return 'The payment provider is unavailable right now. Try again in a moment.';
      default:
        return 'Payment could not be started. Your order is saved.';
    }
  }
}
