import 'package:supabase_flutter/supabase_flutter.dart';

/// A message that is already safe to show to a customer.
class FriendlyException implements Exception {
  const FriendlyException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Turns database, network, and payment errors into short, actionable copy.
///
/// Raw Postgres and provider details are never shown. Messages raised by the
/// checkout functions are already written for customers, so the part after
/// the error code is reused.
String friendlyError(Object error, {String fallback = 'Something went wrong. Please try again.'}) {
  if (error is FriendlyException) return error.message;

  if (error is AuthException) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'That email and password do not match. Try again.';
    }
    if (message.contains('already registered')) {
      return 'An account with this email already exists. Sign in instead.';
    }
    if (message.contains('email not confirmed')) {
      return 'Confirm your email first, then sign in.';
    }
    if (message.contains('rate limit')) {
      return 'Too many attempts. Wait a moment and try again.';
    }
    return error.message;
  }

  if (error is PostgrestException) {
    final raw = (error.message).trim();
    final separator = raw.indexOf(':');
    if (separator > 0 && separator < 40) {
      final code = raw.substring(0, separator).trim();
      final rest = raw.substring(separator + 1).trim();
      const known = <String>{
        'EMPTY_CART',
        'CART_TOO_LARGE',
        'INVALID_CART',
        'INVALID_NAME',
        'INVALID_PHONE',
        'INVALID_ADDRESS',
        'INVALID_EMAIL',
        'INVALID_ACCESS',
        'INVALID_QUANTITY',
        'INVALID_TOTAL',
        'UNAVAILABLE',
        'OUT_OF_STOCK',
        'DUPLICATE_REQUEST',
        'NOT_FOUND',
        'ORDER_NOT_FOUND',
        'AMOUNT_MISMATCH',
      };
      if (known.contains(code) && rest.isNotEmpty) return rest;
    }
    if (error.code == '23505') {
      return 'That request was already submitted. Check your orders.';
    }
    if (error.code == '42501' || error.code == 'PGRST301') {
      return 'You do not have access to that order.';
    }
    return fallback;
  }

  if (error is FunctionException) {
    final details = error.details;
    final code = details is Map ? (details['error'] ?? '').toString() : '';
    switch (code) {
      case 'PAYMENT_NOT_CONFIGURED':
      case 'SERVER_NOT_CONFIGURED':
        return 'Secure payment is not switched on yet. Your order is saved.';
      case 'ORDER_CLOSED':
        return 'This payment has closed. Place a new order to try again.';
      case 'PAYMENT_FAILED':
        return 'The payment did not go through. You can try again from the order.';
      case 'ORDER_NOT_FOUND':
        return 'We could not find that order.';
      case 'INVALID_REFERENCE':
        return 'That order reference is not valid.';
      case 'PAYMENT_PROVIDER_ERROR':
        return 'The payment provider is unavailable right now. Try again in a moment.';
      case 'INVALID_ORDER_TOTAL':
        return 'That order total is not valid. Please start a new order.';
      default:
        if (error.status == 404) {
          return 'Payment is not available yet. Your order has been saved.';
        }
        return 'Payment could not be started. Your order is saved — try again from its page.';
    }
  }

  final text = error.toString().toLowerCase();
  if (text.contains('socketexception') ||
      text.contains('socket exception') ||
      text.contains('failed host lookup') ||
      text.contains('clientexception') ||
      text.contains('xmlhttprequest error') ||
      text.contains('connection closed')) {
    return 'Could not reach the store. Check your connection and try again.';
  }
  if (text.contains('timeout') || text.contains('timed out')) {
    return 'The store took too long to respond. Try again.';
  }
  return fallback;
}
