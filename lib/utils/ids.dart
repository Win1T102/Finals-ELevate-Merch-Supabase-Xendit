import 'dart:convert';
import 'dart:math';

/// Client-side codes for guest access and idempotent checkout.
class Ids {
  const Ids._();

  static final Random _random = Random.secure();

  static String _urlSafeToken(int bytes) {
    final data = List<int>.generate(bytes, (_) => _random.nextInt(256));
    return base64Url.encode(data).replaceAll('=', '');
  }

  /// 24 random bytes -> 32 URL-safe characters (192 bits of entropy).
  ///
  /// The database requires at least 32 characters and stores only a SHA-256
  /// hash of this value. It is kept on the device for guest order access.
  static String guestAccessCode() => _urlSafeToken(24);

  /// Stable-per-checkout key so a double tap cannot create two orders.
  static String idempotencyKey() => 'idem_${_urlSafeToken(18)}';
}
